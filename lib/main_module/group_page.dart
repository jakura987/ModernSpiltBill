import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';

class GroupPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    // TODO: implement build
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Group Page', style: TextStyle(fontSize: 24)),
            Text('User Name: ${userModel.userName}', style: TextStyle(fontSize: 20)), // 显示用户名
            Text('User Email: ${userModel.userEmail}', style: TextStyle(fontSize: 20)), // 显示用户邮件
            Text('User dailyLimit: ${userModel.dailyLimit}', style: TextStyle(fontSize: 20)),
            Text('User weeklyLimit: ${userModel.weeklyLimit}', style: TextStyle(fontSize: 20)),
            Text('User monthlyLimit: ${userModel.monthlyLimit}', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}