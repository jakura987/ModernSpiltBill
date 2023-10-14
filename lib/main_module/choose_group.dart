import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'create_bill.dart';
import '../models/user_model.dart';
import '../constants/palette.dart';

class ChooseGroup extends StatefulWidget {
  @override
  _ChooseGroupState createState() => _ChooseGroupState();
}

class _ChooseGroupState extends State<ChooseGroup> {

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

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      backgroundColor: Palette.primaryColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Choose your group", style: TextStyle(color: Colors.white)),
        backgroundColor: Palette.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: _firestore.collection('groups').where('peopleName', arrayContains: userModel.userName).snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text("You currently have no groups", style: TextStyle(color: Colors.black, fontSize: 18))
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final group = snapshot.data!.docs[index];
                final groupName = group['groupName'] as String;
                final memberCount = (group['peopleName'] as List).length;  // 获取群组的成员数
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateBill(selectedGroups: [groupName]), // Navigate to the next page with the selected group name
                          ),
                        );
                      },
                      leading: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: Palette.primaryColor,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(Icons.house, color: Colors.white),
                      ),
                      title: Text(groupName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text('$memberCount members', style: TextStyle(color: Palette.secondaryColor)),
                      trailing: IconButton(  // 添加的 "Next" 按钮
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateBill(selectedGroups: [groupName]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

