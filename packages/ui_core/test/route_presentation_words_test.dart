// What a screen's dismiss control says (0.6.0): nothing on a root, the
// back words on a pushed page, the close words on a sheet, in the app's
// language.
import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

class _German extends DefaultRawWidgetsLocalizations {
  const _German();

  @override
  String get backButtonTooltip => 'Zurück';

  @override
  String get closeButtonLabel => 'Schließen';
}

class _GermanDelegate extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _GermanDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _German());

  @override
  bool shouldReload(_GermanDelegate old) => false;
}

void main() {
  testWidgets('nothing on a root, Back on a pushed page, Close on a sheet', (
    tester,
  ) async {
    // What each screen's control says, by the screen.
    final said = <String, String?>{};
    Widget reader(String screen) => Builder(
      builder: (context) {
        said[screen] = RoutePresentation.of(context).dismissLabel(context);
        return const SizedBox.expand();
      },
    );
    await tester.pumpWidget(harness(reader('root')));
    expect(said, {'root': null});
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => reader('pushed'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(said['pushed'], 'Back');
    unawaited(
      navigator.push(
        PageRouteBuilder<void>(
          fullscreenDialog: true,
          pageBuilder: (context, _, _) => reader('sheet'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(said['sheet'], 'Close');
    expect(said['root'], isNull);
  });

  testWidgets("the words are the app's language's", (tester) async {
    final said = <RoutePresentation, String?>{};
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de'),
        delegates: const [
          _GermanDelegate(),
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            for (final at in RoutePresentation.values) {
              said[at] = at.dismissLabel(context);
            }
            return const SizedBox();
          },
        ),
      ),
    );
    expect(said, {
      RoutePresentation.root: null,
      RoutePresentation.pushed: 'Zurück',
      RoutePresentation.sheet: 'Schließen',
    });
  });
}
