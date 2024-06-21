import 'auth/signin.dart';
import 'grading/grading.dart';
import 'outward/outward.dart';
import 'ripening/ripening.dart';
import 'inward/addinginward.dart';
import 'inward/inward_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bluetooth/bluetooth_scan_page.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mango Management', style: TextStyle(color: Color(0xffFFA62F))),
        actions: [

          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              final user = userProvider.user;
              return user != null && user.photoURL != null
                  ? CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL!),
                radius: 20,
              )
                  : IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage()),
                  );
                },
                icon: Icon(Icons.account_circle, size: 40, color: Color(0xffFFA62F)),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: RoundedButton(
                    text: 'Inward',
                    isSelected: _selectedIndex == 0,
                    onPressed: () => _onItemTapped(0),
                    color: _selectedIndex == 0 ? Colors.green[900] : Colors.green[200],
                  ),
                ),
                Expanded(
                  child: RoundedButton(
                    text: 'Grading',
                    isSelected: _selectedIndex == 1,
                    onPressed: () => _onItemTapped(1),
                    color: _selectedIndex == 1 ? Colors.green[900] : Colors.green[200],
                  ),
                ),
                Expanded(
                  child: RoundedButton(
                    text: 'Ripening',
                    isSelected: _selectedIndex == 2,
                    onPressed: () => _onItemTapped(2),
                    color: _selectedIndex == 2 ? Colors.green[900] : Colors.green[200],
                  ),
                ),
                Expanded(
                  child: RoundedButton(
                    text: 'Outward',
                    isSelected: _selectedIndex == 3,
                    onPressed: () => _onItemTapped(3),
                    color: _selectedIndex == 3 ? Colors.green[900] : Colors.green[200],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                InwardPage(),
                GradingPage(),
                RipeningPage(),
                OutwardPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InwardPage extends StatefulWidget {
  @override
  _InwardPageState createState() => _InwardPageState();
}

class _InwardPageState extends State<InwardPage> {
  final CollectionReference _inwardCollection = FirebaseFirestore.instance.collection('lots');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      return TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.green[500] ?? Colors.transparent)),
                        ),
                        children: [
                          _buildTableCell(
                              rowData['Lot No'] ?? 'N/A', rowData),
                          _buildTableCell(rowData['Mango'] ?? 'N/A', rowData),
                          _buildTableCell(
                              rowData['Inward']?['Total Weight']?.toString() ??
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
                color: Colors.green,
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
      children: [
        for (var value in values)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: color ?? Colors.black,

                    ),
                  ),
                  if (value != 'Owner')
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      height: 2,
                      color: Colors.green[300],
                      width: MediaQuery.of(context).size.width * 0.75,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class RoundedButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onPressed;
  final Color? color;

  const RoundedButton({
    required this.text,
    required this.isSelected,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
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