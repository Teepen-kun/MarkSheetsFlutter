import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
      body: Center(
        child: Image.asset(
          'assets/images/QRofGOD.png', 
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
