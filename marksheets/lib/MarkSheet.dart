import 'package:flutter/material.dart';

int numCellRows = 50;  //表示する行数
int numMarks = 10; //マークの数

class Marksheet extends StatefulWidget {
  const Marksheet({super.key, required this.title});

  final String title;

  @override
  State<Marksheet> createState() => _Marksheet();
}

class _Marksheet extends State<Marksheet> {

  List<List<Color>> markColors = List.generate(
    numCellRows, 
    (indexCellRows) => List.generate(numMarks, (indexMarks) => Colors.white)); 
  // MarkBoxセル生成
  List<Widget> buildMarkBox(int indexMarks) {
    return List.generate(numMarks, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: GestureDetector(
          onTap: (){
            setState(() {
              markColors[indexMarks][index] = (markColors[indexMarks][index] == Colors.white) ? Colors.black38 : Colors.white;
            });
          },
          child: CircleAvatar(
            radius: 10,
            backgroundColor: markColors[indexMarks][index],
            child: Text(
              '$index',
              style: TextStyle(fontSize: 10.5, color: Colors.blue),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MarkSheet')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            border: TableBorder.all(color: Colors.grey), 
            columnWidths: const{
              0: FixedColumnWidth(40)
            },
            children: List.generate(numCellRows, (index) {
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