# SCARA–Unicycle Simulation

Two interactive robotics simulations built in Processing. In **SCARAMASTER**, you control the SCARA manipulator and the unicycle follows the ground projection of its end effector. In **UNIMASTERFINALE**, you drive the unicycle and the SCARA end effector tracks it.

## How to run

1. Download or clone this repository.
2. Open `SCARAMASTER.pde` or `UNIMASTERFINALE.pde` in Processing.
3. Press **Run** and click the simulation window before using the keyboard controls.

## SCARAMASTER — Control the SCARA

The unicycle follows the ground projection of the SCARA end effector as you move the arm.

| Key | Action |
|---|---|
| `1`, `2`, `3` | Select a SCARA joint |
| `←` / `→` | Move the selected joint |
| `S` | Stop the unicycle |
| `M` | Resume unicycle motion |
| `G` | Restart the unicycle after a base collision and enable ghost mode |
| `↑` / `↓` | Adjust the camera height |

If the unicycle hits the SCARA base, it stops and changes colour. Pressing `G` lets it move through the base in ghost mode. The SCARA’s third link automatically lifts to avoid a collision with the unicycle.

## UNIMASTER — Drive the unicycle

The SCARA tracks the centre of the unicycle using inverse kinematics and proportional control. Its prismatic joint follows changes in the unicycle’s height, keeping a constant vertical gap between the end effector and the unicycle.

| Key | Action |
|---|---|
| `↑` / `↓` | Accelerate forwards or backwards |
| `←` / `→` | Steer left or right |
| `Space` | Stop the unicycle |
| `+` / `-` | Increase or decrease the tracking gain `kp` |
| `W` / `S` | Adjust the unicycle’s height |
| `1` / `2` | Select the elbow-up or elbow-down configuration |
| `Q` / `A` | Adjust the camera height |

If the unicycle leaves the SCARA’s reachable workspace, a warning appears and the arm holds its last pose. Tracking resumes when the unicycle re-enters the workspace. At the edge of the simulation area, the unicycle wraps around to the opposite side while retaining its velocities.

## Credits

Robotics laboratory group project at the University of Rome Tor Vergata, developed by Mirko Damiano, Sara Denti, Ettore Pietrabissa and Alessio Pompeo.
