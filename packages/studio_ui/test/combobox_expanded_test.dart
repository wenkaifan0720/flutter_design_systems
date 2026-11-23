// A combobox's and a tag input's text entry says whether its list is
// expanded, as a select's key does: collapsed at rest, expanded while the
// list shows, collapsed again after Escape.
import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

// The gallery's app frame; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp;

const _shows = ['Morning edition', 'Field notes', 'Late session'];

final _fields = <String, Widget>{
  'combobox': StudioCombobox<String>(
    labelText: 'Show',
    options: _shows,
    labelOf: (s) => s,
    onSelected: (_) {},
  ),
  'tag input': StudioTagInput<String>(
    labelText: 'Shows',
    values: const [],
    options: _shows,
    labelOf: (s) => s,
    onChanged: (_) {},
  ),
};

void main() {
  setUpAll(studioLoadFonts);

  for (final MapEntry(key: kind, value: field) in _fields.entries) {
    testWidgets("a $kind's text entry reads expanded while its list shows", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
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
      await tester.enterText(find.byType(EditableText), 'e');
      await tester.pumpAndSettle();
      expect(find.text('Field notes'), findsWidgets, reason: 'listed');
      expect(expanded(), Tristate.isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Field notes'), findsNothing, reason: 'closed');
      expect(expanded(), Tristate.isFalse);
      semantics.dispose();
    });
  }
}
