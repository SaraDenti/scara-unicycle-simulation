//PROGETTO 2: UNICICLO MASTER
//STUDENTI:
//DAMIANO MIRKO 0309989
//DENTI SARA 0311013
//PIETRABISSA ETTORE 0334458
//POMPEO ALESSIO 0310289

//Questo sketch rappresenta un robot SCARA, il cui punto terminale insegue un robot UNICICLO controllato manualmente nel seguente modo:
//freccia SU = accelerazione in avanti;
//freccia GIU = accelerazione all'indietro;
//freccia SINISTRA = accelerazione verso sinistra;
//freccia DESTRA = accelerazione verso destra;
//barra SPAZIATRICE = l'uniciclo si ferma.
//Lo SCARA si muove tramite la cinematica inversa: assegnando ai punti desiderati (xDes, yDes) le coordinate (xU, yU) del centro
//dell'UNICICLO, gli angoli theta1 e theta2 vengono regolati di conseguenza per garantire la configurazione desiderata.
//Lo SCARA segue l'uniciclo secondo una legge proporzionale che garantisce il posizionamento corretto correggendo un errore di misura
//e arrivando nel punto desiderato con velocità variabile tramite una costante kp, modificabile nel codice con i pulsanti '+','-'.
//Mentre gli angoli theta1, theta2 sono gestiti tramite la cinematica inversa del manipolatore planare, la terza variabile di giunto dello
//SCARA, ovvero la posizione del terzo link L3 (che trasla grazie a un giunto prismatico) è strettamente correlata all'altezza (variabile)
//dell'UNICICLO: tramite i pulsanti 'W', 'S' è possibile regolare l'altezza verticale dell'UNICICLO e, di conseguenza, la posizione del 
//terzo link. Si può osservare come la distanza fra il punto terminale dello SCARA e l'uniciclo si mantenga costante. E' inoltre possibile
//impostare il gomito alto premendo il tasto '1' ed impostare il gomito basso premendo il tasto '2'.
//L'altezza della visuale può essere regolata tramite i pulsanti 'Q','A'.
//Se l'UNICICLO esce dallo spazio di lavoro dello SCARA, appare sullo schermo una segnalazione; è ancora possibile muovere l'UNICICLO, mentre
//lo SCARA rimane fermo, assumendo l'ultima posa assunta. Nel momento in cui l'UNICICLO rientra nello spazio di lavoro, lo SCARA
//si riposiziona sopra di esso.
//Per impedire che l'UNICICLO esca dal piano di lavoro, è stato implementato un "effetto Pac-Man": quando il robot esce dal piano, esso viene
//traslato sul bordo opposto ma con le stesse velocità.
//NOTA: in questo sketch le scelte di alcuni pulsanti sono da attribuire a una maggiore comodità nel momento in cui si esegue il programma:
//gli autori hanno preferito mantenere determinati pulsanti vicini tra loro e in punti specifici della tastiera per azionare i robot 
//più agevolmente e più velocemente.


// parametro della funzione camera() che viene modificato con le frecce SU e GIU e determina l'altezza della vista rispetto al robot
float eyeY = 0; 

//parametro per gestire l'anti-aliased del font
boolean aliased = true; 

/******************************************************************************************************************************************************
                                                  VARIABILI GLOBALI MANIPOLATORE PLANARE
******************************************************************************************************************************************************/

// coordinate del centro del link 1 del robot che viene spostato col mouse
float xBase; 
float yBase;

// dimensioni link 0:
float d0x = 30; // lungo x
float d0y = 200; // lungo y
float d0z = 30; // lungo z

// dimensioni link 1
float d1x = 200; // lungo x
float d1y = 30; // lungo y
float d1z = 30; // lungo z

// dimensioni link 2
float d2x = 200; // lungo x
float d2y = 30; // lungo y
float d2z = 30; // lungo z

// dimensioni link 3
float d3x = 30; // lungo x
float d3y = 200; // lungo y
float d3z = 30; // lungo z

