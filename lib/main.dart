import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Lawn Mower',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  List<BluetoothDevice> devices = [];
  bool isStopButtonPressed = false;

  @override
  void initState() {
    super.initState();
    // Listen for Bluetooth state changes
    FlutterBlue.instance.state.listen((state) {
      if (state == BluetoothState.on) {
        // Start searching for devices
        scanForDevices();
      }
    });
  }

  void scanForDevices() async {
    // Start scanning for Bluetooth devices
    await FlutterBlue.instance.startScan(timeout: const Duration(seconds: 10));
    // Listen for discovered devices
    FlutterBlue.instance.scanResults.listen((results) {
      for (var result in results) {
        print('Discovered device: ${result.device.name}');
        if (!devices.contains(result.device)) {
          setState(() {
            devices.add(result.device);
          });
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice? device) async {
    if (device != null) {
      try {
        await device.connect();
        setState(() {
          connectedDevice = device;
        });
        print("Connected to ${device.name}!");
        // Get services and characteristics
        List<BluetoothService> services = await device.discoverServices();
        for (var service in services) {
          for (var characteristic in service.characteristics) {
            // Look for the characteristic used for communication (replace UUID if needed)
            if (characteristic.uuid.toString() ==
                "00001101-0000-1000-8000-00805F9B34FB") {
              setState(() {
                this.characteristic = characteristic;
              });
            }
          }
        }
      } catch (e) {
        print("Connection error: $e");
      }
    }
  }

  void sendCommand(String command) async {
    if (characteristic != null) {
      List<int> data = utf8.encode(command);
      await characteristic!.write(data);
      // For stop button, trigger animation and delay resetting isStopButtonPressed to false
      if (command == 'S') {
        setState(() {
          isStopButtonPressed = true;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          isStopButtonPressed = false;
        });
      }
    } else {
      print("Characteristic not found!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Lawn Mower Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display selected device name
            connectedDevice != null
                ? Text('Selected Device: ${connectedDevice!.name}')
                : const Text('No device selected'),
            const SizedBox(height: 20),
            // Dropdown menu for selecting devices
            DropdownButton<BluetoothDevice>(
              value: connectedDevice,
              onChanged: connectToDevice,
              items: devices.map<DropdownMenuItem<BluetoothDevice>>(
                  (BluetoothDevice device) {
                return DropdownMenuItem<BluetoothDevice>(
                  value: device,
                  child: Text(device.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand('F'),
                  child: const Text('↑'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand('L'),
                  child: const Text('←'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => sendCommand('R'),
                  child: const Text('→'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand('B'),
                  child: const Text('↓'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendCommand('Z'),
              child: const Text('Cut'),
            ),
            const SizedBox(height: 20),
            // Animated stop button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isStopButtonPressed ? 100 : 80,
              height: 50,
              child: ElevatedButton(
                onPressed: () => sendCommand('S'),
                child: const Text('Stop'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
