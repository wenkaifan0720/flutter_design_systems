// A combobox's and a multi-select's input says whether its list is expanded,
// as a select's button does: collapsed at rest, expanded while the list
// shows, collapsed again after Escape.
import 'dart:ui' show Tristate;

import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(
  Widget page, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => WidgetsApp(
  color: const Color(0xFF000000),
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Fluent2Host(brightness: brightness, child: child!),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => page,
  ),
);

const _environments = [
  Fluent2Option('staging', 'Staging'),
  Fluent2Option('canary', 'Canary'),
  Fluent2Option('production', 'Production'),
];

final _fields = <String, Widget>{
  'combobox': Fluent2Combobox<String>(
    semanticLabel: 'Environment',
    options: _environments,
    value: null,
    onChanged: (_) {},
  ),
  'multi-select': Fluent2MultiSelect<String>(
    semanticLabel: 'Environments',
    options: _environments,
    selected: const [],
    onChanged: (_) {},
  ),
};

void main() {
  setUpAll(loadFluent2TestFonts);

  for (final MapEntry(key: kind, value: field) in _fields.entries) {
    testWidgets("a $kind's input reads expanded while its list shows", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Align(
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
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pumpAndSettle();
      expect(find.text('Canary'), findsWidgets, reason: 'listed');
      expect(expanded(), Tristate.isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Canary'), findsNothing, reason: 'closed');
      expect(expanded(), Tristate.isFalse);
      semantics.dispose();
    });
  }
}
