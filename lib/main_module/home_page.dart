import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../bill_created_notification.dart';
import '../models/user_model.dart';
import 'add_page.dart';
import 'bill_page.dart';
import '../constants/palette.dart';

class HomePage extends StatefulWidget {
  final VoidCallback goToBillPage;
  HomePage({required this.goToBillPage});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasNewBill = false;
  String _currentUserName = 'Loading...';
  String _billInfo = 'Loading...';

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.fetchUser();
      _checkUserStatus();
    }
    super.didChangeDependencies();
  }

  Future<void> _checkUserStatus() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    await userModel.fetchUser();
    setState(() {
      _currentUserName = userModel.userName;
    });

    QuerySnapshot billsSnapshot = await _firestore.collection('bills').get();
    bool hasNewBill = false;

    for (DocumentSnapshot billDoc in billsSnapshot.docs) {
      Map<String, dynamic> data = billDoc.data() as Map<String, dynamic>;
      var peopleStatusList = data['peopleStatus'] as List;

      for (var status in peopleStatusList) {
        if (status['name'] == _currentUserName && status['isViewed'] == false) {
          setState(() {
            _hasNewBill = true;
            _billInfo = 'You have a new bill!';
          });
          return;
        }
      }
    }

    if (!_hasNewBill) {
      setState(() {
        _billInfo = 'No new bill found.';
      });
    }
  }

  void handleViewBill() async {
    QuerySnapshot billsSnapshot = await FirebaseFirestore.instance.collection('bills').get();

    for (DocumentSnapshot billDoc in billsSnapshot.docs) {
      Map<String, dynamic> data = billDoc.data() as Map<String, dynamic>;
      var peopleStatusList = data['peopleStatus'] as List;

      bool updated = false;
      for (var status in peopleStatusList) {
        if (status['name'] == _currentUserName && status['isViewed'] == false) {
          status['isViewed'] = true;
          updated = true;
        }
      }

      if (updated) {
        await billDoc.reference.update({
          'peopleStatus': peopleStatusList,
        });
      }
    }

    setState(() {
      _hasNewBill = false;
      _billInfo = 'No new bill found.';
    });

    Navigator.push(context, MaterialPageRoute(builder: (context) => BillPage()));
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        title: Text('Hello, ${userModel.userName}', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1.0,
        actions: [
          if (_hasNewBill)
            IconButton(
              icon: Icon(Icons.notifications_active, color: Colors.red),
              onPressed: handleViewBill,
            )
          else
            IconButton(
              icon: Icon(Icons.notifications_none, color: Colors.grey),
              onPressed: () {}, // Do nothing or show no new notifications
            ),
        ],
      ),
      body: NotificationListener<BillCreatedNotification>(
        onNotification: (notification) {
          _checkUserStatus();
          return true;
        },
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Palette.primaryColor,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Need to split？",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Palette.primaryColor,
                          padding: EdgeInsets.symmetric(
                              vertical: 20.0, horizontal: 30.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddPage()),
                          );
                        },
                        child: Text(
                          "Create new bill",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bills Display Title
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent bills",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BillPage()));
                    },
                    child: Text("See all",
                        style: TextStyle(
                            color: Palette.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Bills Display
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bills').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Something went wrong!"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final bills = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final billName = bill['billName'] ?? "No name";
                      final billPrice = bill['billPrice'] ?? "0.0";

                      // Timestamp processing
                      final Timestamp timestamp = bill['billDate'];
                      final DateTime billDate = timestamp.toDate();
                      final formattedDate =
                          "${billDate.year}-${billDate.month}-${billDate.day}";

                      final peopleNumber = bill['peopleNumber'] ?? "Unknown Count";

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        margin: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 20.0),
                          leading: Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Palette.primaryColor,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(Icons.receipt, color: Colors.white),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(billName,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16,fontWeight: FontWeight.bold)),
                              Text("\$ $billPrice",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16,fontWeight: FontWeight.bold))
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formattedDate,
                                  style: TextStyle(
                                      color: Palette.secondaryColor,
                                      fontWeight: FontWeight.bold)),
                              Text("$peopleNumber people",
                                  style: TextStyle(
                                      color: Palette.secondaryColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
