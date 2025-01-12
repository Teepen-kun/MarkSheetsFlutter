import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marksheets/SQLDebug.dart';
import 'SettingScreen.dart';
import 'HomeScreen.dart';
import 'dart:async';
import 'database_helper.dart';
import 'SQLDebug.dart';
import 'package:sqflite/sqflite.dart';



Future<void> deleteDatabaseFile() async {
  final databasePath = await getDatabasesPath();
  final path = '$databasePath/marksheets.db';
  await deleteDatabase(path); // データベースファイルを削除
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();

  if (kDebugMode) {
    print('デバッグモードで実行中');
    // デバッグモードでのみデータベースを削除
    await deleteDatabaseFile();
    print('データベースを削除しました。');


  // サンプルデータ挿入
  await dbHelper.insertMarksheet({
    'title': 'Sample Sheet',
    'numCellRows': 10,
    'markTypes': 'A,B,C,D',
    'isMultipleSelectionAllowed': 1,
    'isTimeLimitEnabled': 0,
    'timelimit': 0,
    'createdAt': DateTime.now().toIso8601String(),
  });

  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarkSheetsApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(), //DebugScreen()
    );
  }
}