//dimensione marker
float d4x = 10; 
float d4y = 10; 
float d4z = 10; 

//distanze effettive tra i punti di giunto per il calcolo della cinematica inversa
//utilizzare le lunghezze dei link porta a un errore di misura che aumenta progressivamente 
//con l'allontanarsi dell'uniciclo dalle coordinate (xBase, yBase)
float l1 = d1x - (d0x + d2z)/2;
float l2 = d2x - (d3x + d2z)/2; 

// parametri giunto (theta1, theta2, d3)
float[] q = {0,0,0}; //coordinate di giunto 
//definisco gli angoli desiderati per approssimare gli angoli di giunto 
float theta1Des = 0;
float theta2Des = 0; 

//legge di controllo proporzionale per il moto dello SCARA
float kp = .1; // la kp del controllo 
float precisione = .001; // la differenza tra angolo finale e desiderato
float gomito = 1; //posizione del gomito dello SCARA 

float xDes, yDes; //coordinate del punto terminale della pinza: da determinare con la cinematica inversa

//Variabili utilizzate per la cinematica inversa dello SCARA
float argAcos2;
float C2;
float S2;

/******************************************************************************************************************************************************
                                                         VARIABILI GLOBALI ROBOT UNICICLO
******************************************************************************************************************************************************/

// dimensioni robot uniciclo
float d5x = 80;
float d5y = 50; 
float d5z = 50;

// dimensioni base freccia direzionale
float d6x = 15;
float d6y = 5;
float d6z = 10;

// dimensioni vertici freccia direzionale
float d1 = 15;
float d2 = 40;
float d3 = 20;
float d4 = 20;

//il valore di firstime determina la posizione iniziale dell'UNICICLO nel momento in cui si avvia la simulazione per la prima volta
boolean firstime = true; 

// coordinate attuali dell'uniciclo
float xU;
float yU;
float thetaU;

float dt = (float) 1/60; // tempo di campionamento
float deltaV = .3; //coefficiente di accelerazione dell'uniciclo 
int nGiri=0;

float v1 = 0; // velocità lineare robot
float v2 = 0; // velocità rotazionale robot

//gestione dell'altezza dell'uniciclo e dello SCARA: 
//le variabili dMin e Dmax impongono dei limiti per l'altezza dell'uniciclo
float dMin = d4; //altezza minima dell'UNICICLO
float scarto = d0y +d2y - d3y - d4; //distanza tra SCARA e UNICICLO. Tale misura viene dal fatto che dMin = d4 = d0y+d2y-d3y-scarto
float dMax= d0y-scarto; //altezza massima UNICICLO

boolean fuoriDalloSpazio =false; //questa variabile vale true se il centro dell'uniciclo è fuori dallo spazio di lavoro dello SCARA
//se questa variabile è true, appare a schermo la segnalazione

/******************************************************************************************************************************************************
                                                                   INIZIO CODICE
******************************************************************************************************************************************************/

//SETUP
void setup() 
{
  size(1000, 800, P3D);
  
  //creazione del font scelto
  PFont myFont;
  myFont = createFont("Georgia",15,aliased);
  textFont(myFont);
  
  stroke(255);
  strokeWeight(2);
  //la xBase e la yBase sono inizializzati al centro della finestra
  xBase = width/2;
  yBase = height/2;  
  smooth();
}

