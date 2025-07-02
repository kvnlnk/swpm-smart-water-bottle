#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <ESP32Time.h>
#include "WaterBottleDisplay.h"

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Input/Output Pins
volatile int pulseCount = 0;
const byte flowPin = 19;
const byte ledNone = 14;
const byte ledNormal = 12;
const byte ledImportant = 13;
const byte randomWaterDataPin = 17;

// Water Variables
unsigned long lastFlowCheck = 0;
const unsigned long FLOW_CHECK_INTERVAL = 1000;
float sessionVolumeMl = 0.0;
int noWaterCounter = 0; 
int fillingDirection = 1;
int waterGoal = 4000;
int currentWater = 0;

// Synchronisation Variables
unsigned long lastSyncRequestTime = 0;
const unsigned long SYNC_REQUEST_INTERVAL = 2000; 
bool timeSyncRequested = false;
bool timeSyncConfirmed = false;
bool lastSynchedState = false;

// Connection Status
bool isConnected = false;
bool lastConnectedState = false;

// Display Variables
unsigned long messageDisplayStart = 0;
bool showReminderMessage = false;

// Status Display Variables
unsigned long statusDisplayStart = 0;
bool statusDisplayActive = false;
bool shouldShowStatus = false;
int currentReminderType = 0;

// ESP32Time Object
ESP32Time rtc(0); 

// BLE Variables
BLECharacteristic* pCharacteristic;
BLEServer* pServer;

void setRTCFromTimestamp(String timestamp) {
  // Timestamp Format: "2025-06-26T14:35:00.000Z"
  // Parsing: YYYY-MM-DDTHH:MM:SS.sssZ
  if (timestamp.length() < 19) {
    Serial.println("Invalid Timestamp Format");
    return;
  }
  
  // Extract year, month, day, hour, minute, second from the timestamp
  int year = timestamp.substring(0, 4).toInt();
  int month = timestamp.substring(5, 7).toInt();
  int day = timestamp.substring(8, 10).toInt();
  int hour = timestamp.substring(11, 13).toInt();
  int minute = timestamp.substring(14, 16).toInt();
  int second = timestamp.substring(17, 19).toInt();
  
  // Set RTC time: second, minute, hour, day, month, year
  rtc.setTime(second, minute, hour, day, month, year);
  
  Serial.println("RTC successfully set:");
  Serial.print("New Time: ");
  Serial.println(rtc.getTime("%Y-%m-%d %H:%M:%S"));
}

void sendTimeSyncRequest() {
  if (pServer->getConnectedCount() == 0) return;
  
  JsonDocument doc;
  doc["syncRequest"] = true;
 
  String output;
  serializeJson(doc, output);
  pCharacteristic->setValue(output.c_str());
  pCharacteristic->notify();

  Serial.print("Sync-Request sent: ");
  Serial.println(output);
}

void handleTimeSynchronization() {
  // Only if sync is requested but not confirmed
  if (!timeSyncRequested || timeSyncConfirmed) return;

  // Only if enough time has passed
  if (millis() - lastSyncRequestTime < SYNC_REQUEST_INTERVAL) return;
  
  // Send sync request
  sendTimeSyncRequest();
  lastSyncRequestTime = millis();
}

void sendWaterDataViaBLE(float volumeMl) {
  if (pServer->getConnectedCount() == 0) return;
  
  JsonDocument doc;
  doc["amountMl"] = volumeMl;
  doc["timestamp"] = rtc.getTime("%Y-%m-%dT%H:%M:%S.000Z");
 
  String output;
  serializeJson(doc, output);
  pCharacteristic->setValue(output.c_str());
  pCharacteristic->notify();

  Serial.print("Sent: ");
  Serial.println(output);
}

void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void processFlowSensorData(int countedPulses, bool isConnected) {
  float flowRate = (float)countedPulses / 7.5;
  float volumePerSecond = flowRate / 60.0;
  float volumeMl = volumePerSecond * 1000.0;
  
  if (fillingDirection == 1) {
    if (volumeMl > 0) {
      sessionVolumeMl += volumeMl;
      noWaterCounter = 0;
    } else {
      noWaterCounter++;
    }
    
    // Send water data if enough time (3s) has passed without water
    if (noWaterCounter >= 3 && sessionVolumeMl > 0 && isConnected && timeSyncConfirmed) {
      sendWaterDataViaBLE(sessionVolumeMl);
      sessionVolumeMl = 0;
    }
  }
}

void generateAndSendRandomWaterData(bool isConnected) {
  static int lastButtonState = 0;
  int currentButton = digitalRead(randomWaterDataPin);
 
  if (currentButton == LOW && lastButtonState == HIGH) {
    if (timeSyncConfirmed && isConnected) {
      // Random value between 1 and 1000 ml
      float randomVolume = random(1, 1001);
      sendWaterDataViaBLE(randomVolume);
      Serial.println("Test-Water-Data sent: " + String(randomVolume) + " ml");
    } 
    // Debounce delay
    delay(200); 
  }
  lastButtonState = currentButton;
}

