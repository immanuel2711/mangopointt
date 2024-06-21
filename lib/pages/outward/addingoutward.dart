import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class AddingOutwardPage extends StatefulWidget {
  final String lotNo;

  const AddingOutwardPage({Key? key, required this.lotNo}) : super(key: key);

  @override
  _AddingOutwardPageState createState() => _AddingOutwardPageState();
}

class _AddingOutwardPageState extends State<AddingOutwardPage> {
  final _formKey = GlobalKey<FormState>();
  final _dispatchToController = TextEditingController();
  final _weightController = TextEditingController();
  final _cratesController = TextEditingController();
  final _crateWeightController = TextEditingController();

  String? _selectedDispatchTo;
  String? _selectedGrade;
  List<String> _grades = ['G1', 'G2', 'G3', 'G4'];
  List<DocumentSnapshot> _dispatchList = [];

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
    _fetchDispatchList();
    requestPermissions();
  }

  @override
  void dispose() {
    _dispatchToController.dispose();
    _weightController.dispose();
    _cratesController.dispose();
    _crateWeightController.dispose();
    _disconnectFromDevice();
    _stopScan();
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
    if (!isScanning) {
      setState(() {
        isScanning = true;
        _devicesList.clear();
      });

      scanSubscription = flutterBlue.scan(timeout: Duration(seconds: 5)).listen(
            (result) {
          if (!_devicesList.any((device) => device.id == result.device.id)) {
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
  }

  void _stopScan() {
    if (isScanning) {
      scanSubscription?.cancel();
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _showSnackBar('Connecting to device...');
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _weightCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristicSubscription = characteristic.value.listen((value) {
              String weightString = String.fromCharCodes(value);
              double? weight = double.tryParse(weightString);
              if (weight != null) {
                setState(() {
                  _weightController.text = weight.toString();
                });
              }
            });
          }
        }
      }
      setState(() {
        _device = device;
      });
      _showSnackBar('Connected to device');
    } catch (e) {
      _showSnackBar('Error connecting to device: $e');
    }
  }

  Future<void> _disconnectFromDevice() async {
    characteristicSubscription?.cancel();
    if (_device != null) {
      await _device!.disconnect();
    }
    setState(() {
      _device = null;
      _weightCharacteristic = null;
    });
    _showSnackBar('Disconnected from device');
  }

  void _fetchDispatchList() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('dispatch').get();
    setState(() {
      _dispatchList = snapshot.docs;
    });
  }

  List<String> _getFilteredDispatchList(String query) {
    return _dispatchList
        .map((doc) => doc['name'] as String)
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _addOutward() async {
    if (_formKey.currentState!.validate() && _selectedDispatchTo != null && _selectedGrade != null) {
      Map<String, dynamic> outwardDetail = {
        'weight': double.parse(_weightController.text),
        'crates': int.parse(_cratesController.text),
        'crateWeight': double.parse(_crateWeightController.text),
      };

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(
            FirebaseFirestore.instance.collection('lots').doc(widget.lotNo));
        if (snapshot.exists) {
          Map<String, dynamic> existingData =
          snapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> outward = existingData['Outward'] ?? {};

          List<Map<String, dynamic>> existingDetails =
          List<Map<String, dynamic>>.from(outward[_selectedGrade!] ?? []);
          existingDetails.add(outwardDetail);
          outward[_selectedGrade!] = existingDetails;

          existingData['Outward'] = outward;
          existingData['Dispatched To'] = _selectedDispatchTo;

          transaction.update(snapshot.reference, existingData);
        }
      });

      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Bluetooth Device'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: _devicesList.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_devicesList[index].name.isNotEmpty ? _devicesList[index].name : _devicesList[index].id.toString()),
                onTap: () async {
                  Navigator.of(context).pop();
                  _connectToDevice(_devicesList[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Outward Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth_disabled),
            onPressed: _disconnectFromDevice,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dispatchToController,
                decoration: InputDecoration(
                  labelText: 'Dispatch To',
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedDispatchTo = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a dispatch location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: InputDecoration(labelText: 'Grade'),
                items: _grades
                    .map((grade) => DropdownMenuItem(
                  value: grade,
                  child: Text(grade),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a grade';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _cratesController,
                decoration: InputDecoration(
                  labelText: 'Crates',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of crates';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _crateWeightController,
                decoration: InputDecoration(
                  labelText: 'Crate Weight (kg)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter crate weight';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addOutward,
                child: Text('Add Outward'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
