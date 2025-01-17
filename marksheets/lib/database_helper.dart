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
  }

  Future<int> insertMarksheet(Map<String, dynamic> marksheet) async {
  final db = await database;
  return await db.insert('marksheets', marksheet);
}

  Future<List<Map<String, dynamic>>> getMarksheets() async {
  final db = await database; // 既にあるデータベースを取得
  return await db.query('marksheets', orderBy: 'createdAt DESC'); // 作成日時順で取得
}


  Future<int> updateMarksheet(int id, Map<String, dynamic> updatedData) async {
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


}


