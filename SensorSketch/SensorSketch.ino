
/*
  Pulse Oximetry Reading
  BMED Design
  Cal Poly - San Luis Obispo
  
  Team: Pulse
 */

//RedBear Lab
#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>
#include <services.h> 

//Constants
const int infraredPin = 3;
const int redLEDPin = 2; 
const int sensorPin = A0;
const int boardLED = 13;

//Variables
const int binSize = 30;
uint8_t dataBin[binSize]; //Size should correspond with packet sent via BLE
int i = 0;

void setup() {
  
  //BLE Setup
  ble_set_name("PulseFinder");
  ble_begin();
  
  // Enable serial debug
  Serial.begin(57600);

  //Sensor Setup
  pinMode(boardLED, OUTPUT);

  pinMode(infraredPin, OUTPUT);
  pinMode(redLEDPin, OUTPUT);
}

void loop() {
  uint8_t sensorValue = analogRead(sensorPin);
  dataBin[i++] = sensorValue;
//  Serial.println(sensorValue);
  
  digitalWrite(boardLED, LOW);

  if (i == binSize-1) {
      digitalWrite(boardLED, HIGH);
      
      for(int j=0; j < binSize; j++) {
          ble_write(dataBin[j]);
      }  
      
      i = 0; //Reset Bin
  }
  else { //BLE not connected
    digitalWrite(boardLED, LOW);
  }

  //Crucial
  ble_do_events();
  
  if ( ble_available() ) {
//      Serial.print("Reading: ");    
//      Serial.println(ble_read());
  }
  
  digitalWrite(infraredPin, HIGH);
  digitalWrite(redLEDPin, LOW); 
}
