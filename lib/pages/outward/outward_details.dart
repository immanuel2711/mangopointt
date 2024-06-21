import 'addingoutward.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class OutwardDetails extends StatefulWidget {
  final String lotNo;

  const OutwardDetails({Key? key, required this.lotNo}) : super(key: key);

  @override
  _OutwardDetailsState createState() => _OutwardDetailsState();
}

class _OutwardDetailsState extends State<OutwardDetails> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('lots').doc(widget.lotNo).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(body: Center(child: Text('No data found')));
        }

        Map<String, dynamic> rowData = snapshot.data!.data() as Map<String, dynamic>;

        
        Map<String, List<Map<String, dynamic>>> gradingData = {};
        if (rowData['Grading'] != null) {
          rowData['Grading'].forEach((key, value) {
            gradingData[key] = List<Map<String, dynamic>>.from(value as List<dynamic>);
          });
        }

        
        Map<String, dynamic> ripeningData = {};
        if (rowData['Ripening'] != null) {
          ripeningData = Map<String, dynamic>.from(rowData['Ripening']);
        }

        
        Map<String, List<Map<String, dynamic>>> outwardData = {};
        if (rowData['Outward'] != null) {
          rowData['Outward'].forEach((key, value) {
            outwardData[key] = List<Map<String, dynamic>>.from(value as List<dynamic>);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Outward Details',style: TextStyle(color: Color(0xffFFA62F))),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grading Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                ...gradingData.entries.map((entry) {
                  String grade = entry.key;
                  List<Map<String, dynamic>> details = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$grade:'),
                      ...details.map((detail) {
                        return Text(
                            '  Serial: ${detail['serial']}, Weight: ${detail['weight']} kg, Crates: ${detail['crates']}, Crate Weight: ${detail['crateWeight']} kg');
                      }).toList(),
                      SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                SizedBox(height: 16),
                Text(
                  'Ripening Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                Text('Chamber No: ${ripeningData['Chamber Number']}'),
                SizedBox(height: 8),
                Text('Ripening Set Date: ${ripeningData['Set Date'] != null ? DateFormat('dd/MM/yyyy').format((ripeningData['Set Date'] as Timestamp).toDate()) : 'N/A'}'),
                SizedBox(height: 8),
                Text('Ripening Set Time: ${ripeningData['Set Time']}'),
                SizedBox(height: 8),
                Text('Ripening Set Temp (°C): ${ripeningData['Temperature']}'),
                SizedBox(height: 8),
                if (ripeningData['Brix Value'] != null)
                  Text('Brix Value: ${ripeningData['Brix Value']}%'),
                SizedBox(height: 8),
                Text('Lead Ripening Set By: ${rowData['Owner']}'),
                
                SizedBox(height: 8),
                // ElevatedButton(
                //   onPressed: () {
                //     _readyToDispatch(widget.lotNo);
                //   },
                //   child: Text('Ready to Dispatch'),
                // ),
                // SizedBox(height: 16),
                Text(
                  'Outward Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 16),
                ...outwardData.entries.map((entry) {
                  String grade = entry.key;
                  List<Map<String, dynamic>> details = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$grade:'),
                      ...details.map((detail) {
                        return Text(
                            '  Weight: ${detail['weight']} kg, Crates: ${detail['crates']}, Crate Weight: ${detail['crateWeight']} kg');
                      }).toList(),
                      SizedBox(height: 8),
                    ],
                  );
                }).toList(),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddingOutwardPage(lotNo: widget.lotNo),
                        settings: RouteSettings(
                          arguments: widget.lotNo,
                        ),
                      ),
                    );
                  },
                  child: Text('Dispatch'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBrixValueDialog(BuildContext context, String lotNo, Map<String, dynamic> ripeningData) async {
    TextEditingController brixController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Brix Value'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: brixController,
                  decoration: InputDecoration(labelText: 'Brix Value (%)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                final brixValue = brixController.text;
                if (brixValue.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('lots').doc(lotNo).update({
                    'Ripening.Brix Value': double.parse(brixValue),
                  });
                  setState(() {
                    ripeningData['Brix Value'] = double.parse(brixValue);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _readyToDispatch(String lotNo) async {
    await FirebaseFirestore.instance.collection('lots').doc(lotNo).update({
      'Stage': 'ready_to_dispatch',
    });
    Navigator.of(context).pop();
  }
}
