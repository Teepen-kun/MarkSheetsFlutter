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

          //設定完了！！！！！！
          ElevatedButton(
            child: Text('OK'),
            onPressed: (){
              int numberOfQuestions =  int.tryParse(_numberofquestionController.text)  ??  1 ;
              if(numberOfQuestions <= 0) numberOfQuestions = 1;
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Marksheet(
                    title: _marksheetnameController.text,
                    numCellRows: numberOfQuestions,
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
                              color: Colors.blue,  
                          ),
                          
                        ),               
                      ),
                    ],
                  );
  }
}
