import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'MarkSheet.dart';
import 'package:numberpicker/numberpicker.dart';


class SettingScreen extends StatefulWidget{
  const SettingScreen({super.key});

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
  String selectedMarkType = 'A-Z'; // デフォルトは 'A-Z'
  final List<String> markTypes = ['a-z', 'A-Z', '0-9', '+-', 'あ-ん', 'ア-ン'];
  List<String> selectedMarkTypes = ['1','2','3','4'];

  @override
  void dispose() {
      _marksheetnameController.dispose(); // メモリリークを防ぐためにdisposeする...必要性はあとで考える
      _numberofquestionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
          //マークシート名入力欄
          TextField(
              controller: _marksheetnameController,
              decoration: InputDecoration(labelText: 'Mark Sheet Name'),//MarkSheetの名前
            ),
          SizedBox(height: 20),

          //問題数入力欄
          TextField(
              controller: _numberofquestionController,
              decoration: InputDecoration(labelText: '問題数'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], //数値限定
            ),
          SizedBox(height: 20),

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
            SizedBox(height: 20),
          
            ElevatedButton(
              onPressed: () => _showMarkSelectDialog(selectedMarkTypes),
              child: Text("Select Mark Types"),
            ),   

          //設定完了！！！！！！
          ElevatedButton(
            child: Text('OK'),
            onPressed: (){
              int numberOfQuestions =  int.tryParse(_numberofquestionController.text)  ??  1 ;
              if(numberOfQuestions <= 0) numberOfQuestions = 1;

              int _TimeLimit = 3600*_timeLimitHour + 60*_timeLimitMinute + _timeLimitSecond;//設定時間（秒）
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Marksheet(
                    title: _marksheetnameController.text,
                    numCellRows: numberOfQuestions,
                    timelimit: _TimeLimit,
                    ),
                )
              );

              

            },
          )

        ],)
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
