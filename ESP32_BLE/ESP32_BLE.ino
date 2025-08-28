/*
 * ESP32 BLE Echo Server
 * 
 * Bu proje ESP32'yi BLE Peripheral olarak yapılandırır.
 * Telefon uygulamasından gelen verileri alır ve aynısını geri gönderir.
 * 
 * Özellikler:
 * - BLE Peripheral modu
 * - Tek servis, iki karakteristik
 * - Write Characteristic: Veri alma
 * - Notify Characteristic: Veri gönderme
 * - Echo mantığı: Gelen veriyi aynen geri gönderme
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE Servis ve Karakteristik UUID'leri
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WRITE_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define NOTIFY_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// BLE nesneleri
BLEServer* pServer = NULL;
BLECharacteristic* pWriteCharacteristic = NULL;
BLECharacteristic* pNotifyCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Bağlantı durumu callback sınıfı
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE Cihazı Bağlandı!");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE Cihazı Koptu!");
    }
};

// Write karakteristiği callback sınıfı
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        Serial.print("Gelen Veri: ");
        for (int i = 0; i < rxValue.length(); i++) {
          Serial.print(rxValue[i]);
        }
        Serial.println();

        // Echo: Gelen veriyi notify karakteristiği ile geri gönder
        pNotifyCharacteristic->setValue(rxValue);
        pNotifyCharacteristic->notify();
        
        Serial.println("Veri geri gönderildi (Echo)");
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 BLE Echo Server Başlatılıyor...");

  // BLE cihazını başlat
  BLEDevice::init("ESP32_BLE");

  // BLE sunucusunu oluştur
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // BLE servisini oluştur
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Write Karakteristiği oluştur (Telefon buraya veri yazar)
  pWriteCharacteristic = pService->createCharacteristic(
                      WRITE_CHAR_UUID,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pWriteCharacteristic->setCallbacks(new MyCallbacks());

  // Notify Karakteristiği oluştur (ESP32 buradan veri gönderir)
  pNotifyCharacteristic = pService->createCharacteristic(
                      NOTIFY_CHAR_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pNotifyCharacteristic->addDescriptor(new BLE2902());

  // Servisi başlat
  pService->start();

  // Advertising başlat
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Echo Server Hazır!");
  Serial.println("Cihaz adı: ESP32_BLE");
  Serial.println("Bağlantı bekleniyor...");
}

void loop() {
  // Bağlantı durumu değişikliklerini kontrol et
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // BLE stack için bekle
    pServer->startAdvertising(); // Yeniden advertising başlat
    Serial.println("Yeniden advertising başlatıldı");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  delay(100); // CPU yükünü azalt
}
