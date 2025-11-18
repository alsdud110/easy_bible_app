import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../providers/language_provider.dart';
import '../../utils/bible_key_converter.dart';
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

  Map<String, dynamic>? _fullBibleData;
  Map<int, String>? _currentChapterVerses;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBible();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // ⭐ mounted 체크
      final languageProvider = context.read<LanguageProvider>();
      languageProvider.addListener(_onLanguageChanged);
    });
  }

  @override
  void dispose() {
    try {
      final languageProvider = context.read<LanguageProvider>();
      languageProvider.removeListener(_onLanguageChanged);
    } catch (e) {
      // Provider가 이미 dispose된 경우 무시
    }
    super.dispose();
  }

  /// ⭐ 언어 변경 감지 콜백 (mounted 체크 추가)
  void _onLanguageChanged() async {
    if (!mounted) return;

    print('🔄 언어 변경 감지');

    // 현재 상태 저장
    final currentStep = step;
    final currentBook = selectedBook;
    final currentChapter = selectedChapter;
    final currentVerse = selectedVerse;

    setState(() {
      isLoading = true;
    });

    // JSON 다시 로드
    _fullBibleData = await _loadBibleJson(context);

    if (!mounted) return;

    // 현재 보고 있는 장이 있으면 재로드
    if (currentBook != -1 && currentChapter != -1) {
      final book = bibleBookList[currentBook];
      final chapterNum = currentChapter + 1;
      _currentChapterVerses = await _loadChapter(book.name, chapterNum);
    }

    if (!mounted) return;

    // ⭐ 현재 단계로 다시 설정하여 화면 재구성
    setState(() {
      step = currentStep;
      selectedBook = currentBook;
      selectedChapter = currentChapter;
      selectedVerse = currentVerse;
      isLoading = false;
    });

    print('✅ 언어 변경 완료');
  }

  Future<void> _initBible() async {
    bibleBookList = bibleBooks;
    _fullBibleData = await _loadBibleJson(context);

    if (!mounted) return; // ⭐ mounted 체크

    setState(() {
      isLoading = false;
    });
  }

  /// JSON 파일만 로드 (파싱은 나중에)
  Future<Map<String, dynamic>> _loadBibleJson(BuildContext context) async {
    final languageProvider = context.read<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    final String assetPath = currentLanguage == BibleLanguage.korean
        ? 'assets/bible.json'
        : 'assets/bible_kjv.json';

    print('📖 JSON 로드: $assetPath');

    final String data = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> flat = json.decode(data);

    print('✅ JSON 로드 완료: ${flat.length}개 구절');

    return flat;
  }

  /// 특정 장의 구절만 추출
  Future<Map<int, String>> _loadChapter(String bookName, int chapter) async {
    if (_fullBibleData == null) return {};

    final languageProvider = context.read<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    final Map<int, String> verses = {};

    String searchPrefix;
    if (currentLanguage == BibleLanguage.korean) {
      searchPrefix = '$bookName$chapter:';
    } else {
      final englishBookName = BookNameConverter.koreanToEnglish(bookName);
      searchPrefix = '$englishBookName$chapter:';
    }

    print('🔍 검색 Prefix: $searchPrefix (언어: ${currentLanguage.displayName})');

    _fullBibleData!.forEach((key, value) {
      if (key.startsWith(searchPrefix)) {
        final verseNumStr = key.substring(searchPrefix.length);
        final verseNum = int.tryParse(verseNumStr);
        if (verseNum != null) {
          verses[verseNum] = value as String;
        }
      }
    });

    print('📖 로드된 구절 수: ${verses.length}');
    if (verses.isEmpty) {
      print('❌ 구절을 찾을 수 없습니다!');
      print('🔍 첫 10개 키 샘플:');
      int count = 0;
      for (var key in _fullBibleData!.keys) {
        if (count++ >= 10) break;
        print('  - $key');
      }
    }

    return verses;
  }

  /// 장의 절 개수만 세기
  int _getVerseCount(String bookName, int chapter) {
    if (_fullBibleData == null) return 0;

    final languageProvider = context.read<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    int count = 0;
    String searchPrefix;

    if (currentLanguage == BibleLanguage.korean) {
      searchPrefix = '$bookName$chapter:';
    } else {
      final englishBookName = BookNameConverter.koreanToEnglish(bookName);
      searchPrefix = '$englishBookName$chapter:';
    }

    for (var key in _fullBibleData!.keys) {
      if (key.startsWith(searchPrefix)) {
        count++;
      }
    }

    return count;
  }

  void _reset() {
    if (!mounted) return; // ⭐ mounted 체크
    setState(() {
      step = 0;
      selectedBook = -1;
      selectedChapter = -1;
      selectedVerse = -1;
      _currentChapterVerses = null;
    });
  }

  void _goToChapterSelector() {
    if (!mounted) return; // ⭐ mounted 체크
    setState(() {
      step = 1;
      selectedChapter = -1;
      selectedVerse = -1;
      _currentChapterVerses = null;
    });
  }

  void _goToVerseSelector() {
    if (!mounted) return; // ⭐ mounted 체크
    setState(() {
      step = 2;
      selectedVerse = -1;
    });
  }

  void _navigateToChapter(int bookIdx, int chapter) {
    if (!mounted) return; // ⭐ mounted 체크
    setState(() {
      selectedBook = bookIdx;
      selectedChapter = chapter - 1;
      selectedVerse = -1;
      step = 2;
    });
  }

  void _navigateDirectlyToVerse(int bookIdx, int chapter, int verse) async {
    if (!mounted) return; // ⭐ mounted 체크

    final book = bibleBookList[bookIdx];

    setState(() {
      isLoading = true;
    });

    final verses = await _loadChapter(book.name, chapter);

    if (!mounted) return; // ⭐ 비동기 작업 후 mounted 체크

    if (verses.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName} $chapter장을 불러올 수 없습니다'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (verse < 1 || verse > verses.length) {
      setState(() {
        isLoading = false;
      });
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
      selectedChapter = chapter - 1;
      selectedVerse = verse - 1;
      _currentChapterVerses = verses;
      step = 3;
      isLoading = false;
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
          if (!mounted) return; // ⭐ mounted 체크
          setState(() {
            selectedBook = idx;
            step = 1;
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
          if (!mounted) return; // ⭐ mounted 체크
          setState(() {
            selectedChapter = chapter;
            step = 2;
          });
        },
        onBack: _reset,
        onDirectNavigate: _navigateDirectlyToVerse,
      );
    } else if (step == 2) {
      final book = bibleBookList[selectedBook];
      final chapterNum = selectedChapter + 1;
      final verseCount = _getVerseCount(book.name, chapterNum);

      return VerseSelector(
        key: ValueKey('verse-$selectedBook-$selectedChapter'),
        book: book,
        chapter: chapterNum,
        verseCount: verseCount,
        onSelect: (verse) async {
          if (!mounted) return; // ⭐ mounted 체크

          setState(() {
            isLoading = true;
          });

          final verses = await _loadChapter(book.name, chapterNum);

          if (!mounted) return; // ⭐ 비동기 작업 후 mounted 체크

          setState(() {
            selectedVerse = verse;
            _currentChapterVerses = verses;
            step = 3;
            isLoading = false;
          });
        },
        onBack: () {
          if (!mounted) return; // ⭐ mounted 체크
          setState(() => step = 1);
        },
        onGoHome: _reset,
        onDirectNavigate: _navigateDirectlyToVerse,
      );
    } else if (step == 3) {
      final book = bibleBookList[selectedBook];
      final chapterNum = selectedChapter + 1;

      return VerseListView(
        key: ValueKey('list-$selectedBook-$selectedChapter-$selectedVerse'),
        book: book,
        chapter: chapterNum,
        verses: _currentChapterVerses ?? {},
        selectedVerse: selectedVerse + 1,
        onBack: () {
          if (!mounted) return; // ⭐ mounted 체크
          setState(() => step = 2);
        },
        onChapterChanged: (newChapter) async {
          if (!mounted) return; // ⭐ mounted 체크

          setState(() {
            isLoading = true;
          });

          final verses = await _loadChapter(book.name, newChapter);

          if (!mounted) return; // ⭐ 비동기 작업 후 mounted 체크

          setState(() {
            selectedChapter = newChapter - 1;
            selectedVerse = 0;
            _currentChapterVerses = verses;
            step = 3;
            isLoading = false;
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
