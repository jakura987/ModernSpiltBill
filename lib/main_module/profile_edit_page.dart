import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:SpiltBill/models/user_avatar_model.dart';
import '../models/user_model.dart';
import '../constants/palette.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

Future<int?> _showImagePicker(BuildContext context) async {
  // 设定每个头像的大小
  double avatarSize = 100.0; // 您可以根据需要调整此值
  // 设定头像的边距
  double avatarPadding = 10.0;

  // 计算每行的高度
  double rowHeight = (avatarSize + (2 * avatarPadding)) * 2; // 2 rows as we want 4 avatars per row

  return await showModalBottomSheet<int>(
    context: context,
    builder: (BuildContext bc) {
      return Container(
        height: rowHeight,  // 设置容器高度
        child: GridView.count(
          physics: NeverScrollableScrollPhysics(), // 禁止滚动，因为我们已经知道了所需的高度
          crossAxisCount: 4,
          children: List.generate(8, (index) {
            return Padding(
              padding: EdgeInsets.all(avatarPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(index + 1);
                },
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/image${index + 1}.jpg'),
                ),
              ),
            );
          }),
        ),
      );
    },
  );
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String? userImage = 'assets/images/image1.jpg';

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  int? _currentHeadValue;

  Future<void> _loadUserAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("用户未登录");
    } else {
      print("用户已登录，UID是：${user.uid}");
    }

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        _currentHeadValue = userDoc.data()!['head'] ?? 1;
      } else {
        _currentHeadValue = 1;
      }

      final userAvatar = Provider.of<UserAvatar>(context, listen: false);
      userAvatar.avatarPath = 'assets/images/image${_currentHeadValue}.jpg';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not signed in!'))
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent.'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending password reset email.'))
      );
    }
  }

  Future<void> _updateAvatarInFirestore(int index) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'head': index});
      }
      print("Updating avatar in Firestore with index: $index");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final userAvatar = Provider.of<UserAvatar>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    int? userHeadValue = userModel.head;  // 获取 head 的值
    String avatarPath = userAvatar.avatarPath;  // 根据 head 值构造头像的资产路径

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
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
          centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  final user = _auth.currentUser;
                  if (user != null) {
                    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
                    if (userDoc.exists && !(userDoc.data() as Map<String, dynamic>).containsKey('head')) {
                      await _firestore.collection('users').doc(user.uid).set({'head': 1}, SetOptions(merge: true));
                    }

                    // Allow the user to pick a new avatar now
                    final selectedImageIndex = await _showImagePicker(context);
                    if (selectedImageIndex != null) {
                      final userAvatar = Provider.of<UserAvatar>(context, listen: false);
                      userAvatar.avatarPath = 'assets/images/image${selectedImageIndex}.jpg';

                      await _updateAvatarInFirestore(selectedImageIndex);
                      setState(() {
                        _currentHeadValue = selectedImageIndex;  // 更新私有变量的值并触发UI更新
                      });// Update the head value in Firestore
                    }
                  }
                },
                child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(avatarPath)
                ),
              ),


              SizedBox(height: screenHeight * 0.06),
              // Name Card
              Card(
                margin: EdgeInsets.all(10), // Add margin
                shape: RoundedRectangleBorder(
                  // Add rounded corners
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  title: Row(
                    children: [
                      Text('Name: ', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10), // Horizontal spacing
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Align to the start
                    children: [
                      SizedBox(height: 15), // Vertical spacing
                      Text(userModel.userName ?? 'Username',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),
              // Email Card
              Card(
                margin: EdgeInsets.all(10), // Add margin
                shape: RoundedRectangleBorder(
                  // Add rounded corners
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  title: Row(
                    children: [
                      Text('Email: ', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10), // Horizontal spacing
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Align to the start
                    children: [
                      SizedBox(height: 15), // Vertical spacing
                      Text(userModel.userEmail ?? 'user@email.com',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.06),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.primaryColor,  // Button's background color
                  foregroundColor: Colors.white,  // Button's text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),  // Rounded edges
                  ),
                ),
                child: Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _resetPassword,  // Call _resetPassword method when the button is pressed
              ),
            ],
          ),
        ),
      ),
    );
  }
}
