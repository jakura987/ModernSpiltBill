import 'package:flutter/material.dart';

class UserAvatar with ChangeNotifier {
  String _avatarPath = 'assets/images/image1.jpg';

  String get avatarPath => _avatarPath;

  set avatarPath(String value) {
    _avatarPath = value;
    notifyListeners();
  }

}