// The package's Material and Cupertino words follow the app's language: an
// app that gives none of material_ui's or cupertino_ui's (one on Flutter's own
// Material, say) still reads a field's text menu in German or Arabic, and
// a language those libraries lack in English.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  for (final (locale, direction, copy) in const [
    (Locale('de'), TextDirection.ltr, 'Kopieren'),
    (Locale('ar'), TextDirection.rtl, 'نسخ'),
    (Locale('tlh'), TextDirection.ltr, 'Copy'),
  ]) {
    testWidgets(
      'in ${locale.languageCode}, a field\'s text menu says $copy',
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
      (tester) async {
        late BuildContext at;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            locale: locale,
            supportedLocales: [locale],
            localizationsDelegates: const [RawWidgetsLocalizations.delegate],
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => builder(context),
            ),
            builder: (context, child) => Directionality(
              textDirection: direction,
              child: FrostedHost(brightness: Brightness.light, child: child!),
            ),
            home: Builder(
              builder: (context) {
                at = context;
                return const Center(
                  child: SizedBox(
                    width: 340,
                    child: FrostedTextField(
                      label: 'Name',
                      value: 'Ada Lovelace',
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(MaterialLocalizations.of(at).copyButtonLabel, copy);
        expect(
          Localizations.of<CupertinoLocalizations>(
            at,
            CupertinoLocalizations,
          )?.copyButtonLabel,
          copy,
        );
        final editable = find.byType(EditableText);
        await tester.tap(editable);
        await tester.pump(const Duration(milliseconds: 300));
        final state = tester.state<EditableTextState>(editable);
        state.selectAll(SelectionChangedCause.toolbar);
        state.showToolbar();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(FrostedTextContextMenu), findsOneWidget);
        expect(find.text(copy), findsOneWidget);
      },
    );
  }
}
