import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:SpiltBill/dashed_line.dart';
import 'package:SpiltBill/navigate_page.dart';
import 'package:SpiltBill/register_page.dart';
import '../auth_service.dart';
import 'models/user_model.dart';

const kPrimaryColor = Color(0xFF3BBBA4);
const kSecondaryColor = Color(0xffDBDBDB);
const kDontHaveAccountColor = Color(0xffBABEBD);
final kFillColor = Colors.grey[200];
const kAppName = 'SplitBill';
const kUsernameHint = 'Email';
const kPasswordHint = 'Password';
const kLoginButtonText = 'Login';
const kRegisterButtonText = 'Register';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryColor, kSecondaryColor],
          ),
        ),
        child: Center(child: LoginForm()),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  //非第三放登录方法
  Future<void> _login() async {
    final String email = _usernameController.text;
    final String password = _passwordController.text;

    // 获取 AuthService 的实例
    final authService = Provider.of<AuthService>(context, listen: false);

    // 使用 AuthService 的 signIn 方法进行登录
    final userCredential = await authService.signIn(email, password);

    if (userCredential != null) {
      if (!userCredential.user!.emailVerified) {
        // 用户已登录但电子邮件未经验证
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please verify your email before logging in.')));
        await FirebaseAuth.instance.signOut(); // 退出登录
        return;
      }

      final userModel = Provider.of<UserModel>(context, listen: false);
      await userModel.fetchUser(context); // 调用 UserModel 的 fetchUser 方法
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => NavigatePage()), // 如果登录成功，导航到 NavigatePage 页面
      );
    } else {
      // 如果登录失败，根据 FirebaseAuthException 的错误代码显示对应的错误信息
      String message;
      switch (authService.errorCode) {
        case 'invalid-email':
          message = 'your email address format is incorrect';
          break;
        case 'INVALID_LOGIN_CREDENTIALS':
          message = 'checking if your email address and password are correct';
          break;
        default:
          message = 'login fail: ${authService.errorMessage}';
          break;
      }

      // 显示包含错误信息的 SnackBar
      final snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
  Future<String?> _displayPasswordResetDialog(BuildContext context) async {
    TextEditingController _emailController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter your email'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(hintText: "Email address"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',style: TextStyle(color: kSecondaryColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Submit',style: TextStyle(color: kPrimaryColor)),
              onPressed: () => Navigator.of(context).pop(_emailController.text),
            ),
          ],
        );
      },
    );
  }

  void _resetPassword() async {
    String? email = await _displayPasswordResetDialog(context);

    if (email != null && email.trim().isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset email sent to $email.'))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending password reset email.'))
        );
      }
    }
  }

  //跳转register页面
  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16),
                  AppName(),
                  SizedBox(height: 32),
                  CustomTextField(
                      controller: _usernameController, hint: kUsernameHint),
                  SizedBox(height: 16),
                  CustomTextField(
                      controller: _passwordController,
                      hint: kPasswordHint,
                      isObscured: true),
                  SizedBox(height: 16),
                  LoginButton(onPressed: _login, text: kLoginButtonText),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _resetPassword,
                    child: Text("Forget password?",
                        style: TextStyle(
                            color: kPrimaryColor, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 1),
                ],
              ),
            ),
            DashedLine(width: 280),
            Container(
              width: 300,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "You can also login with",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Feature under development')));
                    },
                    child: Image.asset('assets/images/btn_google.png',
                        width: 30, height: 30),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: TextStyle(
                              color: kDontHaveAccountColor,
                              fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: _navigateToRegisterPage,
                        child: Text("Sign up",
                            style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppName extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      kAppName,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: kPrimaryColor,
      ),
    );
  }
}

// CustomTextField is a custom text input component
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isObscured;

  CustomTextField(
      {required this.controller, required this.hint, this.isObscured = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: kFillColor,
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        // 调整了垂直边距为5.0
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: isObscured,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

// LoginButton is a custom ElevatedButton
class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  LoginButton({required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
        // Made text bold
        style: ElevatedButton.styleFrom(
            primary: kPrimaryColor), // Setting the button color
      ),
    );
  }
}

// RegisterButton is a custom TextButton
class RegisterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  RegisterButton({required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed, // 在这里使用传入的 onPressed 函数
      child: Text(text),
    );
  }
}
