import 'package:flutter/widgets.dart';

/// 한글은 글자마다 줄이 바뀔 수 있어 단어 중간에서 끊긴다("가든|지").
/// 단어 안 글자 사이에 단어 결합자(U+2060)를 넣어 띄어쓰기에서만 줄바꿈되게 한다.
/// 화면 표시용으로만 쓰고, 저장·공유하는 문자열에는 쓰지 않는다.
String keepWords(String text) => text.splitMapJoin(
      ' ',
      onNonMatch: (word) => word.characters.join('⁠'),
    );
