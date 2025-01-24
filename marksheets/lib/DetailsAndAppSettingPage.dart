import 'package:flutter/material.dart';
import 'package:marksheets/openMail.dart';
import 'AppInfoPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'openMail.dart';

class DetailsAndAppSettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 設定セクション
              _buildSection(
                title: '設定',
                context: context,
                children: [
                  ListTile(
                    title: Text('テーマカラー'),
                    trailing: Icon(Icons.color_lens),
                    onTap: () {
                      // アクション
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // その他セクション
              _buildSection(
                title: 'その他',
                context: context,
                children: [
                  ListTile(
                    title: Text('利用規約'),
                    onTap: () {
                      // アクション
                    },
                  ),
                  ListTile(
                    title: Text('プライバシーポリシー'),
                    onTap: () {
                      // アクション
                    },
                  ),
                  ListTile(
                    title: Text('ライセンス'),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'まーくしーと！',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                  ListTile(
                    title: Text('お問い合わせ'),
                    onTap: () async {
                      
                      if (!await OpenMail().openmail()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('メールアプリを開けませんでした'),
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
              const SizedBox(height: 16),

              // アプリのバージョンセクション
              _buildSection(
                title: 'アプリのバージョン',
                context: context,
                children: [
                  ListTile(
                    title: Text('Version: 1.0.0'),
                    onTap: () {
                      // アクション
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppInfoPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // セクションを作成する共通メソッド
  Widget _buildSection({
    required String title,
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary, //.withOpacity(0.5),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(), // タイトルの下に区切り線を追加
          ...children, // 子ウィジェットを展開
        ],
      ),
    );
  }
}
