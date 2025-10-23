import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../providers/language_provider.dart';
import '../../widgets/breadcrumb_bar.dart';

class VerseSelector extends StatefulWidget {
  final BibleData book;
  final int chapter;
  final int verseCount;
  final void Function(int verseIdx) onSelect;
  final VoidCallback onBack;
  final VoidCallback? onGoHome;

  const VerseSelector({
    required this.book,
    required this.chapter,
    required this.verseCount,
    required this.onSelect,
    required this.onBack,
    this.onGoHome,
    super.key,
  });

  @override
  State<VerseSelector> createState() => _VerseSelectorState();
}

class _VerseSelectorState extends State<VerseSelector>
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
              ? '${widget.book.getLocalizedFullName(true)} ${widget.chapter}장(절 선택)'
              : '${widget.book.getLocalizedFullName(false)} ${widget.chapter} (Select Verse)',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: BackButton(
          onPressed: widget.onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
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
                    onTap: widget.onGoHome,
                  ),
                  BreadcrumbItem(
                    label: widget.book.getLocalizedFullName(languageProvider.isKorean),
                    onTap: () {
                      widget.onBack();
                    },
                  ),
                  BreadcrumbItem(
                    label: languageProvider.isKorean ? '${widget.chapter}장' : 'Ch ${widget.chapter}',
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
                  itemCount: widget.verseCount,
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
                          child: Text(
                            '${i + 1}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        tooltip: '책 선택으로',
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.menu_book),
      ),
    );
  }
}
