import 'package:easy_bible_app/widgets/themed_lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('그라디언트가 있는 로티도 예외 없이 그린다', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(
        home: ThemedLottie.asset('assets/lottie/Microsoft Designer.json',
            width: 100, height: 100),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
