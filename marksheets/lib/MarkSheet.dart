import 'package:flutter/material.dart';
import 'dart:async';


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
  
  late List<List<bool>> selectedMarks;

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
      isScoringMode = true;
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
        
          borderColor = selectedMarks[indexCellRow][index] ? Colors.green : Colors.red;
      }else{
          borderColor = Colors.black38;
      }
          //isCorrect = selectedMark[indexCellRow] == index;

      return GestureDetector(
        onTap: () {
          if (!isScoringMode) {
            setState(() {
              if (widget.isMultipleSelectionAllowed) {
                // 複数選択モードのタップ処理
                selectedMarks[indexCellRow][index] = !selectedMarks[indexCellRow][index];
                markColors[indexCellRow][index] =
                    selectedMarks[indexCellRow][index] ? Colors.black45 : Colors.white;
              } else {
                // 単一選択モードのタップ処理
                for (int i = 0; i < widget.marks.length; i++) {
                    selectedMarks[indexCellRow][i] = (i == index);
                    markColors[indexCellRow][i] = (i == index) ? Colors.black45 : Colors.white;
                  }
              }
            });
            print(selectedMarks);
          }else{
            // 採点モードでの枠線色の切り替え
              if (selectedMarks[indexCellRow][index]) {
                // 正解選択済みを解除
                selectedMarks[indexCellRow][index] = false;
              } else {
                // 不正解選択済みを解除
                selectedMarks[indexCellRow][index] = true;
              }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
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
                  onPressed: isScoringMode ? null : startScoring,
                  child: const Text("Start Scoring"),
              ),
            ],
          );
  }
  

  
}