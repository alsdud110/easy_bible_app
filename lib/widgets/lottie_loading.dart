import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 로딩 중 표시할 Lottie 애니메이션 위젯
class LottieLoading extends StatelessWidget {
  final String? message;
  final double size;

  const LottieLoading({
    super.key,
    this.message,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
