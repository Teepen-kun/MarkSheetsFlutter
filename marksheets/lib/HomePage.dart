import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'MarkSheet.dart';
import 'SettingScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _marksheetsFuture;

  @override
  void initState() {
    super.initState();
    _fetchMarksheets(); // 初期化時にデータを取得
  }

  void _fetchMarksheets() {
    setState(() {
      _marksheetsFuture = DatabaseHelper().getMarksheets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: FutureBuilder(
        future: _marksheetsFuture,
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

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 列の数
              crossAxisSpacing: 10.0, // 列間のスペース
              mainAxisSpacing: 10.0, // 行間のスペース
              childAspectRatio: 3 / 4, // カードの縦横比
            ),
            padding: const EdgeInsets.all(10.0),
            itemCount: savedMarkSheets.length,
            itemBuilder: (context, index) {
              final sheet = savedMarkSheets[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    //三点リーダ
                    Positioned(
                      top: 5,
                      right: 5,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingScreen(
                                  isNew: false,
                                  existingData: sheet,
                                ),
                              ),
                            ).then((_) => _fetchMarksheets());
                          } else if (value == 'delete') {
                            _deleteMarksheet(sheet['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('編集'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('削除'),
                          ),
                        ],
                      ),
                    ),
                    //シートの詳細
                    Column(
                      children: [
                        const SizedBox(height: 25),
                        ListTile(
                            title: Text(sheet['title']),
                            subtitle: Text('問題数: ${sheet['numCellRows']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Marksheet(
                                    marksheetID: sheet['id'],
                                    title: sheet['title'],
                                    numCellRows: sheet['numCellRows'],
                                    marks: (sheet['markTypes'] as String).split(','),
                                    isMultipleSelectionAllowed:
                                        sheet['isMultipleSelectionAllowed'] == 1,
                                    isTimeLimitEnabled: sheet['isTimeLimitEnabled'] == 1,
                                    timelimit: sheet['timelimit'],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteMarksheet(int id) async {
    await DatabaseHelper().deleteMarksheet(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('マークシートを削除しました')),
    );
    _fetchMarksheets(); // リストを再取得して更新
  }
}
