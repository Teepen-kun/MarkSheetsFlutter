import 'package:flutter/material.dart';
import 'SettingScreen.dart';
import 'database_helper.dart';
import 'HomePage.dart';
import 'DetailsAndAppSettingPage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'MarkSheet.dart';
//

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
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.create),
                    title: const Text('新規マークシート作成'),
                    onTap: () {
                      Navigator.pop(context); // メニューを閉じる
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingScreen(isNew: true),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_open),
                    title: const Text('マークシートを読み込む'),
                    onTap: () async {
                      final id = await _importMarksheet();
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Marksheet(marksheetID: id),
                          ),
                        );
                      }
                      ;
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        tooltip: '新規マークシート作成',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

//マークシート読み込み
  Future<String?> _importMarksheet() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // JSONファイルに限定
      );

      if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

        // JSONをデコードして検証
        final Map<String, dynamic> data = jsonDecode(content);
        if (_validateMarksheetData(data)) {
          final id =
              await DatabaseHelper.instance.importMarksheet(data);
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('マークシートをインポートしました！！！'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 10,
              left: 16,
              right: 16,
            ),
          ),
        );
          return id;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ファイルが無効です！！！'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 10,
              left: 16,
              right: 16,
            ),
          ),
        );
          return null;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('キャンセルされました！！！'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 10,
              left: 16,
              right: 16,
            ),
          ),
        );
        return null;
      }
    } catch (e) {
      print('エラーだにょ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: 10,
              left: 16,
              right: 16,
            ),
          ),
        );
      return null;
    }
  }

  bool _validateMarksheetData(Map<String, dynamic> data) {
    return data.containsKey('id') &&
        data.containsKey('title') &&
        data.containsKey('numCellRows') &&
        data.containsKey('markTypes');
  }
}
