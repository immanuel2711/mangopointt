import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MangoManagementDashboard(),
  ));
}

class MangoManagementDashboard extends StatefulWidget {
  @override
  _MangoManagementDashboardState createState() =>
      _MangoManagementDashboardState();
}

class _MangoManagementDashboardState extends State<MangoManagementDashboard> {
  DateTime selectedDate = DateTime.now();
  double totalInwardWeight = 0.0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInwardWeight();
  }

  Future<void> _fetchInwardWeight() async {
    setState(() {
      isLoading = true;
    });

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Fetching data for date: $formattedDate");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lots')
          .where('Date', isEqualTo: formattedDate)
          .get();

      double totalWeight = 0.0;
      for (var doc in snapshot.docs) {
        totalWeight += (doc['Kg'] as num).toDouble();
      }

      setState(() {
        totalInwardWeight = totalWeight;
        isLoading = false;
        print("Total inward weight for $formattedDate: $totalInwardWeight Kgs");
      });
    } catch (e) {
      print("Error fetching inward weight: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        isLoading = true; // Set loading state when date changes
      });
      await _fetchInwardWeight();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mango Management'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 20),
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Select Date: ",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    "${selectedDate.toLocal()}".split(' ')[0],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: <Widget>[
                DashboardItem(
                  title: 'Inward',
                  subtitle: isLoading
                      ? 'Loading...' // Show loading text while fetching
                      : "Today's Total Inward: ${totalInwardWeight.toStringAsFixed(2)} Kgs",
                ),
                DashboardItem(
                  title: 'Grading',
                  subtitle: 'Weight of Mangoes in Grading',
                ),
                DashboardItem(
                  title: 'Ripening',
                  subtitle: 'Weight of Mangoes in Ripening',
                ),
                DashboardItem(
                  title: 'Outward',
                  subtitle: "Today's Total Outward",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String title;
  final String subtitle;

  DashboardItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
