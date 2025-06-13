# This is a Demo Based on The PIC16F15223 Datasheet
This project is designed to demosntrate the PWM and analogue input functionality of the PIC16F15223. It uses the PWM 3 and 4 to control a servo. They both recieve the same output, but PWM3 is 1/4 speed to reach the lower-speed analogue servo PWM spec.    
The analogue input is on C2 (pin 8 on the 14-pin package). PWM3 is on pin C3(7) and PWM4 is on C4 (6).    
This project demonstrates a pure assembly project in MPLAB X IDE v6.25 and is set up to either program to a PICkit BASIC ICD or the built-in simulator.