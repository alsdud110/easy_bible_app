import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 앱 팔레트에 맞춰 색을 덮어쓰는 Lottie.
///
/// 에셋 파일은 그대로 두고, 렌더링할 때 파랑~보라 계열 색만
/// 강조색(가름끈 버건디)의 색상으로 옮긴다. 원래 밝기는 유지해서
/// 그림의 명암과 입체감은 남는다. 초록·노랑 등 다른 색과 회색은 그대로.
class ThemedLottie extends StatelessWidget {
  final String name;
  final AnimationController? controller;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool? repeat;
  final bool? animate;
  final void Function(LottieComposition)? onLoaded;
  final Alignment? alignment;

  const ThemedLottie.asset(
    this.name, {
    super.key,
    this.controller,
    this.width,
    this.height,
    this.fit,
    this.repeat,
    this.animate,
    this.onLoaded,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Lottie.asset(
      name,
      controller: controller,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      onLoaded: onLoaded,
      alignment: alignment,
      delegates: LottieDelegates(values: paletteDelegates(accent)),
    );
  }

  /// 파랑/보라 → 강조색 색상으로 옮기는 델리게이트 묶음
  static List<ValueDelegate> paletteDelegates(Color accent) {
    final target = HSLColor.fromColor(accent);

    Color remap(Color c) {
      final hsl = HSLColor.fromColor(c);
      final isBluePurple =
          hsl.saturation >= 0.2 && hsl.hue >= 180 && hsl.hue <= 330;
      if (!isBluePurple) return c;
      return hsl
          .withHue(target.hue)
          // 채도는 강조색 수준을 넘지 않게 눌러서 형광 느낌을 없앤다
          .withSaturation(
              (hsl.saturation * 0.8).clamp(0.0, target.saturation))
          .toColor();
    }

    // 키프레임 사이의 현재 색 (원래 색)
    Color current(Color? start, Color? end, double t) {
      if (start == null) return Colors.transparent;
      return Color.lerp(start, end ?? start, t) ?? start;
    }

    return [
      ValueDelegate.color(const ['**'],
          callback: (i) => remap(current(
              i.startValue, i.endValue, i.interpolatedKeyframeProgress))),
      ValueDelegate.strokeColor(const ['**'],
          callback: (i) => remap(current(
              i.startValue, i.endValue, i.interpolatedKeyframeProgress))),
      // shortcut: 그라디언트는 lottie가 콜백에 원래 색을 넘겨주지 않아(빈 리스트 →
      // colors/colorStops 길이 불일치 예외) 원래 색 그대로 둔다. 바꾸려면 에셋을 직접 수정.
    ];
  }
}
