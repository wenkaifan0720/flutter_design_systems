// The theme as Flutter's ThemeData is one: immutable, with copyWith, lerp, ==, hashCode and debugFillProperties; a
// ComicTheme that is an InheritedTheme and installs under any app; an animated one; motion that cuts under Reduce Motion.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + .05) / (lo + .05);
}

ComicThemeData _read(WidgetTester tester) =>
    ComicTheme.of(tester.element(find.byKey(const Key('probe'))));

const _probe = SizedBox(key: Key('probe'));

void main() {
  group('ComicThemeData', () {
    test('a named factory per preset, equal to preset()', () {
      expect(
        ComicThemeData.offset(),
        ComicThemeData.preset('offset', Brightness.light),
      );
      expect(
        ComicThemeData.reprint(Brightness.dark),
        ComicThemeData.preset('reprint', Brightness.dark),
      );
      expect(ComicThemeData.newsstand().id, 'newsstand');
      expect(ComicThemeData.pulp().id, 'pulp');
      expect(ComicThemeData.sunday().id, 'sunday');
      expect(ComicThemeData.presets, [
        'offset',
        'reprint',
        'newsstand',
        'pulp',
        'sunday',
      ]);
    });

    test('== and hashCode follow the parts', () {
      final a = ComicThemeData.offset();
      expect(a, a.copyWith());
      expect(a.hashCode, a.copyWith().hashCode);
      expect(a, isNot(ComicThemeData.offset(Brightness.dark)));
      expect(a, isNot(a.copyWith(width: 500)));
      expect(a, isNot(a.copyWith(onDots: true)));
    });

    test('copyWith changes only what it names', () {
      final a = ComicThemeData.offset();
      final b = a.copyWith(colors: ComicThemeData.sunday().colors);
      expect(b.id, 'offset');
      expect(b.colors, ComicThemeData.sunday().colors);
      expect(b.width, a.width);
      expect(a.copyWith(width: 1100).desk, isTrue);
      expect(a.copyWith(width: 1100).window, ComicWindowSizeClass.expanded);
    });

    test('lerp: the ends are the themes, the middle blends and flips', () {
      for (final id in ComicThemeData.presets) {
        final day = ComicThemeData.preset(id, Brightness.light);
        final night = ComicThemeData.preset(id, Brightness.dark);
        expect(day.lerp(night, 0), day);
        expect(day.lerp(night, 1).colors, night.colors);
        final mid = day.lerp(night, .5);
        expect(
          mid.colors.background,
          Color.lerp(day.colors.background, night.colors.background, .5),
        );
        expect(mid.colors.series.length, day.colors.series.length);
        expect(day.lerp(null, .3), same(day));
        expect(day.lerp(day, .7), same(day));
      }
      final a = ComicThemeData.offset(), b = ComicThemeData.reprint();
      expect(a.lerp(b, .4).id, 'offset');
      expect(a.lerp(b, .6).id, 'reprint');
      expect(
        a.copyWith(width: 400).lerp(a.copyWith(width: 800), .5).width,
        600,
      );
    });

    test('debugFillProperties names the parts', () {
      final names = DiagnosticPropertiesBuilder();
      ComicThemeData.offset(Brightness.dark).debugFillProperties(names);
      final listed = names.properties.map((p) => p.name).toList();
      expect(listed, containsAll(['id', 'brightness', 'width', 'colors']));
      final cn = DiagnosticPropertiesBuilder();
      ComicThemeData.offset().colors.debugFillProperties(cn);
      expect(
        cn.properties.map((p) => p.name),
        containsAll(['background', 'text', 'primary']),
      );
    });

    test('the window classes are Material\'s', () {
      expect(ComicWindowSizeClass.ofWidth(390), ComicWindowSizeClass.compact);
      expect(ComicWindowSizeClass.ofWidth(599.9), ComicWindowSizeClass.compact);
      expect(ComicWindowSizeClass.ofWidth(600), ComicWindowSizeClass.medium);
      expect(ComicWindowSizeClass.ofWidth(839), ComicWindowSizeClass.medium);
      expect(ComicWindowSizeClass.ofWidth(840), ComicWindowSizeClass.expanded);
      expect(ComicWindowSizeClass.ofWidth(1199), ComicWindowSizeClass.expanded);
      expect(ComicWindowSizeClass.ofWidth(1200), ComicWindowSizeClass.large);
    });

    test(
      'the focus ring reads 3:1 on every ground in every preset and mode',
      () {
        for (final id in ComicThemeData.presets) {
          for (final b in Brightness.values) {
            final t = ComicThemeData.preset(id, b);
            final ring = t.focus.color;
            for (final ground in [
              t.colors.background,
              t.colors.card,
              t.colors.control,
            ]) {
              expect(
                _ratio(ring, ground),
                greaterThanOrEqualTo(3),
                reason: '$id $b',
              );
            }
          }
        }
      },
    );
  });

  group('ComicTheme', () {
    for (final host in ['MaterialApp', 'CupertinoApp', 'WidgetsApp']) {
      testWidgets('installs under $host', (tester) async {
        Widget wear(BuildContext context, Widget? child) => ComicTheme(
          data: ComicThemeData.pulp(Brightness.dark),
          child: child!,
        );
        const home = _probe;
        await tester.pumpWidget(switch (host) {
          'MaterialApp' => MaterialApp(builder: wear, home: home),
          'CupertinoApp' => CupertinoApp(builder: wear, home: home),
          _ => WidgetsApp(
            color: const Color(0xFF000000),
            builder: wear,
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (c, a, s) => builder(c),
            ),
            home: home,
          ),
        });
        final t = _read(tester);
        expect(t.id, 'pulp');
        expect(t.brightness, Brightness.dark);
        expect(
          ComicTheme.maybeOf(tester.element(find.byKey(const Key('probe')))),
          t,
        );
        // Its text and icons wear it too.
        final context = tester.element(find.byKey(const Key('probe')));
        expect(
          DefaultTextStyle.of(context).style.fontFamily,
          contains('ShantellSans'),
        );
        expect(IconTheme.of(context).color, t.colors.text);
      });
    }

    testWidgets('of throws without one, maybeOf answers null', (tester) async {
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: _probe),
      );
      final context = tester.element(find.byKey(const Key('probe')));
      expect(ComicTheme.maybeOf(context), isNull);
      expect(() => ComicTheme.of(context), throwsFlutterError);
    });

    testWidgets('a nested one restyles its subtree only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComicTheme(
            data: ComicThemeData.offset(),
            child: Column(
              children: [
                const SizedBox(key: Key('outer')),
                ComicTheme(
                  data: ComicThemeData.reprint(Brightness.dark),
                  child: const SizedBox(key: Key('inner')),
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        ComicTheme.of(tester.element(find.byKey(const Key('outer')))).id,
        'offset',
      );
      expect(
        ComicTheme.of(tester.element(find.byKey(const Key('inner')))).id,
        'reprint',
      );
    });

    testWidgets('a route raised under it keeps it (InheritedTheme.capture)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComicTheme(
            data: ComicThemeData.sunday(),
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showDialog<void>(context: context, builder: (_) => _probe),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(_read(tester).id, 'sunday');
    });

    testWidgets('its type is set for the window it stands in', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, child) =>
              ComicTheme(data: ComicThemeData.offset(), child: child!),
          home: _probe,
        ),
      );
      final t = _read(tester);
      expect(t.desk, isTrue);
      expect(t.window, ComicWindowSizeClass.large);
    });

    testWidgets('AnimatedComicTheme eases to a new theme through lerp', (
      tester,
    ) async {
      Widget app(ComicThemeData data) => MaterialApp(
        home: AnimatedComicTheme(
          data: data,
          duration: const Duration(milliseconds: 200),
          child: _probe,
        ),
      );
      await tester.pumpWidget(app(ComicThemeData.offset()));
      final start = _read(tester).colors.background;
      await tester.pumpWidget(app(ComicThemeData.offset(Brightness.dark)));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _read(tester).colors.background;
      expect(mid, isNot(start));
      expect(
        mid,
        isNot(ComicThemeData.offset(Brightness.dark).colors.background),
      );
      await tester.pumpAndSettle();
      expect(
        _read(tester).colors.background,
        ComicThemeData.offset(Brightness.dark).colors.background,
      );
    });

    testWidgets('ComicDotsScope and ComicLetteringScope re-scope the inks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComicTheme(
            data: ComicThemeData.offset(),
            child: Column(
              children: const [
                ComicDotsScope(child: SizedBox(key: Key('dots'))),
                ComicLetteringScope(
                  Color(0xFFFF00FF),
                  child: SizedBox(key: Key('letters')),
                ),
              ],
            ),
          ),
        ),
      );
      final dots = ComicTheme.of(tester.element(find.byKey(const Key('dots'))));
      expect(dots.onDots, isTrue);
      expect(dots.colors.textSecondary, dots.colors.text);
      final letters = ComicTheme.of(
        tester.element(find.byKey(const Key('letters'))),
      );
      expect(letters.colors.text, const Color(0xFFFF00FF));
    });

    testWidgets('Reduce Motion cuts every duration', (tester) async {
      late BuildContext still, moving;
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: Builder(
                  builder: (c) {
                    still = c;
                    return const SizedBox();
                  },
                ),
              ),
              Builder(
                builder: (c) {
                  moving = c;
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      );
      expect(ComicMotion.of(still).press, Duration.zero);
      expect(ComicMotion.of(still).raise, Duration.zero);
      expect(
        ComicMotion.durationOf(still, const Duration(seconds: 1)),
        Duration.zero,
      );
      expect(ComicMotion.of(moving).press, const ComicMotion().press);
      expect(
        ComicMotion.durationOf(moving, const Duration(seconds: 1)),
        const Duration(seconds: 1),
      );
    });
  });
}
