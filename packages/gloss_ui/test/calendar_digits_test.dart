// A calendar writes its days in the app's digits, as Material's does: in Arabic the 20th reads ٢٠.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

void main() {
  setUpAll(glossLoadFonts);

  testWidgets('in Arabic the days are written in Arabic-Indic digits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [RawWidgetsLocalizations.delegate],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondary) => builder(context),
        ),
        builder: (context, navigator) =>
            GlossTheme(data: kitTheme(Brightness.light), child: navigator!),
        home: Align(
          alignment: Alignment.topCenter,
          child: GlossCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            selectedDate: DateTime(2026, 11, 9),
            onDateChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });
}
