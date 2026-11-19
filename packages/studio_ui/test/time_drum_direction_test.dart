// A time drum in the reader's language. It reads hours then minutes, left
// to right, in a right-to-left language too, as a clock does and Material's
// time picker keeps it: in Arabic the hours stand on the left, Tab reaches
// them first, and the right arrow moves on to the minutes. A screen reader
// names each drum in the reader's words, ui_core's "Hour" and "Minute".
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: Brightness.light, child: app!),
      home: Localizations(
        locale: locale,
        delegates: const [
          DesignLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  for (final (locale, hour, minute) in [
    (const Locale('ar'), '٠٩', '٣٠'),
    (const Locale('en'), '09', '30'),
  ]) {
    testWidgets('in ${locale.languageCode} the hours stand left of the '
        'minutes', (tester) async {
      await _show(
        tester,
        StudioTimePicker(
          value: const StudioTime(hour: 9, minute: 30),
          onChanged: (_) {},
        ),
        locale: locale,
      );
      final hours = tester.getCenter(find.text(hour).first);
      final colon = tester.getCenter(find.text(':'));
      final minutes = tester.getCenter(find.text(minute).first);
      expect(hours.dx, lessThan(colon.dx));
      expect(colon.dx, lessThan(minutes.dx));
    });
  }

  testWidgets('in Arabic Tab reaches the hours first and the right arrow '
      'moves on to the minutes', (tester) async {
    var time = const StudioTime(hour: 9, minute: 30);
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) => StudioTimePicker(
          value: time,
          onChanged: (t) => setState(() => time = t),
        ),
      ),
    );
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    await press(LogicalKeyboardKey.tab);
    await press(LogicalKeyboardKey.arrowDown);
    expect(time, const StudioTime(hour: 10, minute: 30));

    await press(LogicalKeyboardKey.arrowRight);
    await press(LogicalKeyboardKey.arrowDown);
    expect(time, const StudioTime(hour: 10, minute: 35));

    await press(LogicalKeyboardKey.arrowLeft);
    await press(LogicalKeyboardKey.arrowUp);
    expect(time, const StudioTime(hour: 9, minute: 35));
  });

  for (final (locale, hour, minute, separator) in [
    (const Locale('ar'), 'ساعة', 'دقيقة', '، '),
    (const Locale('de'), 'Stunde', 'Minute', ', '),
    (const Locale('en'), 'Hour', 'Minute', ', '),
  ]) {
    testWidgets('in ${locale.languageCode} a screen reader names the drums '
        '$hour and $minute', (tester) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        Column(
          children: [
            StudioTimePicker(
              value: const StudioTime(hour: 9, minute: 30),
              semanticLabel: 'Reminder',
              onChanged: (_) {},
            ),
            StudioTimePicker(
              value: const StudioTime(hour: 9, minute: 30),
              onChanged: (_) {},
            ),
          ],
        ),
        locale: locale,
      );
      expect(find.bySemanticsLabel('Reminder$separator$hour'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Reminder$separator$minute'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(hour), findsOneWidget);
      expect(find.bySemanticsLabel(minute), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('hours|minutes|Time')), findsNothing);
      semantics.dispose();
    });
  }
}
