// BUTTON LOGIC DEFINITIONS
#define BUTTON_PIN 15
#define LED_PIN 13
#define PRESS_TIME 3000      // 3-second hold to trigger SOS
#define SOS_COOLDOWN 7000    // 7-second cooldown

// BLE LIBRARIES
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE UUIDs
#define SERVICE_UUID  "12345678-1234-1234-1234-1234567890ab"
#define SOS_CHAR_UUID "abcd1234-5678-1234-5678-abcdef123456"

BLECharacteristic *sosCharacteristic = nullptr;

unsigned long pressStart = 0;
unsigned long lastSOSTime = 0;

bool buttonPressed = false;
bool sosSent = false;

void setup() {
  Serial.begin(115200);

  // Button & LED setup
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // BLE setup
  BLEDevice::init("Safety Pendant");
  BLEServer *server = BLEDevice::createServer();
  BLEService *service = server->createService(SERVICE_UUID);

  sosCharacteristic = service->createCharacteristic(
    SOS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );

  // Initial value = "0" for LightBlue
  sosCharacteristic->setValue("0");
  sosCharacteristic->addDescriptor(new BLE2902());

  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->start();

  Serial.println("BLE ready and advertising");
}

void loop() {
  int buttonState = digitalRead(BUTTON_PIN);

  if (buttonState == LOW) { // Button pressed
    if (!buttonPressed) {
      buttonPressed = true;
      pressStart = millis();
      sosSent = false;
      Serial.println("Button pressed...");
    } else {
      // Held long enough + cooldown check
      if (!sosSent && (millis() - pressStart >= PRESS_TIME) &&
          (millis() - lastSOSTime >= SOS_COOLDOWN)) {

        sosSent = true;
        lastSOSTime = millis();

        Serial.println("SOS TRIGGERED!");
        digitalWrite(LED_PIN, HIGH); // LED feedback

        // Send BLE notification as text for LightBlue
        sosCharacteristic->setValue("1");
        sosCharacteristic->notify();
      }
    }
  } else { // Button released
    if (buttonPressed) {
      buttonPressed = false;

      if (sosSent) {
        Serial.println("SOS sent on release");

        // Reset BLE characteristic to "0" and notify
        sosCharacteristic->setValue("0");
        sosCharacteristic->notify();

        digitalWrite(LED_PIN, LOW); // Turn off LED
        sosSent = false;            // ready for next trigger
      } else {
        Serial.println("Button released too soon, no SOS");
      }
    }
  }
}