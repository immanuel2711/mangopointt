import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:bun/pages/auth/signup.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class AddingInwardPage extends StatefulWidget {
  @override
  _AddingInwardPageState createState() => _AddingInwardPageState();
}

class _AddingInwardPageState extends State<AddingInwardPage> {
  String? _selectedState;
  String? _selectedMangoVariety;
  TextEditingController _weightController = TextEditingController();
  TextEditingController _cratesController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> _weightsData = [];

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _weightCharacteristic;
  StreamSubscription<ScanResult>? scanSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;
  bool isScanning = false;
  List<BluetoothDevice> _devicesList = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _cratesController.dispose();
    _phoneController.dispose();
    _stopScan();  // Ensure scanning stops when the page is disposed
    super.dispose();
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetooth.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      _startScan();
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      if (!(statuses[Permission.bluetooth]!.isGranted &&
          statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted)) {
        _showSnackBar('Bluetooth permissions are denied');
      } else {
        _startScan();
      }
    }
  }

  void _startScan() {
    setState(() {
      isScanning = true;
      _devicesList.clear();
    });

    scanSubscription = flutterBlue.scan(timeout: Duration(seconds: 5)).listen(
          (result) {
        if (!_devicesList.contains(result.device)) {
          setState(() {
            _devicesList.add(result.device);
          });
        }
      },
      onDone: () {
        setState(() {
          isScanning = false;
        });
        _showDevicesDialog();
      },
      onError: (error) {
        setState(() {
          isScanning = false;
        });
        _showSnackBar('Scan error: $error');
      },
    );
  }

  void _stopScan() {
    scanSubscription?.cancel();
    setState(() {
      isScanning = false;
    });
    _showDevicesDialog();
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Available Bluetooth Devices'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _devicesList.map((device) {
                return ListTile(
                  title: Text(
                      device.name.isEmpty ? device.id.toString() : device.name),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showConnectDialog(device);
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Stop Scanning'),
              onPressed: () {
                _stopScan();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showConnectDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Device Actions'),
          content: Text('Would you like to connect or disconnect?'),
          actions: <Widget>[
            TextButton(
              child: Text('Connect'),
              onPressed: () {
                Navigator.of(context).pop();
                _connectToDevice(device);
              },
            ),
            TextButton(
              child: Text('Disconnect'),
              onPressed: () {
                Navigator.of(context).pop();
                _disconnectFromDevice();
              },
            ),
          ],
        );
      },
    );
  }

  void _connectToDevice(BluetoothDevice device) async {
    _showSnackBar('Connecting to device...');
    try {
      await device.connect();
      _device = device;
      _showSnackBar('Connected to device');

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == "6e400001-b5a3-f393-e0a9-e50e24dcca9e") {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() ==
                "6e400003-b5a3-f393-e0a9-e50e24dcca9e") {
              _weightCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);
              characteristicSubscription = characteristic.value.listen((value) {
                setState(() {
                  _weightController.text = String.fromCharCodes(value);
                });
              });
            }
          }
        }
      }
    } catch (e) {
      _showSnackBar('Error connecting to device: $e');
    }
  }

  void _disconnectFromDevice() async {
    characteristicSubscription?.cancel();
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
      _showSnackBar('Disconnected from device');
    }
  }

  void _addWeightData() {
    setState(() {
      _weightsData.add({
        'serial': _weightsData.length + 1,
        'weight': double.parse(_weightController.text),
        'crates': int.parse(_cratesController.text),
      });
      _weightController.clear();
      _cratesController.clear();
    });
  }

  void _removeWeightData(int index) {
    setState(() {
      _weightsData.removeAt(index);
      for (int i = 0; i < _weightsData.length; i++) {
        _weightsData[i]['serial'] = i + 1;
      }
    });
  }

  double get _totalWeight {
    return _weightsData.fold(0.0, (sum, item) => sum + item['weight']);
  }

  int get _totalCrates {
    return _weightsData.fold(0, (sum, item) => sum + item['crates'] as int);
  }

  String getLotNumber() {
    if (_selectedState == null ||
        _selectedMangoVariety == null ||
        _phoneController.text.isEmpty) {
      return 'Incomplete Data';
    }

    String stateCode = _stateCodes[_selectedState!]!;
    String phoneNumber = _phoneController.text;
    String date = DateFormat('MMddyy').format(DateTime.now());
    String mangoVarietyCode = _selectedMangoVariety!.split('-').last;

    return '$stateCode$phoneNumber$date$mangoVarietyCode';
  }

  Future<void> _addInwardData(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('lots').doc(data['Lot No']).set(data, SetOptions(merge: true));
  }

  Future<void> _showReviewDialog() async {
    print('_weightController.text: ${_weightController.text}');
    final newData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                Text('Phone Number: ${_phoneController.text}'),
                Text('State: $_selectedState'),
                Text('Mango Variety: $_selectedMangoVariety'),
                Text('Weight: ${_weightController.text} kg'),
                Text('Crates: ${_cratesController.text}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Edit'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () async {
                if (_weightController.text.isNotEmpty) {
                  String? ownr = await context.read<UserProvider>().fetchUserName();
                  print('_weightController.text: ${_weightController.text}');
                  final newData = {
                    'Lot No': getLotNumber(),
                    'Mango': _selectedMangoVariety!,
                    'Inward Date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'Kg':_totalWeight,
                    'Owner': ownr,
                    'Phone No': _phoneController.text,

                    'Stage': 'inward',
                    'State': _selectedState,
                    'Total Crates': _totalCrates,
                    'Weights': _weightsData,
                    'buyer':'',
                    'quality':'',
                    'trade date':'',
                    'rate':''
                  };
                  await _addInwardData(newData);
                  Navigator.of(context).pop(newData);
                } else {
                  _showSnackBar('Please enter weight and crates');
                }
              },
            ),
          ],
        );
      },
    );

    if (newData != null) {
      _showSnackBar('Data submitted successfully');
    }
  }

  final Map<String, String> _stateCodes = {
    'Maharashtra': 'MH',
    'Gujarat': 'GJ',
    'Andhra Pradesh': 'AP',
    'Telangana': 'TS',
    'Karnataka': 'KA',
  };

  final List<String> _states = [
    'Maharashtra',
    'Gujarat',
    'Andhra Pradesh',
    'Telangana',
    'Karnataka',
  ];

  final List<String> _mangoVarieties = [
    'Alphonso-1',
    'Kesar-2',
    'Banganapalli-3',
    'Dasheri-4',
    'Langra-5',
  ];

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adding Inward Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth_disabled),
            onPressed: _disconnectFromDevice,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButton<String>(
                hint: Text('Select State'),
                value: _selectedState,
                onChanged: (newValue) {
                  setState(() {
                    _selectedState = newValue;
                  });
                },
                items: _states.map((state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              DropdownButton<String>(
                hint: Text('Select Mango Variety'),
                value: _selectedMangoVariety,
                onChanged: (newValue) {
                  setState(() {
                    _selectedMangoVariety = newValue;
                  });
                },
                items: _mangoVarieties.map((variety) {
                  return DropdownMenuItem<String>(
                    value: variety,
                    child: Text(variety),
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _cratesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Crates',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addWeightData,
                child: Text('Add Weight Data'),
              ),
              SizedBox(height: 16.0),
              DataTable(
                columns: [
                  DataColumn(label: Text('Serial')),
                  DataColumn(label: Text('Weight')),
                  DataColumn(label: Text('Crates')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _weightsData.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(Text(data['serial'].toString())),
                      DataCell(Text(data['weight'].toString())),
                      DataCell(Text(data['crates'].toString())),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _removeWeightData(data['serial'] - 1);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _showReviewDialog,
                child: Text('Review & Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
