import 'dart:convert';

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
      // lottie는 decoder 동일성까지 캐시 키로 쓰므로 강조색마다 같은 함수를 재사용한다
      decoder: _decoders.putIfAbsent(
          accent, () => (bytes) => _decodeWithGradients(bytes, accent)),
    );
  }

  static final _decoders = <Color, LottieDecoder>{};

  /// 그라디언트는 델리게이트로 원래 색을 받을 수 없어서, 읽어 들일 때 JSON의 색 정지점을 직접 바꾼다.
  static Future<LottieComposition?> _decodeWithGradients(
      List<int> bytes, Color accent) {
    final remap = _remapper(accent);
    final json = jsonDecode(utf8.decode(bytes));

    // [pos, r, g, b] * p 개 뒤에 불투명도 정지점이 올 수 있다. 색 부분만 바꾼다.
    void recolor(List stops, int p) {
      for (var i = 0; i + 3 < stops.length && i < p * 4; i += 4) {
        final c = remap(Color.from(
          alpha: 1,
          red: (stops[i + 1] as num).toDouble(),
          green: (stops[i + 2] as num).toDouble(),
          blue: (stops[i + 3] as num).toDouble(),
        ));
        stops[i + 1] = c.r;
        stops[i + 2] = c.g;
        stops[i + 3] = c.b;
      }
    }

    void walk(Object? o) {
      if (o is Map) {
        final g = o['g'];
        if ((o['ty'] == 'gf' || o['ty'] == 'gs') && g is Map) {
          final p = g['p'] as int;
          final k = (g['k'] as Map)['k'] as List;
          if (k.isNotEmpty && k.first is Map) {
            // 애니메이션되는 그라디언트: 키프레임마다 s(시작)/e(끝) 값
            for (final kf in k) {
              for (final key in const ['s', 'e']) {
                if (kf[key] is List) recolor(kf[key] as List, p);
              }
            }
          } else {
            recolor(k, p);
          }
        }
        o.values.forEach(walk);
      } else if (o is List) {
        o.forEach(walk);
      }
    }

    walk(json);
    return LottieComposition.fromBytes(utf8.encode(jsonEncode(json)));
  }

  /// 파랑/보라 계열만 강조색 색상으로 옮긴다. 밝기는 유지.
  static Color Function(Color) _remapper(Color accent) {
    final target = HSLColor.fromColor(accent);
    return (Color c) {
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
    };
  }

  /// 파랑/보라 → 강조색 색상으로 옮기는 델리게이트 묶음
  static List<ValueDelegate> paletteDelegates(Color accent) {
    final remap = _remapper(accent);

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
      // 그라디언트는 델리게이트로 바꾸면 예외가 나서 _decodeWithGradients에서 처리한다.
    ];
  }
}
