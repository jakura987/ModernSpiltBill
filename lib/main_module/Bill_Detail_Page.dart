import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../constants/palette.dart';
import '../models/user_model.dart';
import 'bill_page.dart';

class BillDetailPage extends StatelessWidget {
  final Bill bill;

  BillDetailPage({required this.bill});

  Future<void> _deleteBill(BuildContext context) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this bill?"),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Palette.secondaryColor)),
            onPressed: () {
              Navigator.pop(context, false); // Returns false to the calling method
            },
          ),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bills').doc(bill.documentId).delete();
              Navigator.pop(context, true); // Returns true to the calling method
              Navigator.pop(context); // Close the current page after deletion
            },
          ),
        ],
      ),
    );
  }


  Future<void> _markAsSettled(BuildContext context) async {
    // 获取当前用户
    UserModel userModel = Provider.of<UserModel>(context, listen: false);

    // 更新Firestore中的数据
    DocumentReference billRef = FirebaseFirestore.instance.collection('bills').doc(bill.documentId);
    List<PersonStatus> updatedStatus = [];

    for (PersonStatus status in bill.peopleStatus) {
      if (status.name == userModel.userName) {
        updatedStatus.add(PersonStatus(name: status.name, status: true));
      } else {
        updatedStatus.add(status);
      }
    }

    await billRef.update({
      'peopleStatus': updatedStatus.map((status) => {
        'name': status.name,
        'status': status.status
      }).toList()
    });
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    final peopleStatus = bill.peopleStatus;

    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Close the current page
          },
        ),
        title: Text(
          'Bill Details',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteBill(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bill Name Card
              Card(
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('Bill Name'),
                  subtitle: Text(bill.name),
                ),
              ),
              // Total Bill Amount Card
              Card(
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('Total Bill Amount'),
                  subtitle: Text('\$${bill.price.toStringAsFixed(2)}'),
                ),
              ),
              // Description Card
              Card(
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('Description'),
                  subtitle: Text(bill.billDescription),
                ),
              ),
              // Average Amount Per Person Card
              Card(
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('Average Amount Per Person'),
                  subtitle: Text('\$${bill.AAPP.toStringAsFixed(2)}'),
                ),
              ),
              // People Status Card
              Expanded(
                child: Card(
                  margin: EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.builder(
                    itemCount: peopleStatus.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: peopleStatus[index].status ? Colors.green : Colors.red,
                          child: Text(peopleStatus[index].name[0], style: TextStyle(color: Colors.white)),
                        ),
                        title: Text(peopleStatus[index].name),
                        subtitle: Text(peopleStatus[index].status ? "done" : "undone"),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(15.0),
        child: ElevatedButton(
          onPressed: () => _markAsSettled(context),
          child: Text('Settled'),
          style: ElevatedButton.styleFrom(
            primary: Palette.primaryColor,
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}
