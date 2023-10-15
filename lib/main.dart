import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SpiltBill/models/user_avatar_model.dart';
import 'package:SpiltBill/models/user_model.dart';
import 'auth_service.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'navigate_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定初始化
  // await Hive.initFlutter();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // 初始化 Firebase
  runApp(
    MultiProvider(
      providers: [
        Provider(
          create: (context) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserAvatar(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kAppName,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        colorScheme: ThemeData().colorScheme.copyWith(secondary: kSecondaryColor),
        buttonTheme: ButtonThemeData(
          buttonColor: kPrimaryColor,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginPage(); // 用户未登录，导航到登录页面
          }
          return NavigatePage(); // 用户已登录，导航到主页面
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(), // 在等待Firebase响应时显示一个加载指示器
          ),
        );
      },
    );
  }
}






