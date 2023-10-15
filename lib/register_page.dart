import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashed_line.dart';
import 'login_page.dart';


const kPrimaryColor = Color(0xFF3BBBA4);
const kSecondaryColor = Color(0xffDBDBDB);
const kDontHaveAccountColor = Color(0xffBABEBD);
final kFillColor = Colors.grey[200];
const kAppName = 'SplitBill';
const kPreferredName = 'PreferredName';
const kEmailHint = 'Email';
const kConfirmPasswordHint = 'Confirm Password';
const kSignUpButtonText = 'Sign up';

class RegisterPage extends StatelessWidget {
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
        child: Center(child: RegisterForm()),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _preferredNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      kAppName,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    SizedBox(height: 32),
                    CustomTextFormField(
                      controller: _preferredNameController,
                      hint: kPreferredName,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _emailController,
                      hint: kEmailHint,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value))
                          return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _passwordController,
                      hint: kPasswordHint,
                      isObscured: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        if (value.length < 6) return 'Password must be at least 6 characters long';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _confirmPasswordController,
                      hint: kConfirmPasswordHint,
                      isObscured: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        child: Text(kSignUpButtonText, style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(primary: kPrimaryColor),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Feature under development'))
                      );
                    },
                    child: Image.asset('assets/images/btn_google.png', width: 30, height: 30),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: TextStyle(color: kDontHaveAccountColor, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text('Login', style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
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


  Future<bool> isNameUnique(String name) async {
    final users = await FirebaseFirestore.instance.collection('users')
        .where('name', isEqualTo: name)
        .get();

    return users.docs.isEmpty;
  }


  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {

      // Step 1: Check if the name is unique
      bool nameIsUnique = await isNameUnique(_preferredNameController.text.trim());
      if (!nameIsUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('The name has been used by other accounts.'))
        );
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'name': _preferredNameController.text.trim(),
            'email': _emailController.text.trim(),
            'dailyLimit': 200,  // 默认的日限额
            'weeklyLimit': 1000, // 默认的周限额
            'monthlyLimit': 3000, // 默认的月限额
            'head': 1, //默认的头像
          });
          userCredential.user!.sendEmailVerification().then((value) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thank you for registering! A email has been sent to your email address.'))
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sending verification email: $error'))
            );
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // 显示错误消息给用户，告知邮箱已被使用
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('The email address is already in use by another account.')));
        } else {
          // 其他Firebase错误的处理
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'An unknown error has occurred.')));
        }
      } catch (e) {
        // 处理其他未知错误
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An unknown error has occurred.')));
      }
    }
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isObscured;
  final FormFieldValidator<String>? validator;

  CustomTextFormField({
    required this.controller,
    required this.hint,
    this.isObscured = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400]),
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        filled: true,
        fillColor: kFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: isObscured,
      validator: validator,
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
