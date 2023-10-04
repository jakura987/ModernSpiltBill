import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spiltbill/main_module/add_page.dart';
import 'package:spiltbill/navigate_page.dart';

import '../bill_created_notification.dart';
import 'home_page.dart';


class CreateBill extends StatefulWidget {
  final List<String> selectedGroups;

  CreateBill({required this.selectedGroups});

  @override
  _CreateBillState createState() => _CreateBillState();
}

class PersonStatus {
  final String name;
  final bool status;
  final bool isViewed; // 添加 isViewed 属性

  PersonStatus({
    required this.name,
    this.status = false,
    this.isViewed = false, // 默认值为 false
  });

  // 将对象转换为Map以供Firebase使用
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'isViewed': isViewed, // 添加到 map 中
    };
  }
}



class _CreateBillState extends State<CreateBill> {


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _selectedPeople = [];
  List<String> allPeopleNames = [];
  Set<String> uniquePeopleNamesSet = Set<String>();


  DateTime? _selectedDate;
  String? _billDescription;
  String _billName = '';
  double? _billPrice;
  String _summaryText = '';


  Future<void> _checkDailyLimit() async {
    List<String> exceededUsers = [];
    double currentBillAAPP = _billPrice! / _selectedPeople.length;

    for (var person in _selectedPeople) {
      double peopleSpend = currentBillAAPP;
      QuerySnapshot billsSnapshot = await _firestore.collection('bills').where('billDate', isEqualTo: _selectedDate).get();
      for (var bill in billsSnapshot.docs) {
        var billData = bill.data() as Map<String, dynamic>;
        if (billData['peopleName'] is List && (billData['peopleName'] as List).contains(person)) {
          peopleSpend += billData['AAPP']?.toDouble() ?? 0.0;
        }
      }

      // New code for fetching user data based on name
      QuerySnapshot userQuery = await _firestore.collection('users').where('name', isEqualTo: person).get();
      Map<String, dynamic>? userData;
      if (userQuery.docs.isNotEmpty) {
        userData = userQuery.docs.first.data() as Map<String, dynamic>;
      } else {
        print('No data found for user $person');
      }

      double dailyLimit = userData?['dailyLimit']?.toDouble() ?? 0.0;
      print("Person: $person, Spend: $peopleSpend, Limit: $dailyLimit");

      if (peopleSpend > dailyLimit) {
        exceededUsers.add(person);
      }
    }


    if (exceededUsers.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // This makes the column only as tall as its children.
            children: exceededUsers.map((user) => Text('$user have exceeded daily limit.')).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => NavigatePage()),
                        (route) => false
                );
              },
            ),
          ],
        ),
      );
    }

  }



  Future<void> _submitBill() async {
    await _checkDailyLimit();
    try {
      // Prepare the data
      List<PersonStatus> peopleStatus = _selectedPeople.map((personName) => PersonStatus(name: personName)).toList();
      List<Map<String, dynamic>> peopleStatusMapList = peopleStatus.map((e) => e.toMap()).toList();

      Map<String, dynamic> billData = {
        'billName': _billName,
        'billDate': Timestamp.fromDate(_selectedDate!),
        'billPrice': _billPrice,
        'billDescription': _billDescription,
        'peopleNumber': _selectedPeople.length,
        'AAPP': _billPrice! / _selectedPeople.length,
        'peopleName': _selectedPeople,
        'peopleStatus': peopleStatusMapList,
      };

      // Submit the data to Firestore
      await _firestore.collection('bills').add(billData);

      // Show snackbar upon successful submission
      final snackBar = SnackBar(content: Text('Submit success'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      //sendNotification
      BillCreatedNotification().dispatch(context);

      // Navigate to HomePage and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NavigatePage()),
            (route) => false, // remove all routes
      );

    } catch (e) {
      print('Error submitting bill: $e');
      final snackBar = SnackBar(content: Text('Error submitting bill. Please try again.'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }



  _splitBill() {
    // Check if all the necessary data is provided
    if (_billName.isEmpty || _selectedDate == null || _billPrice == null || _selectedPeople.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please provide all the necessary data.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    int peopleNumber = _selectedPeople.length;
    double avgAmount = _billPrice! / peopleNumber;

    setState(() {
      _summaryText = """
      Bill Name: $_billName
      Date: ${_selectedDate?.toLocal().toString().split(' ')[0]}
      Bill Price: \$${_billPrice?.toStringAsFixed(2) ?? '0'}
      Description: $_billDescription
      People Number: $peopleNumber
      Average Amount Per Person: \$${avgAmount.toStringAsFixed(2)}
    """;
    });
  }


  @override
  void initState() {
    super.initState();

    print('Received Selected Groups: ${widget.selectedGroups}');

    fetchPeopleNames();
  }

  Future<void> fetchPeopleNames() async {
    for (String groupName in widget.selectedGroups) {
      final group = await _firestore.collection('groups').doc(groupName).get();
      final List<String> peopleNames = List<String>.from(group['peopleName']);
      uniquePeopleNamesSet.addAll(peopleNames);  // 使用 addAll 方法将所有人名添加到 Set 中
    }
    setState(() {
      allPeopleNames = uniquePeopleNamesSet.toList();  // 将 Set 转换为 List
    });
  }


  Future<void> fetchPeopleNamesFromSelectedGroups() async {
    for (String groupName in widget.selectedGroups) {
      final group = await _firestore.collection('groups').doc(groupName).get();
      final List<String> peopleNames = List<String>.from(group['peopleName']);
      allPeopleNames.addAll(peopleNames);
    }
    setState(() {}); // 更新UI
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Create your bill"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 返回到 ChooseGroup 页面
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Bill Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bill Information",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    // Bill Name
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bill Name  *", style: TextStyle(fontSize: 20)),
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Enter bill name",
                            ),
                            onChanged: (value) {
                              _billName = value;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Date
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date  *", style: TextStyle(fontSize: 20)),
                          ElevatedButton(
                            onPressed: () async {
                              DateTime? chosenDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (chosenDate != null && chosenDate != _selectedDate) {
                                setState(() {
                                  _selectedDate = chosenDate;
                                });
                              }
                            },
                            child: Text(_selectedDate == null
                                ? "Select Date"
                                : "${_selectedDate!.toLocal()}".split(' ')[0]),
                          ),
                        ],
                      ),
                    ),

                    // Bill Price
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bill Price  *", style: TextStyle(fontSize: 20)),
                          TextField(
                            keyboardType: TextInputType.number, // Only allow numbers
                            decoration: InputDecoration(
                              hintText: "Enter bill price",
                            ),
                            onChanged: (value) {
                              _billPrice = double.tryParse(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Description", style: TextStyle(fontSize: 20)),
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Enter bill description",
                            ),
                            onChanged: (value) {
                              _billDescription = value;
                            },
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),


            SizedBox(height: 20),


            // Shared to
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shared to  *",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 200.0,
                      child: SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: allPeopleNames.length,
                          itemBuilder: (context, index) {
                            return CheckboxListTile(
                              title: Text(allPeopleNames[index], style: TextStyle(fontSize: 24)),
                              value: _selectedPeople.contains(allPeopleNames[index]),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedPeople.add(allPeopleNames[index]);
                                  } else {
                                    _selectedPeople.remove(allPeopleNames[index]);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SizedBox(height: 20),

            // Bill Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bill Summary",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _summaryText,
                      style: TextStyle(fontSize: 20),
                    ),
                    if (_summaryText.isNotEmpty) // Only show the "Submit bill" button if _summaryText is not empty
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton(
                            onPressed: _submitBill,
                            child: Text("Submit bill", style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),



            SizedBox(height: 20),

            // Split Bill Button
            ElevatedButton(
              onPressed: _splitBill,
              child: Text("Split bill", style: TextStyle(fontSize: 28)),
            ),
          ],
        ),
      ),
    );
  }
}
