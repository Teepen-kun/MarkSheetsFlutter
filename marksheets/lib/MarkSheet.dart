import 'package:flutter/material.dart';
import 'dart:async';
import 'HomeScreen.dart';
import 'SettingScreen.dart';
import 'database_helper.dart';
import 'package:share_plus/share_plus.dart';

class Marksheet extends StatefulWidget {
  const Marksheet({
    super.key,
    required this.marksheetID,
  });
  final String marksheetID; // マークシートのid

  @override
  State<Marksheet> createState() => _Marksheet();
}

class _Marksheet extends State<Marksheet> {
  late int remainingTime; // 残り時間
  Timer? _timer; // タイマーの管理
  bool isCounting = false; // カウントが開始しているかどうか
  bool hasStarted = false; // タイマーが開始されたかどうか.

  // 試験モード(false)or採点モード(true)
  bool isScoringMode = false;
  // 正解数の計算
  int correctCount = 0;
  int nomarksCount = 0;
  late String title; // マークシートタイトル
  late int numCellRows; // 表示する行数
  late bool isTimeLimitEnabled; // 制限時間の可否
  late int timelimit; // 制限時間
  late List<String> marks; // 選択したマークの種類
  late bool isMultipleSelectionAllowed; // 複数選択の可否

  //各回答ごとのマーク
  late List<List<String>> selectedMarks; //選択済みマークの位置
  late List<List<String>> answerList; //正解のマークの位置
  late List<int> questionResults; // 問題ごとの正解状態
  late List<int> checkBoxes;
  late List<List<bool>> markColors;
  late List<String> sortedselectedMarks; //回答と正解が一致するかどうかを判定するために使う
  late List<String> sortedanswerList;

  bool isInitialized = false;

  @override
  void initState() {
    _fetchMarksheetData();
    super.initState();
  }