void draw() 
{
  background(0);
  lights();
  
  pianoDAppoggio();
  
// Permette di ruotare la vista:
// camera richiede la posizione del centro e le coordinate della telecamera
  camera((width/2.0), height/2 - eyeY, (height/2.0) / tan(PI*60.0 / 360.0), width/2.0, height/2.0, 0, 0, 1, 0); 
  
  if (mousePressed) 
  {
    xBase = mouseX;
    yBase = mouseY;
  }
  if (keyPressed) 
  {    
    // movimento camera
    if (key == 'A' || key == 'a') {
      eyeY -= 5;
    }
    if (key == 'Q' || key == 'q') {
      eyeY += 5;
    }
    
    //velocità dell'uniciclo 
    if (keyCode == UP) { //aumento velocità longitudinale
      v1 += 5*deltaV;
    }
    if (keyCode == DOWN) { //diminuisco velocità longitudinale
      v1 -= 5*deltaV;
    }
    if (keyCode == LEFT) { //aumento velocità angolare
      v2 += .2*deltaV;
    }
    if (keyCode == RIGHT) { //diminuisco velocità angolare
      v2 -= .2*deltaV;
    }
    
    //stop dell'uniciclo 
    if (key == ' ') {
      v1 = 0; 
      v2 = 0; 
    }
    
    //altezza uniciclo: cambiando il valore d5y (entro dei valori soglia) modifico la posizione del terzo link 
    // l'altezza massima comporta che il terzo link sia a fine corsa, mentre l'altezza minima è stata scelta
    //per essere ugualle all'altezza della freccia 
    if ((key == 'W' || key == 'w') &&  d5y + 1 <=  dMax) {
      d5y += 1;
    }
    if ((key == 'S' || key == 's') &&  d5y - 1 >= dMin) {
      d5y -= 1; 
    }
    
    //gestione velocità del manipolatore:
    if (key == '+') {
      kp += .01;
      if (kp > .5)
      {
        kp=.5;
      }
    }
    if (key == '-') {
      kp -= .01; 
      if (kp < 0.01)
      {
        kp=0.01;
      }
    }
 
    //cambio del segno del gomito
    if (key == '1') { //gomito alto
      gomito = -1;
    }
    if (key== '2'){ //gomito basso
      gomito=1;
    }
  }
  
  muoviUniciclo();
  
  uniciclo();
  
  muoviManipolatore(xU,yU);
  
  manipolatore();
  
  scritte();
  
}


//Questa funzione disegna un piano d'appoggio per il manipolatore
void pianoDAppoggio()
{
  //rappresentazione del piano di appoggio:
  pushMatrix();
  translate (xBase, yBase + (d0y/2) + 1, 0);
  //alla coordinata y viene aggiunto un pixel per far sì che il robot poggi sulla base e quindi non abbia la sua stessa ordinata
  fill (255);
  box (2 * width, 0, 2 * width); //piano rappresentato da una box di altezza nulla
  popMatrix();
}

/******************************************************************************************************************************************************
                                                     DISEGNO E CINEMATICA INVERSA DELLO SCARA
******************************************************************************************************************************************************/


void manipolatore()
{
  q[2]=(d3y-d2y)/2+d4-d5y; //il valore di q[2] dipende da d5y
  
 pushMatrix(); // Memorizza il sistema di riferimento attuale

  fill(128,0,0); // Colore del robot
  
  // Link 0 (base)
  translate(xBase,yBase);
  box(d0x,d0y,d0z);
  
  // Link 1 (si muove con theta1 = q[0])
  rotateY(q[0]); 
  translate((d1x-d0x)/2,-(d0y+d1y)/2,0);  //cambio il sistema di riferimento
  box(d1x,d1y,d1z);
  
  // Link 2 (si muove con theta2 = q[1])
  //attraverso il primo translate mi porto sull'asse della successiva rotazione, 
  //attraverso rotateY ruoto il sistema di riferimento in accordo con la rotazione del giunto
  //attraverso il secondo translate mi pongo al centro del link 2
  translate((d1x-d2z)/2,0,0);
  rotateY(q[1]);
  translate((d2x-d2z)/2,0,0); 
  box(d2x,d2y,d2z);  
  
  // Link 3 (si muove con d3 = q[2])
  translate((d2x-d3x)/2,q[2],0);  
  box(d3x,d3y,d3z);
  
  // Marker
  //il marker deve trovarsi sempre a terra, indipendentemente dall'altezza del link L3
  //per il posizionamento è stata impiegata una funzione che tiene conto di tutte le traslazioni lungo y,
  //mentre lungo x,z ho le stesse coordinate del centro del link L3
  translate (0, d0y + (d1y / 2) - q[2] - (d4y / 2), 0);
  box (d4x, d4y, d4z);
  
  popMatrix();  
  //ritorno al sistema di riferimento iniziale 
}


