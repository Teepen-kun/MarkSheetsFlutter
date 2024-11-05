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

  //各回答ごとのマーク
  late List<List<Color>> markColors;
  late List<int?> selectedMark;
  late List<List<bool>> selectedMarks;

  @override 
  void initState(){ //widgetプロパティを使うため
  super.initState();
  remainingTime = widget.timelimit; // 初期残り時間をセット
  markColors = List.generate(
    widget.numCellRows, 
    (indexCellRows) => List.generate(widget.marks.length, (indexMarks) => Colors.white)); 
  
  //各問題の現在の選択．複数選択がtrueならselectedMarks, falseならselectedMark．
    if (widget.isMultipleSelectionAllowed) {
      selectedMarks = List.generate(widget.numCellRows, (_) => List.filled(widget.marks.length, false));
    } else {
      selectedMark = List.generate(widget.numCellRows, (index) => null);
    }
  }

  // hh:mm:ssのフォーマットに変換
  String formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  // タイマーを開始
  void startTimer() {
    if (isCountingDown) return; // すでにカウントダウン中なら何もしない
    setState(() {
      isCountingDown = true;
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

  @override
  void dispose() {
    _timer?.cancel(); // タイマーを停止
    super.dispose();
  }

  // MarkBoxセル生成
  List<Widget> buildMarkBox(int indexCellRow) {
    return List.generate(widget.marks.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: (){
            setState(() {
              if (widget.isMultipleSelectionAllowed) {
                selectedMarks[indexCellRow][index] = !selectedMarks[indexCellRow][index];
                markColors[indexCellRow][index] = selectedMarks[indexCellRow][index] ? Colors.black45 : Colors.white;
              } else {
              if(selectedMark[indexCellRow] == index){
                markColors[indexCellRow][index] = Colors.white;
                selectedMark[indexCellRow] = null;
              }else {
                if(selectedMark[indexCellRow] != null){
                markColors[indexCellRow][selectedMark[indexCellRow]!] = Colors.white;
              }
              markColors[indexCellRow][index] = Colors.black45;
              selectedMark[indexCellRow] = index;
              }
              }
            });
          
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black38 ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: markColors[indexCellRow][index],
              child: Text(
                '${widget.marks[index]}',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
            Row(
              children: [
                Text(formatTime(remainingTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: startTimer,
                  child: const Text("Start"),
                ),
              ],
            ),
          ],
        )
        ),
        body: SingleChildScrollView(
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: buildMarkBox(index),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}