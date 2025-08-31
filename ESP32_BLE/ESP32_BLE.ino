/*
 * ESP32 BLE Echo Server
 * 
 * This project configures ESP32 as a BLE Peripheral device.
 * It receives data from the phone application and sends it back as an echo.
 * 
 * Features:
 * - BLE Peripheral mode
 * - Single service, two characteristics
 * - Write Characteristic: Data reception
 * - Notify Characteristic: Data transmission
 * - Echo logic: Send back received data as is
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE Service and Characteristic UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WRITE_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define NOTIFY_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// BLE objects
BLEServer* pServer = NULL;
BLECharacteristic* pWriteCharacteristic = NULL;
BLECharacteristic* pNotifyCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Connection status callback class
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE Device Connected!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE Device Disconnected!");
    }
};

// Write characteristic callback class
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.print("Received Data: ");
        Serial.println(rxValue);

        // Echo: Send back received data via notify characteristic
        Serial.println("Writing data to notify characteristic...");
        pNotifyCharacteristic->setValue(rxValue);
        
        Serial.println("Calling notify()...");
        pNotifyCharacteristic->notify();
        
        Serial.println("Data sent back (Echo) - rxValue.length(): " + String(rxValue.length()));
        Serial.println("Notify characteristic UUID: " + String(pNotifyCharacteristic->getUUID().toString().c_str()));
      } else {
        Serial.println("Received data is empty!");
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 BLE Echo Server Starting...");

  // Initialize BLE device
  BLEDevice::init("ESP32_BLE");

  // Create BLE server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create Write Characteristic (Phone writes data here)
  pWriteCharacteristic = pService->createCharacteristic(
                      WRITE_CHAR_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pWriteCharacteristic->setCallbacks(new MyCallbacks());

  // Create Notify Characteristic (ESP32 sends data from here)
  pNotifyCharacteristic = pService->createCharacteristic(
                      NOTIFY_CHAR_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pNotifyCharacteristic->addDescriptor(new BLE2902());
  
  Serial.println("Notify characteristic created");
  Serial.println("UUID: " + String(pNotifyCharacteristic->getUUID().toString().c_str()));
  Serial.println("Properties: " + String(pNotifyCharacteristic->getProperties()));

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Echo Server Ready!");
  Serial.println("Device name: ESP32_BLE");
  Serial.println("Waiting for connection...");
}

void loop() {
  // Check connection status changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Wait for BLE stack
    pServer->startAdvertising(); // Restart advertising
    Serial.println("Advertising restarted");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  delay(100); // Reduce CPU load
}
