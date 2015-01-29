/*
  SpO2 Reading
  
  Team: Pulse
 */

//Constants
int timer = 200;           // The higher the number, the slower the timing.
int infraredPin = 7;
int redLEDPin = 8; 
int sensorPin = A0;

//Variables
int freq = timer; 
int infrared = 1; // 1 indicates readings are coming in from infrared light

const int binSize = 100;
float infraredReadings[binSize]; //Size should correspond with packet sent via BLE
//int LEDReadings[100];
int i = 0;

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  pinMode(13, OUTPUT);
  
  pinMode(infraredPin, OUTPUT);
  pinMode(redLEDPin, OUTPUT);
}

void loop() {
  
  infrared = --freq > timer/2; 
    
  ///Blink 
  //Blink cannot use a delay as this will interfere with the analogRead
  if (--freq > timer/2) {
    digitalWrite(13, HIGH);
    digitalWrite(infraredPin, HIGH);
    digitalWrite(redLEDPin, LOW);
  }
  else if (freq > 0) {
    digitalWrite(13, LOW);
    digitalWrite(infraredPin, LOW);
    digitalWrite(redLEDPin, HIGH);
  }
  else {
     freq = timer;
  }
  
  int sensorValue = analogRead(sensorPin);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
  float voltage = sensorValue * (5.0 / 1023.0);

  // apply the calibration to the sensor reading
//  sensorValue = map(sensorValue, sensorMin, sensorMax, 0, 255);
//  sensorValue = constrain(sensorValue, 0, 255);
  
  infraredReadings[i++] = voltage;
 
//  if (infrared) {
//     //infraredReadings[i++] = voltage;
//  }
//  else { 
//    //LEDReadings[j++] = voltage; 
//  }

// Printing in batches to try and increase 
// processor speed. 
  if (i == binSize-1) {
    Serial.println(-100);
      Serial.println(",");

    for(int j=0; j<binSize; j++) {
      Serial.print(infraredReadings[j]);
      Serial.println(",");
    }
    
    Serial.println(-1);
    Serial.println(",");

    i = 0; 
  }
}

void plot(int num) {
  for(int i=0; i<num; i+= 100) {
      Serial.print("-");
  }
    Serial.println(num);
}
