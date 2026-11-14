/// ExpressiveScaffold derives its bar from the route register: the root's
/// large flexible bar collapsing to the small row (and settling), a pushed
/// page's small bar and back arrow, a sheet's close and title, the
/// authored bar and the `none` sentinel.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget home) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: _theme, brightness: Brightness.light, child: app!),
  home: home,
);

double _barHeight(WidgetTester tester) =>
    tester.getSize(find.byType(ExpressiveAppBar)).height;

Widget _rows() => Column(
  children: <Widget>[
    for (var i = 0; i < 40; i++)
      SizedBox(height: ExpressiveSpacing.s48, child: Text('Row $i')),
  ],
);

void main() {
  testWidgets('a root derives the large bar, collapsing to 64dp and '
      'settling', (tester) async {
    await tester.pumpWidget(
      _app(ExpressiveScaffold(title: 'Journal', body: _rows())),
    );
    expect(_barHeight(tester), 120);
    expect(find.byType(ExpressiveIconButton), findsNothing);

    final list = find.byType(Scrollable);
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_barHeight(tester), 64);

    await tester.drag(list, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(_barHeight(tester), 120);

    // Released under half of the 56dp range: the bar settles open.
    await tester.drag(list, const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(_barHeight(tester), 120);

    // Released past half: it settles collapsed.
    await tester.drag(list, const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(_barHeight(tester), 64);
  });

  testWidgets('a pushed page derives the small bar and the back arrow', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ExpressiveScaffold(body: SizedBox())));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) =>
                const ExpressiveScaffold(title: 'Entry', body: Text('Body')),
          ),
        );
    await tester.pumpAndSettle();
    expect(_barHeight(tester), 64);
    expect(find.byIcon(ExpressiveSymbols.arrowBack), findsOneWidget);
    await tester.tap(pressableOf(find.byIcon(ExpressiveSymbols.arrowBack)));
    await tester.pumpAndSettle();
    expect(find.text('Entry'), findsNothing);
  });

  testWidgets('a full-bleed body reads the bar height; the bar is clear at '
      'rest and fills as content passes under', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 24 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    double? bodyTop;
    await tester.pumpWidget(
      _app(
        ExpressiveScaffold(
          topBar: const ExpressiveAppBar(title: 'Cover'),
          fullBleed: true,
          padding: EdgeInsets.zero,
          body: Builder(
            builder: (context) {
              bodyTop = MediaQuery.paddingOf(context).top;
              return _rows();
            },
          ),
        ),
      ),
    );
    expect(bodyTop, 24 + 64);
    // The body starts under the status bar, behind the bar.
    expect(tester.getTopLeft(find.text('Row 0')).dy, 0);

    Color barColor() => tester
        .widget<ExpressiveSurface>(
          find
              .descendant(
                of: find.byType(ExpressiveAppBar),
                matching: find.byType(ExpressiveSurface),
              )
              .first,
        )
        .color;
    expect(barColor().a, 0);

    await tester.drag(find.byType(Scrollable), const Offset(0, -200));
    await tester.pumpAndSettle();
    // AppBarTokens.onScrollContainerColor.
    expect(barColor(), _theme.colors.surfaceContainer);
  });

  testWidgets('a sheet derives close and the title', (tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          const ExpressiveSheetPage<void>(
            child: ExpressiveScaffold(title: 'Filter', body: Text('Chips')),
          ).createRoute(tester.element(find.byType(SizedBox).first)),
        );
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsOneWidget);
    expect(find.byIcon(ExpressiveSymbols.close), findsOneWidget);
    await tester.tap(pressableOf(find.byIcon(ExpressiveSymbols.close)));
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsNothing);
  });

  testWidgets('an authored bar wins; none removes it (Cody: none sentinel)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveScaffold(
          title: 'Ignored',
          topBar: ExpressiveAppBar(title: 'Authored'),
          body: SizedBox(),
        ),
      ),
    );
    expect(find.text('Authored'), findsOneWidget);
    expect(find.text('Ignored'), findsNothing);

    await tester.pumpWidget(
      _app(
        const ExpressiveScaffold(
          title: 'Ignored',
          topBar: ExpressiveAppBar.none,
          body: Text('Body'),
        ),
      ),
    );
    expect(find.byType(ExpressiveAppBar), findsNothing);
    expect(find.text('Body'), findsOneWidget);
  });

  // CONTRACT §5 keyboard: a drag dismisses the keyboard on iOS (UIKit's
  // scrolling screens); on Android the keyboard stays up.
  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    final dismisses = platform == TargetPlatform.iOS;
    testWidgets('${platform.name}: a drag ${dismisses ? 'dismisses' : 'keeps'} '
        'the keyboard, collapsing or not', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        for (final title in <String?>['Journal', null]) {
          final field = FocusNode();
          addTearDown(field.dispose);
          await tester.pumpWidget(
            _app(
              ExpressiveScaffold(
                key: ValueKey<String?>(title),
                title: title,
                body: Focus(focusNode: field, child: _rows()),
              ),
            ),
          );
          field.requestFocus();
          await tester.pump();
          expect(field.hasFocus, isTrue);
          await tester.drag(find.byType(Scrollable), const Offset(0, -200));
          await tester.pumpAndSettle();
          expect(field.hasFocus, !dismisses, reason: 'title: $title');
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
