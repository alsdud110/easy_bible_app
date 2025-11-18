import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../providers/language_provider.dart';
import '../../services/bible_search_service.dart';
import '../../widgets/banner_ad_widget.dart';
import 'verse_list_view.dart';

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
  final void Function(int bookIdx, int chapter, int verse)? onDirectNavigate;
  final void Function(int bookIdx, int chapter)? onChapterNavigate;
  final VoidCallback? onThemeToggle;
  final bool isDark;

  const BookSelector({
    required this.books,
    required this.onSelect,
    this.onDirectNavigate,
    this.onChapterNavigate,
    this.onThemeToggle,
    this.isDark = false,
    super.key,
  });

  @override
  State<BookSelector> createState() => _BookSelectorState();
}

enum SearchMode { quickFind, wordSearch }

class _BookSelectorState extends State<BookSelector>
    with SingleTickerProviderStateMixin {
  bool isGrid = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.quickFind;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 단어 검색 관련
  List<BibleSearchResult> _wordSearchResults = [];
  bool _isSearching = false;
  int _totalWordSearchCount = 0;

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
  void didUpdateWidget(covariant BookSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 애니메이션은 초기 로드 시에만 실행
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<BibleData> _filterBooks(List<BibleData> books) {
    if (_searchQuery.isEmpty) return books;

    final versePattern = RegExp(r'(.+?)\s*(\d+)[\s:]+(\d+)');
    final chapterPattern = RegExp(r'(.+?)\s+(\d+)$');
    if (versePattern.hasMatch(_searchQuery) ||
        chapterPattern.hasMatch(_searchQuery)) {
      return books;
    }

    return books.where((book) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = book.name.contains(_searchQuery) ||
          book.fullName.contains(_searchQuery);
      // 영어 검색 지원
      final engMatch = book.eng.toLowerCase().contains(query) ||
          book.getLocalizedName(false).toLowerCase().contains(query);
      return nameMatch || engMatch;
    }).toList();
  }

  void _handleSearch(String query) async {
    if (query.isEmpty) return;

    final versePattern = RegExp(r'(.+?)\s*(\d+)[\s:]+(\d+)');
    final verseMatch = versePattern.firstMatch(query);

    final chapterPattern = RegExp(r'(.+?)\s+(\d+)$');
    final chapterMatch = chapterPattern.firstMatch(query);

    if (verseMatch != null) {
      final bookName = verseMatch.group(1)!.trim();
      final chapter = int.tryParse(verseMatch.group(2)!) ?? 1;
      final verse = int.tryParse(verseMatch.group(3)!) ?? 1;
      _handleVerseSearch(bookName, chapter, verse);
    } else if (chapterMatch != null) {
      final bookName = chapterMatch.group(1)!.trim();
      final chapter = int.tryParse(chapterMatch.group(2)!) ?? 1;
      _handleChapterSearch(bookName, chapter);
    } else {
      final queryLower = query.toLowerCase();
      final bookIndex = widget.books.indexWhere(
        (b) =>
            b.name == query ||
            b.fullName == query ||
            b.eng.toLowerCase() == queryLower ||
            b.getLocalizedName(false).toLowerCase() == queryLower,
      );
      if (bookIndex != -1) {
        widget.onSelect(bookIndex);
      }
    }
  }

  void _handleVerseSearch(String bookName, int chapter, int verse) {
    final bookNameLower = bookName.toLowerCase();
    final matchedBooks = widget.books
        .where(
          (b) =>
              b.name.contains(bookName) ||
              b.fullName.contains(bookName) ||
              b.eng.toLowerCase().contains(bookNameLower) ||
              b.getLocalizedName(false).toLowerCase().contains(bookNameLower),
        )
        .toList();

    if (matchedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 성경책을 찾을 수 없습니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (matchedBooks.length > 1) {
      final booksWithChapter = matchedBooks
          .where(
            (b) => b.chapters >= chapter,
          )
          .toList();

      if (booksWithChapter.isEmpty) {
        _showBookSelectionDialogForVerse(matchedBooks, chapter, verse);
      } else if (booksWithChapter.length == 1) {
        final book = booksWithChapter.first;
        final bookIndex = widget.books.indexOf(book);
        _navigateToVerse(bookIndex, book, chapter, verse);
      } else {
        _showBookSelectionDialogForVerse(booksWithChapter, chapter, verse);
      }
    } else {
      final book = matchedBooks.first;
      final bookIndex = widget.books.indexOf(book);
      _navigateToVerse(bookIndex, book, chapter, verse);
    }
  }

  void _handleChapterSearch(String bookName, int chapter) {
    final bookNameLower = bookName.toLowerCase();
    final matchedBooks = widget.books
        .where(
          (b) =>
              b.name.contains(bookName) ||
              b.fullName.contains(bookName) ||
              b.eng.toLowerCase().contains(bookNameLower) ||
              b.getLocalizedName(false).toLowerCase().contains(bookNameLower),
        )
        .toList();

    if (matchedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 성경책을 찾을 수 없습니다'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (matchedBooks.length > 1) {
      final booksWithChapter = matchedBooks
          .where(
            (b) => b.chapters >= chapter,
          )
          .toList();

      if (booksWithChapter.isEmpty) {
        _showBookSelectionDialogForChapter(matchedBooks, chapter);
      } else if (booksWithChapter.length == 1) {
        final book = booksWithChapter.first;
        final bookIndex = widget.books.indexOf(book);
        _navigateToChapter(bookIndex, book, chapter);
      } else {
        _showBookSelectionDialogForChapter(booksWithChapter, chapter);
      }
    } else {
      final book = matchedBooks.first;
      final bookIndex = widget.books.indexOf(book);
      _navigateToChapter(bookIndex, book, chapter);
    }
  }

  void _showBookSelectionDialogForVerse(
    List<BibleData> books,
    int chapter,
    int verse,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성경책을 선택하세요'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: books.map((book) {
                final hasChapter = book.chapters >= chapter;
                return ListTile(
                  title: Text(
                    book.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasChapter
                          ? cs.onSurface
                          : cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                  subtitle: Text(
                    hasChapter
                        ? '총 ${book.chapters}장'
                        : '총 ${book.chapters}장 ($chapter장 없음)',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasChapter
                          ? cs.onSurface.withOpacity(0.6)
                          : cs.error.withOpacity(0.6),
                    ),
                  ),
                  enabled: hasChapter,
                  onTap: hasChapter
                      ? () {
                          Navigator.pop(context);
                          final bookIndex = widget.books.indexOf(book);
                          _navigateToVerse(bookIndex, book, chapter, verse);
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showBookSelectionDialogForChapter(
    List<BibleData> books,
    int chapter,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('성경책을 선택하세요'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: books.map((book) {
                final hasChapter = book.chapters >= chapter;
                return ListTile(
                  title: Text(
                    book.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasChapter
                          ? cs.onSurface
                          : cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                  subtitle: Text(
                    hasChapter
                        ? '총 ${book.chapters}장'
                        : '총 ${book.chapters}장 ($chapter장 없음)',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasChapter
                          ? cs.onSurface.withOpacity(0.6)
                          : cs.error.withOpacity(0.6),
                    ),
                  ),
                  enabled: hasChapter,
                  onTap: hasChapter
                      ? () {
                          Navigator.pop(context);
                          final bookIndex = widget.books.indexOf(book);
                          _navigateToChapter(bookIndex, book, chapter);
                        }
                      : null,
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _navigateToVerse(int bookIndex, BibleData book, int chapter, int verse) {
    if (chapter < 1 || chapter > book.chapters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName}은(는) ${book.chapters}장까지 있습니다'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.onDirectNavigate != null) {
      widget.onDirectNavigate!(bookIndex, chapter, verse);
    } else {
      widget.onSelect(bookIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName} $chapter장 $verse절로 이동'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToChapter(int bookIndex, BibleData book, int chapter) {
    if (chapter < 1 || chapter > book.chapters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.fullName}은(는) ${book.chapters}장까지 있습니다'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.onChapterNavigate != null) {
      widget.onChapterNavigate!(bookIndex, chapter);
    } else {
      widget.onSelect(bookIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = context.watch<LanguageProvider>();
    final oldBooks = _filterBooks(
      widget.books.where((b) => b.isOldTestament).toList(),
    );
    final newBooks = _filterBooks(
      widget.books.where((b) => !b.isOldTestament).toList(),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(languageProvider.isKorean ? '성경책 선택' : 'Select Book'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        iconTheme: theme.appBarTheme.iconTheme,
        actionsIconTheme: theme.appBarTheme.actionsIconTheme,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: languageProvider.isKorean ? '홈으로' : 'Home',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          },
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.appBarTheme.iconTheme?.color ??
                      theme.colorScheme.onSurface,
                ),
              ),
            ),
            tooltip: languageProvider.isKorean ? 'English' : '한글',
            onPressed: () async {
              await languageProvider.toggleLanguage();
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // 검색 영역
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // 세그먼트 버튼
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSegmentButton(
                                context,
                                label: languageProvider.isKorean
                                    ? '성경 간편 찾기'
                                    : 'Quick Find',
                                icon: Icons.menu_book,
                                isSelected: _searchMode == SearchMode.quickFind,
                                onTap: () {
                                  setState(() {
                                    _searchMode = SearchMode.quickFind;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildSegmentButton(
                                context,
                                label: languageProvider.isKorean
                                    ? '단어 검색'
                                    : 'Word Search',
                                icon: Icons.search,
                                isSelected:
                                    _searchMode == SearchMode.wordSearch,
                                onTap: () {
                                  setState(() {
                                    _searchMode = SearchMode.wordSearch;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 검색 바
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _searchMode == SearchMode.quickFind
                              ? (languageProvider.isKorean
                                  ? '예) 창세기, 출, 민수기 6, 눅 11, 요한복음 3:16, 요 3 16'
                                  : 'e.g.) Genesis, Exo, Numbers 6, Luke 11, John 3:16')
                              : (languageProvider.isKorean
                                  ? '단어 검색 (예: 사랑, 믿음)'
                                  : 'Word search (e.g., love, faith)'),
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            _searchMode == SearchMode.quickFind
                                ? Icons.menu_book
                                : Icons.search,
                            color: theme.colorScheme.primary,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 단어 검색 모드가 아닐 때만 화살표 표시
                                    if (_searchMode == SearchMode.quickFind)
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward,
                                          color: theme.colorScheme.primary,
                                        ),
                                        onPressed: () {
                                          _handleSearch(_searchController.text);
                                        },
                                        tooltip: languageProvider.isKorean
                                            ? '검색'
                                            : 'Search',
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _wordSearchResults = [];
                                          _totalWordSearchCount = 0;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          // 단어 검색 모드일 때 자동 검색 (디바운싱)
                          if (_searchMode == SearchMode.wordSearch) {
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              if (_searchController.text == value && mounted) {
                                _performWordSearch(value);
                              }
                            });
                          }
                        },
                        onSubmitted: (value) {
                          if (_searchMode == SearchMode.quickFind) {
                            _handleSearch(value);
                          } else {
                            _performWordSearch(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 검색 결과 또는 전체 목록
              Expanded(
                child: _searchMode == SearchMode.wordSearch &&
                        _searchQuery.isNotEmpty
                    ? _buildWordSearchResults(theme, languageProvider)
                    : _searchQuery.isNotEmpty &&
                            oldBooks.isEmpty &&
                            newBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '검색 결과가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '다른 검색어를 시도해보세요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              if (oldBooks.isNotEmpty) ...[
                                _SectionTitle(
                                    title: languageProvider.isKorean
                                        ? '구약'
                                        : 'Old Testament'),
                                isGrid
                                    ? _BookGrid(
                                        books: oldBooks,
                                        allBooks: widget.books,
                                        onSelect: widget.onSelect,
                                        isKorean: languageProvider.isKorean,
                                      )
                                    : _BookList(
                                        books: oldBooks,
                                        allBooks: widget.books,
                                        onSelect: widget.onSelect,
                                        isKorean: languageProvider.isKorean,
                                      ),
                              ],
                              if (newBooks.isNotEmpty) ...[
                                _SectionTitle(
                                    title: languageProvider.isKorean
                                        ? '신약'
                                        : 'New Testament'),
                                isGrid
                                    ? _BookGrid(
                                        books: newBooks,
                                        allBooks: widget.books,
                                        onSelect: widget.onSelect,
                                        isKorean: languageProvider.isKorean,
                                      )
                                    : _BookList(
                                        books: newBooks,
                                        allBooks: widget.books,
                                        onSelect: widget.onSelect,
                                        isKorean: languageProvider.isKorean,
                                      ),
                              ],
                            ],
                          ),
              ),

              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  // 단어 검색 수행
  Future<void> _performWordSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _wordSearchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final languageProvider = context.read<LanguageProvider>();
    final response = await BibleSearchService.searchBible(
      query,
      languageProvider.currentLanguage,
    );

    if (!mounted) return;

    setState(() {
      _wordSearchResults = response.results;
      _totalWordSearchCount = response.totalCount;
      _isSearching = false;
    });
  }

  // 단어 검색 결과 표시
  Widget _buildWordSearchResults(
      ThemeData theme, LanguageProvider languageProvider) {
    final cs = theme.colorScheme;

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_wordSearchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              languageProvider.isKorean ? '검색 결과가 없습니다' : 'No results found',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              languageProvider.isKorean
                  ? '다른 검색어를 시도해보세요'
                  : 'Try different search terms',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            languageProvider.isKorean
                ? '$_totalWordSearchCount개의 결과'
                : '$_totalWordSearchCount result${_totalWordSearchCount > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _wordSearchResults.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: cs.outline.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final result = _wordSearchResults[index];
              return _buildSearchResultTile(result, theme, languageProvider);
            },
          ),
        ),
      ],
    );
  }

  // 검색 결과 타일
  Widget _buildSearchResultTile(
    BibleSearchResult result,
    ThemeData theme,
    LanguageProvider languageProvider,
  ) {
    final cs = theme.colorScheme;

    return ListTile(
      onTap: () => _navigateToVerseFromSearch(result),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          result.reference,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: cs.primary,
            letterSpacing: 0.2,
          ),
        ),
      ),
      subtitle: RichText(
        text: _highlightSearchTerm(
          result.text,
          _searchQuery,
          cs.primary.withOpacity(0.2),
          cs.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: cs.primary.withOpacity(0.5),
      ),
    );
  }

  // 검색어 하이라이트 처리
  TextSpan _highlightSearchTerm(
      String text, String query, Color highlightColor, Color textColor) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'ChosunCentennial',
          fontSize: 15,
          height: 1.5,
          color: textColor,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(
              fontFamily: 'ChosunCentennial',
              fontSize: 15,
              height: 1.5,
              color: textColor,
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontFamily: 'ChosunCentennial',
            fontSize: 15,
            height: 1.5,
            color: textColor,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          fontFamily: 'ChosunCentennial',
          fontSize: 15,
          height: 1.5,
          backgroundColor: highlightColor,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  // 검색 결과에서 구절로 이동
  Future<void> _navigateToVerseFromSearch(BibleSearchResult result) async {
    final languageProvider = context.read<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    // JSON 로드
    final String assetPath = currentLanguage == BibleLanguage.korean
        ? 'assets/bible.json'
        : 'assets/bible_kjv.json';

    final String data = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> fullBibleData = json.decode(data);

    // 해당 장의 모든 구절 추출
    final Map<int, String> verses = {};
    String searchPrefix;

    if (currentLanguage == BibleLanguage.korean) {
      final book = bibleBooks[result.bookIndex];
      searchPrefix = '${book.name}${result.chapter}:';
    } else {
      final book = bibleBooks[result.bookIndex];
      searchPrefix = '${book.eng}${result.chapter}:';
    }

    fullBibleData.forEach((key, value) {
      if (key.startsWith(searchPrefix)) {
        final verseNumStr = key.substring(searchPrefix.length);
        final verseNum = int.tryParse(verseNumStr);
        if (verseNum != null) {
          verses[verseNum] = value as String;
        }
      }
    });

    if (!mounted) return;

    // verse_list_view로 이동
    final book = bibleBooks[result.bookIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerseListView(
          book: book,
          chapter: result.chapter,
          verses: verses,
          selectedVerse: result.verse,
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.85 + (value * 0.15),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<BibleData> books;
  final List<BibleData> allBooks;
  final void Function(int idx) onSelect;
  final bool isKorean;

  const _BookGrid({
    required this.books,
    required this.allBooks,
    required this.onSelect,
    required this.isKorean,
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
      itemBuilder: (context, i) {
        final book = books[i];
        final originalIndex = allBooks.indexOf(book);
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
            onTap: () => onSelect(originalIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.32)),
              ),
              alignment: Alignment.center,
              child: Text(
                book.getLocalizedName(isKorean),
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
      },
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BibleData> books;
  final List<BibleData> allBooks;
  final void Function(int idx) onSelect;
  final bool isKorean;

  const _BookList({
    required this.books,
    required this.allBooks,
    required this.onSelect,
    required this.isKorean,
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
      itemBuilder: (context, i) {
        final book = books[i];
        final originalIndex = allBooks.indexOf(book);
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (i * 25)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(-30 * (1 - value), 0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: ListTile(
            onTap: () => onSelect(originalIndex),
            title: Text(
              book.getLocalizedFullName(isKorean),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
            trailing: Icon(Icons.chevron_right,
                size: 20, color: theme.colorScheme.primary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            tileColor: theme.colorScheme.surface,
          ),
        );
      },
    );
  }
}
