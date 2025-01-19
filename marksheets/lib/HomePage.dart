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
  List<Map<String, dynamic>> _marksheets = []; // 並び替え用リスト
  String _sortCriteria = 'createdAt'; // デフォルト並び
  bool _isAscending = false; // 昇順かどうか


  @override
  void initState() {
    super.initState();
    _fetchMarksheets(); // 初期化時にデータを取得
  }

  void _fetchMarksheets() async {
    setState(() {
      _marksheetsFuture = DatabaseHelper().getMarksheets();
    });
  }

  Widget deleteDialog(int id, String title){
    return AlertDialog(
      title: Text('$titleを削除しますか？'),
      content: Text('回答データも削除されます'),
      actions: <Widget>[
        GestureDetector(
          child: Text('いいえ'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        GestureDetector(
          child: Text('はい'),
          onTap: (){
            _deleteMarksheet(id);
            Navigator.pop(context);
            },
        )
      ],
    );

  }

  void _deleteMarksheet(int id) async {
    await DatabaseHelper().deleteMarksheet(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('マークシートを削除しました'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
                bottom: 10, 
                left: 16,
                right: 16,
              ),
        ),
    );
    _fetchMarksheets(); // リストを再取得して更新
  }

    void _sortMarksheets() {
    setState(() {
      _marksheets.sort((a, b) {
        final aValue = a[_sortCriteria];
        final bValue = b[_sortCriteria];
        if (_isAscending) {
          return aValue.compareTo(bValue);
        } else {
          return bValue.compareTo(aValue);
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    print(_marksheetsFuture);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: const Text('マークシート',style: TextStyle( fontWeight: FontWeight.bold, color: Colors.black),      
        ),
      actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'createdAt') {
                  _sortCriteria = 'createdAt';
                } else if (value == 'title') {
                  _sortCriteria = 'title';
                }
                _isAscending = !_isAscending; // 昇順/降順を切り替え
                _sortMarksheets(); // 並び替えを適用
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'createdAt', child: Text('作成日時順')),
              const PopupMenuItem(value: 'title', child: Text('タイトル順')),
            ],
          ),
        ],
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
              return GestureDetector(
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
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    side: BorderSide( 
                    color: Theme.of(context).colorScheme.primary,
                    width: 3
                  ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      //シートの詳細
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          ListTile(
                              title: Text(
                                sheet['title'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black),
                                overflow: TextOverflow.fade,
                                maxLines: 2,
                                  ),
                              subtitle: Text('問題数: ${sheet['numCellRows']}'),
                            ),
                        ],
                      ),
                      //三点リーダ
                      Positioned(
                        top: 0,
                        right: 0,
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
                              showDialog( 
                                context: context,
                                builder: (BuildContext context) {
                                  return  deleteDialog(sheet['id'], sheet['title']);
                                },
                              );
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}
