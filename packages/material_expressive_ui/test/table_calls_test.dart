/// The 11-05 table calls (`scratch/looks/api_table.md`): the parts the
/// table names take its words, the press ink is Expressive's whatever the
/// host's splash, keyboard focus draws the M3 ring at 3:1, an action row
/// whose press would do nothing is out of use, and the date range headline
/// stops growing at Material's 1.3.
library;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart'
    show InkResponse, InkRipple, InkSparkle, NoSplash, Theme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// [child] in a 390dp-wide column, under the Expressive host.
Widget _app(Widget child, {double textScale = 1}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Center(child: SizedBox(width: 390, child: child)),
    ),
  ),
);

/// [builder]'s page on a navigator, so dialogs, sheets and snackbars rise.
Widget _page(WidgetBuilder builder) => _app(
  SizedBox(
    height: 800,
    child: Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => builder(context),
      ),
    ),
  ),
);

void _expectEnabled(WidgetTester tester, Finder pressable, bool enabled) {
  final handle = tester.ensureSemantics();
  expect(
    tester.getSemantics(pressable),
    isSemantics(hasEnabledState: true, isEnabled: enabled),
  );
  handle.dispose();
}

void main() {
  group('ExpressiveChip, as the table has it', () {
    testWidgets('tells its kind by what it is given', (tester) async {
      await tester.pumpWidget(
        _app(
          Wrap(
            children: <Widget>[
              ExpressiveChip('Assist', onPressed: () {}),
              ExpressiveChip('Filter', selected: true, onPressed: () {}),
              ExpressiveChip('Input', onDeleted: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // A selected filter chip leads with the check; an input chip ends
      // with its remove glyph.
      expect(find.byIcon(ExpressiveSymbols.check), findsOneWidget);
      expect(find.byIcon(ExpressiveSymbols.close), findsOneWidget);
    });

    testWidgets('a filter chip flips on onPressed', (tester) async {
      var on = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, update) => _app(
            ExpressiveChip.filter(
              'Open now',
              selected: on,
              onPressed: () => update(() => on = !on),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open now'));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      await tester.tap(find.text('Open now'));
      await tester.pumpAndSettle();
      expect(on, isFalse);
    });

    testWidgets('deleteLabel names the remove target', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          ExpressiveChip(
            'Hiking',
            onDeleted: () {},
            deleteLabel: 'Drop the hiking tag',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Drop the hiking tag'), findsOneWidget);
      await tester.pumpWidget(_app(ExpressiveChip('Hiking', onDeleted: () {})));
      expect(find.bySemanticsLabel('Drop the hiking tag'), findsNothing);
      handle.dispose();
    });
  });

  group('the segmented buttons', () {
    const segments = <ExpressiveButtonSegment<String>>[
      ExpressiveButtonSegment('day', 'Day'),
      ExpressiveButtonSegment('week', 'Week'),
      ExpressiveButtonSegment('month', 'Month', enabled: false),
    ];

    testWidgets('one value: told the segment chosen, never the same one', (
      tester,
    ) async {
      var value = 'day';
      final told = <String>[];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, update) => _app(
            ExpressiveSegmentedButton<String>(
              segments: segments,
              value: value,
              onChanged: (next) => update(() {
                told.add(next);
                value = next;
              }),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.tap(find.text('Month'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(told, <String>['week']);
    });

    testWidgets('a set: toggles, and keeps the last unless empty is allowed', (
      tester,
    ) async {
      for (final allowed in <bool>[false, true]) {
        var value = <String>{'day'};
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, update) => _app(
              ExpressiveMultiChoiceSegmentedButton<String>(
                segments: segments,
                value: value,
                emptySelectionAllowed: allowed,
                onChanged: (next) => update(() => value = next),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Week'));
        await tester.pumpAndSettle();
        expect(value, <String>{'day', 'week'});
        await tester.tap(find.text('Day'));
        await tester.pumpAndSettle();
        expect(value, <String>{'week'});
        // The last one chosen: let go only when empty is allowed.
        await tester.tap(find.text('Week'));
        await tester.pumpAndSettle();
        expect(value, allowed ? <String>{} : <String>{'week'});
      }
    });

    testWidgets('no onChanged: out of use', (tester) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveSegmentedButton<String>(
            segments: segments,
            value: 'day',
            onChanged: null,
          ),
        ),
      );
      final week = find.descendant(
        of: find.widgetWithText(ExpressiveToggleButton, 'Week'),
        matching: find.byType(ExpressivePressable),
      );
      _expectEnabled(tester, week, false);
    });
  });

  group('the snackbar functions', () {
    testWidgets('hideCurrentExpressiveSnackBar lets the next one up', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        _page((context) {
          page = context;
          return const SizedBox.expand();
        }),
      );
      showExpressiveSnackBar(page, 'First');
      showExpressiveSnackBar(page, 'Second');
      await tester.pumpAndSettle();
      expect(find.text('First'), findsOneWidget);
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });

    test('a duration knows its timeout', () {
      expect(ExpressiveSnackBarDuration.short.timeout, isNotNull);
      expect(
        ExpressiveSnackBarDuration.long.timeout! >
            ExpressiveSnackBarDuration.short.timeout!,
        isTrue,
      );
      expect(ExpressiveSnackBarDuration.indefinite.timeout, isNull);
    });
  });

  group('the press ink', () {
    testWidgets("is Expressive's whatever splash the host names", (
      tester,
    ) async {
      for (final platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        // The host's Material theme names no splash at all.
        await tester.pumpWidget(
          _app(
            Theme(
              data: ThemeData(splashFactory: NoSplash.splashFactory),
              child: ExpressiveFilledButton('Save', onPressed: () {}),
            ),
          ),
        );
        final ink = tester.widget<InkResponse>(find.byType(InkResponse));
        expect(
          ink.splashFactory,
          platform == TargetPlatform.android
              ? InkSparkle.splashFactory
              : InkRipple.splashFactory,
          reason: platform.name,
        );
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('the focus ring', () {
    final ring = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          '${w.foregroundPainter.runtimeType}' == '_FocusRingPainter',
    );

    /// Focuses the pressable's own node (its ink response's, which lies over
    /// the content), as a Tab would, without depending on it.
    void focus(WidgetTester tester) => Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byWidgetPredicate((w) => w is InkResponse),
              matching: find.byType(MouseRegion),
            )
            .first,
      ),
      createDependency: false,
    ).requestFocus();

    testWidgets('draws under keyboard focus, never in touch mode', (
      tester,
    ) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(
        _app(ExpressiveFilledButton('Save', onPressed: () {})),
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      focus(tester);
      await tester.pumpAndSettle();
      expect(ring, findsNothing);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pumpAndSettle();
      expect(ring, findsOneWidget);
      // A stroke centred 3.5dp out: the 3dp ring, 2dp off the edge.
      final box = Offset.zero & tester.getSize(ring);
      expect(
        ring,
        paints..something((method, args) {
          if (method != #drawRRect) return false;
          final rrect = args[0] as RRect;
          final paint = args[1] as Paint;
          expect(rrect.outerRect, box.inflate(3.5));
          expect(paint.style, PaintingStyle.stroke);
          expect(paint.strokeWidth, ExpressiveFocusRing.thickness);
          expect(paint.color, isSameColorAs(_theme.colors.secondary));
          return true;
        }),
      );
      primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(ring, findsNothing);
    });

    testWidgets('draws on a phone whose mouse connected after the part was '
        'built, though no listener heard the mode turn', (tester) async {
      // Each test starts on a fresh focus manager, its mode the platform's
      // default: touch on Android until a mouse connects, then traditional
      // without a word to the highlight-mode listeners.
      await tester.pumpWidget(
        _app(ExpressiveFilledButton('Save', onPressed: () {})),
      );
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      focus(tester);
      await tester.pumpAndSettle();
      expect(ring, findsOneWidget);
    });

    test('reads at 3:1 on every surface of every preset, light and dark', () {
      expect(ExpressiveFocusRing.thickness, 3);
      expect(ExpressiveFocusRing.offset, 2);
      for (final id in ExpressiveThemeData.presets) {
        for (final brightness in Brightness.values) {
          final c = ExpressiveThemeData.preset(id, brightness).colors;
          for (final (name, surface) in <(String, Color)>[
            ('surface', c.surface),
            ('surfaceDim', c.surfaceDim),
            ('surfaceBright', c.surfaceBright),
            ('surfaceContainerLowest', c.surfaceContainerLowest),
            ('surfaceContainerLow', c.surfaceContainerLow),
            ('surfaceContainer', c.surfaceContainer),
            ('surfaceContainerHigh', c.surfaceContainerHigh),
            ('surfaceContainerHighest', c.surfaceContainerHighest),
          ]) {
            expect(
              expressiveContrastRatio(c.secondary, surface),
              greaterThanOrEqualTo(3),
              reason: '$id ${brightness.name}: secondary on $name',
            );
          }
        }
      }
    });
  });

  group('an action row whose press would do nothing', () {
    testWidgets('a dialog action that neither closes nor runs is out of use', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ExpressiveDialog(
            title: 'Rename',
            actions: <ExpressiveDialogAction>[
              ExpressiveDialogAction('Stay', closesDialog: false),
              ExpressiveDialogAction('Close'),
            ],
          ),
        ),
      );
      Finder pressable(String label) => find
          .ancestor(
            of: find.text(label),
            matching: find.byType(ExpressivePressable),
          )
          .first;
      _expectEnabled(tester, pressable('Stay'), false);
      _expectEnabled(tester, pressable('Close'), true);
      expect(
        const ExpressiveDialogAction('Stay', closesDialog: false).inUse,
        isFalse,
      );
      expect(
        ExpressiveDialogAction(
          'Check',
          closesDialog: false,
          onPressed: () {},
        ).inUse,
        isTrue,
      );
      expect(
        const ExpressiveDialogAction('Off', enabled: false).inUse,
        isFalse,
      );
    });
  });

  testWidgets('the date range headline stops growing at 1.3', (tester) async {
    double? scaleOf(String text) =>
        MediaQuery.textScalerOf(tester.element(find.text(text))).scale(10) / 10;
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 700,
          child: ExpressiveDateRangePicker(
            start: DateTime(2026, 9, 3),
            end: DateTime(2026, 9, 9),
            currentDate: DateTime(2026, 9, 1),
            initialMonth: DateTime(2026, 9),
            onChanged: (_, _) {},
          ),
        ),
        textScale: 2,
      ),
    );
    final start = ExpressiveFormat.date(DateTime(2026, 9, 3));
    expect(scaleOf(start), closeTo(1.3, 1e-9));
    // The calendar below keeps the reader's scale.
    expect(scaleOf('September 2026'), closeTo(2, 1e-9));
  });
}
