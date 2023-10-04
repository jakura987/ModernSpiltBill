import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

//TODO 将名字之类的写成常量放一个文件
const kPreferredName = 'PreferredName';
const kEmailHint = 'Email';
const kConfirmPasswordHint = 'Confirm Password';
const kSignUpButtonText = 'SignUp';

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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kAppName,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
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
                    ElevatedButton(
                      onPressed: _register,
                      child: Text(kSignUpButtonText),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Container( // 新增的第二个Container
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text('Login'),
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
            SnackBar(content: Text('该名称已被其他账户使用。'))
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
            'dailyLimit': 20,  // 默认的日限额
            'weeklyLimit': 200, // 默认的周限额
            'monthlyLimit': 2000, // 默认的月限额
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // 显示错误消息给用户，告知邮箱已被使用
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('该电子邮件地址已被其他账户使用。')));
        } else {
          // 其他Firebase错误的处理
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '发生未知错误')));
        }
      } catch (e) {
        // 处理其他未知错误
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发生未知错误')));
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
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: isObscured,
      validator: validator,
    );
  }
}
