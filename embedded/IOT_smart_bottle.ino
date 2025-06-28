#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <ESP32Time.h>

volatile int pulseCount = 0;
const byte flowPin = 21;
const byte buttonPin = 17;
const byte ledNone = 2;
const byte ledNormal = 4;
const byte ledImportant = 16;

float sessionVolumeMl = 0.0;
int noWaterCounter = 0; 
int fuellrichtung = 1;

bool isConnected = false;
bool isSynched = false;
unsigned long lastSyncAttempt = 0;
const unsigned long syncInterval = 2000;

ESP32Time rtc(0);  

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLECharacteristic* pCharacteristic;

void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

// // Klasse, welche BLE Callback für empfangene Daten betreibt
class MyCallbacks : public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic* characteristic) override {
    std::string value = std::string((char*)characteristic->getData(), characteristic->getLength());
    if (value.length() == 0) return;

    String input = String(value.c_str());
    StaticJsonDocument<128> doc;


    DeserializationError err = deserializeJson(doc, input);
    if (err) {
      Serial.print("JSON-Fehler: ");
      Serial.println(err.c_str());
      return;
    }

if (doc["syncConfirmed"] == true && doc.containsKey("timestamp")) {
  String timestamp = doc["timestamp"];

  struct tm timeinfo;
  if (sscanf(timestamp.c_str(), "%4d-%2d-%2dT%2d:%2d:%2d",
             &timeinfo.tm_year, &timeinfo.tm_mon, &timeinfo.tm_mday,
             &timeinfo.tm_hour, &timeinfo.tm_min, &timeinfo.tm_sec) == 6) {

    timeinfo.tm_year -= 1900;  // struct tm erwartet Jahre seit 1900
    timeinfo.tm_mon -= 1;      // struct tm: 0 = Jan

    time_t epochTime = mktime(&timeinfo);  
    rtc.setTime(epochTime);

    isSynched = true;
    Serial.println("Synchronisation erfolgreich.");
  } else {
    Serial.println("Fehler beim Parsen des Zeitstempels.");
  }
  return;
}


    int typ = doc["DrinkReminderType"];

    // Alle LEDs ausschalten
    digitalWrite(ledNone, LOW);
    digitalWrite(ledNormal, LOW);
    digitalWrite(ledImportant, LOW);

    // LED je nach Typ setzen
    switch (typ) {
      case 0:
        digitalWrite(ledNone, HIGH);
        break;
      case 1:
        digitalWrite(ledNormal, HIGH);
        break;
      case 2:
        digitalWrite(ledImportant, HIGH);
        break;
      case 3:
        break;
      default:
        Serial.println("Unbekannter DrinkReminderType");
        break;
    }
    
    Serial.print("Empfangenes JSON: ");
    Serial.println(input);
  }
};

// Klasse, welche auch Verbindungs-Callbacks eingeht und handelt
class MyServerCallbacks : public BLEServerCallbacks{
    void onConnect(BLEServer* pServer){
    Serial.println("Mit Client verbunden");
    isConnected = true;
    isSynched = false;
    lastSyncAttempt = 0;
  }
  // Advertising bei Disconnect
  void onDisconnect(BLEServer* pServer){
    Serial.println("Client getrennt, starte Advertising");
    delay(500); //Sicherheitsdelay
    isConnected = false;
    isSynched = false;
    BLEDevice::startAdvertising();
  }
};


void setup() {
  Serial.begin(9600);

  rtc.setTime(0, 35, 14, 26, 6, 2025); // 26.06.2025 14:35:00
  pinMode(flowPin, INPUT_PULLUP);
  pinMode(buttonPin, INPUT);
  pinMode(ledNone, OUTPUT);
  pinMode(ledNormal, OUTPUT);
  pinMode(ledImportant, OUTPUT);
  attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);

  BLEDevice::init("WasserSensor_BLE");
  BLEServer* pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());  
  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_WRITE
  );

  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();

  // Advertising beim Neustart
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
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


  if (isConnected && !isSynched) {
    if (millis() - lastSyncAttempt >= syncInterval) {
      StaticJsonDocument<64> syncMsg;
      syncMsg["syncRequest"] = true;
      String syncOut;
      serializeJson(syncMsg, syncOut);
      pCharacteristic->setValue(syncOut.c_str());
      pCharacteristic->notify();
      Serial.println("SyncRequest gesendet: " + syncOut);
      lastSyncAttempt = millis();
    }
    delay(100);
    return;
  }

  noInterrupts();
  int countedPulses = pulseCount;
  pulseCount = 0;
  interrupts();

  delay(1000); // 1 Sekunde messen WERT NICHT AENDERN!

  float flowRate = (float)countedPulses / 7.5;
  float volumePerSecond = flowRate / 60.0;
  float volumeMl = volumePerSecond * 1000.0;

  if (fuellrichtung == 1 ) {
    if (volumeMl > 0){
        sessionVolumeMl += volumeMl;
        noWaterCounter = 0;
    } else{
      noWaterCounter++;
    }
    //BLE senden
    if (noWaterCounter >= 3 && sessionVolumeMl > 0 && isConnected && isSynched ) {
      StaticJsonDocument<64> doc;
      doc["amountMl"] = sessionVolumeMl;
      doc["timestamp"] = rtc.getTime("%Y-%m-%dT%H:%M:%S.000Z");

      String output;
      serializeJson(doc, output);

      pCharacteristic->setValue(output.c_str());
      pCharacteristic->notify();

      Serial.print("Gesendet: ");
      Serial.println(output);

      sessionVolumeMl = 0;
    }
  }
}
