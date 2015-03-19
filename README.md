# pulse
Cal Poly Biomedical Engineering Design

##Disclaimer

This project is a result of a class assignment, and it has been graded and accepted as fulfillment of the course requirements. Acceptance does not imply technical accuracy or reliability. Any use of information in this report is done at the risk of the user. These risks may include catastrophic failure of the device or infringement of patent or copyright laws. California Polytechnic State University at San Luis Obispo and its staff cannot be held liable for any use or misuse of the project.

##Abstract

Wearable, noninvasive sensors create an opportunity for precision medicine by considerably lowering the barrier to entry for continuously monitoring vital signs. Pulse is a wearable pulse oximeter ring used to track both heart rate (HR) and blood oxygen saturation levels (SpO2), not of a patient, but of a typical individual. Once collected, this information is transmitted via Bluetooth low energy protocol and recorded by an iOS application that provides the user with details about, and analysis of, their collected health data. Finally, this collected information can be sent to Heartful (a Django Web app) to facilitate analytics allowing the user to garner a greater understanding of what this newly collected information means, as well as compare their fitness to their friends.

<center><img src="/static/Poster.jpg" title="Poster" width="600" /></center>

Monitor Screen             |  Analysis Screen
:-------------------------:|:-------------------------:
<img src="/static/Monitor.png" title="Monitor Screen" width="450" />  |  <img src="/static/Analysis.png" title="Analysis Screen" width="450" />



##Hardware

Utilizing a TinyDuino and TinyShield BLE112.
[TinyCircuits] (https://tiny-circuits.com/products.html)

[BGLib](https://github.com/jrowberg/bglib)

#Notes
Shared Playground Directory: /Users/<#Document#>/Documents/Shared\ Playground\
Data 

#Recognition

[BEMSimpleLineGraph] (https://github.com/Boris-Em/BEMSimpleLineGraph)
