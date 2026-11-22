// A menu entry that destroys something (Delete) prints its words in the
// danger ink, in a key's menu, a context menu and a menu bar's menu, as a
// dialog's destructive key does; its neighbours keep the ink.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show Material;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

const _entries = [
  RawMenuEntry(label: 'Rename', onPressed: _none),
  RawMenuEntry(label: 'Delete', isDestructiveAction: true, onPressed: _none),
];

void _none() {}

Color? _ink(WidgetTester tester, String words) => tester
    .renderObject<RenderParagraph>(find.text(words).last)
    .text
    .style
    ?.color;

Future<void> _show(
  WidgetTester tester,
  Widget menu,
  Brightness brightness,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: Material(
        child: Align(alignment: Alignment.topCenter, child: menu),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectInks(WidgetTester tester) {
  final c = KeycapTheme.of(tester.element(find.text('Delete').last)).colors;
  expect(_ink(tester, 'Delete'), c.dangerInk);
  expect(_ink(tester, 'Rename'), c.ink);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a key\'s menu prints Delete in the danger ink '
        '(${brightness.name})', (tester) async {
      await _show(
        tester,
        KeycapMenu(
          semanticLabel: 'Note',
          entries: _entries,
          builder: (context, anchor) => KeycapIconButton(
            icon: const Icon(LucideIcons.ellipsis),
            semanticLabel: 'More',
            onPressed: anchor.toggle,
          ),
        ),
        brightness,
      );
      await tester.tap(find.bySemanticsLabel('More'));
      await tester.pumpAndSettle();
      _expectInks(tester);
    });

    testWidgets('a context menu prints Delete in the danger ink '
        '(${brightness.name})', (tester) async {
      await _show(
        tester,
        const KeycapContextMenu(
          entries: _entries,
          child: SizedBox(width: 300, height: 80, child: Text('A note')),
        ),
        brightness,
      );
      await tester.tap(find.text('A note'), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      _expectInks(tester);
    });

    testWidgets('a menu bar\'s menu prints Delete in the danger ink '
        '(${brightness.name})', (tester) async {
      await _show(
        tester,
        const KeycapMenuBar(
          menus: [RawMenuEntry(label: 'Note', children: _entries)],
        ),
        brightness,
      );
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      _expectInks(tester);
    });
  }
}
