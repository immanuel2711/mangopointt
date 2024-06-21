import 'grading.dart';
import 'grading_details.dart';
import '../inward/addinginward.dart';
import '../inward/inward_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:bun/pages/auth/signin.dart';
import '../../providers/user_provider.dart';
import 'package:bun/pages/ripening/ripening.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bun/pages/grading/addinggrading.dart';

class GradingPage extends StatefulWidget {
  @override
  _GradingPageState createState() => _GradingPageState();
}

class _GradingPageState extends State<GradingPage> {
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
                    .where('Stage', isEqualTo: 'grading')
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
                      _buildTableRow(
                        ['Lot No', 'Mango', 'Kg', 'Date', 'Owner'],
                        color: Colors.grey,
                      ),
                      ...data.map(
                            (doc) {
                          final rowData =
                          doc.data() as Map<String, dynamic>;
                          lotNo = rowData['Lot No'];

                          rowData['id'] = doc.id;

                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.green,

                                ),
                              ),
                            ),
                            children: [
                              _buildTableCell(
                                rowData['Lot No'] ?? 'N/A',
                                rowData,
                              ),
                              _buildTableCell(
                                rowData['Mango'] ?? 'N/A',
                                rowData,
                              ),
                              _buildTableCell(
                                rowData['Inward']?['Total Weight']
                                    ?.toString() ??
                                    'N/A',
                                rowData,
                              ),
                              _buildTableCell(
                                rowData['Inward Date'] ?? 'N/A',
                                rowData,
                              ),
                              _buildTableCell(
                                rowData['Owner'] ?? 'N/A',
                                rowData,
                              ),
                            ],
                          );
                        },
                      ).toList(),
                    ],
                  );
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
            builder: (context) => GradingDetails(
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.lightGreen,

          ),
        ),
      ),
      children: values
          .map(
            (value) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.black,
              fontWeight: value == 'Mango' ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}
