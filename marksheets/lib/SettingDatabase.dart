import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initializeDB() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'marksheets.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE marksheets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            numCellRows INTEGER,
            marks TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  static Future<void> insertMarkSheet(String title, int numCellRows, String marks) async {
    final db = await initializeDB();
    await db.insert('marksheets', {
      'title': title,
      'numCellRows': numCellRows,
      'marks': marks,
    });
  }

  static Future<List<Map<String, dynamic>>> getMarkSheets() async {
    final db = await initializeDB();
    return await db.query('marksheets');
  }
}
