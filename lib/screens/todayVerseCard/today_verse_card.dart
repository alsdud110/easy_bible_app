import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/today_verse_model.dart';

class TodayVerseCard extends StatefulWidget {
  const TodayVerseCard({super.key});

  @override
  State<TodayVerseCard> createState() => _TodayVerseCardState();
}

class _TodayVerseCardState extends State<TodayVerseCard>
    with TickerProviderStateMixin {
  String? verse;
  String? ref;
  int? pendingIdx;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _sizeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 270),
    )..value = 1.0;
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _sizeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _loadTodayVerse();
  }

  Future<void> _loadTodayVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastPickDate = prefs.getString('lastVerseDate');
    final verseIdx = prefs.getInt('todayVerseIdx');

    if (lastPickDate == '${today.year}-${today.month}-${today.day}' &&
        verseIdx != null) {
      setState(() {
        verse = todayVerses[verseIdx].text;
        ref = todayVerses[verseIdx].ref;
      });
    } else {
      setState(() {
        verse = null;
        ref = null;
      });
    }
  }

  Future<void> _pickVerse() async {
    final idx = Random().nextInt(todayVerses.length);
    setState(() {
      pendingIdx = idx;
    });

    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierLabel: "오늘의 구절",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.22),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: 0.97 + curved.value * 0.03,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 34),
                      const SizedBox(height: 10),
                      Text(
                        "오늘의 구절",
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 21,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.93),
                            ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 13),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.09),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          todayVerses[idx].ref,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 15.2,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        todayVerses[idx].text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16.7,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.98),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            // Fade out → 내용 변경 → Fade in
                            await _fadeCtrl.reverse();
                            final prefs = await SharedPreferences.getInstance();
                            final today = DateTime.now();
                            await prefs.setString('lastVerseDate',
                                '${today.year}-${today.month}-${today.day}');
                            await prefs.setInt('todayVerseIdx', idx);
                            setState(() {
                              verse = todayVerses[idx].text;
                              ref = todayVerses[idx].ref;
                              pendingIdx = null;
                            });
                            await _fadeCtrl.forward();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              const Text('확인', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetVerse() async {
    await _fadeCtrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('todayVerseIdx');
    await prefs.remove('lastVerseDate');
    setState(() {
      verse = null;
      ref = null;
    });
    await _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 각 상태별로 min/max height를 맞춤 (ex: 뽑기와 구절 보여줄 때 크기가 달라도 부드럽게)
    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 16),
          color: cs.surface,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: verse == null
                    ? _TodayVerseEmptyCard(onTap: _pickVerse)
                    : _TodayVerseShowCard(ref: ref, verse: verse),
              ),
              if (verse != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: Icon(Icons.refresh_rounded, color: cs.primary),
                    tooltip: '오늘의 구절 다시 뽑기',
                    onPressed: _resetVerse,
                    splashRadius: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 오늘의 구절 뽑기 카드
class _TodayVerseEmptyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayVerseEmptyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        key: const ValueKey("pick"),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.035),
              cs.surface.withOpacity(0.98)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.03),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 34, color: cs.primary),
            const SizedBox(height: 14),
            Text(
              '오늘의 구절 뽑기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.2,
                  color: cs.primary),
            ),
            const SizedBox(height: 7),
            Text(
              '하루에 한 번, 하나님이 주시는 말씀을 받아보세요!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 오늘의 구절 보여주는 카드
class _TodayVerseShowCard extends StatefulWidget {
  final String? ref;
  final String? verse;
  const _TodayVerseShowCard({this.ref, this.verse});

  @override
  State<_TodayVerseShowCard> createState() => _TodayVerseShowCardState();
}

class _TodayVerseShowCardState extends State<_TodayVerseShowCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _shineCtrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _SheenPainter(progress: _shineCtrl.value),
          child: child, // ← 반드시 child 써줘야 구절 내용 나옴!
        );
      },
      // child 부분에 카드 내용 전부 넣기
      child: Container(
        key: const ValueKey("verse"),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.035),
              cs.surface.withOpacity(0.99)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.03),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 11),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                widget.ref ?? "",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              widget.verse ?? "",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    height: 1.7,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 13),
            Text(
              '내일이 되면 새롭게 받을 수 있어요!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.72),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. 사선 빛나는 효과 Painter 추가
class _SheenPainter extends CustomPainter {
  final double progress;
  _SheenPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Rect.fromLTWH(0, 0, width, height);

    final borderRadius = BorderRadius.circular(20);
    final rrect = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);

    // 왼쪽 위~중앙, 중앙~오른쪽 아래로 구간 나누기
    double cx, cy, radius;
    if (progress < 0.5) {
      // 0~0.5: 점점 중앙으로 오고 커짐/밝아짐
      final p = progress / 0.7; // 0~1
      cx = lerpDouble(0.0, width / 2, p)!;
      cy = lerpDouble(0.0, height / 2, p)!;
      radius = lerpDouble(width * 0.70, width * 0.92, p)!;
    } else {
      // 0.5~1.0: 중앙~오른쪽 아래로 가며 점점 사라짐
      final p = (progress - 0.5) / 0.5; // 0~1
      cx = lerpDouble(width / 2, width, p)!;
      cy = lerpDouble(height / 2, height, p)!;
      radius = lerpDouble(width * 0.70, width * 0.92, p)!;
    }

    final gradient = RadialGradient(
      center: Alignment((cx / width) * 2 - 1, (cy / height) * 2 - 1),
      radius: radius / width,
      colors: [
        Colors.white.withOpacity(0.4),
        Colors.white.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.57, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
          .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
      ..blendMode = BlendMode.lighten;

    canvas.drawRect(rect, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// lerpDouble은 dart:ui 또는 math에 없으면 직접 구현
double? lerpDouble(num a, num b, double t) => a * (1.0 - t) + b * t;
