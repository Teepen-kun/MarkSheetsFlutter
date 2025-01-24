import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoPage extends StatefulWidget {
  @override
  _AppInfoPageState createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String appName = '';
  String version = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchAppInfo();
  }

  Future<void> _fetchAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('アプリ情報')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('アプリ名: $appName', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('バージョン: $version', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('ビルド番号: $buildNumber', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