// Server Callbacks for Connect/Disconnect Events
class WaterBottleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    Serial.println("Client connected");
    // Start time synchronization on connect
    timeSyncRequested = true;
    timeSyncConfirmed = false;
    lastSyncRequestTime = 0; // Send immediately
    Serial.println("Starting time synchronization...");
  }
  
  void onDisconnect(BLEServer* pServer) override {
    Serial.println("Client disconnected");
    // Reset synchronization
    timeSyncRequested = false;
    timeSyncConfirmed = false;
    // Restart advertising after short delay
    delay(500);
    BLEDevice::startAdvertising();
    Serial.println("Started advertising again");
  }
};

// BLE Callback Handler for Characteristic Writes
class WaterBottleBLEHandler : public BLECharacteristicCallbacks {
private:
  void handleTimeSynchronization(const JsonDocument& doc) {
    timeSyncConfirmed = true;
    timeSyncRequested = false;
    Serial.println("Time synchronization confirmed!");

    // Set RTC time from the received timestamp
    if (doc["timestamp"].is<String>()) {
      String timestamp = doc["timestamp"];
      Serial.print("Time received: ");
      Serial.println(timestamp);
      
      setRTCFromTimestamp(timestamp);
    }
  }
  
  void handleDrinkReminder(const JsonDocument& doc) {
    int reminderType = doc["DrinkReminderType"];
    setReminderLEDs(reminderType);
  }

  void handleWaterGoal(const JsonDocument& doc) {
    int receivedWaterGoal = doc["waterGoal"];
    if (waterGoal != receivedWaterGoal) {
      waterGoal = receivedWaterGoal;
      if (isConnected && timeSyncConfirmed && !statusDisplayActive) {
        showWaterInfo();
      }
    }
  }
    
  void handleCurrentWater(const JsonDocument& doc) {
    int receivedCurrentWater = doc["currentWater"];
    if (currentWater != receivedCurrentWater) {
      currentWater = receivedCurrentWater;
      if (isConnected && timeSyncConfirmed && !statusDisplayActive) {
        showWaterInfo();
      }
    }
  }

public:
  void onWrite(BLECharacteristic* characteristic) override {
    std::string value = std::string((char*)characteristic->getData(), characteristic->getLength());
    if (value.length() == 0) return;
    
    String input = String(value.c_str());
    JsonDocument doc;
    DeserializationError err = deserializeJson(doc, input);
    
    if (err) {
      Serial.print("Error in JSON: ");
      Serial.println(err.c_str());
      return;
    }

    Serial.print("Received JSON: ");
    Serial.println(input);

    // Time synchronization confirmation check
    if (doc["syncConfirmed"].is<bool>() && doc["syncConfirmed"] == true) {
      handleTimeSynchronization(doc);
      return;
    }

    // Process DrinkReminderType
    if (doc["DrinkReminderType"].is<int>()) {
      handleDrinkReminder(doc);
    }

    // Process water goal
    if (doc["waterGoal"].is<int>()) {
      handleWaterGoal(doc);
    }

    // Process current water
    if (doc["currentWater"].is<int>()) {
      handleCurrentWater(doc);
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Initialize TFT display
  initializeDisplay();

  // Set default RTC time 
  rtc.setTime(0, 35, 14, 26, 6, 2025); 

  // Initialize pins
  pinMode(flowPin, INPUT_PULLUP);
  pinMode(randomWaterDataPin, INPUT_PULLUP);
  pinMode(ledNone, OUTPUT);
  pinMode(ledNormal, OUTPUT);
  pinMode(ledImportant, OUTPUT);
  attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);

  BLEDevice::init("Smart Water Bottle");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new WaterBottleServerCallbacks()); 
  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_WRITE
  );

  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new WaterBottleBLEHandler());
  pService->start();

  // Advertising beim Neustart
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  // Set advertising parameters / helps with iphone connection issues
  pAdvertising->setMinPreferred(0x06);  
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("Waiting for client connection...");

  // Initialize random seed for random water data
  randomSeed(analogRead(0)); 
}

void loop() {
  unsigned long now = millis();
  
  // Handle status display logic
  if (!showReminderMessage) {
    updateStatusDisplayLogic();
  }

  // Handle disconnected clients and restart advertising
  static bool wasConnected = false;
  isConnected = pServer->getConnectedCount() > 0;

  if (wasConnected && !isConnected) {
    Serial.println("Client hat getrennt (loop-Check)");
    BLEDevice::startAdvertising();
  }
  wasConnected = isConnected;

  // Handle time synchronization requests
  handleTimeSynchronization();

  // Process flow sensor data every second without delay
  if (now - lastFlowCheck >= FLOW_CHECK_INTERVAL) {
    lastFlowCheck = now;

    noInterrupts();
    int countedPulses = pulseCount;
    pulseCount = 0;
    interrupts();

    processFlowSensorData(countedPulses, isConnected);
  }

  if (isConnected) {
    generateAndSendRandomWaterData(isConnected);
  }
}