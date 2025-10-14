import 'package:flutter/material.dart';
import '../../widgets/breadcrumb_bar.dart'; // ✅ 추가

class VerseSelector extends StatelessWidget {
  final String bookFullName;
  final int chapter;
  final int verseCount;
  final void Function(int verseIdx) onSelect;
  final VoidCallback onBack;
  final VoidCallback? onGoHome; // ✅ 추가

  const VerseSelector({
    required this.bookFullName,
    required this.chapter,
    required this.verseCount,
    required this.onSelect,
    required this.onBack,
    this.onGoHome, // ✅ 추가
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$bookFullName $chapter장(절 선택)',
          style: theme.appBarTheme.titleTextStyle,
        ),
        leading: BackButton(
          onPressed: onBack,
          color: theme.appBarTheme.iconTheme?.color,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        centerTitle: theme.appBarTheme.centerTitle ?? true,
      ),
      body: Column(
        children: [
          BreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: '홈',
                onTap: onGoHome, // ✅ 책 선택으로
              ),
              BreadcrumbItem(
                label: bookFullName, // ✅ 이미 fullName
                onTap: () {
                  // ✅ Chapter Selector로 이동 (onBack 호출)
                  onBack();
                },
              ),
              BreadcrumbItem(
                label: '$chapter장',
                onTap: () {}, // 현재 페이지
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
              itemCount: verseCount,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.secondary.withOpacity(0.33)),
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
            ),
          ),
        ],
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