void muoviManipolatore(float xDes, float yDes) {
  float argACos2 = ( (sq(xDes) + sq(yDes) - sq(l1) - sq (l2)) / (2*l1*l2) );
  
  if (abs(argACos2) <= 1)  //condizione per l'esistenza di una soluzione: l'argomento dell'arcocoseno di theta2 deve essere in modulo minore o uguale a 1
  {
    fuoriDalloSpazio=false;
    theta2Des = gomito * acos (argACos2);
    float C2 = cos (theta2Des);
    float S2 = sin (theta2Des);
    
    theta1Des = atan2 (-l2 * S2 * xDes + (l1 + l2*C2) * yDes, (l1 + l2*C2) * xDes + l2*S2*yDes)+nGiri*2*PI;
    if (abs(theta1Des+2*PI-q[0]) < abs(theta1Des-q[0])) //questa parte di codice permette di evitare i salti causati dall'atan2 in prossimità di 180°. 
    {
      theta1Des = theta1Des+2*PI;
      nGiri += 1;
    }
    else 
    {
      if (abs(theta1Des-2*PI-q[0]) < abs(theta1Des-q[0]))
      {
        theta1Des = theta1Des-2*PI;
        nGiri += -1;
      }
    }
    
    if (abs (q[0] - theta1Des) > precisione) {
      q[0] += kp * (theta1Des - q[0]);
    }
    if (abs (q[1] - theta2Des) > precisione) {
      q[1] += kp * (theta2Des - q[1]);
    }
    
  
  }
  
  //se l'uniciclo esce dallo spazio di lavoro, appare una segnalazione sullo schermo (attivata dal cambio di valore della variabile booleana)
  else
  {
    fuoriDalloSpazio=true;
  }
  
}

/******************************************************************************************************************************************************
                                                         MOVIMENTI E DISEGNO DELL'UNICICLO
******************************************************************************************************************************************************/

void muoviUniciclo() 
{
  if (firstime) { //scelgo una posizione da cui far partire l'uniciclo quando viene avviato il programma
    xU = d1x+d2x-d2z-(d0x+d3x)/2; //segue dal fatto che, alla prima iterazione xU=(d1x-(d0x+d2z)/2)*cos(q[0])+(d2x-(d2z+d3x)/2)*cos(q[0]+q[1]) con q[0]=q[1]=0°
    yU = 0; //segue dal fatto che, alla prima iterazione, =(d1x-(d0x+d2z)/2)*sin(q[0])+(d2x-(d2z+d3x)/2)*sin(q[0]+q[1]) con q[0]=q[1]=0°
    thetaU = atan2(yU, xU);
    firstime = false; 
  }
  else {
    //cinematica uniciclo
    xU = xU + v1 * cos (thetaU) * dt;
    yU = yU + v1 * sin (thetaU) * dt;
    thetaU = thetaU +v2 * dt;
    
    //effetto Pac-Man: se l'uniciclo esce dal piano, ricompare dall'altra parte
    if (xU >= width || xU <= -width)
    {
      xU = -xU;
    }
    if (yU >= width || yU <= -width)
    {
      yU = -yU;
    }
  }
}

