/*
  SpO2 Reading
  
  Team: Pulse
 */

//Constants
int timer = 200;           // The higher the number, the slower the timing.
int infraredPin = 7;
int redLEDPin = 8; 

//Variables
int freq = timer; 
int infrared = 1; // 1 indicates readings are coming in from infrared light

int infraredReadings[100]; //Size should correspond with packet sent vie BLE
int LEDReadings[100]; //Size should correspond with packet sent vie BLE
int i = 0;
int j = 0; 

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  pinMode(13, OUTPUT);
  
  pinMode(7, OUTPUT);
  pinMode(8, OUTPUT);
 
}

void loop() {
  
  infrared = --freq > timer/2; 
    
  ///Blink 
  //Blink cannot use a delay as this will interfere with the analogRead
  if (--freq > timer/2) {
    digitalWrite(13, HIGH);
    digitalWrite(7, HIGH);
    digitalWrite(8, LOW);
  }
  else if (freq > 0) {
    digitalWrite(13, LOW);
    digitalWrite(7, LOW);
    digitalWrite(8, HIGH);
  }
  else {
     freq = timer;
  }
  //Serial.println(freq);
  
  int sensorValue = analogRead(A0);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
  float voltage = sensorValue * (5.0 / 1023.0);
  
  if (infrared) {
     infraredReadings[i++] = voltage;
     Serial.print("Infrared: ");
     Serial.println(voltage);
  }
  else { 
    LEDReadings[j++] = voltage; 
    Serial.print("LED: ");
    Serial.println(voltage);
  }

  //TODO: Exit if array out of bounds
}
