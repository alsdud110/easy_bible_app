import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../utils/bible_loader.dart';
import '../../utils/bible_key_converter.dart';
import '../../providers/language_provider.dart';
import '../screens/bible/verse_list_view.dart';

/// 성경 전체를 관리하는 메인 뷰
class BibleView extends StatefulWidget {
  const BibleView({super.key});

  @override
  State<BibleView> createState() => _BibleViewState();
}

class _BibleViewState extends State<BibleView> {
  // 현재 선택된 책, 장, 절
  BibleData? _selectedBook;
  int? _selectedChapter;
  int _selectedVerse = 1;

  // 현재 로드된 구절 데이터
  Map<int, String>? _currentVerses;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // LanguageProvider 변경 감지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageProvider = context.read<LanguageProvider>();
      languageProvider.addListener(_onLanguageChanged);
    });
  }

  @override
  void dispose() {
    final languageProvider = context.read<LanguageProvider>();
    languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// 언어 변경 시 호출되는 콜백
  void _onLanguageChanged() async {
    if (_selectedBook == null || _selectedChapter == null) return;

    setState(() {
      _isLoading = true;
    });

    // 동일한 책/장/절로 새로운 언어의 구절 로드
    await _loadVerses(_selectedBook!, _selectedChapter!);

    setState(() {
      _isLoading = false;
    });
  }

  /// 책 선택
  void _selectBook(BibleData book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _currentVerses = null;
    });
  }

  /// 장 선택
  void _selectChapter(int chapter) async {
    if (_selectedBook == null) return;

    setState(() {
      _selectedChapter = chapter;
      _selectedVerse = 1;
      _isLoading = true;
    });

    await _loadVerses(_selectedBook!, chapter);

    setState(() {
      _isLoading = false;
    });
  }

  /// 구절 로드
  Future<void> _loadVerses(BibleData book, int chapter) async {
    final languageProvider = context.read<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    // 현재 언어에 맞는 책 이름 결정
    String bookName;
    if (currentLanguage == BibleLanguage.korean) {
      bookName = book.name;
    } else {
      bookName = BookNameConverter.getEnglishName(book);
    }

    // 구절 로드
    final verses = await BibleVerseExtractor.extractVerses(
      currentLanguage,
      bookName,
      chapter,
    );

    setState(() {
      _currentVerses = verses;
    });
  }

  /// 장 변경 (이전/다음 장 버튼)
  void _onChapterChanged(int newChapter) {
    _selectChapter(newChapter);
  }

  /// 홈으로 이동 (책 선택 화면)
  void _goToHome() {
    setState(() {
      _selectedBook = null;
      _selectedChapter = null;
      _currentVerses = null;
    });
  }

  /// 장 선택 화면으로 이동
  void _goToChapterSelector() {
    setState(() {
      _selectedChapter = null;
      _currentVerses = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 책이 선택되지 않은 경우 - 책 선택 화면
    if (_selectedBook == null) {
      return _buildBookSelector();
    }

    // 장이 선택되지 않은 경우 - 장 선택 화면
    if (_selectedChapter == null) {
      return _buildChapterSelector();
    }

    // 구절이 로드 중인 경우
    if (_isLoading || _currentVerses == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로딩 중...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 구절 표시 화면
    return VerseListView(
      book: _selectedBook!,
      chapter: _selectedChapter!,
      verses: _currentVerses!,
      selectedVerse: _selectedVerse,
      onBack: _goToChapterSelector,
      onChapterChanged: _onChapterChanged,
      onGoToChapterSelector: _goToChapterSelector,
      onGoHome: _goToHome,
    );
  }

  /// 책 선택 화면 (구현 필요)
  Widget _buildBookSelector() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성경 책 선택'),
        actions: [
          _buildLanguageToggleButton(),
        ],
      ),
      body: ListView.builder(
        itemCount: bibleBooks.length,
        itemBuilder: (context, index) {
          final book = bibleBooks[index];
          return ListTile(
            title: Text(book.fullName),
            subtitle: Text(book.eng),
            trailing: Text('${book.chapters}장'),
            onTap: () => _selectBook(book),
          );
        },
      ),
    );
  }

  /// 장 선택 화면 (구현 필요)
  Widget _buildChapterSelector() {
    if (_selectedBook == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBook!.fullName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToHome,
        ),
        actions: [
          _buildLanguageToggleButton(),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _selectedBook!.chapters,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          return ElevatedButton(
            onPressed: () => _selectChapter(chapter),
            child: Text('$chapter'),
          );
        },
      ),
    );
  }

  /// 언어 토글 버튼
  Widget _buildLanguageToggleButton() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return IconButton(
          icon: Icon(
            languageProvider.isKorean ? Icons.language : Icons.translate,
          ),
          tooltip: languageProvider.isKorean ? 'English' : '한글',
          onPressed: () async {
            await languageProvider.toggleLanguage();
          },
        );
      },
    );
  }
}
