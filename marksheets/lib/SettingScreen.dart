import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'MarkSheet.dart';
import 'package:numberpicker/numberpicker.dart';
import 'templates.dart';
import 'database_helper.dart';


class SettingScreen extends StatefulWidget{

  final bool isNew; // 新規作成か更新か
  final Map<String, dynamic>? existingData; // 更新時のデータ

  const SettingScreen({super.key, required this.isNew, this.existingData});

  @override
  State<SettingScreen> createState() => _SettingScreen();
}

class _SettingScreen extends State<SettingScreen>{
  final TextEditingController _marksheetnameController = TextEditingController(); //マークシートの名前を入力
  final TextEditingController _numberofquestionController = TextEditingController(); //問題数を入力
  bool _isTimeLimitEnabled = false; // 時間設定の有無
  int _timeLimitHour = 1; // 選択された時間
  int _timeLimitMinute = 0; //分
  int _timeLimitSecond = 0; //秒
  final List<String> markTypes = ['a-z', 'A-Z', '0-9', '+-', 'あ-ん', 'ア-ン'];
  List<String> selectedMarkTypes = ['1','2','3','4'];
  bool _isMultipleSelectionAllowed = false; //複数選択の可否

  String selectedTemplate = 'Custom';  //テンプレ

  @override
  void initState() {
    super.initState();
    if (!widget.isNew && widget.existingData != null) {
      // 更新時にデータを初期化
      final data = widget.existingData!;
      _marksheetnameController.text = data['title'];
      _numberofquestionController.text = data['numCellRows'].toString();
      selectedMarkTypes = (data['markTypes'] as String).split(',');
      _isTimeLimitEnabled = data['isTimeLimitEnabled'] == 1;
      final timelimit = data['timelimit'] as int;
      _timeLimitHour = timelimit ~/ 3600;
      _timeLimitMinute = (timelimit % 3600) ~/ 60;
      _timeLimitSecond = timelimit % 60;
      _isMultipleSelectionAllowed = data['isMultipleSelectionAllowed'] == 1;
    }
  }


  @override
  void dispose() {
      _marksheetnameController.dispose(); // メモリリークを防ぐためにdisposeする...必要性はあとで考える
      _numberofquestionController.dispose();
    super.dispose();
  }