void uniciclo()
{
  pushMatrix();
  translate(xBase+xU, yBase+(d0y-d5y)/2, -yU);
  rotateY(thetaU);
  fill(100,149,237);
  box(d5x,d5y,d5z);
  freccia();
  popMatrix();
  
}
//FRECCIA
void freccia()
{
  // disegno freccia direzionale
  pushMatrix();
  translate((d5x/2)+1,0,0);
  fill(255,216,0);
  box(d6x,d6y,d6z);
  popMatrix();
  
  // disegno punta della freccia
  pushMatrix();
  translate(2*d6x,0,0);
  fill(255,216,0);
  beginShape();
  vertex(d2/2, -d4/2, d4/2);
  vertex(d2/2, d4/2, d4/2);
  vertex(d2/2, d4/2, -d4/2);
  vertex(d2/2, -d4/2, -d4/2);
  vertex(d2/2, -d4/2, d4/2);
  endShape(CLOSE);
  
  beginShape();
  vertex(d2/2, -d4/2, d4/2);
  vertex(d2/2, d4/2, d4/2);
  vertex(d2/2+d3, 0, 0);
  vertex(d2/2, -d4/2, d4/2);
  endShape(CLOSE);
  
  beginShape();
  vertex(d2/2, d4/2, d4/2);
  vertex(d2/2, d4/2, -d4/2);
  vertex(d2/2+d3, 0, 0);
  vertex(d2/2, d4/2, d4/2);
  endShape(CLOSE);
  
  beginShape();
  vertex(d2/2, d4/2, -d4/2);
  vertex(d2/2, -d4/2, -d4/2);
  vertex(d2/2+d3, 0, 0);
  vertex(d2/2, d4/2, -d4/2);
  endShape(CLOSE);
  
  beginShape();
  vertex(d2/2, -d4/2, -d4/2);
  vertex(d2/2, -d4/2, d4/2);
  vertex(d2/2+d3, 0, 0);
  vertex(d2/2, -d4/2, -d4/2);
  endShape(CLOSE);
  popMatrix();
}


/******************************************************************************************************************************************************
                                                                 SCRITTE
******************************************************************************************************************************************************/

void scritte() {
  
  pushMatrix();
  
  //il seguente translate viene effettuato per far sì che le scritte siano a distanza fissa dal link 0, lungo x e dal piano d'appoggio lungo y
  translate(xBase-((d1x-(d0x+d2z)/2)+(d2x-(d2z+d3x)/2))-150,yBase+d0y/2-470, 0);
  fill(255);
  
  textSize(25);
  fill(128,0,0);
  text("Theta1 = ",10,30); 
  text(trasformazioneAngoli(q[0])*180/PI,120,30);
  text("gradi",250,30);
  
  text("Theta2 = ",10,80); 
  text(q[1]*180/PI,120,80); //non si controlla se theta2 è compreso tra -180 e 180 gradi vista la presenza del fine corsa dell'angolo stesso
  text("gradi",250,80);
  
  text("d3 = ",10,130); 
  text(q[2] - dMin + 55,120,130);
  text("pixel",250,130);
  
  text ("kpS = ", 10, 220);
  text(kp, 120, 220);
  text("pixel",250, 220);
  
  fill(255);  
  text("Coordinata y vista = ",500,30); 
  text(eyeY,750,30);

  
  if (fuoriDalloSpazio)
  {
    fill(255, 0, 0);
    text ("L'uniciclo è uscito dallo spazio di lavoro!", 500, 120);
  }
  
  fill(100,149,237);
  
  text ("xU = ", 10, 320);
  text(xU, 120, 320);
  text ("pixel", 250, 320);
  text ("yU = ", 10, 370);
  text(yU, 120, 370);
  text("pixel", 250, 370);
  
  popMatrix();
}


//la seguente funzione restituisce l'angolo corrispondente a theta compreso tra -180° e 180°
float trasformazioneAngoli(float theta)
{
  float alpha;
  if (theta>=0)
  {
    alpha = theta % (2*PI);
    if (alpha > PI)
    {
      alpha = alpha - 2*PI;
    }
  } 
  else
  {
    alpha = - abs(theta)%(2*PI);
    if (alpha < -PI)
    {
      alpha = alpha+ 2*PI;
    }
  }
  return alpha;
}
