import 'dart:ui';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'MarkSheet.dart';
import 'SettingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _marksheetsFuture;
  late List<Map<String, dynamic>> _marksheets; // 並び替え用リスト
  String _sortBy = 'createdAt'; // デフォルト並び
  bool _isAscending = false; // 昇順か
  List<bool> _isViewSelected = [
    true,
    false,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchMarksheets(); // 初期化時データ取得
  }

  void _fetchMarksheets() {
    setState(() {
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
    });
  }

  Widget deleteDialog(String id, String title) {
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
          onTap: () {
            _deleteMarksheet(id);
            Navigator.pop(context);
          },
        )
      ],
    );
  }

  void _deleteMarksheet(String id) async {
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAscending = prefs.getBool('isAscending') ?? false;
      _sortBy = prefs.getString('sortBy') ?? 'createdAt';
      final savedViewIndex = prefs.getInt('viewIndex') ?? 0;
      _isViewSelected = [false, false];
      _isViewSelected[savedViewIndex] = true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAscending', _isAscending);
    await prefs.setString('sortKey', _sortBy);
    final viewIndex = _isViewSelected.indexWhere((isSelected) => isSelected);
    await prefs.setInt('viewIndex', viewIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: const Text(
            'マークシート',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(children: [
          Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: HowToView()),
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
                    //final marksheets = snapshot.data ?? [];

                    if (_marksheets.isEmpty) {
                      return const Center(child: Text('マークシートがありません'));
                    }
                    if (_isViewSelected[0]) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                              onTap: () {
                                PassData(sheet);
                              },
                              child: _buildMarksheetCard(sheet));
                        },
                      );
                    } else if (_isViewSelected[1]) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: _marksheets.length,
                        itemBuilder: (context, index) {
                          final sheet = _marksheets[index];
                          return GestureDetector(
                              onTap: () {
                                PassData(sheet);
                              },
                              child: _buildMarksheetCard(sheet));
                        },
                      );
                    } else {
                      _isViewSelected = [
                        true,
                        false,
                      ];
                      return const Center(child: Text('error'));
                    }
                  }))
        ]));
  }

//表示方法の群
  Widget HowToView() {
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
                    _savePreferences();
                  });
                },
                children: const [
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
                  DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('更新日時',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),
                  DropdownMenuItem(
                      value: 'title',
                      child: Text('タイトル',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),
                ],
              ),
              IconButton(
                icon: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                    _savePreferences();
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
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          //シートの詳細,
          CardLayout(sheet),
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
                      return deleteDialog(sheet['id'], sheet['title']);
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

  Widget CardLayout(Map<String, dynamic> sheet) {
    final score = sheet['score'];
    final totalQuestions = sheet['numCellRows'];
    final title = sheet['title'];
    final updatedAt = sheet['createdAt'];
    final displayScore = score ?? 0; //scoreがnullなら0
    final isNullScore = score == null;

    final formattedDate = updatedAt != null
        ? DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(updatedAt))
        : '日時未設定';

    final completedRatio =
        totalQuestions > 0 ? displayScore / totalQuestions : 0.1;
    final remainingRatio = 1.0 - completedRatio;

    //GridViewのとき
    if (_isViewSelected[0] && !_isViewSelected[1]) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 10),
            child: SizedBox(
              height: 80,
              child: ListTile(
                title: Tooltip(
                  message: title,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 更新日時
                      Text('$formattedDate',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                          ),
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        overflow: TextOverflow.fade,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            width: 120,
            child: Padding(
              padding: EdgeInsets.only(top: 30),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 円グラフ
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 270,
                      sections: [
                        if (displayScore > 0)
                          PieChartSectionData(
                            value: completedRatio,
                            title: '',
                            color:
                                Theme.of(context).colorScheme.primary, //正解の割合
                            radius: 25,
                          ),
                        if (displayScore < totalQuestions)
                          PieChartSectionData(
                              value: remainingRatio, //不正解の割合
                              title: '',
                              color: Colors.grey,
                              radius: 25),
                      ],
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                    ),
                  ),
                  // 円グラフの中心に表示するテキスト
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isNullScore ? '-' : displayScore.toString(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/ $totalQuestions',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_isViewSelected[1] && !_isViewSelected[0]) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 50),
            child: ListTile(
              title: Tooltip(
                message: title,
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                // 更新日時
                padding: const EdgeInsets.only(left: 10),
                child: Text('$formattedDate',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.only(right:10.0),
                child: Row(
                  children: [
                    Text(
                      isNullScore ? '-' : displayScore.toString(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),                    Text(
                      '/ $totalQuestions',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: LinearProgressIndicator(
              value: completedRatio,
              minHeight: 15,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 10),
        ],
      );
    } else {
      return Container(
        child: Text("それはエラーすぎ"),
      );
    }
  }

  void PassData(Map<String, dynamic> sheet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Marksheet(marksheetID: sheet['id']),
      ),
    ).then((isUpdated) {
      if (isUpdated == true) {
        _fetchMarksheets(); // データを再取得
      }
    });
  }
}
