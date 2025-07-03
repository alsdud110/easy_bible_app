import 'package:flutter/material.dart';
import '../../models/bible_data.dart';

// (ChapterSelector 등 필요한 import 추가)

void pushModernTransition(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade =
            CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final scale = Tween<double>(begin: 0.98, end: 1.0).animate(animation);
        final offset =
            Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: offset,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 290),
      reverseTransitionDuration: const Duration(milliseconds: 230),
    ),
  );
}

class BookSelector extends StatefulWidget {
  final List<BibleData> books;
  final void Function(int idx) onSelect;
  const BookSelector({required this.books, required this.onSelect, super.key});

  @override
  State<BookSelector> createState() => _BookSelectorState();
}

class _BookSelectorState extends State<BookSelector> {
  bool isGrid = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oldBooks = widget.books.where((b) => b.isOldTestament).toList();
    final newBooks = widget.books.where((b) => !b.isOldTestament).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('성경책 선택'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        iconTheme: theme.appBarTheme.iconTheme,
        actionsIconTheme: theme.appBarTheme.actionsIconTheme,
        actions: [
          Row(
            children: [
              _modeBtn(
                  '그리드', isGrid, () => setState(() => isGrid = true), theme),
              _modeBtn(
                  '목록', !isGrid, () => setState(() => isGrid = false), theme),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          const _SectionTitle(title: '구약'),
          isGrid
              ? _BookGrid(
                  books: oldBooks,
                  onSelect: (idx) {
                    widget.onSelect(idx); // 기존 콜백 사용
                  },
                  offset: 0,
                )
              : _BookList(
                  books: oldBooks,
                  onSelect: (idx) {
                    widget.onSelect(idx);
                  },
                  offset: 0,
                ),
          const _SectionTitle(title: '신약'),
          isGrid
              ? _BookGrid(
                  books: newBooks,
                  onSelect: (idx) => widget.onSelect(idx + oldBooks.length),
                  offset: 0,
                )
              : _BookList(
                  books: newBooks,
                  onSelect: (idx) => widget.onSelect(idx + oldBooks.length),
                  offset: 0,
                ),
        ],
      ),
    );
  }

  Widget _modeBtn(
      String text, bool selected, VoidCallback onTap, ThemeData theme) {
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? cs.primary : cs.secondary.withOpacity(0.65),
              width: 1.1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title, super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.09),
            blurRadius: 9,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
          letterSpacing: 1.2,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<BibleData> books;
  final void Function(int idx) onSelect;
  final int offset;
  const _BookGrid({
    required this.books,
    required this.onSelect,
    required this.offset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.45,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => onSelect(i + offset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.32)),
          ),
          alignment: Alignment.center,
          child: Text(
            books[i].name,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: theme.colorScheme.primary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BibleData> books;
  final void Function(int idx) onSelect;
  final int offset;
  const _BookList({
    required this.books,
    required this.onSelect,
    required this.offset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: theme.dividerColor, thickness: 1.0),
      itemBuilder: (context, i) => ListTile(
        onTap: () => onSelect(i + offset),
        title: Text(
          books[i].fullName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        trailing: Icon(Icons.chevron_right,
            size: 20, color: theme.colorScheme.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        tileColor: theme.colorScheme.surface,
      ),
    );
  }
}
