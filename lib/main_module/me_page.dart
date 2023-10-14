import 'package:flutter/material.dart';
import 'package:spiltbill/main_module/profile_edit_page.dart';
import 'package:spiltbill/main_module/settings_page.dart';
import '../constants/palette.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../login_page.dart';
import '../models/user_avatar_model.dart';
import '../models/user_model.dart';

class MePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // 获取屏幕的高度
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1.0,
      ),
      body: Container(
        color: Palette.backgroundColor,
        child: Column(
          children: <Widget>[
            // 添加这个 SizedBox 来控制与 AppBar 的距离
            SizedBox(height: screenHeight * 0.03),

            // 添加外部的 Container，为其设置白色背景
            Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildProfileSection(context),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // 功能列表部分
            ..._buildFunctionList(context),

            Spacer(),

            // 登出部分
            _buildLogoutSection(context),

            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer2<UserAvatar, UserModel>(
      builder: (context, userProfile, userModel, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileEditPage()));
          },
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(userProfile.avatarPath),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(userModel.userName ?? 'Username',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text(userModel.userEmail ?? 'user@email.com',
                              style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  List<Widget> _buildFunctionList(BuildContext context) {
    final functions = [
      'Notifications',
      'Rate us',
      'Contact us',
      'Settings'
    ];
    return functions.map((f) => _buildFunctionItem(context, f)).toList();
  }

  Widget _buildFunctionItem(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        if (name == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        }
        // 在此，你可以根据其他的功能名称添加更多的跳转逻辑
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border:
          Border(bottom: BorderSide(color: Colors.grey[400]!, width: 0.5)),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(name, style: TextStyle(fontSize: 16)),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await _auth.signOut();
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => LoginPage()));
          },
          child: Text(
            'Log out',
            style: TextStyle(
              color: Palette.primaryColor,
              fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Copyright © SYD COMP5216 2023',
          style: TextStyle(
            color: Palette.secondaryColor,
            fontSize: 12.0,
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
