import 'dart:async';
import 'package:flutter/material.dart';
import 'package:SplitBill/main_module/profile_edit_page.dart';
import 'package:SplitBill/main_module/settings_page.dart';
import '../constants/palette.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../login_page.dart';
import '../models/user_avatar_model.dart';
import '../models/user_model.dart';
import '../contact_us_page.dart';
import 'monthly_expenses_review.dart';
import 'package:sensors/sensors.dart';
import 'dart:math';

class MePage extends StatefulWidget {
  @override
  _MePageState createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _accelerometerStreamSubscription;
  List<double>? _accelerometerValues;
  double shakeThreshold = 20.0;
  DateTime? _lastShakeTime;
  DateTime? _muteEndTime;

  @override
  void initState() {
    super.initState();
    _accelerometerStreamSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerValues = [event.x, event.y, event.z];
      _detectShake(event);
    });
  }

  _detectShake(AccelerometerEvent event) {
    double speed = event.x + event.y + event.z;
    final currentTime = DateTime.now();

    if (_muteEndTime != null && currentTime.isBefore(_muteEndTime!)) {
      return;
    }

    if (speed > shakeThreshold) {
      final currentTime = DateTime.now();
      if (_lastShakeTime == null ||
          currentTime.difference(_lastShakeTime!).inSeconds > 10) {
        _lastShakeTime = currentTime;
        _showDiceRoll();
      }
    }
  }

  _showDiceRoll() {
    int diceNumber = Random().nextInt(6) + 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('You rolled a'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$diceNumber',
                style: TextStyle(fontSize: 60, color: Palette.primaryColor)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  child: Text('Mute in 5 mins', style: TextStyle(color: Palette.secondaryColor)),
                  onPressed: () {
                    _muteEndTime = DateTime.now().add(Duration(minutes: 5));
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: Text('OK', style: TextStyle(color: Palette.primaryColor)),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _accelerometerStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: screenHeight * 0.03),
            Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildProfileSection(context),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            ..._buildFunctionList(context),
            Spacer(),
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
    final functions = ['Monthly expenses review', 'Contact us', 'Settings'];
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
        if (name == 'Contact us') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContactUsPage()),
          );
        }
        if (name == 'Monthly expenses review') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MonthlyExpensesPage()),
          );
        }
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
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirm Logout'),
                content: Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel',
                        style: TextStyle(color: Palette.secondaryColor)),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                  TextButton(
                    child: Text('Logout',
                        style: TextStyle(color: Palette.primaryColor)),
                    onPressed: () async {
                      await _auth.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            );
          },
          child: Text(
            'Log out',
            style: TextStyle(
              color: Palette.primaryColor,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
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
