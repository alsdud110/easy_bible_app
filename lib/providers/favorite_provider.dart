import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_verse.dart';

class FavoriteProvider with ChangeNotifier {
  static const String _storageKey = 'favorite_verses';
  List<FavoriteVerse> _favorites = [];
  bool _isLoaded = false;

  List<FavoriteVerse> get favorites => _favorites;
  bool get isLoaded => _isLoaded;

  // 초기 로드
  Future<void> loadFavorites() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _favorites =
            jsonList.map((json) => FavoriteVerse.fromJson(json)).toList();
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('북마크 로드 실패: $e');
      _favorites = [];
      _isLoaded = true;
    }
  }

  // 저장
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        _favorites.map((fav) => fav.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('북마크 저장 실패: $e');
    }
  }

  // 북마크 추가
  Future<void> addFavorite(FavoriteVerse favorite) async {
    final exists = _favorites.any((fav) => fav.key == favorite.key);
    if (exists) {
      debugPrint('이미 북마크에 존재합니다: ${favorite.reference}');
      return;
    }

    _favorites.add(favorite);
    _favorites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
    await _saveFavorites();
  }

  // 북마크 제거
  Future<void> removeFavorite(String key) async {
    _favorites.removeWhere((fav) => fav.key == key);
    notifyListeners();
    await _saveFavorites();
  }

  // ✅ 메모 추가
  Future<void> addMemo(String favoriteKey, String content) async {
    final index = _favorites.indexWhere((fav) => fav.key == favoriteKey);
    if (index == -1) return;

    final memo = Memo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
    );

    final updatedMemos = [..._favorites[index].memos, memo];
    _favorites[index] = _favorites[index].copyWith(memos: updatedMemos);

    notifyListeners();
    await _saveFavorites();
  }

  // ✅ 메모 수정
  Future<void> updateMemo(
      String favoriteKey, String memoId, String newContent) async {
    final index = _favorites.indexWhere((fav) => fav.key == favoriteKey);
    if (index == -1) return;

    final memos = _favorites[index].memos;
    final memoIndex = memos.indexWhere((m) => m.id == memoId);
    if (memoIndex == -1) return;

    final updatedMemo = memos[memoIndex].copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );

    final updatedMemos = [...memos];
    updatedMemos[memoIndex] = updatedMemo;

    _favorites[index] = _favorites[index].copyWith(memos: updatedMemos);

    notifyListeners();
    await _saveFavorites();
  }

  // ✅ 메모 삭제
  Future<void> deleteMemo(String favoriteKey, String memoId) async {
    final index = _favorites.indexWhere((fav) => fav.key == favoriteKey);
    if (index == -1) return;

    final updatedMemos =
        _favorites[index].memos.where((m) => m.id != memoId).toList();

    _favorites[index] = _favorites[index].copyWith(memos: updatedMemos);

    notifyListeners();
    await _saveFavorites();
  }

  // 특정 절이 북마크인지 확인
  bool isVerseFavorited(String bookName, int chapter, int verse) {
    return _favorites.any((fav) => fav.containsVerse(bookName, chapter, verse));
  }

  // 특정 범위가 북마크인지 확인
  bool isRangeFavorited(
      String bookName, int chapter, int startVerse, int endVerse) {
    return _favorites.any((fav) =>
        fav.bookName == bookName &&
        fav.chapter == chapter &&
        fav.startVerse == startVerse &&
        fav.endVerse == endVerse);
  }

  // 특정 책/장의 모든 북마크 가져오기
  List<FavoriteVerse> getFavoritesForChapter(String bookName, int chapter) {
    return _favorites
        .where((fav) => fav.bookName == bookName && fav.chapter == chapter)
        .toList();
  }

  // 특정 키의 북마크 가져오기
  FavoriteVerse? getFavoriteByKey(String key) {
    try {
      return _favorites.firstWhere((fav) => fav.key == key);
    } catch (e) {
      return null;
    }
  }

  // 전체 삭제
  Future<void> clearAll() async {
    _favorites.clear();
    notifyListeners();
    await _saveFavorites();
  }
}
