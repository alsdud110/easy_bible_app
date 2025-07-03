// screens/easyBible/easy_bible_screen.dart
import 'package:flutter/material.dart';

class EasyBibleHomeScreen extends StatelessWidget {
  const EasyBibleHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('어성경 바이블')),
      body: const Center(child: Text('여기에 어성경 바이블 콘텐츠 구현!')),
    );
  }
}
