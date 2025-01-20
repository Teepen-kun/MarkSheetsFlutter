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
  late List<Map<String, dynamic>> _marksheets; // 並び替え用リスト
  String _sortBy = 'createdAt'; // デフォルト並び
  bool _isAscending = false; // 昇順か
  List<bool> _isViewSelected = [true, false,];


  @override
  void initState() {
    super.initState();
    _fetchMarksheets(); // 初期化時にデータを取得
  }

  void _fetchMarksheets() {
    _marksheetsFuture = DatabaseHelper().getMarksheets().then((data) {
    if (data.isNotEmpty) {
      _marksheets = data; 
      _sortMarksheets(); 
    } else {
      _marksheets = []; 
    }
    return _marksheets; 
  }).catchError((error) {
    print('Error in _fetchMarksheets: $error'); 
    throw error; 
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
        final aValue = a[_sortBy];
        final bValue = b[_sortBy];
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: const Text('マークシート',style: TextStyle( fontWeight: FontWeight.bold, color: Colors.black),      
        )
      ),
      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: HowToView()
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _marksheetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(child: Text('エラー: ${snapshot.error}'));    
                    }
            
                  // 取得データをローカル変数に格納
                  if (_marksheets.isEmpty) {
                    _marksheets = snapshot.data as List<Map<String, dynamic>>;
                    _sortMarksheets(); 
                  }
            
                  if (_marksheets.isEmpty) {
                    return const Center(child: Text('マークシートがありません'));
                  }
                  if(_isViewSelected[0]){
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0, 
                      childAspectRatio: 3 / 4, 
                    ),
                    padding: const EdgeInsets.all(10.0),
                    itemCount: _marksheets.length,
                    itemBuilder: (context, index) {
                      final sheet = _marksheets[index];
                      return GestureDetector(
                        onTap: () { PassData(sheet);},
                        child: _buildMarksheetCard(sheet)
                        );   
                    },
                  );
                  }else if(_isViewSelected[1]){
                    return ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemCount: _marksheets.length,
                      itemBuilder: (context, index) {
                      final sheet = _marksheets[index];
                      return GestureDetector(
                        onTap: () { PassData(sheet);},
                        child: _buildMarksheetCard(sheet));
                  },
                );
                  }else{
                    return const Center(child: Text('error'));
                  }
              }
            )
          )
        ]
      )
    );         
}
//表示方法の群
  Widget HowToView(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          Row(
            children: [
              const SizedBox(width: 10),
              ToggleButtons(
                  isSelected: _isViewSelected,
                  onPressed: (int index) {
                  setState(() { 
                    for (int i = 0; i < _isViewSelected.length; i++) {
                      _isViewSelected[i] = i == index; // 1つだけ選択
                    }
                  });
                },
                  children: const[  
                  Icon(Icons.grid_view, size: 16),
                  Icon(Icons.view_list, size: 16),
                  ],
                  borderWidth: 3,
                  borderColor: Colors.grey,
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  constraints: const BoxConstraints(
                  minWidth: 40.0, 
                  minHeight: 30.0,
                ),
                
                  ),
            ],
          ),
              
            // プルダウンでソート基準を選択
            Row(
              children: [
                DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: const SizedBox(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _sortMarksheets();
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'createdAt', child: Text('作成日時',style: TextStyle( fontWeight: FontWeight.bold, color: Colors.black) )),
                    DropdownMenuItem(value: 'title', child: Text('タイトル' ,style: TextStyle( fontWeight: FontWeight.bold, color: Colors.black))),
                  ],
                ),
                IconButton(
              icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _sortMarksheets();
                });
              },
            ),
              ],
            ),
            // 昇順/降順ボタン
            
          
        ],
      ),
    );
  }

  // カードのビルダー
  Widget _buildMarksheetCard(Map<String, dynamic> sheet) {
    return  Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          side: BorderSide( 
                          color: Theme.of(context).colorScheme.primary,
                          width: 3
                        ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:Stack(
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
                      );
  }

  void PassData(Map<String, dynamic> sheet){
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
                                  
  }
  
}

