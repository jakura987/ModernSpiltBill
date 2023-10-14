import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../constants/palette.dart';
import 'Bill_Detail_Page.dart';

class Bill {
  final String documentId; // <-- Add this
  final String name;
  final double price;
  final DateTime dateTime;
  final int numberOfPeople;
  final String billDescription;
  final double AAPP;
  final List<PersonStatus> peopleStatus;
  final String imageUrl;

  Bill({
    required this.documentId, // <-- Add this
    required this.name,
    required this.price,
    required this.dateTime,
    required this.numberOfPeople,
    required this.billDescription,
    required this.AAPP,
    required this.peopleStatus,
    required this.imageUrl,
  });

}


class BillPage extends StatefulWidget {
  @override
  _ShowBillState createState() => _ShowBillState();
}

class PersonStatus {
  final String name;
  final bool status;

  PersonStatus({required this.name, required this.status});
}

class _ShowBillState extends State<BillPage>
    with SingleTickerProviderStateMixin {

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }


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


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference bills = FirebaseFirestore.instance.collection(
      'bills');

  List<PersonStatus> parsePersonStatus(List<dynamic> peopleStatusList) {
    return peopleStatusList.map((personStatusMap) {
      return PersonStatus(
        name: personStatusMap['name'],
        status: personStatusMap['status'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 获取UserModel的实例
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        title: Text('Bills', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1.0,
        bottom: TabBar( // Add this TabBar
          controller: _tabController,
          tabs: [
            Tab(text: "All Bills"),
            Tab(text: "Finished Bills"),
            Tab(text: "Unfinished Bills"),
          ],
        ),
      ),
      body: TabBarView( // And this TabBarView
        controller: _tabController,
        children: [
          _buildBillList(userModel, null), // All bills
          _buildBillList(userModel, true), // Finished bills
          _buildBillList(userModel, false), // Unfinished bills
        ],
      ),
    );

    // body: StreamBuilder<QuerySnapshot>(
    //   stream: _firestore.collection('bills').where('peopleName', arrayContains: userModel.userName).snapshots(),
    //   builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    //     if (snapshot.hasError) {
    //       return Center(child: Text('Something went wrong'));
    //     }
    //
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return Center(child: CircularProgressIndicator());
    //     }
    //
    //     return ListView(
    //       children: snapshot.data!.docs.map((DocumentSnapshot document) {
    //         Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    //         return BillBox(
    //           bill: Bill(
    //             documentId: document.id,  // <-- Add this
    //             name: data['billName'] ?? "Unknown",
    //             price: data['billPrice']?.toDouble() ?? 0.0,
    //             dateTime: (data['billDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    //             numberOfPeople: data['peopleNumber']?.toInt() ?? 0,
    //             billDescription: data['billDescription'] ?? "Description not provided",
    //             AAPP: data['AAPP']?.toDouble() ?? 0.0,
    //             peopleStatus: data['peopleStatus'] != null ? parsePersonStatus(data['peopleStatus']) : [],
    //           ),
    //         );
    //       }).toList(),
    //     );
    //   },
    // ),
  }

  Widget _buildBillList(UserModel userModel, bool? isFinished) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bills').where(
        'peopleName',
        arrayContains: userModel.userName,
      ).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text("You currently have no bills", style: TextStyle(color: Colors.grey, fontSize: 18))
          );
        }

        List<BillBox> bills = snapshot.data!.docs.map((
            DocumentSnapshot document) {
          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
          List<PersonStatus> personStatuses = parsePersonStatus(
              data['peopleStatus'] ?? []);
          if (isFinished == null ||
              personStatuses.any((status) => status.name ==
                  userModel.userName && status.status == isFinished)) {
            return BillBox(
              bill: Bill(
                documentId: document.id,
                // <-- Add this
                name: data['billName'] ?? "Unknown",
                price: data['billPrice']?.toDouble() ?? 0.0,
                dateTime: (data['billDate'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                numberOfPeople: data['peopleNumber']?.toInt() ?? 0,
                billDescription: data['billDescription'] ??
                    "Description not provided",
                AAPP: data['AAPP']?.toDouble() ?? 0.0,
                peopleStatus: data['peopleStatus'] != null ? parsePersonStatus(
                    data['peopleStatus']) : [],
                imageUrl: data['imageUrl'] ?? "",
              ),
            );
          } else {
            return null;
          }
        }).where((billBox) => billBox != null).toList().cast<BillBox>();

        return ListView(children: bills);
      },
    );
  }
}


class BillBox extends StatelessWidget {
  final Bill bill;

  BillBox({required this.bill});

  @override
  Widget build(BuildContext context) {
// Extract bill properties for easier reference
    String billName = bill.name;
    String billPrice = bill.price.toStringAsFixed(2);
    String formattedDate = '${bill.dateTime.toLocal()}'.split(' ')[0];
    int peopleNumber = bill.numberOfPeople;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
        leading: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: Palette.primaryColor, // Ensure you have this color defined
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(Icons.receipt, color: Colors.white),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(billName,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text("\$ $billPrice",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate,
                style: TextStyle(
                    color: Palette.secondaryColor,
                    // Ensure you have this color defined
                    fontWeight: FontWeight.bold)),
            Text("$peopleNumber people",
                style: TextStyle(
                    color: Palette.secondaryColor,
                    // Ensure you have this color defined
                    fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BillDetailPage(bill: bill),
          ));
        },

      ),
    );
}

}