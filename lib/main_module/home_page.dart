import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../bill_created_notification.dart';
import '../models/user_model.dart';


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

  // bool? displayedIsViewed;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  /**
   * 检测firestorage是否有新的bill
   */
  Future<void> _checkUserStatus() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    await userModel.fetchUser();
    setState(() {
      _currentUserName = userModel.userName;
    });
    // 获取所有 bills 的文档
    QuerySnapshot billsSnapshot = await _firestore.collection('bills').get();
    bool hasNewBill = false; // 初始值为 false

    for (DocumentSnapshot billDoc in billsSnapshot.docs) {
      Map<String, dynamic> data = billDoc.data() as Map<String, dynamic>;
      var peopleStatusList = data['peopleStatus'] as List;

      // 查找当前用户名对应的 isViewed 是否为 false
      for (var status in peopleStatusList) {
        if (status['name'] == _currentUserName && status['isViewed'] == false) {
          setState(() {
            _hasNewBill = true;
          });
          // hasNewBill = true;
          setState(() {
            _billInfo = 'You have a new bill!';
          });
          return; // 找到后直接退出方法
        }
      }
    }
    // 如果遍历了所有文档都没有找到新账单，那么更新状态
    if (!_hasNewBill) {
      setState(() {
        _billInfo = 'No new bill found.';
      });
    }
  }

  /**
   * 点击View btn后跳转对应至页面并且更新firestorage中的isViewed属性
   */
  void handleViewBill() async {
    // 获取所有 bills 的文档
    QuerySnapshot billsSnapshot = await FirebaseFirestore.instance.collection('bills').get();

    for (DocumentSnapshot billDoc in billsSnapshot.docs) {
      Map<String, dynamic> data = billDoc.data() as Map<String, dynamic>;
      var peopleStatusList = data['peopleStatus'] as List;

      // 查找当前用户名对应的项并更新 isViewed
      bool updated = false;
      for (var status in peopleStatusList) {
        if (status['name'] == _currentUserName && status['isViewed'] == false) {
          status['isViewed'] = true;
          updated = true;
        }
      }

      // 如果进行了更新，将更新的数据写回到 Firestore
      if (updated) {
        await billDoc.reference.update({
          'peopleStatus': peopleStatusList,
        });
      }
    }

    // 更新页面状态
    setState(() {
      _hasNewBill = false;
      _billInfo = 'No new bill found.'; // 或其他您希望显示的内容
    });

    widget.goToBillPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HomePage')),
      body: NotificationListener<BillCreatedNotification>(
        onNotification: (notification) {
          _checkUserStatus();
          return true; // true 表示我们已经处理了这个 notification。
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Username: $_currentUserName"),
              SizedBox(height: 20),
              Text("$_billInfo"),
              SizedBox(height: 20),
              // 如果有新的账单，则显示按钮
              if (_hasNewBill)
                ElevatedButton(
                  onPressed: handleViewBill,  // 使用新创建的方法
                  child: Text("View New Bill", style: TextStyle(fontSize: 18)),
                ),


            ],
          ),
        ),
      ),
    );
  }
}
