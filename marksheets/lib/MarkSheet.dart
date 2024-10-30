import 'package:flutter/material.dart';


int numMarks = 10; //各解答番号（各行）ごとのマークの数

class Marksheet extends StatefulWidget {
  const Marksheet({
    super.key, 
    required this.title,
    required this.numCellRows
    });

  final String title;
  final int numCellRows; //表示する行数

  @override
  State<Marksheet> createState() => _Marksheet();
}

class _Marksheet extends State<Marksheet> {

  //各回答ごとのマーク
  late List<List<Color>> markColors;
  late List<int?> selectedMark;

  @override 
  void initState(){ //widgetプロパティを使うため
  super.initState();
  markColors = List.generate(
    widget.numCellRows, 
    (indexCellRows) => List.generate(numMarks, (indexMarks) => Colors.white)); 
  
  //各問題の現在の選択．1つの回答欄行に複数選択するのを防ぐため必要．
  selectedMark = List.generate(widget.numCellRows,(index) => null);
  }
  // MarkBoxセル生成
  List<Widget> buildMarkBox(int indexCellRow) {
    return List.generate(numMarks, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: (){
            setState(() {
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
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black38 ),
            ),
            child: CircleAvatar(
              radius: 10,
              backgroundColor: markColors[indexCellRow][index],
              child: Text(
                '$index',
                style: TextStyle(fontSize: 10.5, color: Colors.black87),
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
      appBar: AppBar(title: Text(widget.title)),
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