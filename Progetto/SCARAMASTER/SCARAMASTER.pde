//PROGETTO 1: SCARA MASTER
//STUDENTI:
//DAMIANO MIRKO 0309989
//DENTI SARA 0311013
//PIETRABISSA ETTORE 0334458
//POMPEO ALESSIO 0310289

//Questo sketch rappresenta un robot UNICICLO che insegue la proiezione sul terreno dell'estremità di un manipolatore SCARA. 
//Attraverso i tasti '1','2','3' è possibile selezionare i giunti dello SCARA e muoverli a piacere tramite le frecce DESTRA-SINISTRA. 
//E' possibile fermare il moto dell'UNICICLO, pigiando i tasti 's','S', e riprenderlo pigiando i tasti 'm','M'.
//Nel caso avvenisse una collisione con la base dello SCARA l'UNICICLO si ferma e cambia colore.
//E' necessario pigiare i tasti 'g','G' per far ripartire l'UNICICLO, il quale può a questo punto ignorare la base dello SCARA comportandosi 
//come un "fantasma".
//Nel caso in cui il terzo link dello SCARA si trovasse ad una altezza tale per cui collide con l'UNICICLO, sia se l'uniciclo si avvicina
//allo SCARA o viceversa, il terzo link dello SCARA si alza automaticamente per evitare la collisione con l'UNICICLO.
//E' infine possibile cambiare l'altezza della visuale, con la freccia SU-GIU, per seguire lo sketch da più angolazioni.

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

// variabile per compattare le condizioni di fine corsa
int segno = 1; //a seconda del segno mi muovo a destra o a sinistra (alto vs basso)

// permette di selezionare il giunto da muovere
int giunto = 0;

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

// parametri giunto (theta1, theta2, d3)
float[] q = {0,0,0}; //coordinate di giunto 

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

// parametri booleani
boolean firstime = true;
boolean move = true;

// coordinate attuali dell'uniciclo
float xU;
float yU;
float thetaU;

// coordinate desiderate dell'uniciclo
float xDes;
float yDes;

float dt = (float) 1/60; // tempo di campionamento

int nGiri=0;
float e_p = 0; // errore posizionamento
float v1 = 0; // velocità lineare robot
float kv1 = 2; // costante legge proporzionale controllo v1
float v2 = 0; // velocità rotazionale robot
float kv2 = 5;  // costante legge proporzionale controllo v2
float thetaDes; // orientamento desiderato (per raggiungere il target)

/******************************************************************************************************************************************************
                                                                   GESTIONE URTO
******************************************************************************************************************************************************/

float diagS = sqrt(sq(d0x/2)+sq(d0z/2)); //lunghezza diagonale dello Scara /2
float diagU = sqrt(sq(d5x/2)+sq(d5z/2)); //lunghezza diagonale dell'Uniciclo /2
float dMin = diagS+diagU; //il caso peggiore lo si ha quando l'angolo tra la diagonale dello SCARA e dell'UNICICLO è pari a -180°

float diagBaseS = sqrt(sq(d3x/2))+sqrt(sq(d3z/2)); //lunghezza diagonale del link 3 dello SCARA /2
float dMinL3 = diagBaseS + diagU;

//parametri booleani
boolean togo = false; //se togo == true l'UNICICLO può attraversare la base dello SCARA
boolean beat = false; //se beat == true l'UNICICLO è all'interno della zona critica

/******************************************************************************************************************************************************
                                                                   INIZIO CODICE
******************************************************************************************************************************************************/

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
    if (keyCode == DOWN)
    {
      eyeY -= 5;
    }
    if (keyCode == UP)
    {
      eyeY += 5;
    }
    // selezione giunti
    if (key == '1')
    {
      giunto = 0;
    }
    if (key == '2')
    {
      giunto = 1;
    }
    if (key == '3')
    {
      giunto = 2;
    }
    // movimento manipolatore SCARA
    if (keyCode == LEFT)
    {
      segno = -1;
      muoviManipolatore();
    }
    if (keyCode == RIGHT)
    {
      segno = 1;
      muoviManipolatore();      
    }
    // movimento uniciclo
    // i tasti 's','S' permettono di fermare il movimento dell'uniciclo
    if ((key == 's') || (key == 'S'))
    {
      move = false;
    }
    // i tasti 'm','M' permettono di riprendere il movimento dell'uniciclo
    if ((key == 'm') || (key == 'M'))
    {
      move = true;
    }
  }    

  collisioneL3();
  
  manipolatore();
  
  muoviUniciclo();
  
  uniciclo();
  
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
                                                         MOVIMENTI E DISEGNO DELLO SCARA
******************************************************************************************************************************************************/

void muoviManipolatore() //deve semplicemente gestire i movimenti 
{
  if (giunto == 0)
  {
    q[giunto] += segno*.02;
  }
  if (giunto == 1)
  {
    if (segno*q[giunto]-165*PI/180<0) //finecorsa
    {
      q[giunto] += segno*.02;
    }
  }
  if (giunto == 2)
  {
    if (segno*q[giunto]-d3y/2+d2y/2<0)
    {
      q[giunto] += segno*1;
    }
  }
}

//Questa funzione disegna il manipolatore planare
void manipolatore()
{
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
  //il marker deve trovarsi a terra sempre, indipendentemente dall'altezza del link L3
  //per il posizionamento è stata impiegata una funzione che tiene conto di tutte le traslazioni lungo y,
  //mentre lungo x,z ho le stesse coordinate del centro del link L3
  translate (0, d0y + (d1y / 2) - q[2] - (d4y / 2), 0);
  box (d4x, d4y, d4z);
  
  popMatrix();  
  //ritorno al sistema di riferimento iniziale 
}

