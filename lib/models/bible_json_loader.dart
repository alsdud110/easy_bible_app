import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// bible.json을 Map<String, String>으로 반환
Future<Map<String, String>> loadBibleJson() async {
  final jsonString = await rootBundle.loadString('assets/bible.json');
  final Map<String, dynamic> raw = json.decode(jsonString);
  return raw.map((k, v) => MapEntry(k, v as String));
}
