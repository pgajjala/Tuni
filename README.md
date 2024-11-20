# Tuni
TUNI is an IoT application meant to help tune instruments! TUNI allows users to connect their phone, a Raspberry Pi, a PiTFT screen, and an LED strip to gain visual tuning feedback. 

Users are be able to select a desired note to tune to, play an instrument of their choice, and see how in tune they are. The LED strip will turn more red if users are lower than the desired note, more blue if users are higher than the desired note, and green if the user is in tune.

Since TUNI is intended for all kinds of instruments, users can choose to tue to notes that are in between Western-defined notes.

Here's a demo! https://drive.google.com/file/d/10mf1Yl1irxktqF2IDFuZBN5j3ATMzDqH/view?usp=sharing

## Technical Capabilities
- Send audio from iPhone microphone to iOS app using the Audiokit library.
- Mobile UI has a "desired" slider, so users can choose to tune to a specific note, in either sharps or flats, and beyond just the Western scale. 
- Mobile UI has a "current" slider, signifying what note the user is playing. Audio input updates this slider.
- iPhone has a Bluetooth Low Energy (BLTE) connection to the Raspberry PI and updates a UI on the PiTFT that matches iPhone UI. The PiTFT UI was built with Kivy.
- PiTFT UI connects to the LED strip with Mosquitto (MQTT) Pub/Sub to update the LED strip light.

## Technical Components
<img width="472" alt="Screenshot 2024-11-09 at 9 25 58 AM" src="https://github.com/user-attachments/assets/c7fb3328-81dc-4bba-aa37-0dc09fc44f85">
