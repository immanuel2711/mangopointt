import 'outward_details.dart';
import '../grading/grading.dart';
import '../inward/addinginward.dart';
import '../inward/inward_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../grading/grading_details.dart';
import 'package:bun/pages/auth/signin.dart';
import '../../providers/user_provider.dart';
import 'package:bun/pages/ripening/ripening.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bun/pages/grading/addinggrading.dart';

class OutwardPage extends StatefulWidget {
  @override
  _OutwardPageState createState() => _OutwardPageState();
}

class _OutwardPageState extends State<OutwardPage> {
  final CollectionReference _inwardCollection =
  FirebaseFirestore.instance.collection('lots');

  final CollectionReference usercoll =
  FirebaseFirestore.instance.collection('users');

  late String lotNo;

  Future<void> someAsyncFunction() async {
    await Future.delayed(Duration(seconds: 1));
    print('Async operation completed!');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: _inwardCollection
                    .where('Stage', isEqualTo: 'outward')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.docs;

                  return Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                      },
                      children: [
                      _buildTableRow(['Lot No', 'Mango', 'Kg', 'Date', 'Owner'],
                      color: Colors.grey),
                  ...data.map((doc) {
                  final rowData = doc.data() as Map<String, dynamic>;
                  lotNo = rowData['Lot No'];

                  rowData['id'] = doc.id;

                  return TableRow(
                  children: [
                  _buildTableCell(
                  rowData['Lot No'] ?? 'N/A', rowData),
                  _buildTableCell(rowData['Mango'] ?? 'N/A', rowData),
                  _buildTableCell(
                  rowData['Inward']?['Total Weight']
                      ?.toString() ??
                  'N/A',
                  rowData),
                  _buildTableCell(
                  rowData['Inward Date'] ?? 'N/A', rowData),
                  _buildTableCell(rowData['Owner'] ?? 'N/A', rowData),
                  ],
                  );
                  }).expand((row) => [
                  row,
                  TableRow(
                  children: [
                  Container(
                  height: 1,
                  color: Colors.green, // Green line color
                  ),
                  Container(
                  height: 1,
                  color: Colors.green, // Green line color
                  ),
                  Container(
                  height: 1,
                  color: Colors.green, // Green line color
                  ),
                  Container(
                  height: 1,
                  color: Colors.green, // Green line color
                  ),
                  Container(
                  height: 1,
                  color: Colors.green, // Green line color
                  ),
                  ],
                  )
                  ]).toList(),
                  ]);
                },
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTableCell(String value, Map<String, dynamic> rowData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OutwardDetails(
              lotNo: lotNo,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(List<String> values, {Color? color}) {
    return TableRow(
      children: values
          .map(
            (value) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.black,
              fontWeight:
              value == 'Mango' ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Future<void> Function()? onPressed;

  const RoundedButton({
    required this.text,
    required this.isSelected,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final Map<String, List<Map<String, dynamic>>> sampleGradingData = {
  'G1': [
    {
      'serial': 1,
      'weight': 100.0,
      'crates': 10,
      'crateWeight': 50.0,
    },
    {
      'serial': 2,
      'weight': 150.0,
      'crates': 15,
      'crateWeight': 75.0,
    },
  ],
  'G2': [
    {
      'serial': 1,
      'weight': 80.0,
      'crates': 8,
      'crateWeight': 40.0,
    },
  ],
  'G3': [
    {
      'serial': 1,
      'weight': 60.0,
      'crates': 6,
      'crateWeight': 30.0,
    },
  ],
  'Wastage': [
    {
      'serial': 1,
      'weight': 20.0,
      'crates': 2,
      'crateWeight': 10.0,
    },
  ],
};
