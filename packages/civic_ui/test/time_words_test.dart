// A wheel of hours and minutes names its columns in the app's language: ui_core's words, which it speaks in 30
// languages. Civic's inventory specimen said "Hour" and "Minute" in English in every one.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

void main() {
  for (final (locale, hour, minute) in const [
    (Locale('de'), 'Stunde', 'Minute'),
    (Locale('ar'), 'ساعة', 'دقيقة'),
    (Locale('en'), 'Hour', 'Minute'),
  ]) {
    testWidgets('a wheel of hours and minutes names its columns in '
        '${locale.languageCode}', (tester) async {
      final semantics = tester.ensureSemantics();
      final wheel = civicInventory.entries
          .singleWhere((entry) => entry.row == 'WheelPicker')
          .builder!;
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
          direction: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          home: Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: locale,
              delegates: const [DesignLocalizations.delegate],
              child: Center(child: Builder(builder: wheel)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in [hour, minute]) {
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}')),
          findsOneWidget,
          reason: '"$name" heard',
        );
      }
      semantics.dispose();
    });
  }
}
