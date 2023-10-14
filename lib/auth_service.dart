import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? errorCode; // 存储 FirebaseAuthException 的错误代码
  String? errorMessage; // 存储 FirebaseAuthException 的错误信息

  Future<void> signOut() async {
    await _auth.signOut();
  }

// 可以加入其他与认证相关的逻辑，比如登录、注册等

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      errorCode = e.code; // 在 FirebaseAuthException 捕获时设置错误代码
      errorMessage = e.message; // 在 FirebaseAuthException 捕获时设置错误信息
      return null;
    }
  }
}
