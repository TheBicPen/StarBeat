# CSCB58-Project

A shoot-em-up game written entirely in MIPS assembly. 


### Features
- Music-based gameplay
- 4 distinct stages
- 2 power-ups
- different enemy movement patterns

### Demo
Available at https://youtu.be/m_Hyqk5NpM8. 


### Usage
Run this with the MARS simulator. 
A public version is available [here](https://courses.missouristate.edu/KenVollmar/MARS/).
There is an updated version with some bugs fixed somewhere, but I no longer have access to it (sorry!).

Run the simulator by executing the JAR file: `java -jar MARS.jar`. 
For convenience, Windows users can create a `run.cmd` file with the contents `start /min cmd /c java -jar Mars.jar` to run the simulator.

Open `game.asm` in MARS.

Open a bitmap display window (`Tools -> Bitmap Display`) with the following settings:
- Unit width in pixels: 8
- Unit height in pixels: 8
- Display width in pixels: 256
- Display height in pixels: 512
- Base Address for Display: 0x10008000 ($gp)

Open a keyboard input window: `Tools -> Keyboard and Display MMIO Simulator`

Highly recommended: run the AHK script (also available as an executable) to use quick inputs. Otherwise, Windows adds a delay to repeating keystrokes in text boxes.
You can adjust the delay in the system settings, but you cannot set it to 0 through the Windows 10 GUI. For this reason, use the script.

Assemble and run the game, making sure to keep the simulation speed at maximum.

#### Controls:
- WASD to move
- P to restart

### Other Notes
This game uses some system MARS-specific system calls for audio. It may not work with other simulators.

The game audio was tuned to best fit the limited MARS audio functionality.
MARS does not support playing multiple sounds at the same time. It also has issues switching between sounds too quickly.
In light of this, some compromises had to be made.


This is the public repo for my CSCB58 project. Note to self: see private repo for labs.
