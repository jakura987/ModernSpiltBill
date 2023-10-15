import 'package:flutter/material.dart';
import 'package:SplitBill/main_module/settings_page.dart';
import 'main_module/bill_page.dart';
import 'main_module/group_page.dart';
import 'main_module/home_page.dart';
import 'main_module/me_page.dart';
import 'main_module/choose_group.dart';
import 'constants/palette.dart';

class NavigatePage extends StatefulWidget {
  @override
  _NavigatePageState createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage> {
  int _currentIndex = 0; // 当前选中的页面索引

  List<Widget> get _pages => [
    HomePage(goToBillPage: goToBillPage),
    GroupPage(),
    ChooseGroup(),
    BillPage(),
    MePage(),
    SettingsPage()
  ];

  void goToBillPage() {
    setState(() {
      _currentIndex = 3; // assuming BillPage is at index 3 in the _pages list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, spreadRadius: 0, blurRadius: 1)],
        ),
        child: ClipRRect(
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Group',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.0),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Palette.primaryColor,
                    child: Icon(Icons.add, color: Colors.white, size: 40),
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt),
                label: 'Bill',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
            currentIndex: _currentIndex,
            selectedItemColor: Palette.primaryColor,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}


// ... 其他不变的部分
