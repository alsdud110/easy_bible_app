import 'package:flutter/material.dart';

class Day180Screen extends StatelessWidget {
  const Day180Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final dayList = List.generate(180, (i) => 'DAY ${i + 1} 읽기 본문 샘플');
    return Scaffold(
      appBar: AppBar(title: const Text('성경일독 DAY180')),
      body: ListView.builder(
        itemCount: dayList.length,
        itemBuilder: (_, idx) => ListTile(
          title: Text(dayList[idx]),
        ),
      ),
    );
  }
}