  Future<void> _fetchMarksheetData() async {
    final data = await DatabaseHelper().getMarksheet(widget.marksheetID);

    if (data != null) {
      setState(() {
        title = data['title'] as String;
        numCellRows = data['numCellRows'] as int;
        isTimeLimitEnabled = (data['isTimeLimitEnabled'] as int) == 1;
        timelimit = data['timelimit'] as int;
        marks = (data['markTypes'] as String).split(',');
        isMultipleSelectionAllowed =
            (data['isMultipleSelectionAllowed'] as int) == 1;

        remainingTime = timelimit;
        questionResults = List.filled(numCellRows, 1);
        checkBoxes = List.filled(numCellRows, 0);
        selectedMarks = List.generate(numCellRows, (_) => []);
        answerList = List.generate(numCellRows, (_) => []);
        markColors = List.generate(
          numCellRows,
          (index) => List.filled(marks.length, false),
        );
        sortedselectedMarks = List.filled(numCellRows, '');
        sortedanswerList = List.filled(numCellRows, '');
      });
      getAnswer(widget.marksheetID);
      getCorrectAnswer(widget.marksheetID);
      getCheckBoxes(widget.marksheetID);
      isInitialized = true;
    } else {
      // データが見つからない場合のエラー処理
      print('Marksheet with ID ${widget.marksheetID} not found.');
    }
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
    if (isCounting) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // タイマーを開始
  void _startTimer() {
    if (isCounting) return; // すでにカウントダウン中なら何もしない
    setState(() {
      isCounting = true;
      hasStarted = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (isTimeLimitEnabled) {
          if (remainingTime > 0) {
            remainingTime--;
          } else {
            timer.cancel();
            isCounting = false;
          }
        } else {
          remainingTime++;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      isCounting = false;
    });
  }

  // タイマーをリセット
  void resetTimer() {
    _stopTimer();
    setState(() {
      remainingTime = timelimit;
      hasStarted = false;
    });
  }

  //採点開始！
  void startScoring() {
    gradeQuestions();
    if (isMultipleSelectionAllowed && selectedMarks == null) {
      // 複数選択が許可されていてselectedMarksが初期化されていない場合、初期化する
      selectedMarks = List.generate(numCellRows, (_) => []);
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
      children: List.generate(marks.length, (index) {
        String mark = marks[index]; //タップしたマーク
        Color borderColor = Colors.black38; // デフォルトの枠色
        //bool isCorrect = false; // 正解かどうかを保持

        //isCorrect = selectedMark[indexCellRow] == index;

        if (isScoringMode) {
          // 採点モードの処理
          if (answerList[indexCellRow].contains(mark) &&
              selectedMarks[indexCellRow].contains(mark)) {
            borderColor = Colors.green; // 正解マークが選択されている
          } else if (answerList[indexCellRow].contains(mark) &&
              !selectedMarks[indexCellRow].contains(mark)) {
            borderColor = Colors.red; // 正解マークが選択されていない
          }
        }

        return GestureDetector(
          onTap: () async {
            if (!isScoringMode) {
              //解答モード
              setState(() {
                markColors[indexCellRow][index] =
                    !markColors[indexCellRow][index];
                if (isMultipleSelectionAllowed) {
                  //複数選択モード
                  selectedMarks[indexCellRow].contains(mark)
                      ? selectedMarks[indexCellRow].remove(mark)
                      : selectedMarks[indexCellRow].add(mark);
                } else {
                  //単一選択
                  selectedMarks[indexCellRow].contains(mark)
                      ? selectedMarks[indexCellRow].remove(mark)
                      : selectedMarks[indexCellRow].add(mark);
                  if (selectedMarks[indexCellRow].length > 1) {
                    markColors[indexCellRow][marks.indexWhere((element) =>
                        element == selectedMarks[indexCellRow][0])] = false;
                    print(marks.indexWhere((element) =>
                        element == selectedMarks[indexCellRow][0]));
                    selectedMarks[indexCellRow].removeAt(0);
                  }
                }
                sortedselectedMarks[indexCellRow] =
                    marksSorting(selectedMarks[indexCellRow]);
              });
              saveAnswer(widget.marksheetID);
              print('selectedMarks $selectedMarks');
              //convertSelectedMarksToString(selectedMarks);
            } else {
              //採点モードのときだよーん
              setState(() {
                answerList[indexCellRow].contains(mark)
                    ? answerList[indexCellRow].remove(mark)
                    : answerList[indexCellRow].add(mark);

                sortedanswerList[indexCellRow] =
                    marksSorting(answerList[indexCellRow]);
                saveCorrectAnswer(widget.marksheetID);

                answerList.contains(mark)
                    ? borderColor = Colors.green
                    : borderColor = Colors.red;
                print('answerList : ');
                print(answerList);
                gradeQuestions();
              });
            }
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isScoringMode && (borderColor != Colors.black38)
                    ? 3.0
                    : 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: markColors[indexCellRow][index]
                  ? Colors.black45
                  : Colors.white,
              child: Text(
                '${marks[index]}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold),
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
      for (int i = 0; i < numCellRows; i++) {
        bool isAnswered = selectedMarks[i].isNotEmpty;
        bool isQuestionCorrect = sortedselectedMarks[i] == sortedanswerList[i];
        if (!isAnswered || checkBoxes[i] == 1) {
          questionResults[i] = 2; //無回答かチェック付きなら2
        } else if (isAnswered && !isQuestionCorrect) {
          questionResults[i] = 1; //解答しているが不正解なら1
        } else if (isAnswered && isQuestionCorrect) {
          questionResults[i] = 0; //正解なら0
        }
        nomarksCount = questionResults.where((result) => result == 2).length;
        correctCount = questionResults.where((result) => result == 0).length;
        DatabaseHelper().updateScore(widget.marksheetID, correctCount);
      }
    });
  }

// 問題番号セルの生成
  Widget buildQuestionNumber(int index) {
    Color bgColor = Colors.red;

    if (questionResults[index] == 0) {
      bgColor = Colors.green; // 正解の場合は緑
    } else if (questionResults[index] == 1) {
      bgColor = Colors.red; // 不正解の場合は赤
    } else if (questionResults[index] == 2) {
      bgColor = Colors.yellow; //無回答は黄色
    }

    return Container(
      //height: 50,
      color: isScoringMode ? bgColor : null, // 採点モードのみ色を変える
      alignment: Alignment.center,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  //DBに保存
  Future<void> saveAnswer(String marksheetId) async {
    String answers = selectedMarks
        .map((subList) => subList.where((mark) => mark.isNotEmpty).join(','))
        .join(';');
    print("Saving answers: $answers"); // デバッグログを追加

    final answerdata = {
      'createdAt': DateTime.now().toIso8601String(),
      'answers': answers
    };

    await DatabaseHelper.instance.updateMarksheet(marksheetId, answerdata);
  }

//DBから取得
  Future<void> getAnswer(String marksheetId) async {
    final result = await DatabaseHelper.instance.getAnswer(marksheetId);
    print("Loaded result: $result"); // デバッグログを追加
    if (result != null) {
      // 取得したデータを復元
      print("Loaded answers: $result"); // デバッグログを追加
      selectedMarks = result
          .split(';')
          .map((subList) => subList
              .split(',')
              .where((mark) => mark.isNotEmpty) // 空文字列を除外
              .toList())
          .toList();
      print("Decoded selectedMarks: $selectedMarks"); // デバッグログを追加

      int minRows = numCellRows;
      selectedMarks = selectedMarks.take(minRows).toList();

      while (selectedMarks.length < numCellRows) {
        selectedMarks.add([]);
      }
      // markColors の更新
      for (int row = 0; row < selectedMarks.length; row++) {
        sortedselectedMarks[row] = marksSorting(selectedMarks[row]);
        for (int index = 0; index < marks.length; index++) {
          markColors[row][index] = selectedMarks[row].contains(marks[index]);
        }
      }
    } else {
      // データが存在しない場合の処理（例: 初期化）
      print("No data found for marksheetId: $marksheetId"); // デバッグログを追加
      selectedMarks = List.generate(numCellRows, (_) => []);
    }

    setState(() {}); // UI更新
  }

  //正解をDBに保存
  Future<void> saveCorrectAnswer(String marksheetId) async {
    String correct_answers = answerList
        .map((subList) => subList.where((mark) => mark.isNotEmpty).join(','))
        .join(';');
    print("Saving answers: $correct_answers"); // デバッグログを追加

    final answerdata = {
      'createdAt': DateTime.now().toIso8601String(),
      'correctAnswers': correct_answers
    };
    await DatabaseHelper.instance.updateMarksheet(marksheetId, answerdata);
  }

//正解をDBから取得
  Future<void> getCorrectAnswer(String marksheetId) async {
    final result = await DatabaseHelper.instance.getCorrectAnswer(marksheetId);
    print("Loaded result: $result"); // デバッグログを追加
    if (result != null) {
      // 取得したデータを復元
      print("Loaded Correctanswers: $result"); // デバッグログを追加
      answerList = result
          .split(';')
          .map((subList) => subList
              .split(',')
              .where((mark) => mark.isNotEmpty) // 空文字列を除外
              .toList())
          .toList();
      print("Decoded answerList: $answerList"); // デバッグログを追加

      int minRows = numCellRows;
      answerList = answerList.take(minRows).toList();

      while (answerList.length < numCellRows) {
        answerList.add([]);
      }
      // markColors の更新
      for (int row = 0; row < answerList.length; row++) {
        sortedanswerList[row] = marksSorting(answerList[row]);
      }
    } else {
      // データが存在しない場合の処理（例: 初期化）
      print("No data found for marksheetId: $marksheetId"); // デバッグログを追加
      answerList = List.generate(numCellRows, (_) => []);
    }
    setState(() {}); // UI更新
  }

  //チェックボックスを保存
  Future<void> saveCheckBoxes(String marksheetId) async {
    String checks =
        checkBoxes.map<String>((int check) => check.toString()).join(',');
    print("Saving answers: $checks"); // デバッグログを追加

    final answerdata = {
      'createdAt': DateTime.now().toIso8601String(),
      'checkbox': checks
    };

    await DatabaseHelper.instance.updateMarksheet(marksheetId, answerdata);
  }

  Future<void> getCheckBoxes(String marksheetId) async {
    final result = await DatabaseHelper.instance.getCheckBoxes(marksheetId);

    if (result != null) {
      // 取得したデータを復元
      print("Loaded answers: $result"); // デバッグログを追加
      checkBoxes = result.split(',').map(int.parse).toList();

      int minRows = numCellRows;
      checkBoxes = checkBoxes.take(minRows).toList();

      while (checkBoxes.length < numCellRows) {
        checkBoxes.add(0);
      }
    } else {
      // データが存在しない場合の処理（例: 初期化）
      print("No data found for marksheetId: $marksheetId"); // デバッグログを追加
      checkBoxes = List.filled(numCellRows, 0);
    }
  }

  void shareMarksheet(String id) async {
    try {
      final file = await DatabaseHelper().exportMarksheet(widget.marksheetID);
      print('File created at: ${file.path}');
      await Share.shareXFiles([XFile('${file.path}')], text: 'マークシートを共有します！');
    } catch (e) {
      // エラー処理
      print('Error sharing marksheet: $e');
    }
  }

  String marksSorting(List<String> list) {
    return List.of(list..sort()).toString();
  }

  Widget buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 開始/停止
          OutlinedButton(
            onPressed: toggleTimer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 85, vertical: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 3),
            ),
            child: Text(
              isCounting ? "停止" : (hasStarted ? "再開" : "開始"),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),

          const SizedBox(width: 10),

          //解答入力
          OutlinedButton(
            onPressed: startScoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                width: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: isScoringMode
                ? Text("完了",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black))
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "答え入力\n",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "（採点）",
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center, // テキストを中央揃え
                  ),
          ),
          OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text("何をリセットしますか？",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                    children: <Widget>[
                      Divider(
                        color: Colors.grey,
                        thickness: 1.0,
                        indent: 10.0,
                        endIndent: 10.0,
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          resetTimer();
                          Navigator.pop(context);
                        },
                        child: Text("・タイマー",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          selectedMarks = List.generate(numCellRows, (_) => []);
                          markColors = List.generate(
                              numCellRows,
                              (indexCellRows) =>
                                  List.filled(marks.length, false));
                          questionResults = List.filled(numCellRows, 1);
                          gradeQuestions();
                          Navigator.pop(context);
                        },
                        child: Text("・解答",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          answerList = List.generate(numCellRows, (_) => []);
                          questionResults = List.filled(numCellRows, 1);
                          gradeQuestions();
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text("・答え",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          checkBoxes = List.filled(numCellRows, 0);   
                          gradeQuestions();                       
                          Navigator.pop(context);
                        },
                        child: Text("・チェックボックス",
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),

                      
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(
                width: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            child: const Text(
              "リセット",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          )
        ],
      ),
    );
  }

  Widget buildcheckBox(index) {
    return Center(
      child: SizedBox(
        //width: 10,
        child: Checkbox(
          value: checkBoxes[index] == 1 ? true : false,
          onChanged: (bool? value) {
            setState(() {
              checkBoxes[index] = checkBoxes[index] == 1 ? 0 : 1;
              gradeQuestions();
              saveCheckBoxes(widget.marksheetID);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 120,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                  ),
                ),
              ),
              //残り時間
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isTimeLimitEnabled
                      ? const Text(
                          '残り時間',
                          style: const TextStyle(fontSize: 10),
                        )
                      : const Text(
                          '経過時間',
                          style: const TextStyle(fontSize: 10),
                        ),
                  Text(
                    formatTime(remainingTime),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              // HomeScreen に戻る処理
              if (hasStarted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('テストが実行中です！'),
                      content: Text('ホーム画面に戻るとタイマーがリセットされます！\n(回答データは残ります！)'),
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
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                                (route) => false,
                              );
                            })
                      ],
                    );
                  },
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('現在のデータを共有しますか？'),
                      
                      actions: <Widget>[
                        GestureDetector(
                          child: Text('いいえ'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(),
                        GestureDetector(
                            child: Text('はい'),
                            onTap: () {
                              shareMarksheet(widget.marksheetID);
                              Navigator.pop(context);
                            })
                      ],
                    );
                  },
                );
                
              },
            ),
            IconButton(
              icon: Icon(Icons.settings), // 設定アイコン
              onPressed: () async {
                try {
                  // データベースから現在のマークシート情報を取得
                  final marksheetData =
                      await DatabaseHelper().getMarksheet(widget.marksheetID);

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
            // ボタンを等を配置する部分
            Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: buildControlButtons()),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Table(
                    border: TableBorder(
                      horizontalInside:
                          BorderSide(color: Colors.grey, width: 2.0),
                      verticalInside: BorderSide(color: Colors.grey, width: 2),
                      top: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3),
                      bottom: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3),
                      left: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3),
                      right: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3),
                    ),
                    columnWidths: const {
                      0: FixedColumnWidth(35),
                      2: FixedColumnWidth(35),
                    },
                    children: List.generate(numCellRows, (index) {
                      final Color rowColor = (index % 2 == 0)
                          ? Colors.grey[200]!
                          : Colors.white; //行ごとに少し色変える
                      return TableRow(
                        decoration: BoxDecoration(
                          color: rowColor,

                          //border: Border.all(width: 0.1, color: Colors.yellow),
                        ),
                        children: [
                          // 左側の行番号
                          TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.fill, // 行全体の高さに合わせる
                            child: buildQuestionNumber(index),
                          ),

                          // マークが並んだセル
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment
                                .middle, //セルの位置をちょうど真ん中に
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: buildMarkBox(index),
                              ),
                            ),
                          ),

                          //チェックボックス
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.fill,
                            child: buildcheckBox(index),
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
                color: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "得点",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    Text(
                      "$correctCount / ${numCellRows}",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
