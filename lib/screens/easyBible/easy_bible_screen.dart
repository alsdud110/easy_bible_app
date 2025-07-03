import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/bible_data.dart';
import 'book_selector.dart';
import 'chapter_selector.dart';
import 'verse_selector.dart';
import 'verse_list_view.dart';

class EasyBibleScreen extends StatefulWidget {
  const EasyBibleScreen({super.key});
  @override
  State<EasyBibleScreen> createState() => _EasyBibleScreenState();
}

class _EasyBibleScreenState extends State<EasyBibleScreen> {
  int step = 0; // 0:책, 1:장, 2:절, 3:장전체(절선택)
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
    bibleBookList = bibleBooks; // models/bible_data.dart에서 import
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

  Widget _buildStepScreen() {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (step == 0) {
      return BookSelector(
        books: bibleBookList,
        onSelect: (idx) {
          setState(() {
            selectedBook = idx;
            step = 1;
          });
        },
      );
    } else if (step == 1) {
      final book = bibleBookList[selectedBook];
      return ChapterSelector(
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
      );
    } else if (step == 3) {
      final book = bibleBookList[selectedBook];
      final chapterNum = selectedChapter + 1;
      final verses = bibleMap[book.name]?[chapterNum] ?? {};
      return VerseListView(
        book: book,
        chapter: chapterNum,
        verses: verses,
        selectedVerse: selectedVerse + 1,
        onBack: () => setState(() => step = 2),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _buildStepScreen(),
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