  // データベースにマークシートを保存するメソッド
  /*
  Future<void> _saveMarksheet() async {
    final database = await DatabaseHelper.instance.database;

    final marksheetData = {
      'title': _marksheetnameController.text.isNotEmpty
          ? _marksheetnameController.text
          : 'Untitled',
      'numCellRows': int.tryParse(_numberofquestionController.text) ?? 1,
      'markTypes': selectedMarkTypes.join(','),
      'isMultipleSelectionAllowed': _isMultipleSelectionAllowed ? 1 : 0,
      'isTimeLimitEnabled': _isTimeLimitEnabled ? 1 : 0,
      'timelimit': _isTimeLimitEnabled
          ? _timeLimitHour * 3600 + _timeLimitMinute * 60 + _timeLimitSecond
          : 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await database.insert('marksheets', marksheetData);

    // 保存完了メッセージ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('マークシートを保存しました')),
    );
  }*/


  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // テンプレート選択プルダウン
              DropdownButton<String>(
                value: selectedTemplate,
                items: templates.map((template) {
                  return DropdownMenuItem<String>(
                    value: template['name'],
                    child: Text(template['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTemplate = value!;
                    final template = templates.firstWhere((template) => template['name'] == selectedTemplate);

                    // 選択したテンプレートの値を設定する
                    _marksheetnameController.text = selectedTemplate;
                    _numberofquestionController.text = template['questions'].toString();
                    selectedMarkTypes = List<String>.from(template['markTypes']);

                    _isTimeLimitEnabled = template['isTimeLimitEnabled'];
                    _timeLimitHour = template['timeLimitHour'];
                    _timeLimitMinute = template['timeLimitMinute'];
                    _timeLimitSecond = template['timeLimitSecond'];
                    _isMultipleSelectionAllowed = template['isMultipleSelectionAllowed'];
                  });
                },
              ),

              const SizedBox(height: 20),
            
            //マークシート名入力欄
            TextField(
                controller: _marksheetnameController,
                decoration: InputDecoration(labelText: 'マークシート名'),//MarkSheetの名前
              ),
            const SizedBox(height: 20),
          
            //問題数入力欄
            TextField(
                controller: _numberofquestionController,
                decoration: InputDecoration(labelText: '問題数'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], //数値限定
              ),
            const SizedBox(height: 20),
          
            //時間設定欄，時間必要ならNumberPicker表示，不要ならなにもでない
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("時間を設定する"),
                  Switch(
                    value: _isTimeLimitEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isTimeLimitEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              if (_isTimeLimitEnabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //　時間（Hours）
                    TimePickers(
                      "時間",
                      _timeLimitHour,
                      5,
                      (newValue) => setState(() => _timeLimitHour = newValue), // 値を更新に必要らしい
                    ),
                    Column(
                      children: [
                        Text(""),
                        Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    //分(Minutes)
                    TimePickers(
                      "分", 
                      _timeLimitHour == 5 ? _timeLimitMinute = 0 : _timeLimitMinute, 
                      59,
                      (newValue) => setState(() => _timeLimitMinute = newValue),
                      ),
                    Column(
                      children: [
                        Text(""),
                        Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    //秒(Seconds)
                    TimePickers(
                      "秒",
                      _timeLimitHour == 5 ? _timeLimitSecond = 0 : _timeLimitSecond,
                      59,
                      (newValue) => setState(() => _timeLimitSecond = newValue),
                      )
                  ],
                ),
              const SizedBox(height: 20),
            
              ElevatedButton(
                onPressed: () => _showMarkSelectDialog(selectedMarkTypes),
                child: Text("Select Mark Types"),
              ),   

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("複数選択を許可する"),
                  Switch(
                    value: _isMultipleSelectionAllowed,
                    onChanged: (value) {
                      setState(() {
                        _isMultipleSelectionAllowed= value;
                      });
                    },
                  ),
                ],
              ),
          
            //設定完了！！！！！！
            ElevatedButton(
              child: Text('OK'),
              onPressed: () async{
                
                  int numberOfQuestions =  int.tryParse(_numberofquestionController.text)  ??  1 ;
                  if(numberOfQuestions <= 0) numberOfQuestions = 1;

                  final finalizednumberOfQuestions = numberOfQuestions;
                  final _TimeLimit = 3600*_timeLimitHour + 60*_timeLimitMinute + _timeLimitSecond;//設定時間（秒）

                  final db = await DatabaseHelper.instance.database; 
                  // データベースに保存
                  final newSheet = {
                    'title': _marksheetnameController.text == '' ? '無題' : _marksheetnameController.text,
                    'numCellRows': finalizednumberOfQuestions,
                    'isTimeLimitEnabled': _isTimeLimitEnabled ? 1 : 0,
                    'timelimit': _TimeLimit,
                    'markTypes': selectedMarkTypes.join(','), // リストをカンマ区切りで保存
                    'isMultipleSelectionAllowed': _isMultipleSelectionAllowed ? 1 : 0,
                    'createdAt': DateTime.now().toIso8601String(),
                  };

                  if(widget.isNew){
                    //新規作成
                    final insertedID = await DatabaseHelper().insertMarksheet(newSheet);
                    newSheet['id'] = insertedID;

                    //await db.insert('marksheets', newSheet);
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('マークシートを保存しました！！！'),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: 10, 
                        left: 16,
                        right: 16,
                      ),
                      ),
                  );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Marksheet(
                            marksheetID: insertedID,
                            title: newSheet['title'] as String,
                            numCellRows: newSheet['numCellRows'] as int,
                            marks: selectedMarkTypes, // マークリストをそのまま渡す
                            isMultipleSelectionAllowed: newSheet['isMultipleSelectionAllowed'] == 1,
                            isTimeLimitEnabled: newSheet['isTimeLimitEnabled'] == 1,
                            timelimit: newSheet['timelimit'] as int,
                          ),
                        ),
                    );
                  } else {
                  // 更新
                      final id = widget.existingData!['id'];
                      DatabaseHelper().updateMarksheet(id, newSheet);

                      Navigator.pushAndRemoveUntil(
                        context,
                      MaterialPageRoute(
                        builder: (context) => Marksheet(
                          marksheetID: id,
                          title: newSheet['title'] as String,
                          numCellRows: newSheet['numCellRows'] as int,
                          marks: selectedMarkTypes,
                          isMultipleSelectionAllowed: newSheet['isMultipleSelectionAllowed'] == 1,
                          isTimeLimitEnabled: newSheet['isTimeLimitEnabled'] == 1,
                          timelimit: newSheet['timelimit'] as int,
                        ),
                      ),
                      (route) => false, // これで戻る際に古い画面を削除
                    );
                                        
                    /*
                    await db.update(
                      'marksheets',
                      newSheet,
                      where: 'id = ?',
                      whereArgs: [id],
                    );*/
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('マークシートを更新しました！！！'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                        bottom: 10, 
                        left: 16,
                        right: 16,
                      ),        
                      ),
                    );
                  }
                /*
          
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Marksheet(
                      title: _marksheetnameController.text,
                      numCellRows: numberOfQuestions,
                      isTimeLimitEnabled:_isTimeLimitEnabled,
                      timelimit: _TimeLimit,
                      marks: selectedMarkTypes,
                      isMultipleSelectionAllowed: _isMultipleSelectionAllowed
                      ),
                  )
                );
              */
                
          
              },
            )
          
          ],),
        )
      )
    );
  }

  Widget TimePickers(String Time, int _timeLimit, int max, ValueChanged<int> onChanged){ 
            return Column(
                    children: [
                      Text(Time),
                      Transform.scale(
                        scale: 0.8,
                        child: NumberPicker(
                          minValue: 0,
                          maxValue: max,
                          value: _timeLimit,
                          itemHeight: 25,
                          itemWidth: 50,
                          onChanged: onChanged,
                          infiniteLoop: true,
                          decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          selectedTextStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,  
                              color: Colors.black,  
                          ),
                          
                        ),               
                      ),
                    ],
                  );
  }

  //使用するマークをダイアログ上で選択
  void _showMarkSelectDialog(List<String> selectedMarkTypes){
  // 選択可能なマークタイプ一覧
  List<String> markCategory_PlusMinus = ['+', '-', '±'];
  List<String> markCategory_Number = List.generate(10, (index) => String.fromCharCode('0'.codeUnitAt(0) + index));
  List<String> markCategory_A2Z = List.generate(26, (index) => String.fromCharCode('A'.codeUnitAt(0) + index));
  List<String> markCategory_a2z = List.generate(26, (index) => String.fromCharCode('a'.codeUnitAt(0) + index));
  List<String> markCategory_Hiragana = [
  'あ', 'い', 'う', 'え', 'お', 
  'か', 'き', 'く', 'け', 'こ',
  'さ', 'し', 'す', 'せ', 'そ',
  'た', 'ち', 'つ', 'て', 'と',
  'な', 'に', 'ぬ', 'ね', 'の',
  'は', 'ひ', 'ふ', 'へ', 'ほ',
  'ま', 'み', 'む', 'め', 'も',
  'や',       'ゆ',       'よ',
  'ら', 'り', 'る', 'れ', 'ろ',
  'わ',             'を', 'ん'
];
List<String> markCategory_Katakana = [
  'ア', 'イ', 'ウ', 'エ', 'オ', 
  'カ', 'キ', 'ク', 'ケ', 'コ',
  'サ', 'シ', 'ス', 'セ', 'ソ',
  'タ', 'チ', 'ツ', 'テ', 'ト',
  'ナ', 'ニ', 'ヌ', 'ネ', 'ノ',
  'ハ', 'ヒ', 'フ', 'ヘ', 'ホ',
  'マ', 'ミ', 'ム', 'メ', 'モ',
  'ヤ',       'ユ',       'ヨ',
  'ラ', 'リ', 'ル', 'レ', 'ロ',
  'ワ',             'ヲ', 'ン'
];

final List<String> markAllCategories = [
  ...markCategory_PlusMinus,
  ...markCategory_Number,
  ...markCategory_A2Z,
  ...markCategory_a2z,
  ...markCategory_Hiragana,
  ...markCategory_Katakana,
];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("選択肢の編集"),
        content: Container(
          width : 300,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter SBsetState) {
            
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("選択中のマーク"),
                    Wrap(
                      spacing: 8.0,
                      children: 
                        List.generate(selectedMarkTypes.length, (index) =>CircleAvatar(
                        backgroundColor:Colors.grey,
                        radius: 10,
                        child: Text(
                          selectedMarkTypes[index],
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),),
                    ),
                    ),
                    SizedBox(height: 10),
                    SelectMarksbyTypes('記号（数学）', markCategory_PlusMinus, selectedMarkTypes, SBsetState),
                    SelectMarksbyTypes('数字', markCategory_Number, selectedMarkTypes, SBsetState),
                    SelectMarksbyTypes('A-Z', markCategory_A2Z, selectedMarkTypes, SBsetState),
                    SelectMarksbyTypes('a-z', markCategory_a2z, selectedMarkTypes, SBsetState),
                    SelectMarksbyTypes('あ-ん', markCategory_Hiragana, selectedMarkTypes, SBsetState),
                    SelectMarksbyTypes('ア-ン', markCategory_Katakana, selectedMarkTypes, SBsetState),
            
                  ],
                );
            
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      );
    },
  );
  }

