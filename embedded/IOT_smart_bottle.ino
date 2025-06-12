#include "BluetoothSerial.h"

BluetoothSerial SerialBT;


volatile int pulseCount = 0;
const byte flowPin = 21;
const byte buttonPin = 17;

float tagesziel = 1.0; //Tagesziel in l

int fuellrichtung = 1; // 1 = Wasser kommt rein; 0 = Wasser geht raus
float volumeGes = 0.0; // Gesamtvolumen in Litern

void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);
  SerialBT.begin("WasserSensor"); // Bluetooth-Gerätename
  pinMode(flowPin, INPUT_PULLUP); 
  pinMode(buttonPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(flowPin), pulseCounter, FALLING);
}

void loop() {
  // Druecken des Buttons soll die Fließrichtung aendern
  static int lastButtonState = 0;
  int currentButton = digitalRead(buttonPin);

  if (currentButton == HIGH && lastButtonState == LOW) {
    fuellrichtung = 1 - fuellrichtung;
  }
  lastButtonState = currentButton;

  noInterrupts(); // Vermeiden von Race-Conditions
  int countedPulses = pulseCount;
  pulseCount = 0;
  interrupts();

  delay(1000); // 1 Sekunde messen WERT NICHT AENDERN!

  float flowRate = (float)countedPulses / 7.5;
  float volume = flowRate / 60.0;

  if (fuellrichtung == 1) {
    volumeGes += volume;
  } 

  String json = buildJson(volumeGes);
  SerialBT.println(json);

  if (volumeGes >= tagesziel) {  // Erster Ansatz für das Erreichen des Tagesziels
    Serial.println("Tagesziel erreicht!");
    Serial.println(volumeGes);
  }
}


String buildJson(float value) {
  String json = "{";
  json += "\"volumeGes\": ";
  json += String(value, 2); 
  json += "}";
  return json;
}
