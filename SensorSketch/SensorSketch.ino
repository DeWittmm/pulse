
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
#define MAX_TX_BUFF 20
#define BLE_BAUD_RATE 57600

// Bitmasks
#define BYTE 0xFF // grabs lowest-order byte of unsigned long
#define MAX_UINT16 0x10000

// Constants
const int infraredPin = 3;
const int redPin = 2; 
const int sensorPin = A0;
const int boardLED = 13;
const int binSize = MAX_TX_BUFF;
const int batchSize = 50; // number of red / infrared bins in a row
const int capacitorCharge = 1100; // millis that it takes to charge capacitor

// Global Variables
int currPin = infraredPin; // keeps track of the LED that was previously lit
int batchCount = 0;

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
  digitalWrite(infraredPin, HIGH); //DEBUGGING
}

void loop() {
  uint8_t dataBin[binSize], sensorValue;
  unsigned long startTime, endTime, startSend, endSend;

  // Toggle red / infrared LEDs. First run: R on, IR off
  if(batchCount == batchSize) {
    currPin = togglePin(currPin);
    batchCount = 0;
    delay(capacitorCharge);
  }

  dataBin[0] = pinCode(currPin);
  for(int i = 1; i < binSize; i++) {
    int value = analogRead(sensorPin); // returns 10 bit unsigned number
    dataBin[i] = (unsigned int)value;
  }

  ble_write_bytes((unsigned char *)dataBin, (unsigned char)binSize);
  ble_do_events(); // Update BLE connection status. Transmit/receive data
  batchCount++;
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
