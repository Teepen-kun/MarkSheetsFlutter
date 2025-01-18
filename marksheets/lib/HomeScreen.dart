import 'package:flutter/material.dart';
import 'SettingScreen.dart';
import 'database_helper.dart';
import 'HomePage.dart';
import 'DetailsAndAppSettingPage.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 現在選択されているタブのインデックス
  final DatabaseHelper dbHelper = DatabaseHelper();

  final List<Widget> _pages = [
    HomePage(), // ホーム画面（マークシート一覧）
    DetailsAndAppSettingPage(), // アプリの詳細
  ];

@override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false,
    body: Padding(
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: _pages[_currentIndex],
    ), 
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: '詳細',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingScreen(isNew: true),
          ),
        );
      },
      child: const Icon(Icons.add),
      tooltip: '新規マークシート作成',
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // +ボタンを中央に配置
  );
}

}


