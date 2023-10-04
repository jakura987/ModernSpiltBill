import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'create_bill.dart';
import '../models/user_model.dart';

class AddPage extends StatefulWidget {
  @override
  _ChooseGroupState createState() => _ChooseGroupState();
}

class _ChooseGroupState extends State<AddPage> {

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      // 调用 UserModel 的 fetchUser 方法
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.fetchUser();
    }
    super.didChangeDependencies();
  }


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> selectedGroups = [];
  bool allGroupsSelected = false;  // 新增

  @override
  Widget build(BuildContext context) {

    // 获取UserModel的实例
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Choose your group"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('groups').where('peopleName', arrayContains: userModel.userName).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                List<String> allGroupNames = snapshot.data!.docs.map((doc) => doc['groupName'] as String).toList();
                return ListView(
                  children: [
                    CheckboxListTile(  // 新增
                      title: Text("All Groups", style: TextStyle(fontSize: 24)),
                      value: allGroupsSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          allGroupsSelected = value!;
                          if (allGroupsSelected) {
                            selectedGroups = List.from(allGroupNames);
                          } else {
                            selectedGroups.clear();
                          }
                        });
                      },
                    ),
                    ...List.generate(snapshot.data!.docs.length, (index) {
                      final group = snapshot.data!.docs[index];
                      final groupName = group['groupName'] as String; // 获取groupName字段
                      return CheckboxListTile(
                        title: Text(groupName, style: TextStyle(fontSize: 24)),
                        value: selectedGroups.contains(groupName),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedGroups.add(groupName);
                              if (selectedGroups.length == allGroupNames.length) {
                                allGroupsSelected = true;
                              }
                            } else {
                              selectedGroups.remove(groupName);
                              allGroupsSelected = false;
                            }
                          });
                        },
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedGroups.isNotEmpty
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateBill(selectedGroups: selectedGroups),
                ),
              );
            }
                : null,
            child: Text('Continue', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}

