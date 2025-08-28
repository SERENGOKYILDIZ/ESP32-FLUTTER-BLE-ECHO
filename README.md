# 🚀 BLE Echo Haberleşme Sistemi

ESP32 ve Flutter kullanarak geliştirilmiş Bluetooth Low Energy (BLE) haberleşme sistemi.

## 📁 Proje Yapısı

```
ESP32-FLUTTER-BLE/
├── 📂 ESP32_BLE/
│   └── 📄 ESP32_BLE.ino               # ESP32 Arduino kodu
├── 📂 flutter_esp32_ble/
│   ├── 📄 lib/main.dart               # Flutter ana uygulama
│   ├── 📄 pubspec.yaml                # Flutter bağımlılıkları
│   └── 📂 android/app/src/main/
│       └── 📄 AndroidManifest.xml     # Android izinleri
├── 📄 KURULUM_VE_TEST_REHBERI.md     # Detaylı kurulum rehberi
└── 📄 README.md                       # Bu dosya
```

## 🔧 Sistem Özellikleri

### ESP32 (BLE Peripheral)
- ✅ BLE Peripheral modu
- ✅ Tek servis, iki karakteristik
- ✅ Write Characteristic: Veri alma
- ✅ Notify Characteristic: Veri gönderme
- ✅ Echo mantığı: Gelen veriyi aynen geri gönderme
- ✅ Seri monitör entegrasyonu
- ✅ Otomatik yeniden bağlanma

### Flutter (BLE Central)
- ✅ Otomatik ESP32 tarama
- ✅ Tek tıkla bağlanma
- ✅ Gerçek zamanlı veri gönderme/alma
- ✅ Modern Material Design UI
- ✅ Bağlantı durumu göstergesi
- ✅ Mesaj geçmişi
- ✅ Hata yakalama ve kullanıcı bildirimleri

## 🚀 Hızlı Başlangıç

### 1. ESP32 Kurulumu
1. Arduino IDE'de ESP32 Board Manager'ı kurun
2. `ESP32_BLE.ino` dosyasını yükleyin
3. Seri monitörde "BLE Echo Server Hazır!" mesajını görün

### 2. Flutter Kurulumu
1. `flutter_esp32_ble` klasöründe `flutter pub get` çalıştırın
2. Android cihazda `flutter run` ile uygulamayı başlatın
3. Uygulama otomatik olarak ESP32_BLE'yi bulup bağlanacak

### 3. Test
1. Flutter uygulamasında herhangi bir mesaj yazın
2. "Gönder" butonuna tıklayın
3. ESP32_BLE'den gelen echo mesajını görün

## 📱 Ekran Görüntüleri

### Bağlantı Öncesi
- ESP32 aranıyor göstergesi
- Bluetooth tarama animasyonu

### Bağlantı Sonrası
- Yeşil "ESP32_BLE'ye Bağlı" göstergesi
- Mesaj gönderme TextField'ı
- Mesaj geçmişi listesi

## 🔗 Teknik Detaylar

### BLE UUID'leri
- **Servis UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Write Characteristic**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- **Notify Characteristic**: `beb5483e-36e1-4688-b7f5-ea07361b26a9`

### Veri Formatı
- UTF-8 string formatında veri gönderimi
- Otomatik encoding/decoding
- Binary veri desteği için kolay genişletilebilir

### Güvenlik
- BLE standart güvenlik özellikleri
- UUID tabanlı servis tanımlama
- Bağlantı durumu kontrolü

## 🛠️ Geliştirme

### ESP32 Geliştirme
- Arduino IDE 2.0+ gerekli
- ESP32 Board Manager kurulumu gerekli
- Seri monitör debug için önerilir

### Flutter Geliştirme
- Flutter SDK 3.0+ gerekli
- `flutter_blue_plus` paketi kullanılıyor
- Android Studio / VS Code önerilir

## 📋 Gereksinimler

### Donanım
- ESP32 geliştirme kartı
- Android telefon (BLE desteği olan)
- USB-C kablosu

### Yazılım
- Arduino IDE 2.0+
- Flutter SDK 3.0+
- ESP32 Board Manager
- Android Studio / VS Code

## 🚨 Önemli Notlar

1. **İlk kullanım**: ESP32'yi USB ile bilgisayara bağlayın
2. **Bluetooth**: Telefonda Bluetooth'un açık olduğundan emin olun
3. **Konum izni**: BLE tarama için konum izni gerekli
4. **UUID değişikliği**: Her iki projede de aynı anda değiştirin

## 📞 Destek

Detaylı kurulum ve test rehberi için `KURULUM_VE_TEST_REHBERI.md` dosyasını inceleyin.

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir. Üretim ortamında güvenlik önlemleri eklenmelidir.

---

**🎯 Hedef**: ESP32 ve Flutter arasında güvenilir BLE haberleşme sistemi kurmak
**🔧 Teknoloji**: Arduino, ESP32, Flutter, BLE
**📱 Platform**: Android
**⚡ Performans**: Gerçek zamanlı veri transferi
