import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
// when user logins successfully, trigger this page
class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('Home Page')),
    Center(child: Text('Group Page')),
    Center(child: Text('Plus Page')),
    Center(child: Text('Bill Page')),
    Center(child: Text('Me Page')),
  ];

  Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Welcome'; // 如果没有用户登录，返回默认欢迎信息

    final userDoc = await _firestore
        .collection('users')
        .where('email', isEqualTo: user.email) // 使用 email 查询用户文档
        .limit(1)
        .get();

    if (userDoc.size == 0) return 'Welcome'; // 如果没有找到用户文档，返回默认欢迎信息

    final userName = userDoc.docs.first['name'];
    return 'Welcome $userName'; // 返回带有用户名的欢迎信息
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async{
            await _auth.signOut();//登出用户
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()));//跳转到login页面
          },
        ),
        title: Text('Welcome Page'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey, // 未选中项的颜色
        selectedItemColor: Colors.black, // 选中项的颜色
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Group'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '+'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Bill'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),

    );
  }
}


