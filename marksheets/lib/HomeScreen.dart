import 'package:flutter/material.dart';
import 'SettingScreen.dart';
import 'MarkSheet.dart';

class HomeScreen extends StatelessWidget {
  // 過去のマークシートデータ（サンプル）
  final List<Map<String, dynamic>> savedMarkSheets = [
    {'title': 'Sample 1', 'rows': 10, 'marks': ['A', 'B', 'C', 'D']},
    {'title': 'Math Exam', 'rows': 20, 'marks': ['1', '2', '3', '4', '5']},
    {'title': 'English Test', 'rows': 15, 'marks': ['A', 'B', 'C', 'D', 'E']},
  ];

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
              child: ListView.builder(
                itemCount: savedMarkSheets.length,
                itemBuilder: (context, index) {
                  final sheet = savedMarkSheets[index];
                  return Card(
                    child: ListTile(
                      title: Text(sheet['title']),
                      subtitle: Text('行数: ${sheet['rows']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Marksheet(
                              title: sheet['title'],
                              numCellRows: sheet['rows'],
                              marks: sheet['marks'],
                              isMultipleSelectionAllowed: true, // 適宜設定
                              isTimeLimitEnabled: false, // 適宜設定
                              timelimit: 0, // 適宜設定
                            ),
                          ),
                        );
                      },
                    ),
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
              builder: (context) => const SettingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '新規マークシートを作成',
      ),
    );
  }
}