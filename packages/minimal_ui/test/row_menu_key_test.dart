// A menu key in a list row's trailing slot stands ghost, its glyph alone at
// rest, as the row's other trailing parts do; on a bar it keeps its
// hairline square.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/centred_host.dart';

List<MinimalMenuItem> _items() => [MinimalMenuItem('Rename', onPressed: () {})];

Finder _glyph(IconData icon) =>
    find.byWidgetPredicate((w) => w is MinimalIcon && w.icon == icon);

// The edge of the square drawn round [icon]'s glyph.
BorderSide _rim(WidgetTester tester, IconData icon) {
  final square = tester.widget<Container>(
    find.ancestor(of: _glyph(icon), matching: find.byType(Container)).first,
  );
  final decoration = square.decoration;
  if (decoration is BoxDecoration) {
    final border = decoration.border;
    return border is Border ? border.top : BorderSide.none;
  }
  if (decoration is ShapeDecoration) {
    final shape = decoration.shape;
    return shape is OutlinedBorder ? shape.side : BorderSide.none;
  }
  return BorderSide.none;
}

bool _drawn(BorderSide side) =>
    side.style != BorderStyle.none && side.width > 0 && side.color.a > 0;

void main() {
  testWidgets('a menu key in a list row draws no square at rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      centredHost(
        SizedBox(
          width: 360,
          child: MinimalListTile(
            title: 'Stretch',
            onTap: () {},
            trailing: MinimalMenu.button(
              LucideIcons.ellipsis,
              label: 'Habit actions',
              items: _items(),
            ),
          ),
        ),
      ),
    );
    expect(_drawn(_rim(tester, LucideIcons.ellipsis)), isFalse);
  });

  testWidgets('a menu key on its own keeps its hairline square', (
    tester,
  ) async {
    await tester.pumpWidget(
      centredHost(
        Align(
          child: MinimalMenu.button(
            LucideIcons.ellipsis,
            label: 'Habit actions',
            items: _items(),
          ),
        ),
      ),
    );
    expect(_drawn(_rim(tester, LucideIcons.ellipsis)), isTrue);
  });
}