/******************************************************************************************************************************************************
                                                         MOVIMENTI E DISEGNO DELL'UNICICLO
******************************************************************************************************************************************************/

//la seguente funzione serve per calcolare la collisione di q[2] con l'UNICICLO
void collisioneL3()
{
  
  if (q[2]>=d0y+(d1y/2)-(d3y/2)-d5y) // tale risultato viene dalla condizione che yBase-(d0y+d1y)/2+q[2]+d3y/2 <= yBase+d0y/2-d5y
                                     // quando l'UNICICLO si trova sotto il link 3 dello SCARA
  {
    if(move == true)
    {
      q[2] -= 1;
    }
    else
    {
      float d = sqrt(sq(xU-xDes)+sq(yU-yDes));
      if(d <= 2.5*dMinL3)
      {
        q[2] -= 1;
      }
    }
  }
}

void muoviUniciclo()
{
  xDes =(d1x-(d0x+d2z)/2)*cos(q[0])+(d2x-(d2z+d3x)/2)*cos(q[0]+q[1]) ;
  yDes =(d1x-(d0x+d2z)/2)*sin(q[0])+(d2x-(d2z+d3x)/2)*sin(q[0]+q[1]);
  
  if(firstime){//se è la prima iterazione, imposto xU e yU uguali a xDes e yDes, cosicchè il robot sia disegnato sul marker
    xU = xDes;
    yU = yDes;
    thetaU = atan2(yU, xU);;
    firstime = false;
  }
  
  hoSbattuto();
  possoAttraversare();
  // Calcolo errore e controllo
  if ((beat==false) || (beat==true && togo==true))
  { //seguo legge di controllo
    e_p = sqrt(pow(xDes-xU,2)+pow(yDes-yU,2));
    if (move) //se muovi == true, muovo l'uniciclo
    {
      if (e_p > 1) // mi muovo solo se l'errore è maggiore di una certa quantità, ovvero di 1 pixel
      {
        // assegno velocità secondo legge proporzionale
        v1 = -kv1*((xU-xDes)*cos(thetaU) + (yU-yDes)*sin(thetaU)); 

        // Calcolo l'angolo verso il target: scelgo il multiplo di 2PI più vicino all'orientamento corrente del robot
        thetaDes = atan2(yDes-yU,xDes-xU) + nGiri*2*PI;
        if (abs(thetaDes+2*PI-thetaU) < abs(thetaDes-thetaU))
        {
          thetaDes = thetaDes+2*PI;
          nGiri += 1;
        }
        else if (abs(thetaDes-2*PI-thetaU) < abs(thetaDes-thetaU))
        {
            thetaDes = thetaDes-2*PI;
            nGiri += -1;
        }
        
        // assegno velocità angolare secondo legge proporzionale    
        v2 = kv2*(thetaDes-thetaU);
      }
      else // se sono già abbastanza vicino al target non mi muovo
      {
        v1 = 0;
        v2 = 0;
      }
    }
    else
    {
      v1 = 0;
      v2 = 0;
    }
    xU = xU + v1*cos(thetaU)*dt;
    yU = yU + v1*sin(thetaU)*dt;
    thetaU = thetaU + v2*dt;
  }
  else //se ho sbattuto e non posso attraversare sto fermo
  {
    v1=0;
    v2=0;
  }
}

void hoSbattuto()
{
  float dist = sqrt(sq(xU)+sq(yU));
  
  if(dist <= dMin)
  {
    beat = true;
  }
  else
  {
    beat = false;
  }
}

void possoAttraversare()
{
  if ((togo == false)) 
  {
    if ((beat == true)&&(keyPressed && (key == 'g' || key == 'G'))) //togo diventa true se ho sbattuto ed ho premuto il tasto 'G'
    {
      togo = true;
    }
  }
  else
  {
    if (beat == false) //togo diventa false una volta che sono uscita dalla zona critica
    {
      togo = false;
    }
  }
}

void uniciclo()
{
  pushMatrix();
  translate(xBase+xU, yBase+(d0y-d5y)/2, -yU);
  rotateY(thetaU);
  if (beat == false) //se sto all'infuori della zona critica il colore dell'uniciclo è azzurro
  {
    fill(100,149,237);
  }
  else
  {
    fill(255); //se sto all'interno della zona critica il colore dell'uniciclo è bianco
  }
  box(d5x,d5y,d5z);
  freccia();
  popMatrix();
}

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

void scritte()
{
  pushMatrix();
  
  //il seguente translate viene effettuato per far sì che le scritte siano a distanza fissa dal link 0, lungo x e dal piano d'appoggio lungo y
  translate(xBase-((d1x-(d0x+d2z)/2)+(d2x-(d2z+d3x)/2))-150,yBase+d0y/2-470, 0);
  fill(255);
  
  text("Giunto = ",10,30); 
  text(giunto+1,145,30);
  
  textSize(25);
  fill(128,0,0);
  text("Theta1 = ",10,70); 
  text(trasformazioneAngoli(q[0])*180/PI,120,70);
  text("gradi",250,70);
  
  text("Theta2 = ",10,120); 
  text(q[1]*180/PI,120,120); //non si controlla se theta2 è compreso tra -180 e 180 gradi vista la presenza del fine corsa dell'angolo stesso
  text("gradi",250,120);
  
  text("d3 = ",10,170); 
  text(q[2],120,170);
  text("pixel",250,170);
  
  fill(255);  
  text("Coordinata y vista = ",500,30); 
  text(eyeY,750,30);

  fill(100,149,237);
  
  text ("xDes = ", 10, 220);
  text(xDes, 120, 220);
  text ("pixel", 250, 220);
  text("yDes = ", 10, 270);
  text(yDes, 120, 270);
  text("pixel", 250, 270);

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
