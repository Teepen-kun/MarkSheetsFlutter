import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; 
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  /* ↑
  factory DatabaseHelper() {
    return _instance;
  }*/

  static Database? _database;

  static final DatabaseHelper instance = _instance;


  DatabaseHelper._internal();

  
  Future<Database> get database async {
    if (_database != null)  return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'marksheets.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // マークシート設定のテーブル作成
    await db.execute('''
      CREATE TABLE marksheets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        numCellRows INTEGER NOT NULL,
        markTypes TEXT NOT NULL,
        isTimeLimitEnabled INTEGER NOT NULL,
        timelimit INTEGER NOT NULL,
        isMultipleSelectionAllowed INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        score INTEGER,
        answers TEXT,
        correctAnswers TEXT,
        checkbox TEXT
      )
    ''');

  }

//Marksheetのリストを表示
  Future<List<Map<String, dynamic>>> getMarksheets() async {
  try {
    final db = await database; // データベースの取得
    print('Database acquired successfully');
    final result = await db.query('marksheets', orderBy: 'createdAt DESC');
    print('Query result: $result');
    return  List<Map<String, dynamic>>.from(result);
  } catch (error) {
    print('Error in getMarksheets: $error');
    throw error; // エラーを再スロー
  }
}

  Future<int> insertMarksheet(Map<String, dynamic> marksheet) async {
  final db = await database;
  return await db.insert('marksheets', marksheet);
}

  Future<int> updateMarksheet(int id,  updatedData) async {
  final db = await database;
  return await db.update(
    'marksheets',
    updatedData,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> updateScore(int id, int? score) async {
  final db = await database;
  await db.update(
    'marksheets',
    {'score': score},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> updateAnswer(int id, String? answers) async {
  final db = await database;
  await db.update(
    'marksheets',
    {'answers': answers},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> updateCorrectAnswer(int id, String? correctAnswers) async {
  final db = await database;
  await db.update(
    'marksheets',
    {'correctAnswers': correctAnswers},
    where: 'id = ?',
    whereArgs: [id],
  );
}

  Future<int> deleteMarksheet(int id) async {
  final db = await database;
  return await db.delete(
    'marksheets',
    where: 'id = ?',
    whereArgs: [id],
  );
}  

  Future<Map<String, dynamic>?> getMarksheet(int id) async {
  final db = await database;

  // 特定のIDのマークシートを取得
  final result = await db.query(
    'marksheets',
    where: 'id = ?',
    whereArgs: [id],
  );

  // 結果が存在すれば最初の行を返し、存在しなければ null を返す
  if (result.isNotEmpty) {
    return result.first;
  } else {
    return null;
  }
}



  Future<String?>getAnswer(int marksheetId) async{
  final db = await database;

    final result = await db.query(
    'marksheets',
    columns: ['answers'],
    where: 'id = ?',
    whereArgs: [marksheetId],
  );
  print("getAnswer result: $result");
  if (result.isNotEmpty) {
    return result.first['answers'] as String?;
  } else {
    return null;
  }
}

  Future<String?>getCorrectAnswer(int marksheetId) async{
  final db = await database;

    List<Map<String, dynamic>> result = await db.query(
    'marksheets',
    columns: ['correctAnswers'],
    where: 'id = ?',
    whereArgs: [marksheetId],
  );
  print("getAnswer result: $result");
  if (result.isNotEmpty) {
    return result.first['correctAnswers'] as String?;
  } else {
    return null;
  }
}

Future<String?> getCheckBoxes(int marksheetId) async{
  final db = await database;

    final result = await db.query(
    'marksheets',
    columns: ['checkbox'],
    where: 'id = ?',
    whereArgs: [marksheetId],
  );
  print("getcheckboxes result: $result");
  if (result.isNotEmpty) {
    return result.first['checkbox'] as String?;
  } else {
    return null;
  }
}

}


