import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bun/pages/ripening/ripeningdetails.dart';
//import 'ripeningdetails.dart';

class RipeningDetailsScreen extends StatefulWidget {
  final String lotNo;

  const RipeningDetailsScreen({Key? key, required this.lotNo}) : super(key: key);

  @override
  _RipeningDetailsScreenState createState() => _RipeningDetailsScreenState();
}

class _RipeningDetailsScreenState extends State<RipeningDetailsScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _temperature = 24.0;
  int _chamberNumber = 1;
  final double _fontSize = 16.0;

  Map<String, dynamic> _gradingDetails = {};
  String? _leadRipeningSetBy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGradingDetails();
  }

  Future<void> _fetchGradingDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('lots')
          .doc(widget.lotNo)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _gradingDetails = data;
          _leadRipeningSetBy = data['Owner'];

          if (data['Ripening'] != null && data['Ripening']['Chamber Number'] != null) {
            _chamberNumber = int.tryParse(data['Ripening']['Chamber Number'].toString()) ?? 1;
          }

          if (data['Ripening'] != null && data['Ripening']['Temperature'] != null) {
            _temperature = double.tryParse(data['Ripening']['Temperature'].toString()) ?? 24.0;
          }

          if (data['Ripening'] != null && data['Ripening']['Set Date'] != null) {
            _selectedDate = (data['Ripening']['Set Date'] as Timestamp).toDate();
          }
          if (data['Ripening'] != null && data['Ripening']['Set Time'] != null) {
            _selectedTime = TimeOfDay(
              hour: int.tryParse(data['Ripening']['Set Time'].split(":")[0]) ?? 0,
              minute: int.tryParse(data['Ripening']['Set Time'].split(":")[1]) ?? 0,
            );
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching grading details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _updateRipeningDetails() async {
    try {
      await FirebaseFirestore.instance.collection('lots').doc(widget.lotNo).update({
        'Ripening': {
          'Chamber Number': _chamberNumber,
          'Set Date': _selectedDate,
          'Set Time': _selectedTime.format(context),
          'Temperature': _temperature,
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RipeningAndGradingDetails(lotNo: widget.lotNo),
        ),
      );
    } catch (e) {
      print('Error updating ripening details: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update ripening details'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ripening Details',style: TextStyle(color: Colors.orange)),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Stock No: ${_gradingDetails['Stock No']}\nLot No: ${_gradingDetails['Lot No']}\nMango Variety: ${_gradingDetails['Mango']}',
                style: TextStyle(fontSize: _fontSize),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                initialValue: _chamberNumber.toString(),
                decoration: InputDecoration(
                  labelText: "Chamber No:",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _chamberNumber = int.tryParse(value) ?? _chamberNumber;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Ripening Set Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                  style: TextStyle(fontSize: _fontSize),
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Ripening Set Time: ${_selectedTime.format(context)}",
                  style: TextStyle(fontSize: _fontSize),
                ),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              TextFormField(
                initialValue: _temperature.toString(),
                decoration: InputDecoration(
                  labelText: "Ripening Set Temp (°C):",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _temperature = double.tryParse(value) ?? _temperature;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'G1: 20.00 Kgs ~ 1 Crate\nG2: 30.00 Kgs ~ 2 Crate\nG3: 30.00 Kgs ~ 2 Crate\nG4: 10.00 Kgs ~ 1 Crate\nLead Ripening Set By: $_leadRipeningSetBy',
                style: TextStyle(fontSize: _fontSize),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _updateRipeningDetails,
                child: Text('Submit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                )

              ),
            ],
          ),
        ),
      ),
    );
  }
}
