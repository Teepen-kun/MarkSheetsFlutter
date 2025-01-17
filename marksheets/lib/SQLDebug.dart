import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; 
import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class DebugScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQLiteデバッグ')),
      body: FutureBuilder(
        future: dbHelper.getMarksheets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          final data = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final sheet = data[index];
              return ListTile(
                title: Text(sheet['title']),
                subtitle: Text('行数: ${sheet['numCellRows']}'),
              );
            },
          );
        },
      ),
    );
  }
}
