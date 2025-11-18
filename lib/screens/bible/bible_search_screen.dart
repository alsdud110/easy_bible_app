import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../../models/bible_data.dart';
import '../../providers/language_provider.dart';
import '../../services/bible_search_service.dart';
import 'verse_list_view.dart';

class BibleSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const BibleSearchScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<BibleSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  int _totalResultCount = 0; // 전체 검색 결과 개수

  @override
  void initState() {
    super.initState();
    // 초기 검색어가 있으면 설정
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
      // 자동 검색 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!);
      });
    } else {
      // 화면 열리면 자동으로 포커스
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// 검색 결과 클릭 시 해당 장의 구절 로드 후 verse_list_view로 이동
  Future<void> _navigateToVerse(BibleSearchResult result) async {
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
            Navigator.pop(context); // 검색 화면으로 돌아가기
          },
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchQuery = '';
        _totalResultCount = 0;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    final languageProvider = context.read<LanguageProvider>();
    final response = await BibleSearchService.searchBible(
      query,
      languageProvider.currentLanguage,
    );

    if (!mounted) return;

    setState(() {
      _searchResults = response.results;
      _totalResultCount = response.totalCount;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(languageProvider.isKorean ? '단어 검색' : 'Word Search'),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
      ),
      body: Column(
        children: [
          // 검색 입력 필드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: cs.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: languageProvider.isKorean
                    ? '검색어를 입력하세요 (예: 사랑, 믿음)'
                    : 'Enter search term (e.g., love, faith)',
                hintStyle: TextStyle(
                  color: cs.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: cs.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: cs.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                // 타이핑할 때마다 자동 검색 (디바운싱 적용)
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: _performSearch,
            ),
          ),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: cs.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              languageProvider.isKorean
                                  ? '검색어를 입력하세요'
                                  : 'Enter a search term',
                              style: TextStyle(
                                fontSize: 16,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
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
                                  languageProvider.isKorean
                                      ? '검색 결과가 없습니다'
                                      : 'No results found',
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
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  languageProvider.isKorean
                                      ? '$_totalResultCount개의 결과'
                                      : '$_totalResultCount result${_totalResultCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: cs.outline.withOpacity(0.2),
                                  ),
                                  itemBuilder: (context, index) {
                                    final result = _searchResults[index];
                                    return _SearchResultTile(
                                      result: result,
                                      searchQuery: _searchQuery,
                                      onTap: () {
                                        _navigateToVerse(result);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final BibleSearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  TextSpan _highlightSearchTerm(String text, String query, Color highlightColor) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: highlightColor,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return ListTile(
      onTap: onTap,
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
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'ChosunCentennial',
            fontSize: 15,
            height: 1.5,
            color: cs.onSurface,
          ),
          children: [
            _highlightSearchTerm(
              result.text,
              searchQuery,
              Colors.yellow.withOpacity(0.5),
            ),
          ],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: cs.primary.withOpacity(0.5),
      ),
    );
  }
}
