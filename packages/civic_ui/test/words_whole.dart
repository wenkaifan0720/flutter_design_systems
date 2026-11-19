// No line breaks inside a word: on a phone at twice the text a part that is
// too narrow for its words wraps them mid-word ("applic / ations"), which a
// reader cannot read. Each paragraph on the screen is laid out again as it
// was (its words, its scale, its width) and every line it ends is checked
// to end between words.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _wordy = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);

bool _inWord(String s) => _wordy.hasMatch(s);

bool _hasPlaceholder(InlineSpan span) {
  var found = false;
  span.visitChildren((s) {
    if (s is PlaceholderSpan) found = true;
    return !found;
  });
  return found;
}

/// Each paragraph on screen that ends a line inside a word, as its words
/// with a bar where the line ends ("applic|ations").
List<String> brokenWords(WidgetTester tester) {
  final broken = <String>{};
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
    if (p.didExceedMaxLines || _hasPlaceholder(p.text)) continue;
    final text = p.text.toPlainText(includeSemanticsLabels: false);
    if (text.length < 2) continue;
    final wraps = p.softWrap || p.overflow == TextOverflow.ellipsis;
    final painter =
        TextPainter(
          text: p.text,
          textAlign: p.textAlign,
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          maxLines: p.maxLines,
          locale: p.locale,
          strutStyle: p.strutStyle,
          textWidthBasis: p.textWidthBasis,
          textHeightBehavior: p.textHeightBehavior,
        )..layout(
          minWidth: p.constraints.minWidth,
          maxWidth: wraps ? p.constraints.maxWidth : double.infinity,
        );
    var at = 0;
    while (at < text.length) {
      final line = painter.getLineBoundary(TextPosition(offset: at));
      var end = line.end;
      if (end <= at) end = at + 1;
      if (end < text.length &&
          text[end - 1] != '\n' &&
          _inWord(text[end - 1]) &&
          _inWord(text[end])) {
        final from = (end - 12).clamp(0, text.length);
        final to = (end + 12).clamp(0, text.length);
        broken.add(
          '${text.substring(from, end)}|${text.substring(end, to)}'.replaceAll(
            '\n',
            ' ',
          ),
        );
      }
      at = end;
    }
    painter.dispose();
  }
  return broken.toList();
}

/// Expects no paragraph on screen to break a line inside a word.
void expectWordsWhole(WidgetTester tester, {String? where}) {
  final broken = brokenWords(tester);
  expect(
    broken,
    isEmpty,
    reason: 'a line breaks inside a word${where == null ? '' : ' in $where'}',
  );
}
