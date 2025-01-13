import 'package:flutter/material.dart';
import 'SettingScreen.dart';
import 'MarkSheet.dart';
import 'database_helper.dart';

class HomeScreen extends StatelessWidget {
  //const HomeScreen({Key? key}) : super(key: key);
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 過去のマークシートリスト
            Expanded(
              child: FutureBuilder(
                future: DatabaseHelper().getMarksheets(), // SQLiteからデータ取得
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('エラー: ${snapshot.error}'));
                  }
                  final savedMarkSheets = snapshot.data as List<Map<String, dynamic>>;

                  if (savedMarkSheets.isEmpty) {
                    return const Center(child: Text('マークシートがありません'));
                  }

                  return ListView.builder(
                    itemCount: savedMarkSheets.length,
                    itemBuilder: (context, index) {
                      final sheet = savedMarkSheets[index];
                      return Card(
                        child: ListTile(
                          title: Text(sheet['title']),
                          subtitle: Text('行数: ${sheet['numCellRows']}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Marksheet(
                                  marksheetID: sheet['id'],
                                  title: sheet['title'],
                                  numCellRows: sheet['numCellRows'],
                                  marks: (sheet['markTypes'] as String).split(','), // マークをリストに変換
                                  isMultipleSelectionAllowed:
                                      sheet['isMultipleSelectionAllowed'] == 1,
                                  isTimeLimitEnabled: sheet['isTimeLimitEnabled'] == 1,
                                  timelimit: sheet['timelimit'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // 右下の＋アイコン
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
        tooltip: '新規マークシートを作成',
      ),
    );
  }
}
