import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:spiltbill/models/user_avatar_model.dart';
import '../models/user_model.dart';



class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

Future<String?> _showImagePicker(BuildContext context) async {
  return await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage('assets/images/image1.jpg')),
                title: Text('Image 1'),
                onTap: () => Navigator.of(context).pop('assets/images/image1.jpg'),
              ),
              ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage('assets/images/image2.jpg')),
                title: Text('Image 2'),
                onTap: () => Navigator.of(context).pop('assets/images/image2.jpg'),
              ),
              // Add more ListTiles for other images
            ],
          ),
        );
      }
  );
}




class _ProfileEditPageState extends State<ProfileEditPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String? userImage = 'assets/images/image1.jpg';


  @override
  void initState() {
    super.initState();
    _openHiveBox().then((_) {
      _loadUserImage();
    });
  }

  Future<void> _openHiveBox() async {
    await Hive.openBox('settings');
    setState(() {
      userImage = Hive.box('settings').get('user_avatar', defaultValue: 'assets/images/image1.jpg');
    });
  }

  @override
  void dispose() {
    Hive.close();  // 如果您在整个应用中只有一个Box，则可以这样关闭；否则可以使用Hive.box('settings').close()关闭特定的Box。
    super.dispose();
  }

  Future<void> _loadUserImage() async {
    final userModel = Provider.of<UserModel>(context);
    String? img = Hive.box('settings').get(userModel.userEmail, defaultValue: 'assets/images/image1.jpg');
    if (img != null) {
      setState(() {
        userImage = img;
      });
    }
  }

  //TODO: 修改后要重新登录才会显示修改后的名字
  Future<void> _renameUser() async {
    String? newName = await _showRenameDialog();
    if (newName != null && newName.isNotEmpty) {
      final user = _auth.currentUser;
      if (user != null) {
        // 查找与用户邮箱匹配的文档
        final userDocs = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userDocs.size == 0) {
          print("Document not found");
          return;
        }

        // 使用找到的文档ID来更新用户名
        await _firestore
            .collection('users')
            .doc(userDocs.docs.first.id)
            .update({'name': newName});

        setState(() {});  // 更新UI
      }
    }
  }

  //修改名字的部分页面
  Future<String?> _showRenameDialog() async {
    String? newName;
    final TextEditingController nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'New name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Rename'),
              onPressed: () {
                newName = nameController.text.trim();
                Navigator.of(context).pop(newName);
              },
            ),
          ],
        );
      },
    );
  }

  //修改密码
  Future<bool> _showPasswordVerificationDialog() async {
    final TextEditingController passwordController = TextEditingController();
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify Password'),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Current Password'),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Verify'),
              onPressed: () async {
                final user = _auth.currentUser;
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user?.email ?? "",
                  password: passwordController.text,
                );
                try {
                  await user?.reauthenticateWithCredential(credential);
                  Navigator.of(context).pop(true);
                } catch (e) {
                  Navigator.of(context).pop(false);
                }
              },
            ),
          ],
        );
      },
    ) ?? false;
  }
  //也是修改密码
  Future<void> _showChangePasswordDialog() async {
    final TextEditingController newPasswordController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: newPasswordController,
            decoration: InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                final user = _auth.currentUser;
                try {
                  await user?.updatePassword(newPasswordController.text);
                  Navigator.of(context).pop();
                } catch (e) {
                  // Handle errors here
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final userAvatar = Provider.of<UserAvatar>(context);
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
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
                  final selectedImage = await _showImagePicker(context);
                  if (selectedImage != null) {
                    userAvatar.avatarPath = selectedImage; // 更新 UserProfile 中的头像路径
                    Hive.box('settings').put(userModel.userEmail, selectedImage);  // 使用 userEmail 作为 key 存储到 Hive
                  }
                },
                child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(userAvatar.avatarPath)
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              Text(userModel.userName ?? 'Username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              InkWell(
                onTap: _renameUser,
                child: Icon(Icons.edit, size: 20),
              ),
              SizedBox(height: screenHeight * 0.06),
              Text(userModel.userEmail ?? 'user@email.com', style: TextStyle(fontSize: 15)),
              ElevatedButton(
                child: Text('Change Password'),
                onPressed: () async {
                  final isVerified = await _showPasswordVerificationDialog();
                  if (isVerified) {
                    _showChangePasswordDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Incorrect password')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}




