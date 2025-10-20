import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/bible_data.dart';
import 'book_selector.dart';
import 'chapter_selector.dart';
import 'verse_selector.dart';
import 'verse_list_view.dart';

class BibleHomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDark;

  const BibleHomeScreen({
    super.key,
    this.onThemeToggle,
    this.isDark = false,
  });

  @override
  State<BibleHomeScreen> createState() => _BibleHomeScreenState();
}

class _BibleHomeScreenState extends State<BibleHomeScreen> {
  int step = 0;
  int selectedBook = -1;
  int selectedChapter = -1;
  int selectedVerse = -1;

  List<BibleData> bibleBookList = [];
  Map<String, Map<int, Map<int, String>>> bibleMap = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBible();
  }

  Future<void> _initBible() async {
    bibleBookList = bibleBooks;
    bibleMap = await loadBibleByStructure();
    setState(() {
      isLoading = false;
    });
  }

  void _reset() {
    setState(() {
      step = 0;
      selectedBook = -1;
      selectedChapter = -1;
      selectedVerse = -1;
    });
  }

  void _goToChapterSelector() {
    setState(() {
      step = 1;
      selectedChapter = -1;
      selectedVerse = -1;
    });
  }

  void _goToVerseSelector() {
    setState(() {
      step = 2;
      selectedVerse = -1;
    });
  }

  void _navigateToChapter(int bookIdx, int chapter) {
    setState(() {
      selectedBook = bookIdx;
      selectedChapter = chapter - 1; // 0-based index
      selectedVerse = -1;
      step = 2; // VerseSelector로
    });
  }

  void _navigateDirectlyToVerse(int bookIdx, int chapter, int verse) {
    final book = bibleBookList[bookIdx];
    final verses = bibleMap[book.name]?[chapter] ?? {};

    if (verses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName} $chapter장을 불러올 수 없습니다'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 절 범위 체크
    if (verse < 1 || verse > verses.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName} $chapter장은 ${verses.length}절까지 있습니다'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      selectedBook = bookIdx;
      selectedChapter = chapter - 1; // 0-based index
      selectedVerse = verse - 1; // 0-based index
      step = 3;
    });
  }

  Widget _buildStepScreen() {
    if (isLoading) {
      return const Scaffold(
        key: ValueKey('loading'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (step == 0) {
      return BookSelector(
        key: const ValueKey('book'),
        books: bibleBookList,
        onSelect: (idx) {
          setState(() {
            selectedBook = idx;
            step = 1; // ChapterSelector로
          });
        },
        onDirectNavigate: _navigateDirectlyToVerse,
        onChapterNavigate: _navigateToChapter,
        onThemeToggle: widget.onThemeToggle,
        isDark: widget.isDark,
      );
    } else if (step == 1) {
      final book = bibleBookList[selectedBook];
      return ChapterSelector(
        key: ValueKey('chapter-$selectedBook'),
        book: book,
        onSelect: (chapter) {
          setState(() {
            selectedChapter = chapter;
            step = 2;
          });
        },
        onBack: _reset,
      );
    } else if (step == 2) {
      final book = bibleBookList[selectedBook];
      final chapterNum = selectedChapter + 1;
      final verseCount = bibleMap[book.name]?[chapterNum]?.length ?? 0;
      return VerseSelector(
        key: ValueKey('verse-$selectedBook-$selectedChapter'),
        bookFullName: book.fullName,
        chapter: chapterNum,
        verseCount: verseCount,
        onSelect: (verse) {
          setState(() {
            selectedVerse = verse;
            step = 3;
          });
        },
        onBack: () => setState(() => step = 1),
        onGoHome: _reset,
      );
    } else if (step == 3) {
      final book = bibleBookList[selectedBook];
      final chapterNum = selectedChapter + 1;
      final verses = bibleMap[book.name]?[chapterNum] ?? {};
      return VerseListView(
        key: ValueKey('list-$selectedBook-$selectedChapter-$selectedVerse'),
        book: book,
        chapter: chapterNum,
        verses: verses,
        selectedVerse: selectedVerse + 1,
        onBack: () => setState(() => step = 2),
        onChapterChanged: (newChapter) {
          setState(() {
            selectedChapter = newChapter - 1;
            selectedVerse = 0; // 1절로 초기화 (0-based index이므로 0)
            step = 3;
          });
        },
        onGoToChapterSelector: _goToChapterSelector,
        onGoToVerseSelector: _goToVerseSelector,
        onGoHome: _reset,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildStepScreen(),
      ),
    );
  }
}

/// bible.json을 책/장/절 구조로 변환 (변경X)
Future<Map<String, Map<int, Map<int, String>>>> loadBibleByStructure() async {
  final String data = await rootBundle.loadString('assets/bible.json');
  final Map<String, dynamic> flat = json.decode(data);
  final Map<String, Map<int, Map<int, String>>> bible = {};

  final reg = RegExp(r'^([가-힣]+)(\d+):(\d+)$');
  flat.forEach((key, verse) {
    final match = reg.firstMatch(key);
    if (match == null) return;
    String book = match.group(1)!;
    int chapter = int.parse(match.group(2)!);
    int verseNum = int.parse(match.group(3)!);
    bible.putIfAbsent(book, () => {});
    bible[book]!.putIfAbsent(chapter, () => {});
    bible[book]![chapter]![verseNum] = verse;
  });

  return bible;
}
