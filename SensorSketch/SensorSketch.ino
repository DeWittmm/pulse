
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
#include <RBL_services.h>

// BLE shield contraints
#define MAX_TX_BUFF 64  // For Tinyshield, 20
#define MAX_RX_BUFF 64  // For Tinyshield, 20
#define BLE_BAUD_RATE 57600

// Constants
const int infraredPin = 3;
const int redPin = 2; 
const int sensorPin = A0;
const int boardLED = 13;
const int binSize = MAX_TX_BUFF;

void setup() {
  //BLE Setup
  ble_begin();
  ble_set_name("Pulse"); // Name cannot be longer than 10 characters
  ble_do_events(); // Set initial status of board

  // Enable serial debug
  Serial.begin(BLE_BAUD_RATE);

  //Sensor Setup
  pinMode(boardLED, OUTPUT);
  pinMode(infraredPin, OUTPUT);
  pinMode(redPin, OUTPUT);
}

void loop() {
  uint8_t dataBin[binSize], sensorValue;
  int isRed = ble_read();
  togglePin(isRed);
  Serial.println(isRed);

  //Serial.println();   // Debugging
  for(int i = 0; i < binSize; i++) {
    dataBin[i] = analogRead(sensorPin);
    //Serial.println(dataBin[i]);   // Debugging
  }

  ble_write_bytes((unsigned char *)dataBin, (unsigned char)binSize);

  // Updates status of the BLE connection (connected, available, busy, etc.)
  // Transmits and recieves data using buffer arrays built from ble_write, ble_read, etc.
  ble_do_events();
}

// isRed = 1 -> turn on red pin, turn off ir pin
// isRed = 0 -> turn on ir pin, turn off red pin
void togglePin(int isRed) {
  if(isRed) {
    digitalWrite(redPin, HIGH);
    digitalWrite(infraredPin, LOW);
  } else {
    digitalWrite(infraredPin, HIGH);
    digitalWrite(redPin, LOW);
  }
}
