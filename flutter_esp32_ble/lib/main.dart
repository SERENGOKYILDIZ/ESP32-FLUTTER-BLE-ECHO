import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Client',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BleEchoPage(),
    );
  }
}

class BleEchoPage extends StatefulWidget {
  const BleEchoPage({super.key});

  @override
  State<BleEchoPage> createState() => _BleEchoPageState();
}

class _BleEchoPageState extends State<BleEchoPage> {
  // BLE durum değişkenleri
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  
  // UI değişkenleri
  final TextEditingController _messageController = TextEditingController();
  final List<String> _receivedMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  // BLE Servis ve Karakteristik UUID'leri (ESP32 ile aynı olmalı)
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String WRITE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String NOTIFY_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  @override
  void initState() {
    super.initState();
    _initializeBle();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // BLE başlatma
  void _initializeBle() {
    // BLE durum değişikliklerini dinle
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });
  }

  // BLE tarama başlat
  void _startScan() {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == "ESP32_BLE") {
          _stopScan();
          _connectToDevice(result.device);
          break;
        }
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  // BLE taramayı durdur
  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  // ESP32'ye bağlan
  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });

      // Servisleri keşfet
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          // Write karakteristiğini bul
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == WRITE_CHAR_UUID) {
              _writeCharacteristic = characteristic;
            }
            if (characteristic.uuid.toString() == NOTIFY_CHAR_UUID) {
              _notifyCharacteristic = characteristic;
              // Notify dinlemeye başla
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                if (value.isNotEmpty) {
                  String message = utf8.decode(value);
                  setState(() {
                    _receivedMessages.add("ESP32_BLE'den: $message");
                  });
                  _scrollToBottom();
                }
              });
            }
          }
          break;
        }
      }

      _showMessage("ESP32_BLE'ye bağlandı!");
    } catch (e) {
      _showMessage("Bağlantı hatası: $e");
    }
  }

  // Mesaj gönder
  void _sendMessage() async {
    if (_writeCharacteristic == null || _messageController.text.isEmpty) {
      return;
    }

    try {
      String message = _messageController.text;
      List<int> bytes = utf8.encode(message);
      
      await _writeCharacteristic!.write(bytes);
      
      setState(() {
        _receivedMessages.add("Gönderilen: $message");
      });
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showMessage("Gönderme hatası: $e");
    }
  }

  // Bağlantıyı kes
  void _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
        _receivedMessages.clear();
      });
      _showMessage("Bağlantı kesildi");
      _startScan(); // Yeniden taramaya başla
    }
  }

  // En alta kaydır
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Mesaj göster
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Echo Client'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnect,
              tooltip: 'Bağlantıyı Kes',
            ),
        ],
      ),
      body: Column(
        children: [
          // Bağlantı durumu
          Container(
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                                  Text(
                    _isConnected ? 'ESP32_BLE\'ye Bağlı' : 'ESP32_BLE Aranıyor...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                if (_isScanning) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
          
          // Mesaj gönderme alanı
          if (_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Mesajınızı yazın...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Gönder'),
                  ),
                ],
              ),
            ),
          ],
          
          // Gelen mesajlar
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.message, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mesaj Geçmişi (${_receivedMessages.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _receivedMessages.isEmpty
                        ? const Center(
                                                         child: Text(
                               'Henüz mesaj yok...\nESP32_BLE\'ye mesaj gönderin',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _receivedMessages.length,
                            itemBuilder: (context, index) {
                              String message = _receivedMessages[index];
                                                             bool isFromESP32 = message.startsWith('ESP32_BLE\'den:');
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isFromESP32 
                                      ? Colors.blue.shade50 
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isFromESP32 
                                        ? Colors.blue.shade200 
                                        : Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isFromESP32 
                                          ? Icons.bluetooth 
                                          : Icons.send,
                                      color: isFromESP32 
                                          ? Colors.blue 
                                          : Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isConnected
          ? FloatingActionButton(
              onPressed: _startScan,
              child: const Icon(Icons.bluetooth_searching),
            )
          : null,
    );
  }
}
