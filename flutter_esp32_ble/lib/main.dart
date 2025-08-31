import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';

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
  // BLE status variables
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notifySubscription;
  
  // UI variables
  final TextEditingController _messageController = TextEditingController();
  final List<String> _receivedMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  // BLE Service and Characteristic UUIDs (must match ESP32)
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

  // Initialize BLE
  void _initializeBle() {
    // Listen to BLE status changes
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });
  }

  // Start BLE scanning
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

  // Stop BLE scanning
  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  // Connect to ESP32
  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          // Find write characteristic
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == WRITE_CHAR_UUID) {
              _writeCharacteristic = characteristic;
            }
            if (characteristic.uuid.toString() == NOTIFY_CHAR_UUID) {
              _notifyCharacteristic = characteristic;
              print("Notify characteristic found: ${characteristic.uuid}");
              print("Characteristic properties: ${characteristic.properties}");
              
              // Start listening to notify
              await characteristic.setNotifyValue(true);
              print("setNotifyValue(true) called");
              
              // Cancel previous subscription
              await _notifySubscription?.cancel();
              // Create new subscription
              _notifySubscription = characteristic.value.listen((value) {
                print("Data received from notify characteristic: $value");
                if (value.isNotEmpty) {
                  String message = utf8.decode(value);
                  print("Decoded message: $message");
                  setState(() {
                    _receivedMessages.add("From ESP32_BLE: $message");
                  });
                  _scrollToBottom();
                } else {
                  print("Received data is empty!");
                }
              });
              print("Notify subscription created");
            }
          }
          break;
        }
      }

      _showMessage("Connected to ESP32_BLE!");
    } catch (e) {
      _showMessage("Connection error: $e");
    }
  }

  // Send message
  void _sendMessage() async {
    if (_writeCharacteristic == null || _messageController.text.isEmpty) {
      return;
    }

    try {
      String message = _messageController.text;
      List<int> bytes = utf8.encode(message);
      
      print("Sending message: '$message'");
      print("Byte array: $bytes");
      print("Write characteristic UUID: ${_writeCharacteristic!.uuid}");
      
      await _writeCharacteristic!.write(bytes);
      print("Message sent successfully");
      
      setState(() {
        _receivedMessages.add("Sent: $message");
      });
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print("Send error: $e");
      _showMessage("Send error: $e");
    }
  }

  // Disconnect
  void _disconnect() async {
    if (_connectedDevice != null) {
      // Cancel notify subscription
      await _notifySubscription?.cancel();
      _notifySubscription = null;
      
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
        _receivedMessages.clear();
      });
      _showMessage("Disconnected");
      _startScan(); // Start scanning again
    }
  }

  // Scroll to bottom
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

  // Show message
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
                    _isConnected ? 'Connected to ESP32_BLE' : 'Searching for ESP32_BLE...',
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
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
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
                          'Message History (${_receivedMessages.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _receivedMessages.isEmpty
                        ? const Center(
                                                         child: Text(
                               'No messages yet...\nSend a message to ESP32_BLE',
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
                                                             bool isFromESP32 = message.startsWith('From ESP32_BLE:');
                              
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
