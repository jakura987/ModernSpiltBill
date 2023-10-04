import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userName;
  String? _userEmail;
  double? _dailyLimit;
  double? _weeklyLimit;
  double? _monthlyLimit;

  String get userName => _userName ?? '';
  String get userEmail => _userEmail ?? '';
  double? get dailyLimit => _dailyLimit;
  double? get weeklyLimit => _weeklyLimit;
  double? get monthlyLimit => _monthlyLimit;

  Future<void> fetchUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (userDoc.size == 0) return;

    _userName = userDoc.docs.first['name'];
    _userEmail = userDoc.docs.first['email'];
    _dailyLimit = userDoc.docs.first['dailyLimit'] != null
        ? (userDoc.docs.first['dailyLimit'] as num).toDouble()
        : null;
    _weeklyLimit = userDoc.docs.first['weeklyLimit'] != null
        ? (userDoc.docs.first['weeklyLimit'] as num).toDouble()
        : null;
    _monthlyLimit = userDoc.docs.first['monthlyLimit'] != null
        ? (userDoc.docs.first['monthlyLimit'] as num).toDouble()
        : null;

    notifyListeners(); // Don't forget to notify listeners
  }

}




