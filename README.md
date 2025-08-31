# ESP32-Flutter-BLE Echo Server

A Bluetooth Low Energy (BLE) echo server project that demonstrates bidirectional communication between an ESP32 microcontroller and a Flutter mobile application.

## 🚀 Features

- **ESP32 BLE Peripheral**: Acts as a BLE server that receives data and echoes it back
- **Flutter BLE Client**: Mobile application that connects to ESP32 and sends/receives messages
- **Real-time Communication**: Instant echo response from ESP32 to mobile app
- **Cross-platform**: Flutter app works on both Android and iOS
- **Debug Logging**: Comprehensive logging for troubleshooting

## 🏗️ Architecture

```
┌─────────────────┐    BLE    ┌─────────────────┐
│   Flutter App   │◄─────────►│   ESP32 Device  │
│   (Central)     │           │   (Peripheral)  │
└─────────────────┘           └─────────────────┘
```

## 📱 BLE Service Structure

- **Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Write Characteristic**: `beb5483e-36e1-4688-b7f5-ea07361b26a8` (for sending data to ESP32)
- **Notify Characteristic**: `beb5483e-36e1-4688-b7f5-ea07361b26a9` (for receiving data from ESP32)

## 🛠️ Hardware Requirements

- ESP32 development board
- USB cable for programming
- Android/iOS device with Bluetooth support

## 📋 Software Requirements

### ESP32
- Arduino IDE 2.0+
- ESP32 board package (version 3.3.0+)
- Required libraries:
  - `BLEDevice`
  - `BLEServer`
  - `BLEUtils`
  - `BLE2902`

### Flutter
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Required packages:
  - `flutter_blue_plus: ^1.31.0+`

## 🔧 Setup Instructions

### 1. ESP32 Setup

1. Connect ESP32 to your computer via USB
2. Open `ESP32_BLE/ESP32_BLE.ino` in Arduino IDE
3. Select the correct board and port
4. Upload the code to ESP32
5. Open Serial Monitor (115200 baud) to see debug messages

### 2. Flutter Setup

1. Navigate to the Flutter project directory:
   ```bash
   cd flutter_esp32_ble
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 📖 Usage

### ESP32 Operation
1. Power on ESP32
2. ESP32 automatically starts BLE advertising
3. Device name: `ESP32_BLE`
4. Wait for mobile app connection

### Flutter App Operation
1. Launch the app
2. App automatically scans for ESP32_BLE device
3. Once connected, type a message in the text field
4. Press "Send" button
5. ESP32 will echo the message back
6. View message history in the app

## 🔍 Debug Information

### ESP32 Serial Output
- Connection status
- Received data
- Data transmission confirmation
- BLE characteristic properties

### Flutter Debug Console
- BLE scanning status
- Connection establishment
- Characteristic discovery
- Data transmission/reception

## 🐛 Troubleshooting

### Common Issues

1. **ESP32 not found during scan**
   - Ensure ESP32 is powered and code is uploaded
   - Check Serial Monitor for "BLE Echo Server Ready!" message
   - Verify Bluetooth is enabled on mobile device

2. **Connection fails**
   - Restart ESP32
   - Restart Flutter app
   - Check UUIDs match between ESP32 and Flutter code

3. **No echo response**
   - Verify notify characteristic is properly configured
   - Check ESP32 Serial Monitor for received data
   - Ensure Flutter app has proper permissions

### Debug Steps
1. Check ESP32 Serial Monitor for error messages
2. Verify Flutter debug console output
3. Confirm UUIDs are identical
4. Test with simple text messages first

## 📁 Project Structure

```
ESP32-FLUTTER-BLE/
├── ESP32_BLE/
│   └── ESP32_BLE.ino          # ESP32 BLE server code
├── flutter_esp32_ble/
│   ├── lib/
│   │   └── main.dart          # Flutter BLE client app
│   ├── android/               # Android-specific files
│   ├── ios/                   # iOS-specific files
│   └── pubspec.yaml          # Flutter dependencies
└── README.md                  # This file
```

## 🔒 Permissions

### Android
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

### iOS
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

## 📚 Technical Details

### BLE Communication Flow
1. ESP32 advertises BLE service
2. Flutter app discovers and connects to ESP32
3. App discovers service and characteristics
4. App enables notifications on notify characteristic
5. App writes data to write characteristic
6. ESP32 receives data and echoes via notify characteristic
7. App receives echo data and displays it

### Data Format
- **Input**: UTF-8 encoded strings
- **Output**: Same UTF-8 encoded strings (echo)
- **Maximum length**: Limited by BLE MTU size

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

**Author:** Semi Eren Gökyıldız
- **Email:** [gokyildizsemieren@gmail.com](mailto:gokyildizsemieren@gmail.com)
- **GitHub:** [SERENGOKYILDIZ](https://github.com/SERENGOKYILDIZ)
- **LinkedIn:** [Semi Eren Gökyıldız](https://www.linkedin.com/in/semi-eren-gokyildiz/)