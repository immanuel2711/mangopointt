import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InwardDetails extends StatelessWidget {
  final Map<String, dynamic> rowData;
  final String documentId;
  final String lotNo;

  const InwardDetails({
    Key? key,
    required this.rowData,
    required this.documentId,
    required this.lotNo,
  }) : super(key: key);

  Future<void> _updateInwardStage(String? documentId) async {
    if (documentId != null) {
      await FirebaseFirestore.instance.collection('lots').doc(documentId).update({
        'Stage': 'grading',
      });
    } else {
      print('Document ID is null or not a string.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          rowData['Lot No'],
          style: TextStyle(color: Colors.orange),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Inward Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Stock No: ${rowData['Stock No']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Inward Date: ${rowData['Date']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Lot No: ${rowData['Lot No']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('State: ${rowData['State']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone No: ${rowData['Phone No']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Mango Variety: ${rowData['Mango']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Inward Total Weight [Gross]: ${rowData['Kg']} Kgs', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Inward Total Crates: ${rowData['Total Crates']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Inward Crate Gross Weight: ${rowData['Crate Gross Weight']} Kgs', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Inward Net Weight of Mangoes: ${rowData['Net Weight']} Kgs', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Lead Received By: ${rowData['Lead Received By']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  String? documentId = rowData['id'] as String?;
                  print('Document ID: $documentId');
                  if (documentId != null) {
                    await _updateInwardStage(documentId);
                  } else {
                    print('Document ID is null or not a string.');
                  }
                },
                child: Text('Proceed To Grading'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
