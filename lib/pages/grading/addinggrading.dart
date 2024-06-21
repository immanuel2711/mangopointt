import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class AddingGradingPage extends StatefulWidget {
  final String lotNo;

  const AddingGradingPage({Key? key, required this.lotNo}) : super(key: key);

  @override
  _AddingGradingPageState createState() => _AddingGradingPageState();
}

class _AddingGradingPageState extends State<AddingGradingPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _cratesController = TextEditingController();
  final _crateWeightController = TextEditingController();
  String? _selectedGrade;
  List<String> _grades = ['G1', 'G2', 'G3', 'Wastage'];
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _weightCharacteristic;
  StreamSubscription<ScanResult>? scanSubscription;
  StreamSubscription<List<int>>? characteristicSubscription;
  bool isScanning = false;
  List<BluetoothDevice> _devicesList = [];
  double? _temperature;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  void dispose() {
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
                title: Text(_devicesList[index].name.isNotEmpty
                    ? _devicesList[index].name
                    : _devicesList[index].id.toString()),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addGradingData() async {
    if (_selectedGrade == null) {
      _showSnackBar('Please select a grade');
      return;
    }

    Map<String, dynamic> newData = {
      'serial': DateTime.now().millisecondsSinceEpoch,
      'weight': double.tryParse(_weightController.text) ?? 0,
      'crates': int.tryParse(_cratesController.text) ?? 0,
      'crateWeight': double.tryParse(_crateWeightController.text) ?? 0,
    };

    setState(() {
      _gradingData[_selectedGrade!] ??= [];
      _gradingData[_selectedGrade!]?.add(newData);
    });

    _weightController.clear();
    _cratesController.clear();
    _crateWeightController.clear();
  }

  void _removeGradingData(String grade, int index) {
    setState(() {
      _gradingData[grade]?.removeAt(index);
    });
  }

  void _showReviewDialog() async {
    final newData = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Review Grading Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _gradingData.entries
                      .where((entry) => entry.value.isNotEmpty)
                      .map(
                        (entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Serial')),
                              DataColumn(label: Text('Weight')),
                              DataColumn(label: Text('Crates')),
                              DataColumn(label: Text('Crate Weight')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: entry.value
                                .asMap()
                                .entries
                                .map(
                                  (dataEntry) => DataRow(
                                cells: [
                                  DataCell(Text(
                                      dataEntry.value['serial']
                                          .toString())),
                                  DataCell(Text(
                                      dataEntry.value['weight']
                                          .toString())),
                                  DataCell(Text(
                                      dataEntry.value['crates']
                                          .toString())),
                                  DataCell(Text(
                                      dataEntry.value['crateWeight']
                                          .toString())),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _removeGradingData(
                                            entry.key, dataEntry.key);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  )
                      .toList(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('G1 Total Weight: ${_totalWeightForGrade('G1')}'),
                    Text(
                        'G1 Total Crate Weight: ${_totalCrateWeightForGrade('G1')}'),
                    Text('G2 Total Weight: ${_totalWeightForGrade('G2')}'),
                    Text(
                        'G2 Total Crate Weight: ${_totalCrateWeightForGrade('G2')}'),
                    Text('G3 Total Weight: ${_totalWeightForGrade('G3')}'),
                    Text(
                        'G3 Total Crate Weight: ${_totalCrateWeightForGrade('G3')}'),
                    Text(
                        'Wastage Total Weight: ${_totalWeightForGrade('Wastage')}'),
                    Text(
                        'Wastage Total Crate Weight: ${_totalCrateWeightForGrade('Wastage')}'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_gradingData);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (newData != null) {
      _saveGradingDetails();
    }
  }

  double _totalWeightForGrade(String grade) {
    return _gradingData[grade]
        ?.map((data) => data['weight'] ?? 0.0)
        .fold(0.0, (prev, element) => prev! + element) ??
        0.0;
  }

  double _totalCrateWeightForGrade(String grade) {
    return _gradingData[grade]
        ?.map((data) => data['crateWeight'] ?? 0.0)
        .fold(0.0, (prev, element) => prev! + element) ??
        0.0;
  }

  void _saveGradingDetails() async {
    try {
      final DocumentReference docRef =
      FirebaseFirestore.instance.collection('lots').doc(widget.lotNo);
      final DocumentSnapshot doc = await docRef.get();

      if (doc.exists) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>? ?? {};
        final Map<String, dynamic> existingGrading =
            data['Grading'] as Map<String, dynamic>? ?? {};

        _gradingData.forEach((grade, details) {
          final List<dynamic> existingDetails =
              existingGrading[grade] as List<dynamic>? ?? [];
          existingDetails.addAll(details);
          existingGrading[grade] = existingDetails;
        });

        await docRef.update({'Grading': existingGrading});
      } else {
        await docRef.set({'Grading': _gradingData});
      }

      _showSnackBar('Grading details saved successfully');
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('Failed to save grading details: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _gradingData = {};

  @override
  Widget build(BuildContext context) {
    final lotNo = widget.lotNo;

    return Scaffold(
      appBar: AppBar(
        title: Text('Grading for Lot $lotNo'),
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
                onPressed: _addGradingData,
                child: Text('Add Grading Data'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showReviewDialog,
                child: Text('Review Grading Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
