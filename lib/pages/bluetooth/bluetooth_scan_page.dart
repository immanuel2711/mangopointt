import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScanPage extends StatefulWidget {
  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  Set<String> devicesSet = Set();
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      startScan();
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      if (statuses[Permission.bluetooth]!.isGranted &&
          statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted) {
        startScan();
      } else {
        showSnackBar('Bluetooth permissions are denied');
      }
    }
  }

  void startScan() {
    setState(() {
      isScanning = true;
    });

    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesSet.contains(result.device.id.id)) {
          devicesSet.add(result.device.id.id);
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    }).onDone(() {
      setState(() {
        isScanning = false;
      });
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  void toggleScan() {
    if (isScanning) {
      stopScan();
    } else {
      startScan();
    }
  }

  void clearDevices() {
    setState(() {
      devicesList.clear();
      devicesSet.clear();
    });
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.stop : Icons.search),
            onPressed: toggleScan,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearDevices,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(devicesList[index].name.isNotEmpty
                ? devicesList[index].name
                : devicesList[index].id.toString()),
            subtitle: Text(devicesList[index].id.toString()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailsScreen(device: devicesList[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DeviceDetailsScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceDetailsScreen({required this.device});

  @override
  _DeviceDetailsScreenState createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  Future<void> connectToDevice() async {
    try {
      if (isConnected) {
        print('Device already connected, disconnecting first');
        await disconnect();
      }

      await widget.device.connect();
      print('Connected to device');
      setState(() {
        isConnected = true;
        connectionStatus = 'Connected';
      });
    } catch (e) {
      print('Failed to connect: $e');
      setState(() {
        connectionStatus = 'Failed to connect';
      });
    }
  }

  Future<void> disconnect() async {
    try {
      if (!isConnected) {
        print('Device already disconnected');
        return;
      }

      await widget.device.disconnect();
      setState(() {
        isConnected = false;
        connectionStatus = 'Disconnected';
      });
    } catch (e) {
      print('Failed to disconnect: $e');
      setState(() {
        connectionStatus = 'Failed to disconnect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name.isNotEmpty ? widget.device.name : widget.device.id.toString()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device ID: ${widget.device.id}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Device Name: ${widget.device.name}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Connection Status: $connectionStatus', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isConnected ? disconnect : connectToDevice,
              child: Text(isConnected ? 'Disconnect' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
