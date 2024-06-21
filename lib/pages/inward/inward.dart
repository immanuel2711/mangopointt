import 'addinginward.dart';
import 'inward_details.dart';
import '../grading/grading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:bun/pages/auth/signin.dart';
import '../../providers/user_provider.dart';
import '../bluetooth/bluetooth_scan_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bun/pages/grading/addinggrading.dart';

class InwardPage extends StatefulWidget {
  @override
  _InwardPageState createState() => _InwardPageState();
}

class _InwardPageState extends State<InwardPage> {

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
      // appBar: AppBar(
      //   title: Text('Inward'),
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.bluetooth_searching),
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => BluetoothScanPage()),
      //         );
      //       },
      //     ),
      //     if (user != null && user.photoURL != null)
      //       CircleAvatar(
      //         backgroundImage: NetworkImage(user.photoURL!),
      //       )
      //     else
      //       IconButton(
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => SignInPage()),
      //           );
      //         },
      //         icon: Icon(Icons.account_circle, size: 40),
      //       ),
      //     IconButton(
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(
      //             builder: (context) => AddingGradingPage(
      //               lotNo: lotNo,
      //             ),
      //           ),
      //         );
      //       },
      //       icon: Icon(Icons.arrow_circle_up, size: 30),
      //     ),
      //   ],
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SizedBox(height: 30),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: RoundedButton(text: 'Inward', isSelected: true),
          //       ),
          //       SizedBox(width: 10),
          //       Expanded(
          //         child: RoundedButton(
          //           text: 'Grading',
          //           isSelected: false,
          //           onPressed: () async {

          //             Navigator.push(
          //                 context,
          //                 MaterialPageRoute(
          //                     builder: ((context) => GradingPage())));
          //             print('Inward button pressed!');
          //             await someAsyncFunction();

          //           },
          //         ),
          //       ),
          //       SizedBox(width: 10),
          //       Expanded(
          //         child: RoundedButton(text: 'Ripening', isSelected: false),
          //       ),
          //       SizedBox(width: 10),
          //       Expanded(
          //         child: RoundedButton(text: 'Outward', isSelected: false),
          //       ),
          //     ],
          //   ),
          // ),
          //SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: _inwardCollection.where('Stage', isEqualTo: 'inward').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!.docs;

                  return Table(
                    border: TableBorder.all(
                      color: Colors.grey.withOpacity(0.25),
                      width: 0.5,
                    ),
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
                      ...data.map((doc) {
                        final rowData = doc.data() as Map<String, dynamic>;
                        rowData['id'] = doc.id;
                        //print(rowData['id']);

                        return TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.25),
                                width: 0.5,
                              ),
                            ),
                          ),
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
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: Icon(Icons.add),
                  color: Colors.white,
                  onPressed: () async {
                    final newData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddingInwardPage(),
                      ),
                    );
                    if (newData != null) {
                      setState(() {
                        _inwardCollection.add(newData);
                      });
                    }
                  },
                ),
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
            builder: (context) => InwardDetails(
              rowData: rowData,
              documentId: rowData['id'],
              lotNo: rowData['Lot No'],
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
            color: Colors.grey.withOpacity(0.25),
            width: 0.5,
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

        onPressed:
        onPressed,
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