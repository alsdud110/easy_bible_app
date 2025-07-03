import 'package:flutter/material.dart';

class Day60Screen extends StatelessWidget {
  const Day60Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final dayList = List.generate(60, (i) => 'DAY ${i + 1} 읽기 본문 샘플');
    return Scaffold(
      appBar: AppBar(title: const Text('성경일독 DAY60')),
      body: ListView.builder(
        itemCount: dayList.length,
        itemBuilder: (_, idx) => ListTile(
          title: Text(dayList[idx]),
        ),
      ),
    );
  }
}
