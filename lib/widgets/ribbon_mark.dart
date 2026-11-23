import 'package:flutter/material.dart';

/// 가름끈 표시 (앱의 시그니처 디테일).
/// 성경책의 붉은 가름끈처럼 "지금 여기까지 읽고 있음"을 표시한다.
/// 진행 중인 플랜, 오늘 읽을 날처럼 현재 위치에만 쓰고, 장식으로는 쓰지 않는다.
class RibbonMark extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const RibbonMark({super.key, this.width = 10, this.height = 22, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _RibbonPainter(color ?? Theme.of(context).colorScheme.primary),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final Color color;
  _RibbonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final notch = size.width * 0.5;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - notch)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.color != color;
}