ExpansionTile SelectMarksbyTypes(String title, List<String> MarkCategory, List<String> selectedMarkTypes, StateSetter SBsetState){

              return ExpansionTile(
              title: Text(title),
              children: [
                Wrap(
                  spacing: 8.0,
                  children: List.generate(MarkCategory.length, (index) {
                    final String mark = MarkCategory[index];
                    final bool isSelected = selectedMarkTypes.contains(mark);

                    return GestureDetector(
                      onTap: () {
                        SBsetState(() {
                          if (isSelected) {
                            selectedMarkTypes.remove(mark);
                          } else {
                            selectedMarkTypes.add(mark);
                          }
                          print(selectedMarkTypes);

                          // マークの種類ごとに並び替え
                          selectedMarkTypes.sort((a, b) {
                            int groupA = _getMarkTypeGroup(a);
                            int groupB = _getMarkTypeGroup(b);
                            return groupA == groupB
                                ? a.compareTo(b)
                                : groupA.compareTo(groupB);
                          });
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: isSelected ? Colors.grey : Colors.white,
                        radius: 18,
                        child: Text(
                          mark,
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                      ),
                    );
                  }),
                ),
                
              ],
            );

}
  
}


int _getMarkTypeGroup(String mark) {
  if (mark == '+' || mark == '-' || mark == '±') {
    return 0; // 記号
  } else if (mark.codeUnitAt(0) >= '0'.codeUnitAt(0) && mark.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
    return 1; // 数字
  } else if (mark.codeUnitAt(0) >= 'A'.codeUnitAt(0) && mark.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) {
    return 2; // 大文字アルファベット
  } else if (mark.codeUnitAt(0) >= 'a'.codeUnitAt(0) && mark.codeUnitAt(0) <= 'z'.codeUnitAt(0)) {
    return 3; // 小文字アルファベット
  } else if (mark.codeUnitAt(0) >= 'あ'.codeUnitAt(0) && mark.codeUnitAt(0) <= 'ん'.codeUnitAt(0)) {
    return 4; // ひらがな
  } else if (mark.codeUnitAt(0) >= 'ア'.codeUnitAt(0) && mark.codeUnitAt(0) <= 'ン'.codeUnitAt(0)) {
    return 5; // カタカナ
  }
  return 6; // その他
}