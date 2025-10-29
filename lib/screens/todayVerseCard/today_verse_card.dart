import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/today_verse_model.dart';
import 'package:lottie/lottie.dart';

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
  late AnimationController _shineCtrl; // 여기로 옮김!

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
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 4초 → 2초로 더 빠르게!
    )..repeat();
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
                      Lottie.asset(
                        'assets/lottie/pray.json',
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
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
                                fontFamily: 'ChosunCentennial',
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
                              fontFamily: 'ChosunCentennial',
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
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            Card(
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
            // 빛 효과 - Card 위에 오버레이
            if (verse != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _shineCtrl,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _SimpleGlowPainter(
                              progress: _shineCtrl.value,
                              primaryColor: cs.primary, // primary 색상 전달
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
              color: cs.primary.withOpacity(0.43),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: Transform.scale(
                  scale: 3.0,
                  child: Lottie.asset(
                    'assets/lottie/loading.json',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
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
                  ?.copyWith(color: cs.onSurface.withOpacity(0.75)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 오늘의 구절 보여주는 카드
class _TodayVerseShowCard extends StatelessWidget {
  final String? ref;
  final String? verse;
  const _TodayVerseShowCard({this.ref, this.verse});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey("verse"),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
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
                ref ?? "",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ChosunCentennial',
                    ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              verse ?? "",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'ChosunCentennial',
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

// 은은한 빛 효과 Painter
class _SimpleGlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _SimpleGlowPainter({
    required this.progress,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 진행도에 따라 위치 변경 (더 빠르게 움직이게)
    final offset = size.width * 1.5 * progress - size.width * 0.4;

    // primary 색상으로 빛 효과 (더 촘촘하게)
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        primaryColor.withOpacity(0.03),
        primaryColor.withOpacity(0.06),
        primaryColor.withOpacity(0.12),
        primaryColor.withOpacity(0.13),
        primaryColor.withOpacity(0.12),
        primaryColor.withOpacity(0.06),
        primaryColor.withOpacity(0.03),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.2, 0.35, 0.4, 0.5, 0.65, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(offset - 100, 0, 200, size.height),
      )
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SimpleGlowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor;
}
