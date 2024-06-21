import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bun/pages/grading/addinggrading.dart';
import 'package:bun/pages/ripening/addingripening.dart';

class GradingDetails extends StatefulWidget {
  final String lotNo;

  const GradingDetails({Key? key, required this.lotNo}) : super(key: key);

  @override
  _GradingDetailsState createState() => _GradingDetailsState();
}

class _GradingDetailsState extends State<GradingDetails> {
  //late String lotNo;
  Future<Map<String, dynamic>>? _inwardDetailsFuture;
  Future<Map<String, List<Map<String, dynamic>>>>? _gradingDataFuture;

  @override
  void initState() {
    super.initState();
    _inwardDetailsFuture = fetchInwardDetails(widget.lotNo);
    _gradingDataFuture = fetchGradingData(widget.lotNo);
    //lotNo = widget.lotNo;
    print("komo");
    //print(lotNo);
  }

  Future<Map<String, dynamic>> fetchInwardDetails(String lotNo) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('lots').doc(lotNo).get();

      if (doc.exists) {
        print("yes doc");
        final rowData = doc.data() as Map<String, dynamic>;
        print(rowData['Lot No']);
        return rowData;
      } else {
        print("no doc");
        return {};
      }
    } catch (e) {
      print('Error fetching inward details: $e');
      return {};
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchGradingData(
      String lotNo) async {
    try {
      DocumentSnapshot lotDoc =
      await FirebaseFirestore.instance.collection('lots').doc(lotNo).get();

      Map<String, List<Map<String, dynamic>>> gradingData = {};

      var gradingDetails = lotDoc['Grading'];

      if (gradingDetails != null) {
        for (var gradeKey in gradingDetails.keys) {
          var gradeData = gradingDetails[gradeKey];
          if (gradeData != null) {
            gradingData[gradeKey] = [];
            for (var detail in gradeData) {
              gradingData[gradeKey]!.add(Map<String, dynamic>.from(detail));
            }
          }
        }
      }

      return gradingData;
    } catch (e) {
      print('Error fetching grading data: $e');
      return {};
    }
  }

  Future<void> _updateRipeStage(String? documentId) async {
    if (documentId != null) {
      await FirebaseFirestore.instance
          .collection('lots')
          .doc(documentId)
          .update({
        'Stage': 'ripening',
      });
    } else {
      print('Document ID is null or not a string.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grading Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _inwardDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching inward details');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No inward details available');
                } else {
                  var rowData = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inward Details',
                        textAlign: TextAlign.center, // Center align the heading
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Inward Date: ${rowData['Inward Date'] ?? 'N/A'}'),
                      SizedBox(height: 8),
                      Text('Lot No: ${rowData['Lot No'] ?? 'N/A'}'),
                      SizedBox(height: 8),
                      Text('State: ${rowData['State'] ?? 'N/A'}'),
                      SizedBox(height: 8),
                      Text('Phone No: ${rowData['Phone No'] ?? 'N/A'}'),
                      SizedBox(height: 8),
                      Text('Mango Variety: ${rowData['Mango'] ?? 'N/A'}'),
                      SizedBox(height: 8),
                      Text(
                          'Inward Total Weight [Gross]: ${rowData['Inward'] != null && rowData['Inward']['Total Weight'] != null ? rowData['Inward']['Total Weight'].toString() + ' Kgs' : 'N/A'}'),
                      SizedBox(height: 8),
                      Text('Lead Received By: ${rowData['Owner'] ?? 'N/A'}'),
                      SizedBox(height: 16),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 16),
            Text(
              'Grading Details',
              textAlign: TextAlign.center, // Center align the heading
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _gradingDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error fetching grading data');
                } else {
                  Map<String, List<Map<String, dynamic>>> gradingData =
                      snapshot.data ?? {};

                  List<Widget> gradeWidgets = [];

                  gradingData.forEach((grade, details) {
                    if (details.isNotEmpty) {
                      gradeWidgets.add(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$grade:'),
                          ...details.map((detail) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (detail['serial'] != null)
                                  Text('  Serial: ${detail['serial']}'),
                                if (detail['weight'] != null)
                                  Text('  Weight: ${detail['weight']} kg'),
                                if (detail['crates'] != null)
                                  Text('  Crates: ${detail['crates']}'),
                                if (detail['crateWeight'] != null)
                                  Text(
                                      '  Crate Weight: ${detail['crateWeight']} kg'),
                              ],
                            );
                          }).toList(),
                          SizedBox(height: 8),
                        ],
                      ));
                    }
                  });

                  if (gradeWidgets.isEmpty) {
                    return Text('No grading data available');
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: gradeWidgets,
                    );
                  }
                }
              },
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddingGradingPage(lotNo: widget.lotNo),
                        settings: RouteSettings(
                          arguments: widget.lotNo,
                        ),
                      ),
                    );
                  },
                  child: Text('Add Grading Status'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton(
                  onPressed: () async {
                    DocumentSnapshot doc = await FirebaseFirestore.instance
                        .collection('lots')
                        .doc(widget.lotNo)
                        .get();
                    String? documentId = doc.id;
                    print('Document ID: $documentId');
                    if (documentId != null) {
                      await _updateRipeStage(documentId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RipeningDetailsScreen(lotNo: widget.lotNo,),
                        ),
                      );
                    } else {
                      print('Document ID is null or not a string.');
                    }
                  },
                  child: Text('Proceed to Ripening'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
