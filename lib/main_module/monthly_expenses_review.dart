import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/palette.dart';

class MonthlyExpensesPage extends StatefulWidget {
  @override
  _MonthlyExpensesPageState createState() => _MonthlyExpensesPageState();
}

class MonthlySpendingChart extends StatelessWidget {
  final Map<String, double> monthlySpends;

  MonthlySpendingChart({required this.monthlySpends});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    List<String> lastThreeMonthsLabels = [
      DateFormat('MMM').format(now.subtract(Duration(days: 60))),
      DateFormat('MMM').format(now.subtract(Duration(days: 30))),
      DateFormat('MMM').format(now),
    ];

    var sortedValues = lastThreeMonthsLabels.map((label) => monthlySpends[label] ?? 0).toList();

    double maxY = (sortedValues.isNotEmpty)
        ? sortedValues.reduce((curr, next) => curr > next ? curr : next)
        : 1.0;
    maxY += maxY * 0.1;  // Setting maxY to 10% more than the maximum value

    return Column(
      children: [
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTitles: (value) {
                    switch (value.toInt()) {
                      case 0:
                        return lastThreeMonthsLabels[0];
                      case 1:
                        return lastThreeMonthsLabels[1];
                      case 2:
                        return lastThreeMonthsLabels[2];
                      default:
                        return '';
                    }
                  },
                ),
                leftTitles: SideTitles(showTitles: false),
                topTitles: SideTitles(showTitles: false), // 确保此属性为false
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Palette.primaryColor, width: 1),
              ),
              maxY: maxY,
              barGroups: sortedValues.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      borderRadius: BorderRadius.zero,
                      y: entry.value,
                      width: 15,
                      colors: [Palette.primaryColor],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        ...lastThreeMonthsLabels.map((label) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            margin: EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(label),
              trailing: Text('${monthlySpends[label]?.toStringAsFixed(2) ?? '0'}'),
            ),
          );
        }).toList(),
      ],
    );
  }
}


class _MonthlyExpensesPageState extends State<MonthlyExpensesPage> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.fetchUser(context);
    }
    super.didChangeDependencies();
  }

  Future<Map<String, double>> _fetchMonthlySpends(String userName) async {
    // 为最后三个月初始化地图并设置默认值
    DateTime now = DateTime.now();
    Map<String, double> monthlySpends = {
      DateFormat('MMM').format(now.subtract(Duration(days: 60))): 0,
      DateFormat('MMM').format(now.subtract(Duration(days: 30))): 0,
      DateFormat('MMM').format(now): 0,
    };

    QuerySnapshot billsSnapshot = await FirebaseFirestore.instance
        .collection('bills')
        .where('peopleName', arrayContains: userName)
        .get();

    for (var doc in billsSnapshot.docs) {
      var billData = doc.data() as Map<String, dynamic>;
      DateTime billDate = (billData['billDate'] as Timestamp).toDate();
      String monthKey = DateFormat('MMM').format(billDate);

      monthlySpends[monthKey] = (monthlySpends[monthKey] ?? 0.0) + (billData['AAPP']?.toDouble() ?? 0.0);
    }

    return monthlySpends;
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Monthly Expenses Review', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      body: Padding(
        padding: EdgeInsets.all(50.0),
        child: FutureBuilder<Map<String, double>>(
          future: _fetchMonthlySpends(userModel.userName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.error != null) {
              return Center(child: Text('An error occurred!'));
            } else {
              if (snapshot.data!.isEmpty) {
                return Center(child: Text('No bills data can be found'));
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: MonthlySpendingChart(monthlySpends: snapshot.data!),
              );
            }
          },
        ),
      ),
    );
  }
}

