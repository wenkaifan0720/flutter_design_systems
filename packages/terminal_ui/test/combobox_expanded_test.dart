// A combobox's and a tag input's input says whether its list is expanded,
// as a select's button does: collapsed at rest, expanded while the list
// shows, collapsed again after Escape.
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _branches = ['main', 'feat/main-menu', 'fix/retry'];

final _fields = <String, Widget>{
  'combobox': TermCombobox<String>(
    labelText: 'branch',
    options: _branches,
    onSelected: (_) {},
  ),
  'tag input': TermTagInput<String>(
    labelText: 'branches',
    values: const [],
    options: _branches,
    onChanged: (_) {},
  ),
};

void main() {
  setUpAll(loadFaces);

  for (final MapEntry(key: kind, value: field) in _fields.entries) {
    testWidgets("a $kind's input reads expanded while its list shows", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) =>
              TermTheme(data: TermThemeData.dark(), child: app!),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 360, child: field),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Tristate expanded() {
        final data = tester
            .getSemantics(find.byType(EditableText))
            .getSemanticsData();
        expect(data.flagsCollection.isTextField, isTrue);
        return data.flagsCollection.isExpanded;
      }

      expect(expanded(), Tristate.isFalse);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('feat/main-menu'), findsOneWidget, reason: 'listed');
      expect(expanded(), Tristate.isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('feat/main-menu'), findsNothing, reason: 'closed');
      expect(expanded(), Tristate.isFalse);
      semantics.dispose();
    });
  }
}
