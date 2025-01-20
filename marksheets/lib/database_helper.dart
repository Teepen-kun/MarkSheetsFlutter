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
        createdAt TEXT NOT NULL
      )
    ''');

    // 回答データのテーブル作成
    await db.execute('''
      CREATE TABLE answers (
        marksheet_id INTEGER NOT NULL,
        answer TEXT NOT NULL
      )
    ''');

    // 正解データのテーブル作成
    await db.execute('''
      CREATE TABLE correct_answers (
        marksheet_id INTEGER PRIMARY KEY,
        correct_answer TEXT NOT NULL
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



  // 回答データ関連の操作
  Future<int> insertAnswer(Map<String, dynamic> answerData) async {
    final db = await database;
    
    return await db.insert('answers', answerData);
  }


  Future<int> updateAnswer(int marksheetId, Map<String, dynamic> updatedData) async {
    final db = await database; 
    
    
    return await db.update(
    'answers',
    updatedData,
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
    );

}
  Future<List<Map<String, dynamic>>>getAnswer(int marksheetId) async{
  final db = await database;

    List<Map<String, dynamic>> result = await db.query(
    'answers',
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
  );
  print("getAnswer result: $result");
  return result;
}

Future<bool> doesAnswerExist(int marksheetId) async {
  final db = await database;
  final result = await db.query(
    'answers',
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
  );
  return result.isNotEmpty;
}



  // 正解データ関連の操作
  Future<int> insertCorrectAnswer(Map<String, dynamic> answerData) async {
    final db = await database;
    print("Inserting data: $answerData"); // デバッグログ
    return await db.insert('correct_answers', answerData);
  }


  Future<int> updateCorrectAnswer(int marksheetId, Map<String, dynamic> updatedData) async {
    final db = await database; 
    print("Updating marksheet_id: $marksheetId"); // デバッグログ
    print("Update data: $updatedData"); // デバッグログ
    
    return await db.update(
    'correct_answers',
    updatedData,
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
    );

}
  Future<List<Map<String, dynamic>>>getCorrectAnswer(int marksheetId) async{
  final db = await database;

    List<Map<String, dynamic>> result = await db.query(
    'correct_answers',
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
  );
  print("getAnswer result: $result");
  return result;
}

Future<bool> doesCorrectAnswerExist(int marksheetId) async {
  final db = await database;
  final result = await db.query(
    'correct_answers',
    where: 'marksheet_id = ?',
    whereArgs: [marksheetId],
  );
  return result.isNotEmpty;
}

}


