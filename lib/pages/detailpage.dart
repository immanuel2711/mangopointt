import 'package:flutter/material.dart';
import 'grading/addinggrading.dart';  // Import the AddingGradingPage file

class DetailPage extends StatelessWidget {
  final String stockNo;
  final String inwardDate;
  final String lotNo;
  final String state;
  final String phoneNo;
  final String mangoVariety;
  final double inwardTotalWeight;
  final int inwardTotalCrates;
  final double inwardCrateGrossWeight;
  final double inwardNetWeight;
  final String leadReceivedBy;
  final String gradingStartDateTime;
  final String leadProceededBy;

  DetailPage({
    required this.stockNo,
    required this.inwardDate,
    required this.lotNo,
    required this.state,
    required this.phoneNo,
    required this.mangoVariety,
    required this.inwardTotalWeight,
    required this.inwardTotalCrates,
    required this.inwardCrateGrossWeight,
    required this.inwardNetWeight,
    required this.leadReceivedBy,
    required this.gradingStartDateTime,
    required this.leadProceededBy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stockNo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inward Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Text('Stock No: $stockNo'),
            Text('Inward Date: $inwardDate'),
            Text('Lot No: $lotNo'),
            Text('State: $state'),
            Text('PhoneNo: $phoneNo'),
            Text('Mango Variety: $mangoVariety'),
            Text('Inward Total Weight(Gross): $inwardTotalWeight Kgs'),
            Text('Inward Total Crates: $inwardTotalCrates'),
            Text('Inward Crate Gross Weight: $inwardCrateGrossWeight Kgs'),
            Text('Inward Net Weight of Mangoes: $inwardNetWeight Kgs'),
            Text('Lead Received By: $leadReceivedBy'),
            SizedBox(height: 20),
            Text(
              'Grading Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Text('Start Date and Time: $gradingStartDateTime'),
            Text('Lead Proceeded to Grading By: $leadProceededBy'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddingGradingPage(lotNo:lotNo)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Add Grading Status'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement Proceed to Ripening functionality here
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Proceed To Ripening'),
            ),
          ],
        ),
      ),
    );
  }
}
