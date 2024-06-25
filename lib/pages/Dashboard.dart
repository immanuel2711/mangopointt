import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MangoManagementDashboard extends StatefulWidget {
  @override
  _MangoManagementDashboardState createState() => _MangoManagementDashboardState();
}

class _MangoManagementDashboardState extends State<MangoManagementDashboard> {
  DateTime selectedDate = DateTime.now();
  double totalInwardWeight = 0.0;
  double totalGradingWeight = 0.0;
  double totalRipeningWeight = 0.0;
  double totalOutwardWeight = 0.0;
  double totalG1Weight = 0.0;
  double totalG2Weight = 0.0;
  double totalG3Weight = 0.0;
  double totalWastageWeight = 0.0;
  bool isLoading = false;

  double ototalG1Weight = 0.0;
  double ototalG2Weight = 0.0;
  double ototalG3Weight = 0.0;
  double ototalWastageWeight = 0.0;

  double rtotalG1Weight = 0.0;
  double rtotalG2Weight = 0.0;
  double rtotalG3Weight = 0.0;
  double rtotalWastageWeight = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAllWeights();
  }

  Future<void> _fetchAllWeights() async {
    setState(() {
      isLoading = true;
    });

    await _fetchInwardWeight();
    await _fetchGradingWeight();
    await _fetchRipeningWeight();
    await _fetchOutwardWeight();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchInwardWeight() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Fetching inward data for date: $formattedDate");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lots')
          .where('Inward Date', isEqualTo: formattedDate)
          .get();

      double totalWeight = 0.0;
      for (var doc in snapshot.docs) {
        totalWeight += (doc['Kg'] as num).toDouble();
      }

      setState(() {
        totalInwardWeight = totalWeight;
        print("Total inward weight for $formattedDate: $totalInwardWeight Kgs");
      });
    } catch (e) {
      print("Error fetching inward weight: $e");
    }
  }

  Future<void> _fetchGradingWeight() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Fetching grading data for date: $formattedDate");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lots')
          .where('Inward Date', isEqualTo: formattedDate)
          .where('Stage', isEqualTo: 'grading')
          .get();

      double totalWeight = 0.0;
      double g1Weight = 0.0;
      double g2Weight = 0.0;
      double g3Weight = 0.0;
      double wastageWeight = 0.0;

      for (var doc in snapshot.docs) {
        totalWeight += (doc['Kg'] as num).toDouble();

        if (doc['Grading'] != null && doc['Grading'] is Map<String, dynamic>) {
          Map<String, dynamic> grading = doc['Grading'];
          print("Grading data: $grading");


          if (grading['G1'] != null && grading['G1'] is List<dynamic>) {
            for (var item in grading['G1']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G1 item: $item");
                g1Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G2'] != null && grading['G2'] is List<dynamic>) {
            for (var item in grading['G2']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G2 item: $item");
                g2Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G3'] != null && grading['G3'] is List<dynamic>) {
            for (var item in grading['G3']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G3 item: $item");
                g3Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['Wastage'] != null && grading['Wastage'] is List<dynamic>) {
            for (var item in grading['Wastage']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                wastageWeight += double.parse(item['weight'].toString());
              }
            }
          }
        }
      }


      setState(() {
        totalGradingWeight = totalWeight;
        totalG1Weight = g1Weight;
        totalG2Weight = g2Weight;
        totalG3Weight = g3Weight;
        totalWastageWeight = wastageWeight;
        print("Total grading weight for $formattedDate: $totalGradingWeight Kgs");
        print("Total G1 weight: $totalG1Weight Kgs");
        print("Total G2 weight: $totalG2Weight Kgs");
        print("Total G3 weight: $totalG3Weight Kgs");
        print("Total Wastage weight: $totalWastageWeight Kgs");
      });
    } catch (e) {
      print("Error fetching grading weight: $e");
    }
  }





  Future<void> _fetchRipeningWeight() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Fetching ripening data for date: $formattedDate");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lots')
          .where('Inward Date', isEqualTo: formattedDate)
          .where('Stage', isEqualTo: 'ripening')
          .get();

      double totalWeight = 0.0;
      double rg1Weight = 0.0;
      double rg2Weight = 0.0;
      double rg3Weight = 0.0;
      double rwastageWeight = 0.0;


      for (var doc in snapshot.docs) {
        totalWeight += (doc['Kg'] as num).toDouble();

        if (doc['Grading'] != null && doc['Grading'] is Map<String, dynamic>) {
          Map<String, dynamic> grading = doc['Grading'];
          print("Grading data: $grading");


          if (grading['G1'] != null && grading['G1'] is List<dynamic>) {
            for (var item in grading['G1']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G1 item: $item");
                rg1Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G2'] != null && grading['G2'] is List<dynamic>) {
            for (var item in grading['G2']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G2 item: $item");
                rg2Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G3'] != null && grading['G3'] is List<dynamic>) {
            for (var item in grading['G3']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G3 item: $item");
                rg3Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['Wastage'] != null && grading['Wastage'] is List<dynamic>) {
            for (var item in grading['Wastage']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                rwastageWeight += double.parse(item['weight'].toString());
              }
            }
          }
        }
      }



      setState(() {
        totalRipeningWeight = totalWeight;
        rtotalG1Weight = rg1Weight;
        rtotalG2Weight = rg2Weight;
        rtotalG3Weight =rg3Weight;
        rtotalWastageWeight = rwastageWeight;
        print("Total ripening weight for $formattedDate: $totalRipeningWeight Kgs");
      });
    } catch (e) {
      print("Error fetching ripening weight: $e");
    }
  }

  Future<void> _fetchOutwardWeight() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Fetching outward data for date: $formattedDate");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('lots')
          .where('Inward Date', isEqualTo: formattedDate)
          .where('Stage', isEqualTo: 'outward')
          .get();

      double totalWeight = 0.0;
      double og1Weight = 0.0;
      double og2Weight = 0.0;
      double og3Weight = 0.0;
      double owastageWeight = 0.0;
      for (var doc in snapshot.docs) {
        totalWeight += (doc['Kg'] as num).toDouble();

        if (doc['Grading'] != null && doc['Grading'] is Map<String, dynamic>) {
          Map<String, dynamic> grading = doc['Grading'];
          print("Grading data: $grading");


          if (grading['G1'] != null && grading['G1'] is List<dynamic>) {
            for (var item in grading['G1']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G1 item: $item");
                og1Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G2'] != null && grading['G2'] is List<dynamic>) {
            for (var item in grading['G2']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G2 item: $item");
                og2Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['G3'] != null && grading['G3'] is List<dynamic>) {
            for (var item in grading['G3']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                print("G3 item: $item");
                og3Weight += double.parse(item['weight'].toString());
              }
            }
          }


          if (grading['Wastage'] != null && grading['Wastage'] is List<dynamic>) {
            for (var item in grading['Wastage']) {
              if (item is Map<String, dynamic> && item['weight'] != null) {
                owastageWeight += double.parse(item['weight'].toString());
              }
            }
          }
        }
      }

      setState(() {
        totalOutwardWeight = totalWeight;
        ototalG1Weight = og1Weight;
        ototalG2Weight = og2Weight;
        ototalG3Weight =og3Weight;
        ototalWastageWeight = owastageWeight;
        print("Total outward weight for $formattedDate: $totalOutwardWeight Kgs");
      });
    } catch (e) {
      print("Error fetching outward weight: $e");
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
        isLoading = true;
      });
      await _fetchAllWeights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mango Management',style: TextStyle(color: Colors.green)),
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
              color: Colors.green
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
          isLoading
              ? CircularProgressIndicator()
              : Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    children: <Widget>[
                      DashboardItem(
                        title: 'Inward',
                        subtitle: "Today's Total Inward: ${totalInwardWeight.toStringAsFixed(2)} Kgs",
                      ),
                      DashboardItem(
                        title: 'Grading',
                        subtitle: "Total Grading: ${totalGradingWeight.toStringAsFixed(2)} Kgs",
                        breakdown: " - G1: ${totalG1Weight.toStringAsFixed(2)} "
                            " - G2: ${totalG2Weight.toStringAsFixed(2)} \n"
                            " - G3: ${totalG3Weight.toStringAsFixed(2)} "
                            " - W: ${totalWastageWeight.toStringAsFixed(2)} ",
                      ),
                      DashboardItem(
                        title: 'Ripening',
                        subtitle: "Total Ripening: ${totalRipeningWeight.toStringAsFixed(2)} Kgs",
                        breakdown: " - G1: ${rtotalG1Weight.toStringAsFixed(2)} "
                            " - G2: ${rtotalG2Weight.toStringAsFixed(2)} \n"
                            " - G3: ${rtotalG3Weight.toStringAsFixed(2)} "
                            " - W: ${rtotalWastageWeight.toStringAsFixed(2)}",
                      ),
                      DashboardItem(
                        title: 'Outward',
                        subtitle: "Total Outward: ${totalOutwardWeight.toStringAsFixed(2)}",
                        breakdown: " - G1: ${ototalG1Weight.toStringAsFixed(2)} "
                            " - G2: ${ototalG2Weight.toStringAsFixed(2)}\n"
                            " - G3: ${ototalG3Weight.toStringAsFixed(2)}"
                            " - W: ${ototalWastageWeight.toStringAsFixed(2)}",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: SemiCircleGraph(
                    totalInwardWeight: totalInwardWeight,
                    totalGradingWeight: totalGradingWeight,
                    totalRipeningWeight: totalRipeningWeight,
                    totalOutwardWeight: totalOutwardWeight,
                    totalG1Weight: totalG1Weight,
                    totalG2Weight: totalG2Weight,
                    totalG3Weight: totalG3Weight,
                    totalWastageWeight: totalWastageWeight,
                  ),
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
  final String? breakdown; // Optional breakdown string

  DashboardItem({required this.title, required this.subtitle, this.breakdown});

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
          if (breakdown != null) ...[
            SizedBox(height: 10),
            Text(
              breakdown!,
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class SemiCircleGraph extends StatelessWidget {
  final double totalInwardWeight;
  final double totalGradingWeight;
  final double totalRipeningWeight;
  final double totalOutwardWeight;
  final double totalG1Weight;
  final double totalG2Weight;
  final double totalG3Weight;
  final double totalWastageWeight;

  SemiCircleGraph({
    required this.totalInwardWeight,
    required this.totalGradingWeight,
    required this.totalRipeningWeight,
    required this.totalOutwardWeight,
    required this.totalG1Weight,
    required this.totalG2Weight,
    required this.totalG3Weight,
    required this.totalWastageWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 300,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: totalInwardWeight,
                color: Colors.blue,
                title: 'Inward',
              ),
              PieChartSectionData(
                value: totalGradingWeight,
                color: Colors.green,
                title: 'Grading',
              ),
              PieChartSectionData(
                value: totalRipeningWeight,
                color: Colors.orange,
                title: 'Ripening',
              ),
              PieChartSectionData(
                value: totalOutwardWeight,
                color: Colors.red,
                title: 'Outward',
              ),



              PieChartSectionData(
                value: totalWastageWeight,
                color: Colors.brown,
                title: 'Wastage',
              ),
            ],
            sectionsSpace: 0,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
            ),
          ),
        ),
      ),
    );
  }
}