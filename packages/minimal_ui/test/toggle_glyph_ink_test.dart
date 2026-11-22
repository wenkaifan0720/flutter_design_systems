// A toggle that is off mutes its glyph in every register.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

/// The ink [index]'s glyph is painted in, among the icon buttons.
Color? _glyphInk(WidgetTester tester, int index) {
  final glyph = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(MinimalIconButton).at(index),
          matching: find.byType(RichText),
        )
        .first,
  );
  return glyph.text.style?.color;
}

void main() {
  testWidgets('a toggle that is off mutes its glyph in every register; '
      'on, and a plain action, it is the ink', (tester) async {
    await tester.pumpWidget(
      scaledPage(
        Wrap(
          children: [
            for (final variant in const [
              MinimalIconButtonVariant.outline,
              MinimalIconButtonVariant.secondary,
              MinimalIconButtonVariant.ghost,
            ]) ...[
              MinimalIconButton(
                Icons.star_border,
                label: 'Pin',
                variant: variant,
                selected: true,
                onPressed: doNothing,
              ),
              MinimalIconButton(
                Icons.star_border,
                label: 'Pin',
                variant: variant,
                selected: false,
                onPressed: doNothing,
              ),
            ],
            const MinimalIconButton(
              Icons.search,
              label: 'Search',
              variant: MinimalIconButtonVariant.outline,
              onPressed: doNothing,
            ),
          ],
        ),
      ),
    );
    for (final i in [0, 2, 4]) {
      expect(_glyphInk(tester, i), dayTheme.foreground, reason: 'on $i');
      expect(
        _glyphInk(tester, i + 1),
        dayTheme.mutedForeground,
        reason: 'off $i',
      );
    }
    expect(_glyphInk(tester, 6), dayTheme.foreground);
  });
}
