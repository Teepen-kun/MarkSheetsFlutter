import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'HomeScreen.dart';
import 'SettingScreen.dart';
import 'database_helper.dart';


class Marksheet extends StatefulWidget {
  const Marksheet({
    super.key, 
    required this.marksheetID,
    required this.title,
    required this.numCellRows,
    required this.isTimeLimitEnabled,
    required this.timelimit,
    required this.marks,
    required this.isMultipleSelectionAllowed
    });
  final int marksheetID; // マークシートのid
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
  late List<List<String>> selectedMarks; //選択済みマークの位置

  late List<List<String>> answerList;//正解のマークの位置

  late List<bool> questionResults; // 問題ごとの正解状態

  late List<List<bool>> markColors;

  late List<String> sortedselectedMarks; //回答と正解が一致するかどうかを判定するために使う
  late List<String> sortedanswerList;

  @override 
  void initState(){ //widgetプロパティを使うため
    super.initState();
    remainingTime = widget.timelimit; // 初期残り時間をセット
    questionResults = List.filled(widget.numCellRows, false);// 初期化時はすべて未採点（false）
  

    selectedMarks = List.generate(
    widget.numCellRows,
    (_) => []
    );

    answerList = List.generate(
    widget.numCellRows,
    (_) =>[]
    );

    markColors = List.generate(
    widget.numCellRows, 
    (indexCellRows) => List.filled(widget.marks.length, false)
    ); 
    
    sortedselectedMarks = List.filled(widget.numCellRows, '');
    sortedanswerList = List.filled(widget.numCellRows, '');

    getAnswer(widget.marksheetID);
    getCorrectAnswer(widget.marksheetID);
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
    gradeQuestions();
    if (widget.isMultipleSelectionAllowed && selectedMarks == null) {
    // 複数選択が許可されていてselectedMarksが初期化されていない場合、初期化する
    selectedMarks = List.generate(widget.numCellRows, (_) => []);
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
      String mark = widget.marks[index]; //タップしたマーク
      Color borderColor = Colors.black38; // デフォルトの枠色
      //bool isCorrect = false; // 正解かどうかを保持
      

      //isCorrect = selectedMark[indexCellRow] == index;

      if (isScoringMode) {
        // 採点モードの処理
        if (answerList[indexCellRow].contains(mark) && selectedMarks[indexCellRow].contains(mark)) {
          borderColor = Colors.green; // 正解マークが選択されている
        } else if (answerList[indexCellRow].contains(mark) && !selectedMarks[indexCellRow].contains(mark)) {
          borderColor = Colors.red; // 正解マークが選択されていない
        }
      }

      return GestureDetector(
        onTap: () async {
          if (!isScoringMode) {
            
            //解答モード
            setState(() {
              markColors[indexCellRow][index] = !markColors[indexCellRow][index];
               if (widget.isMultipleSelectionAllowed) { //複数選択モード
                selectedMarks[indexCellRow].contains(mark) ?
                  selectedMarks[indexCellRow].remove(mark):
                  selectedMarks[indexCellRow].add(mark);        
                }else{//単一選択
                selectedMarks[indexCellRow].contains(mark) ?
                  selectedMarks[indexCellRow].remove(mark):
                  selectedMarks[indexCellRow].add(mark);
                  if(selectedMarks[indexCellRow].length > 1){
                    markColors[indexCellRow][widget.marks.indexWhere((element) => element == selectedMarks[indexCellRow][0])] = false;
                    print(widget.marks.indexWhere((element) => element == selectedMarks[indexCellRow][0]));
                    selectedMarks[indexCellRow].removeAt(0);
                  }
              }
              sortedselectedMarks[indexCellRow] = marksSorting(selectedMarks[indexCellRow]);
            });
            saveAnswer(widget.marksheetID);
            print('selectedMarks $selectedMarks');
          //convertSelectedMarksToString(selectedMarks);

          }else{
            //採点モードのときだよーん
            setState(() {            
              answerList[indexCellRow].contains(mark) ?
              answerList[indexCellRow].remove(mark):
              answerList[indexCellRow].add(mark);        
              
              sortedanswerList[indexCellRow] = marksSorting(answerList[indexCellRow]);
              saveCorrectAnswer(widget.marksheetID);

              answerList.contains(mark)? borderColor = Colors.green : borderColor = Colors.red;
              print('answerList : ');
              print(answerList);
              gradeQuestions();              
            });
          }
        },
        child: Container(
          width: 30,
          height: 30,  
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: isScoringMode && (borderColor != Colors.black38) ? 3.0 : 1.0,
              ),
          ),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: markColors[indexCellRow][index] ?  Colors.black45 : Colors.white,
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

 // 回答の正誤
  void gradeQuestions() {
    setState(() {
      for (int i = 0; i < widget.numCellRows; i++) {
        bool isAnswered = selectedMarks[i].isNotEmpty;
        bool isQuestionCorrect = sortedselectedMarks[i] == sortedanswerList[i];

        questionResults[i] = isAnswered && isQuestionCorrect;
      }
    });
  }

// 問題番号セルの生成
  Widget buildQuestionNumber(int index) {
    final Color bgColor = questionResults[index]
        ? Colors.green // 正解の場合は緑
        : Colors.red; // 不正解の場合は赤

    return Container(
      //height: 50,
      color: isScoringMode ? bgColor : null, // 採点モードのみ色を変える
      alignment: Alignment.center,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  //DBに保存
  Future<void> saveAnswer(int marksheetId) async{
    String answers = selectedMarks
    .map((subList) => subList.where((mark) => mark.isNotEmpty).join(',')) 
      .join(';');
    print("Saving answers: $answers"); // デバッグログを追加
    
    final answerdata = {
              'marksheet_id': widget.marksheetID, 
              'answer':answers
            };
    if (await DatabaseHelper.instance.doesAnswerExist(marksheetId)) {
    // データが存在すれば更新
    final updateCount = await DatabaseHelper.instance.updateAnswer(marksheetId, answerdata);
    print("Update count: $updateCount"); // デバッグログ
    print("Updated existing answer in database.");
  } else {
    // データが存在しなければ挿入
    await DatabaseHelper.instance.insertAnswer(answerdata);
    print("Inserted new answer into database.");
  }
  }
//DBから取得
  Future<void> getAnswer(int marksheetId) async {

  final result = await DatabaseHelper.instance.getAnswer(marksheetId);
  print("Loaded result: $result"); // デバッグログを追加
  if(result.isNotEmpty){// 取得したデータを復元
    String encodedAnswers = result.first['answer'];
    print("Encoded answers: $encodedAnswers"); // デバッグログを追加
    selectedMarks = encodedAnswers
      .split(';')
      .map((subList) => subList
          .split(',')
          .where((mark) => mark.isNotEmpty) // 空文字列を除外
          .toList())
      .toList();
    print("Decoded selectedMarks: $selectedMarks"); // デバッグログを追加

    int minRows = widget.numCellRows;
    selectedMarks = selectedMarks.take(minRows).toList();

    while (selectedMarks.length < widget.numCellRows) {
        selectedMarks.add([]);  
    }
    // markColors の更新
    for (int row = 0; row < selectedMarks.length; row++) {
      sortedselectedMarks[row] = marksSorting(selectedMarks[row]);
      for (int index = 0; index < widget.marks.length; index++) {        
        markColors[row][index] = selectedMarks[row].contains(widget.marks[index]);
      }
    } 
      
    
  } else {
    // データが存在しない場合の処理（例: 初期化）
    print("No data found for marksheetId: $marksheetId"); // デバッグログを追加
    selectedMarks = List.generate(widget.numCellRows, (_) => []);
  }

  
  setState(() {}); // UI更新
  
}

 //正解をDBに保存
  Future<void> saveCorrectAnswer(int marksheetId) async{
    String correct_answers = answerList
    .map((subList) => subList.where((mark) => mark.isNotEmpty).join(',')) 
      .join(';');
    print("Saving answers: $correct_answers"); // デバッグログを追加
    
    final answerdata = {
              'marksheet_id': widget.marksheetID, 
              'correct_answer':correct_answers
            };
    if (await DatabaseHelper.instance.doesCorrectAnswerExist(marksheetId)) {
    // データが存在すれば更新
    final updateCount = await DatabaseHelper.instance.updateCorrectAnswer(marksheetId, answerdata);
    print("Update count: $updateCount"); // デバッグログ
    print("Updated existing answer in database.");
  } else {
    // データが存在しなければ挿入
    await DatabaseHelper.instance.insertCorrectAnswer(answerdata);
    print("Inserted new answer into database.");
  }
  }
//正解をDBから取得
  Future<void> getCorrectAnswer(int marksheetId) async {

  final result = await DatabaseHelper.instance.getCorrectAnswer(marksheetId);
  print("Loaded result: $result"); // デバッグログを追加
  if(result.isNotEmpty){// 取得したデータを復元
    String encodedCorrectAnswers = result.first['correct_answer'];
    print("Encoded Correctanswers: $encodedCorrectAnswers"); // デバッグログを追加
    answerList = encodedCorrectAnswers
      .split(';')
      .map((subList) => subList
          .split(',')
          .where((mark) => mark.isNotEmpty) // 空文字列を除外
          .toList())
      .toList();
    print("Decoded answerList: $answerList"); // デバッグログを追加

    int minRows = widget.numCellRows;
    answerList = answerList.take(minRows).toList();

    while (answerList.length < widget.numCellRows) {
        answerList.add([]);  
    }
    // markColors の更新
    for (int row = 0; row < answerList.length; row++) {
      sortedanswerList[row] = marksSorting(answerList[row]);
    } 
  } else {
    // データが存在しない場合の処理（例: 初期化）
    print("No data found for marksheetId: $marksheetId"); // デバッグログを追加
    answerList = List.generate(widget.numCellRows, (_) => []);
  }  
  setState(() {}); // UI更新
  
}

String marksSorting(List<String> list){
  return List.of(list..sort()).toString();
}

Widget buildControlButtons() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 左右に配置
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 開始/停止
        OutlinedButton(
          onPressed: toggleTimer,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10), 
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(isCountingDown ? "停止" : (hasStarted ? "再開" : "開始")),
          
        ),

        //残り時間
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '残り時間',
              style: const TextStyle(fontSize: 10),
            ),
            
            Text(
              formatTime(remainingTime),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          children: [
            //解答入力
            OutlinedButton(
                  onPressed: startScoring,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 20), // ボタンを小さめに
                    //padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(isScoringMode ? "入力完了" : "解答入力",style: const TextStyle(fontSize: 10)),
                ), 
            OutlinedButton(
              onPressed: resetTimer,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 20), 
                //padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text("リセット" ,style: const TextStyle(fontSize: 10),),
            )
          ],
        ),
      
      ],
    ),
  );
}












  @override
  Widget build(BuildContext context) {
    // 正解数の計算
    int correctCount = questionResults.where((result) => result).length;

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
            onPressed: () async {
              try {
                // データベースから現在のマークシート情報を取得
              final marksheetData = await DatabaseHelper().getMarksheet(widget.marksheetID);

               // SettingScreen に遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingScreen(
                      isNew: false,
                      existingData: marksheetData,
                    ),
                  ),
                );
              } catch (e) {
                // エラー処理
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('エラー: データを取得できませんでした'),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                        bottom: 10, 
                        left: 16,
                        right: 16,
                      ),
                    ),
                );
    }
            },
          ),
        ],
          
      ),
        body: Column(
          children: [
            // タイマーを等を配置する部分
            Container(
              color: Colors.grey[200], // タイマー部分に背景色を付ける
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: buildControlButtons()
            ),
            Expanded(
              child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Table(
                  border: TableBorder.all(color: Colors.grey), 
                  columnWidths: const{
                    0: FixedColumnWidth(30)
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
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.fill, // 行全体の高さに合わせる
                          child: buildQuestionNumber(index)
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

        // 点数表示用のContainer  
        if (isScoringMode)
          Container(
            color: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "得点",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                Text(
                  "$correctCount / ${widget.numCellRows}",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
            
          ],
        ),
    );
  }
  
}