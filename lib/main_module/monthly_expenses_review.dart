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
    List<DateTime> lastThreeMonths = [
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];

    // Adjust for year boundaries
    for (int i = 0; i < lastThreeMonths.length; i++) {
      if (lastThreeMonths[i].month <= 0) {
        lastThreeMonths[i] = DateTime(
            lastThreeMonths[i].year - 1, lastThreeMonths[i].month + 12);
      }
    }

    Map<String, double> filteredMonthlySpends = {};
    for (DateTime date in lastThreeMonths) {
      String key = '${date.month}-${date.year}';
      if (monthlySpends.containsKey(key)) {
        filteredMonthlySpends[key] = monthlySpends[key]!;
      }
    }

    // Sort the keys and values
    var sortedKeys = monthlySpends.keys.toList()
      ..sort((a, b) => DateFormat('yyyy-MM')
          .parse(a)
          .compareTo(DateFormat('yyyy-MM').parse(b)));

    var sortedValues = sortedKeys.map((key) => monthlySpends[key]!).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTitles: (value) {
                int index = value.toInt();
                return index < sortedKeys.length ? sortedKeys[index] : '';
              },
            ),
            leftTitles: SideTitles(showTitles: true),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Palette.primaryColor, width: 1),
          ),
          minX: 0,
          maxX: (sortedKeys.length - 1).toDouble(),
          minY: 0,
          maxY: sortedValues.reduce((curr, next) => curr > next ? curr : next),
          lineBarsData: [
            LineChartBarData(
              spots: sortedValues
                  .asMap()
                  .map((index, value) =>
                      MapEntry(index, FlSpot(index.toDouble(), value)))
                  .values
                  .toList(),
              isCurved: true,
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyExpensesPageState extends State<MonthlyExpensesPage> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      // 调用 UserModel 的 fetchUser 方法
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.fetchUser(context);
    }
    super.didChangeDependencies();
  }

  Future<Map<String, double>> _fetchMonthlySpends(String userName) async {
    Map<String, double> monthlySpends = {};

    QuerySnapshot billsSnapshot = await FirebaseFirestore.instance
        .collection('bills')
        .where('peopleName', arrayContains: userName)
        .get();

    for (var doc in billsSnapshot.docs) {
      var billData = doc.data() as Map<String, dynamic>;
      DateTime billDate = (billData['billDate'] as Timestamp).toDate();
      String monthKey = "${billDate.year}-${billDate.month}";

      if (!monthlySpends.containsKey(monthKey)) {
        monthlySpends[monthKey] = 0.0;
      }
      monthlySpends[monthKey] = (monthlySpends[monthKey] ?? 0.0) +
          (billData['AAPP']?.toDouble() ?? 0.0);
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
        padding: EdgeInsets.only(top: 80.0, bottom: 20.0), // Add top padding for chart labels
        child: FutureBuilder<Map<String, double>>(
          future: _fetchMonthlySpends(userModel.userName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.error != null) {
              return Center(child: Text('An error occurred!'));
            } else {
              if (snapshot.data!.isEmpty) {
                return Center(child: Text('no bills data can be found'));
              }

              final sortedKeys = snapshot.data!.keys.toList()
                ..sort((a, b) => a.compareTo(b));
              final sortedValues = sortedKeys.map((key) => snapshot.data![key]!).toList();

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: sortedValues.reduce((curr, next) => curr > next ? curr : next),
                  barGroups: sortedValues.asMap().entries.map((entry) {
                    int index = entry.key;
                    double value = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          y: value,
                          width: 15, // Reduce the width of the bars
                          colors: [Palette.primaryColor],
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        return sortedValues.contains(value) ? value.toStringAsFixed(0) : '';
                      },
                    ),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        int index = value.toInt();
                        if (index < sortedKeys.length) {
                          DateTime dateTime = DateFormat("yyyy-MM").parse(sortedKeys[index]);
                          return DateFormat("MMM yyyy").format(dateTime);
                        }
                        return '';
                      },
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
