import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:SpiltBill/models/user_avatar_model.dart';


class UserModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _userName;
  String? _userEmail;
  double? _dailyLimit;
  double? _weeklyLimit;
  double? _monthlyLimit;
  int? _head;

  String get userName => _userName ?? '';
  String get userEmail => _userEmail ?? '';
  double? get dailyLimit => _dailyLimit;
  double? get weeklyLimit => _weeklyLimit;
  double? get monthlyLimit => _monthlyLimit;
  int? get head => _head;


  Future<void> fetchUser(BuildContext context) async {
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
    _head = userDoc.docs.first['head'];  // 从 Firestore 文档中提取 head 的值
    _dailyLimit = userDoc.docs.first['dailyLimit'] != null
        ? (userDoc.docs.first['dailyLimit'] as num).toDouble()
        : null;
    _weeklyLimit = userDoc.docs.first['weeklyLimit'] != null
        ? (userDoc.docs.first['weeklyLimit'] as num).toDouble()
        : null;
    _monthlyLimit = userDoc.docs.first['monthlyLimit'] != null
        ? (userDoc.docs.first['monthlyLimit'] as num).toDouble()
        : null;
    final userAvatar = Provider.of<UserAvatar>(context, listen: false);
    userAvatar.avatarPath = 'assets/images/image${_head}.jpg';
    notifyListeners(); // notify listeners
  }

  Future<void> updateLimits(double? daily, double? weekly, double? monthly) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users')
        .where('email', isEqualTo: user.email)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.size > 0) {
        final docId = querySnapshot.docs.first.id;
        _firestore.collection('users').doc(docId).update({
          'dailyLimit': daily,
          'weeklyLimit': weekly,
          'monthlyLimit': monthly,
        });
      }
    });
  }
}




