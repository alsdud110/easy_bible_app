import 'package:flutter/material.dart';
import '../../models/bible_data.dart';
import '../../widgets/breadcrumb_bar.dart'; // ✅ 추가

class ChapterSelector extends StatelessWidget {
  final BibleData book;
  final void Function(int chapterIdx) onSelect;
  final VoidCallback onBack;

  const ChapterSelector({
    required this.book,
    required this.onSelect,
    required this.onBack,
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
          '${book.fullName} (장 선택)',
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
                onTap: onBack,
              ),
              BreadcrumbItem(
                label: book.fullName, // ✅ fullName으로 변경
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
              itemCount: book.chapters,
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
    );
  }
}
