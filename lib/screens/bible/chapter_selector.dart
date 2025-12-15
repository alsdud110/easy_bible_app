import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../providers/language_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/breadcrumb_bar.dart';
import '../../widgets/banner_ad_widget.dart';

class ChapterSelector extends StatefulWidget {
  final BibleData book;
  final void Function(int chapterIdx) onSelect;
  final VoidCallback onBack;
  final void Function(int bookIdx, int chapter, int verse)? onDirectNavigate;
  final Widget? bannerAdWidget;

  const ChapterSelector({
    required this.book,
    required this.onSelect,
    required this.onBack,
    this.onDirectNavigate,
    this.bannerAdWidget,
    super.key,
  });

  @override
  State<ChapterSelector> createState() => _ChapterSelectorState();
}

class _ChapterSelectorState extends State<ChapterSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant ChapterSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 언어가 변경되면 애니메이션 재실행
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          languageProvider.isKorean
              ? '${widget.book.getLocalizedFullName(true)} (장 선택)'
              : '${widget.book.getLocalizedFullName(false)} (Select Chapter)',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: BackButton(
          onPressed: widget.onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Text(
                languageProvider.isKorean ? 'Eng' : '한',
                key: ValueKey(languageProvider.isKorean),
                style: TextStyle(
                  fontSize: ResponsiveUtils.buttonFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: theme.appBarTheme.iconTheme?.color ?? cs.onSurface,
                ),
              ),
            ),
            tooltip: languageProvider.isKorean ? 'English' : '한글',
            onPressed: () async {
              await languageProvider.toggleLanguage();
            },
          ),
        ],
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              BreadcrumbBar(
                items: [
                  BreadcrumbItem(
                    label: languageProvider.isKorean ? '홈' : 'Home',
                    onTap: widget.onBack,
                  ),
                  BreadcrumbItem(
                    label: widget.book.getLocalizedFullName(languageProvider.isKorean),
                    onTap: () {},
                    isActive: true,
                  ),
                ],
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.37,
                  ),
                  itemCount: widget.book.chapters,
                  itemBuilder: (context, i) {
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 900 + (i * 60)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.7 + (value * 0.3),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () => widget.onSelect(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: cs.secondary.withOpacity(0.33)),
                            boxShadow: [
                              BoxShadow(
                                color: cs.secondary.withOpacity(0.09),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.bodyFontSize(context),
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 부모에서 전달받은 배너 위젯 사용 (없으면 새로 생성)
              widget.bannerAdWidget ?? const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
