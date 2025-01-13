import 'package:flutter/material.dart';
import 'dart:async';
import 'HomeScreen.dart';
import 'SettingScreen.dart';


class Marksheet extends StatefulWidget {
  const Marksheet({
    super.key, 
    required this.title,
    required this.numCellRows,
    required this.isTimeLimitEnabled,
    required this.timelimit,
    required this.marks,
    required this.isMultipleSelectionAllowed
    });

  final String title;
  final int numCellRows; //表示する行数
  final bool isTimeLimitEnabled; //制限時間の可否
  final int timelimit; //制限時間
  final List<String> marks; //選択したマークの種類
  final bool isMultipleSelectionAllowed; //複数選択の可否

  @override
  State<Marksheet> createState() => _Marksheet();
}

class _Marksheet extends State<Marksheet> {

  late int remainingTime; // 残り時間
  Timer? _timer; // タイマーの管理
  bool isCountingDown = false; // カウントダウンが開始しているかどうか
  bool hasStarted = false; // タイマーが開始されたかどうか.

  // 試験モード(false)or採点モード(true)
  bool isScoringMode = false;


  //各回答ごとのマーク
  late List<List<Color>> markColors;
  
  late List<List<bool>> selectedMarks; //選択済みマークの位置

  late List<List<bool>> answerList;//正解のマークの位置

  @override 
  void initState(){ //widgetプロパティを使うため
  super.initState();
  remainingTime = widget.timelimit; // 初期残り時間をセット

  markColors = List.generate(
    widget.numCellRows, 
    (indexCellRows) => List.generate(widget.marks.length, (indexMarks) => Colors.white)
    ); 

  selectedMarks = List.generate(
    widget.numCellRows,
    (_) => List.filled(widget.marks.length, false)
  );

  answerList = List.generate(
  widget.numCellRows,
  (_) => List.filled(widget.marks.length, false),
);

  
    
  }

  // hh:mm:ssのフォーマットに変換
  String formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  // タイマーのスタート・ストップを切り替える
  void toggleTimer() {
    if (isCountingDown) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // タイマーを開始
  void _startTimer() {
    if (isCountingDown) return; // すでにカウントダウン中なら何もしない
    setState(() {
      isCountingDown = true;
      hasStarted = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel();
          isCountingDown = false;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      isCountingDown = false;
    });
  }

  // タイマーをリセット
  void resetTimer() {
    _stopTimer();
    setState(() {
      remainingTime = widget.timelimit;
      hasStarted = false;
    });
  }
  //採点開始！
  void startScoring() {
    if (widget.isMultipleSelectionAllowed && selectedMarks == null) {
    // 複数選択が許可されていてselectedMarksが初期化されていない場合、初期化する
    selectedMarks = List.generate(widget.numCellRows, (_) => List.filled(widget.marks.length, false));
  }
    setState(() {
      isScoringMode = !isScoringMode;
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // タイマーを停止
    super.dispose();
  }

  // MarkBoxセル生成
  Widget buildMarkBox(int indexCellRow) {
  return Wrap(
    spacing: 4.0,
    runSpacing: 4.0,
    alignment: WrapAlignment.center,
    children: List.generate(widget.marks.length, (index) {
      Color borderColor = Colors.black38; // デフォルトの枠色
      bool isCorrect = false; // 正解かどうかを保持

      // 採点モードの処理
      if (isScoringMode) {
          if (selectedMarks[indexCellRow][index] && answerList[indexCellRow][index]) {
             borderColor = Colors.green; // 正解
          } else if (answerList[indexCellRow][index] && !selectedMarks[indexCellRow][index]) {
            borderColor = Colors.red; // 不正解
          } 
}
          //isCorrect = selectedMark[indexCellRow] == index;

      return GestureDetector(
        onTap: () {
          if (!isScoringMode) {
            //解答モード
            setState(() {
              if (widget.isMultipleSelectionAllowed) {
                // 複数選択モードのタップ処理
                selectedMarks[indexCellRow][index] = !selectedMarks[indexCellRow][index];
                markColors[indexCellRow][index] =
                    selectedMarks[indexCellRow][index] ? Colors.black45 : Colors.white;
              } else {
                // 単一選択モードのタップ処理
                for (int i = 0; i < widget.marks.length; i++) {
                    if (i == index) {
                      // すでに選択されている場合は解除
                      if (selectedMarks[indexCellRow][i]) {
                      selectedMarks[indexCellRow][i] = false;
                      markColors[indexCellRow][i] = Colors.white;
                      } else {
                      selectedMarks[indexCellRow][i] = true;
                      markColors[indexCellRow][i] = Colors.black45;
                    }
                    } else {
                     // 他の選択肢は解除
                      selectedMarks[indexCellRow][i] = false;
                      markColors[indexCellRow][i] = Colors.white;
                    }
                  }
              }
            });
            print(selectedMarks);
          }else{
            //採点モードのときだよーん
            setState(() {answerList[indexCellRow][index] = !answerList[indexCellRow][index];
    });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: isScoringMode && (borderColor == Colors.green || borderColor == Colors.red) ? 3.0 : 1.0,
              ),
          ),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: markColors[indexCellRow][index],
            child: Text(
              '${widget.marks[index]}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ),
      );
    }),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 
            Text(widget.title),
            leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
            // HomeScreen に戻る処理
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // 設定アイコン
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingScreen(),
                ),
              );
            },
          ),
        ],
          
      ),
        body: Column(
          children: [
            // タイマーを配置する部分
            Container(
              color: Colors.grey[200], // タイマー部分に背景色を付ける
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: buildControlButtons()
            ),
            Expanded(
              child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Table(
                  border: TableBorder.all(color: Colors.grey), 
                  columnWidths: const{
                    0: FixedColumnWidth(40)
                  },
                  children: List.generate(widget.numCellRows, (index) {
                    final Color rowColor = (index % 2 == 0) ? Colors.grey[200]! : Colors.white; //行ごとに少し色変える
                    return TableRow(
                      decoration: BoxDecoration(
                        color: rowColor,
                        //border: Border.all(width: 0.1, color: Colors.yellow),
                      ),
                      children: [
                        // 左側の行番号
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(fontSize: 12, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        // マークが並んだセル
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle, //セルの位置をちょうど真ん中に
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0), 
                            child: Center(
                              child:buildMarkBox(index),
                              ),
                          ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
                    ),
            ),
          ],
        ),
    );
  }

  Widget buildControlButtons() {
    return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTime(remainingTime),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: toggleTimer,
                child: Text(isCountingDown ? "Stop" : (hasStarted ? "Restart" : "Start")),
              ),
              const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: const Text("Reset"),
                ),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: startScoring,
                  child: Text(isScoringMode? "End Scoring" : "Start Scoring" ),
              ),
            ],
          );
  }
  

  
}