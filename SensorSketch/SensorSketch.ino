
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
#define BLE_BAUD_RATE 57600

// Bitmasks
#define LOW_ORDER_BYTE 0xFF // grabs lowest-order byte of unsigned long
#define MAX_UINT16 0x10000

// Constants
const int infraredPin = 3;
const int redPin = 2; 
const int sensorPin = A0;
const int boardLED = 13;
const int binSize = MAX_TX_BUFF;

// Global Variables
int prevPin = infraredPin; // keeps track of the LED that was previously lit

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

  // Toggle red / infrared LEDs. First run: R on, IR off
  currPin = togglePin(prevPin);
  prevPin = currPin;

  startTime = millis() % MAX_UINT16; // Wrap around when time greater than 2 bytes
  for(int i = 5; i < binSize; i++) {
    dataBin[i] = analogRead(sensorPin);
  }
  endTime = millis() % MAX_UINT16;

  fill_header(dataBin, currPin, startTime, endTime);
  ble_write_bytes((unsigned char *)dataBin, (unsigned char)binSize);
  ble_do_events(); // Update BLE connection status. Transmit/receive data
}

// Fills bin header
void fill_header(uint8_t *bin, int currPin, unsigned long startTime, unsigned long endTime) {
  bin[0] = pinCode(currPin);                  // red = 0, infrared = 1
  bin[1] = startTime & LOW_ORDER_BYTE;        // first byte of startTime
  bin[2] = (startTime >> 8) & LOW_ORDER_BYTE; // second byte of startTime
  bin[3] = endTime & LOW_ORDER_BYTE;          // first byte of endTime
  bin[4] = (endTime >> 8) & LOW_ORDER_BYTE;   // second byte of endTime
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
