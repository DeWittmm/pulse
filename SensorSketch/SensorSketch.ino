
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
#define MAX_TX_BUFF 64
#define MAX_RX_BUFF 64
#define BLE_BAUD_RATE 57600

// Bitmasks
#define BYTE_1 0xFF // grabs lowest-order byte of unsigned long
#define BYTE_2 0xFF00 // grabs second lowest-order byte of unsigned long
#define MAX_UINT16 0xFFFF

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
  int currPin;
  unsigned long startTime, endTime;

  currPin = togglePin(infraredPin);

  startTime = millis() % (MAX_UINT16 + 1); // Wrap around when time greater than 2 bytes
  for(int i = 5; i < binSize; i++) {
    dataBin[i] = analogRead(sensorPin);
    //Serial.print(dataBin[i] + ", ");
  }
  endTime = millis() % (MAX_UINT16 + 1);

  dataBin[0] = pinCode(currPin); // Pin header (R = 0, IR = 1)
  dataBin[1] = startTime & BYTE_1;
  dataBin[2] = (startTime & BYTE_2) >> 8;
  dataBin[3] = endTime & BYTE_1;
  dataBin[4] = (endTime & BYTE_2) >> 8;

  ble_write_bytes((unsigned char *)dataBin, (unsigned char)binSize);

  // Updates status of the BLE connection (connected, available, busy, etc.)
  // Transmits and recieves data using buffer arrays built from ble_write, ble_read, etc.
  ble_do_events();
}

// R = 0, IR = 1
int pinCode(int pin) {
  return pin - 2;
}

int togglePin(int prevPin) {
  int currPin = (prevPin == infraredPin) ? redPin : infraredPin;

  digitalWrite(currPin, HIGH);
  digitalWrite(prevPin, LOW);

  return currPin;
}
