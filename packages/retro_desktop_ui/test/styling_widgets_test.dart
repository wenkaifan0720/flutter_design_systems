import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Widget host(
  Widget child,
  RetroDesktopThemeData theme, {
  double scale = 1,
  double width = 300,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: RetroDesktopTheme(
    data: theme,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

Color? wordsColor(WidgetTester tester, String words) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(words));
  return (paragraph.text as TextSpan).style?.color;
}

void main() {
  const blue = Color(0xff003366),
      red = Color(0xffaa0000),
      green = Color(0xff006622);
  for (final preset in RetroDesktopThemeData.presets) {
    for (final brightness in Brightness.values) {
      testWidgets('$preset $brightness active window keeps readable body ink', (
        tester,
      ) async {
        final theme = RetroDesktopThemeData.preset(preset, brightness);
        await tester.pumpWidget(
          host(
            const RetroDesktopWindowScope(
              active: true,
              compact: false,
              child: RetroDesktopWindow(
                title: 'Active window',
                child: Text('Plain body'),
              ),
            ),
            theme,
          ),
        );
        expect(wordsColor(tester, 'Plain body'), theme.colors.text);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final density in [
    RetroDesktopDensity.compact,
    RetroDesktopDensity.standard,
    RetroDesktopDensity.comfortable,
  ]) {
    for (final sizeScale in [.9, 1.15]) {
      testWidgets(
        'field target survives density ${density.name} and text $sizeScale',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              host(
                const RetroDesktopTextField(label: 'Name'),
                RetroDesktopThemeData.classic().copyWith(density: density),
                scale: sizeScale,
              ),
            );
            final result = await androidTapTargetGuideline.evaluate(tester);
            expect(result.passed, isTrue, reason: result.reason);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
  for (final width in [328.8, 316.8]) {
    testWidgets('hour columns fit fractional available width $width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const RetroDesktopHourStrip(
            hours: [
              RetroDesktopHour(
                label: 'Now',
                icon: RetroDesktopGlyphs.cloudRain,
                value: 8,
                reading: '8°',
                kind: RetroDesktopSkyCondition.rain,
                share: .6,
              ),
              RetroDesktopHour(
                label: 'Next',
                icon: RetroDesktopGlyphs.cloudRain,
                value: 10,
                reading: '10°',
                kind: RetroDesktopSkyCondition.rain,
                share: .2,
              ),
            ],
          ),
          RetroDesktopThemeData.classic().copyWith(
            density: RetroDesktopDensity.compact,
          ),
          width: width,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.8, 760.8]) {
    testWidgets('month columns fit fractional available width $width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const RetroDesktopMonthGrid(year: 2026, month: 11),
          RetroDesktopThemeData.classic().copyWith(
            density: RetroDesktopDensity.compact,
          ),
          width: width,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('surface overlays animate and cut when motion is disabled', (
    tester,
  ) async {
    final theme = RetroDesktopThemeData.classic().copyWith(
      motion: const RetroDesktopMotion(state: Duration(milliseconds: 200)),
    );
    const snapshot = ValueKey('overlay-snapshot');
    Widget sample(Color overlay, {bool reduce = false}) => host(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: RepaintBoundary(
          key: snapshot,
          child: RetroDesktopButton(
            'Overlay',
            wide: true,
            onPressed: () {},
            style: RetroDesktopStyle(
              fill: const WidgetStatePropertyAll(Colors.white),
              overlay: WidgetStatePropertyAll(overlay),
            ),
          ),
        ),
      ),
      theme,
    );
    Future<Color> drawn() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(snapshot),
      );
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset = ((image.height ~/ 2) * image.width + 8) * 4;
        final result = Color.fromARGB(
          data.getUint8(offset + 3),
          data.getUint8(offset),
          data.getUint8(offset + 1),
          data.getUint8(offset + 2),
        );
        image.dispose();
        return result;
      }))!;
    }

    await tester.pumpWidget(sample(const Color(0x00000000)));
    await tester.pumpWidget(sample(red));
    await tester.pump(const Duration(milliseconds: 100));
    final midpoint = await drawn();
    final expected = Color.alphaBlend(
      Color.lerp(const Color(0x00000000), red, .5)!,
      Colors.white,
    );
    expect(midpoint.r, closeTo(expected.r, .01));
    expect(midpoint.g, closeTo(expected.g, .01));
    expect(midpoint.b, closeTo(expected.b, .01));
    expect(midpoint, isNot(red));
    await tester.pump(const Duration(milliseconds: 100));
    expect(await drawn(), red);
    await tester.pumpWidget(sample(green, reduce: true));
    await tester.pump();
    expect(await drawn(), green);
  }, tags: const ['goldens']);

  testWidgets(
    'avatar styles size the visible face and color the fallback initials',
    (tester) async {
      await tester.pumpWidget(
        host(
          const RetroDesktopAvatar('AL'),
          RetroDesktopThemeData.classic().copyWith(
            avatarTheme: const RetroDesktopStyle(
              minimumSize: WidgetStatePropertyAll(Size(80, 64)),
              foreground: WidgetStatePropertyAll(red),
            ),
          ),
        ),
      );
      // The face's outline box (its clip sits inside the rim).
      final face = find.descendant(
        of: find.byType(RetroDesktopAvatar),
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_Face',
        ),
      );
      expect(tester.getSize(face.first), const Size(80, 64));
      expect(wordsColor(tester, 'AL'), red);
    },
  );

  testWidgets(
    'calendar headings wrap at double text scale without cutting words',
    (tester) async {
      await tester.pumpWidget(
        host(
          const RetroDesktopDayTile(
            month: 'November',
            year: '2026',
            day: '6',
            weekday: 'Wednesday',
            style: RetroDesktopStyle(
              minimumSize: WidgetStatePropertyAll(Size(180, 200)),
              shape: WidgetStatePropertyAll(
                BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
          ),
          RetroDesktopThemeData.classic(),
          scale: 2,
        ),
      );
      for (final text in ['November', '2026', 'Wednesday']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        expect(paragraph.didExceedMaxLines, isFalse, reason: text);
      }
      expect(
        tester.getBottomLeft(find.text('November')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('6')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'explicit states fall through to the component and own defaults',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final themed = RetroDesktopThemeData.classic().copyWith(
        defaultButtonTheme: RetroDesktopStyle(
          foreground: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused) ? red : null,
          ),
        ),
      );
      final style = RetroDesktopStyle(
        foreground: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? green : null,
        ),
      );
      await tester.pumpWidget(
        host(
          RetroDesktopButton(
            'Commit',
            isDefaultAction: true,
            onPressed: () {},
            focusNode: focus,
            style: style,
          ),
          themed,
        ),
      );
      expect(wordsColor(tester, 'Commit'), themed.colors.onHighlight);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      expect(wordsColor(tester, 'Commit'), red);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Commit')),
      );
      await tester.pump(kPressTimeout);
      expect(wordsColor(tester, 'Commit'), green);
      await gesture.up();
    },
  );

  testWidgets(
    'density changes the visible face without shrinking touch reach',
    (tester) async {
      final base = RetroDesktopThemeData.classic();
      Widget button() => RetroDesktopButton(
        'Go',
        size: RetroDesktopButtonSize.small,
        onPressed: () {},
      );
      await tester.pumpWidget(host(button(), base));
      final regular = tester.getSize(find.byType(RetroDesktopButton));
      await tester.pumpWidget(
        host(button(), base.copyWith(density: RetroDesktopDensity.compact)),
      );
      final compact = tester.getSize(find.byType(RetroDesktopButton));
      expect(compact.width, lessThanOrEqualTo(regular.width));
      expect(compact.height, greaterThanOrEqualTo(44));
      expect(compact.width, greaterThanOrEqualTo(44));
    },
  );

  testWidgets('a control keeps its rim at its own height in a stretched row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RetroDesktopButton('Apply', onPressed: () {}),
              const Expanded(child: Text('Details')),
            ],
          ),
        ),
        RetroDesktopThemeData.classic(),
      ),
    );
    final faces = find.descendant(
      of: find.byType(RetroDesktopButton),
      matching: find.byWidgetPredicate(
        (w) => w is ClipPath && w.clipper is ShapeBorderClipper,
      ),
    );
    expect(faces, findsWidgets);
    for (final face in faces.evaluate()) {
      final rect = tester.getRect(
        find.byElementPredicate((e) => identical(e, face)),
      );
      expect(rect.height, lessThan(160));
      expect(rect.height, greaterThan(20));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('arbitrary application outline reaches the rendered face', (
    tester,
  ) async {
    const outline = StadiumBorder();
    await tester.pumpWidget(
      host(
        RetroDesktopButton(
          'Custom outline',
          onPressed: () {},
          style: const RetroDesktopStyle(
            shape: WidgetStatePropertyAll(outline),
            fill: WidgetStatePropertyAll(blue),
            side: WidgetStatePropertyAll(BorderSide(color: red, width: 3)),
          ),
        ),
        RetroDesktopThemeData.classic(),
      ),
    );
    final clips = tester.widgetList<ClipPath>(
      find.descendant(
        of: find.byType(RetroDesktopButton),
        matching: find.byType(ClipPath),
      ),
    );
    expect(
      clips.any(
        (w) =>
            w.clipper is ShapeBorderClipper &&
            (w.clipper! as ShapeBorderClipper).shape is StadiumBorder,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('comfortable padding stays usable at 2x text in RTL, Chisel', (
    tester,
  ) async {
    final theme = RetroDesktopThemeData.classic().copyWith(
      density: RetroDesktopDensity.comfortable,
      appearance: RetroDesktopAppearance.chisel,
    );
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: Column(
            children: [
              RetroDesktopWindow(
                title: 'A longer window title',
                child: RetroDesktopTextField(
                  label: 'Search',
                  hint: 'Search files',
                ),
              ),
              RetroDesktopTabBar(
                tabs: const ['First tab', 'Second tab'],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
              const RetroDesktopBanner(
                title: 'Saved',
                message: 'Your changes are on this computer.',
              ),
              const RetroDesktopLinearProgressIndicator(
                label: 'Copying files',
                value: .5,
              ),
              RetroDesktopListTile(
                title: 'Local folder',
                note: 'Available offline',
                onPressed: () {},
              ),
            ],
          ),
        ),
        theme,
        scale: 2,
        direction: TextDirection.rtl,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('new component themes retain their identities through copy and interpolation', () {
    const first = RetroDesktopStyle(fill: WidgetStatePropertyAll(blue));
    const second = RetroDesktopStyle(fill: WidgetStatePropertyAll(red));
    final a = RetroDesktopThemeData.classic().copyWith(
      windowTheme: first,
      wellTheme: second,
      toolbarTheme: first,
      appBarTheme: second,
      navigationBarTheme: first,
      tabBarTheme: second,
      listTileTheme: first,
      disclosureTheme: second,
      progressTheme: first,
      noticeTheme: second,
      dividerTheme: first,
      chartTheme: second,
    );
    final b = a.lerp(a.copyWith(windowTheme: second, wellTheme: first), .5);
    expect(a.windowTheme, first);
    expect(a.wellTheme, second);
    expect(a.toolbarTheme, first);
    expect(a.copyWith(), a);
    expect(b.windowTheme.fill!.resolve({}), Color.lerp(blue, red, .5));
    expect(b.wellTheme.fill!.resolve({}), Color.lerp(red, blue, .5));
    expect(b.toolbarTheme, first);
  });
  testWidgets(
    'group title and table headers grow at 2x without crossing their contents',
    (tester) async {
      const bodyKey = ValueKey('group-body');
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: Column(
              children: [
                const RetroDesktopGroupBox(
                  title: 'Settings group',
                  child: Text('Group content', key: bodyKey),
                ),
                const RetroDesktopTable(
                  columns: [
                    RetroDesktopTableColumn('Name'),
                    RetroDesktopTableColumn('Quantity', width: 160),
                    RetroDesktopTableColumn('Date', width: 160),
                  ],
                  rows: [
                    ['File', '12', 'Tomorrow'],
                  ],
                ),
              ],
            ),
          ),
          RetroDesktopThemeData.classic(),
          scale: 2,
        ),
      );
      expect(
        tester.getBottomLeft(find.text('Settings group')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(bodyKey)).dy),
      );
      final horizontal = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .where((s) => s.position.axis == Axis.horizontal);
      expect(horizontal.any((s) => s.position.maxScrollExtent > 0), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
