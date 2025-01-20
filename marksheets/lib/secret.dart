import 'package:flutter/material.dart';
import 'ImageScreen.dart';
//import 'package:url_launcher/url_launcher.dart';
class SecretCode{
  final List<int> _targetCodePoints = [
    25298,
    32118,
    21329, 
    29477,  
  ];


  bool checkInput(String inputtext ,BuildContext context) {

    // 入力された文字列を文字コードリストに変換
    final inputCodePoints = inputtext.codeUnits;

    // 判定する文字列のコードポイントと比較
    if(inputCodePoints.length >= 4){
    if (_listEquals(inputCodePoints, _targetCodePoints)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImageScreen()),
      );
      return true;
    }
    }
    return false;
  }
    /*
    if (_listEquals(inputCodePoints, _targetCodePoints)) {
      final url = Uri.parse('https://x.com/bakusatu_hiwai');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } 
    }
  }*/

  // リストの内容を比較する関数
  bool _listEquals(List<int> list1, List<int> list2) {
    print('${list1} and ${list2}');
    for (int i = 0; i < 4; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}