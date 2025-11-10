import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VerseHistoryItem {
  final String reference;
  final String text;
  final DateTime date;

  VerseHistoryItem({
    required this.reference,
    required this.text,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'text': text,
        'date': date.toIso8601String(),
      };

  factory VerseHistoryItem.fromJson(Map<String, dynamic> json) {
    return VerseHistoryItem(
      reference: json['reference'] as String,
      text: json['text'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class VerseHistoryService {
  static const String _historyKey = 'verse_history';
  static const int _maxHistoryItems = 30; // Keep last 30 days

  Future<void> saveVerse(VerseHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // 중복 체크: 같은 reference와 text를 가진 항목이 이미 있으면 제거
    history.removeWhere((h) =>
        h.reference == item.reference && h.text == item.text);

    // Add new item at the beginning
    history.insert(0, item);

    // Keep only the most recent items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // Save to SharedPreferences
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<VerseHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => VerseHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
