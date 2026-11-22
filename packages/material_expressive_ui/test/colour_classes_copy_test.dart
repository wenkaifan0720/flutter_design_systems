/// The colour classes a widget or theme takes copy as Compose's `copy` does
/// and compare by value: a copy changes only what it is given, and two
/// alike are equal with one hash.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

void main() {
  test('ExpressiveToggleButtonColors copies and compares by value', () {
    const a = ExpressiveToggleButtonColors(
      container: Color(0xFF112233),
      checkedContent: Color(0xFF445566),
    );
    final b = a.copyWith(content: const Color(0xFF778899));
    expect(b.container, a.container);
    expect(b.checkedContent, a.checkedContent);
    expect(b.content, const Color(0xFF778899));
    expect(b.checkedContainer, isNull);
    expect(a.copyWith(), a);
    expect(a.copyWith().hashCode, a.hashCode);
    expect(b, isNot(a));
  });

  test('ExpressiveCardColors copies and keeps what it is not given', () {
    final scheme = ExpressiveThemeData.preset(
      'baseline',
      Brightness.light,
    ).colors;
    final a = ExpressiveCardColors.of(ExpressiveCardVariant.outlined, scheme);
    final b = a.copyWith(container: const Color(0xFF101010));
    expect(b.container, const Color(0xFF101010));
    expect(b.content, a.content);
    expect(b.outline, a.outline);
    expect(b.disabledOutline, a.disabledOutline);
    expect(a.copyWith(), a);
  });

  test('ExpressiveStatusColors copies one group and keeps the other', () {
    final a = ExpressiveThemeData.preset('baseline', Brightness.light).status;
    final b = a.copyWith(success: a.warning);
    expect(b.success, a.warning);
    expect(b.warning, a.warning);
    expect(a.copyWith(), a);
  });
}
