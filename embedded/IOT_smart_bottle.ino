#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

volatile int pulseCount = 0;
const byte flowPin = 21;
const byte buttonPin = 17;

int fuellrichtung = 1;

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLECharacteristic *pCharacteristic;

void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);

  pinMode(flowPin, INPUT_PULLUP);
  pinMode(buttonPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);

  // BLE initialisieren
  BLEDevice::init("WasserSensor_BLE"); // Bluetooth-Gerätename
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
}

void loop() {
  // Druecken des Buttons soll die Fließrichtung aendern
  // Bei 1 wird der Wert per Bluetooth geschickt, bei Null nicht
  static int lastButtonState = 0;
  int currentButton = digitalRead(buttonPin);

  if (currentButton == HIGH && lastButtonState == LOW) {
    fuellrichtung = 1 - fuellrichtung;
  }
  lastButtonState = currentButton;

  noInterrupts();
  int countedPulses = pulseCount;
  pulseCount = 0;
  interrupts();

  delay(1000); // 1 Sekunde messen WERT NICHT AENDERN!

  float flowRate = (float)countedPulses / 7.5; // L/min
  float volumePerSecond = flowRate / 60.0;     // L/s
  float volumeMl = volumePerSecond * 1000;      // mL/s


  if (fuellrichtung == 1 && volumeMl != 0) {
    // BLE senden
    char buffer[7];
    dtostrf(volumeMl, 6, 3, buffer); // z. B. " 1500.25"
    pCharacteristic->setValue(buffer);
    pCharacteristic->notify();
  }

  Serial.print("Durchflussrate: ");
  Serial.print(volumeMl);
  Serial.println(" mL/s");
}
