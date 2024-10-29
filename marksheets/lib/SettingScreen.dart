import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'MarkSheet.dart';


class SettingScreen extends StatefulWidget{
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreen();
}

class _SettingScreen extends State<SettingScreen>{
  final TextEditingController _marksheetnameController = TextEditingController();
  final TextEditingController _numberofquestionController = TextEditingController();

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          TextField(
              controller: _marksheetnameController,
              decoration: InputDecoration(labelText: 'Mark Sheet Name'),//MarkSheetの名前
            ),
          SizedBox(height: 20),
          TextField(
              controller: _numberofquestionController,
              decoration: InputDecoration(labelText: '問題数'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], //数値限定
            ),
          SizedBox(height: 20),
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
}