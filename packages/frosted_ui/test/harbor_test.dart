// Harbor, the example's live app (frosted-glass.md, the gate): its Activity and its Settings on a phone (390) and at
// desktop width (1440), by day, by night and over the night sky. On each it draws without an error, keeps Flutter's
// guidelines (Android's 48 px targets, labelled targets, and every word's contrast read off the glass as drawn), and
// works: a row opens its transaction (a sheet on a phone, the pane beside the list at desktop width), the tabs move
// between the screens, the backdrop select sets the theme's backdrop, and Close account asks first. And each screen,
// grown to its whole page, keeps P's keylines (keylines.dart): one leading and one trailing edge per card, section,
// settings group and sidebar, and one height for the controls in a row. With KEYLINES_OUT set, each screen is
// written there with its keylines drawn over it.
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:ui_core/alignment.dart';

import 'keylines.dart';

// Harbor is the example app's; a test reads it from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/harbor.dart';

/// Harbor in a theme it can change: its Settings set the appearance and the
/// backdrop, as the gallery's do.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.brightness,
    required this.backdrop,
    this.density,
    super.key,
  });

  final Brightness brightness;
  final FrostedBackdropKind backdrop;

  /// The density the app is given; null keeps the preset's.
  final FrostedDensity? density;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Brightness _brightness = widget.brightness;
  late FrostedBackdropKind _backdrop = widget.backdrop;

  FrostedThemeData _theme(Brightness b) =>
      FrostedThemeData.preset(FrostedThemeData.presets.first, b).copyWith(
        backdrop: switch (_backdrop) {
          FrostedBackdropKind.night => const FrostedBackdrop.night(),
          FrostedBackdropKind.plain => const FrostedBackdrop.plain(),
          _ => const FrostedBackdrop.dawn(),
        },
        density: widget.density,
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, page) => RepaintBoundary(
      key: _screen,
      child: FrostedHost(
        light: _theme(Brightness.light),
        dark: _theme(Brightness.dark),
        brightness: _brightness,
        child: page!,
      ),
    ),
    home: HarborApp(
      host: HarborHost(
        onBackdrop: (kind) => setState(() => _backdrop = kind),
        onBrightness: (b) => setState(() => _brightness = b),
        onExit: () {},
      ),
    ),
  );
}

const _screen = ValueKey('screen');

/// Lets images decode (they load in real time), then paints the frame they
/// mark, so a check that reads pixels finds every boundary painted.
Future<void> _painted(WidgetTester tester) async {
  // Every image on screen decoded first (ui_core's recipe), then painted.
  await tester.runAsync(
    () => Future.wait([
      for (final e in find.byType(Image).evaluate())
        precacheImage((e.widget as Image).image, e),
    ]),
  );
  await tester.pump();
  // Images land in real time, each marking its boundary unpainted: wait
  // until a while passes with nothing left to paint (the desktop shows more
  // of them than 300 ms brings in).
  var still = 0;
  for (var i = 0; i < 40 && still < 2; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    // A boundary painted once and marked again (one never painted, as the
    // stack's hidden screen, waits for nothing).
    if (tester.allRenderObjects.any(
      (r) => r.isRepaintBoundary && r.debugLayer != null && r.debugNeedsPaint,
    )) {
      still = 0;
      await tester.pump();
    } else {
      still++;
    }
  }
}

/// What the shared checks read on [screen]: the screen shown and the
/// navigation beside or under it. Not the whole app: Harbor keeps the other
/// screen laid out, unpainted, in its IndexedStack, and the checks would
/// read it too.
List<Finder> _shown(String screen, bool wide) => [
  find.byType(screen == 'Activity' ? HarborActivity : HarborSettings),
  find.byType(wide ? FrostedNavigationDrawer : FrostedNavigationBar),
];

/// The bundled fonts under the names the look asks for. A family the package
/// declares itself is in the test bundle's manifest bare (`DMSans`), and the
/// look's styles name it as the package's (`packages/frosted_ui/DMSans`);
/// without both, every word is drawn in the test font's blocks.
Future<void> _loadFonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

/// Grows the view to the shown screen's whole page, so every card stands on
/// screen and none under a bar.
Future<void> _growToPage(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  await _settle(tester);
  final extents = [
    for (final s in tester.stateList<ScrollableState>(
      find.byType(Scrollable).hitTestable(),
    ))
      if (s.position.axis == Axis.vertical) s.position.maxScrollExtent,
  ];
  final extent = extents.isEmpty ? 0.0 : extents.reduce(math.max);
  if (extent > 0) {
    tester.view.physicalSize = Size(size.width, size.height + extent);
    await _settle(tester);
  }
}

/// Every card, section, settings group and sidebar on the shown screen.
Map<String, Finder> _containers() => {
  'section': find.byType(FrostedListSection).hitTestable(),
  'group': find.byType(FrostedSettingsGroup).hitTestable(),
  'card': find.byType(FrostedCard).hitTestable(),
  'sidebar': find.byType(FrostedNavigationDrawer).hitTestable(),
};

/// The backdrop the theme above [finder] stands on.
FrostedBackdropKind _backdropAt(WidgetTester tester, Finder finder) =>
    tester.element(finder.first).frostedTheme.backdrop.kind;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

/// The target guidelines, as laid out.
Future<void> _guidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

/// The words' contrast, read from drawn pixels: it depends on the rasterizer
/// as a golden does, so the tests that read it carry the goldens tag.
Future<void> _contrast(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  setUpAll(_loadFonts);
  const sizes = {'phone': Size(390, 844), 'desktop': Size(1440, 900)};
  const looks = {
    'day': (Brightness.light, FrostedBackdropKind.dawn),
    'night': (Brightness.dark, FrostedBackdropKind.dawn),
    'night sky': (Brightness.dark, FrostedBackdropKind.night),
  };

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    final wide = size.width >= 1024;
    for (final MapEntry(key: look, value: (brightness, backdrop))
        in looks.entries) {
      Future<void> pump(WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _Harness(brightness: brightness, backdrop: backdrop),
        );
        await _settle(tester);
      }

      testWidgets('Activity on a $device by $look', (tester) async {
        await pump(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Activity'), findsWidgets);
        expect(find.text('Today'), findsOneWidget);
        expect(
          find.byType(wide ? FrostedNavigationDrawer : FrostedNavigationBar),
          findsOneWidget,
        );
        await _guidelines(tester);

        // A row opens its transaction: in a sheet on a phone, in the pane
        // beside the list at desktop width (which opens on the newest, the
        // café, so the grocer's is the one that moves it).
        final (name, category) = wide
            ? ('Larder & Co.', 'Groceries')
            : ('Blue Fern Café', 'Dining out');
        final rows = find.text(name).evaluate().length;
        await tester.tap(find.text(name).first);
        await _settle(tester);
        expect(find.text(category), findsWidgets);
        if (wide) {
          // Beside the list: the rows and the pane's header.
          expect(find.text(name), findsNWidgets(rows + 1));
          expect(find.text('Get help'), findsOneWidget);
        } else {
          expect(find.text('Pending'), findsWidgets);
          expect(find.text('Done'), findsOneWidget);
          await _guidelines(tester);
          await tester.tap(find.text('Done'));
          await _settle(tester);
          expect(find.text('Done'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('Settings on a $device by $look', (tester) async {
        await pump(tester);
        await tester.tap(find.text('Settings').first);
        await _settle(tester);
        expect(find.text('Notifications'), findsOneWidget);
        await _guidelines(tester);

        // The backdrop's segments set the theme's backdrop.
        final next = backdrop == FrostedBackdropKind.night
            ? ('Plain', FrostedBackdropKind.plain)
            : ('Night sky', FrostedBackdropKind.night);
        await tester.ensureVisible(find.text(next.$1));
        await _settle(tester);
        await tester.tap(find.text(next.$1));
        await _settle(tester);
        expect(_backdropAt(tester, find.text('Notifications')), next.$2);

        // Close account asks first, and Keep it keeps it.
        await tester.ensureVisible(find.text('Close account'));
        await _settle(tester);
        await tester.tap(find.text('Close account'));
        await _settle(tester);
        expect(find.text('Close your account?'), findsOneWidget);
        await _guidelines(tester);
        await tester.tap(find.text('Keep it'));
        await _settle(tester);
        expect(find.text('Close your account?'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      // The words' contrast where the two tests above read the targets:
      // Activity (and its transaction's sheet on a phone), Settings and
      // Close account's dialog.
      testWidgets('words keep their contrast on a $device by $look', (
        tester,
      ) async {
        await pump(tester);
        await _contrast(tester);
        if (!wide) {
          await tester.tap(find.text('Blue Fern Café').first);
          await _settle(tester);
          await _contrast(tester);
          await tester.tap(find.text('Done'));
          await _settle(tester);
        }
        await tester.tap(find.text('Settings').first);
        await _settle(tester);
        await _contrast(tester);
        // The dialog over the backdrop the Settings test turns to.
        final next = backdrop == FrostedBackdropKind.night
            ? 'Plain'
            : 'Night sky';
        await tester.ensureVisible(find.text(next));
        await _settle(tester);
        await tester.tap(find.text(next));
        await _settle(tester);
        await tester.ensureVisible(find.text('Close account'));
        await _settle(tester);
        await tester.tap(find.text('Close account'));
        await _settle(tester);
        await _contrast(tester);
        expect(tester.takeException(), isNull);
      }, tags: const ['goldens']);

      if (look != 'night sky') {
        // ui_core's row check (the user, 16:34: "the button doesnt have the
        // same height here?"): every pair of controls sharing a row, read by
        // its drawn outline, under each density Frosted ships: both screens
        // and Close account's dialog.
        testWidgets(
          'rows on a $device by $look, standard and compact',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final problems = <String>[];
            for (final (name, density) in [
              ('standard', FrostedDensity.standard),
              ('compact', FrostedDensity.compact),
            ]) {
              tester.view.physicalSize = size;
              await tester.pumpWidget(
                _Harness(
                  key: ValueKey(name),
                  brightness: brightness,
                  backdrop: backdrop,
                  density: density,
                ),
              );
              await _settle(tester);
              for (final screen in ['Activity', 'Settings']) {
                if (screen == 'Settings') {
                  await tester.tap(find.text('Settings').first);
                  await _settle(tester);
                }
                for (final part in _shown(screen, wide)) {
                  await _painted(tester);
                  final report = await const DesignRowCheck(look: 'Frosted')
                      .check(tester.element(part), runAsync: tester.runAsync);
                  problems.addAll([
                    for (final p in report.problems) '$name · $screen: $p',
                  ]);
                }
              }
              await tester.ensureVisible(find.text('Close account'));
              await _settle(tester);
              await tester.tap(find.text('Close account'));
              await _settle(tester);
              await _painted(tester);
              final report = await const DesignRowCheck(look: 'Frosted').check(
                tester.element(find.byKey(_screen)),
                runAsync: tester.runAsync,
              );
              problems.addAll([
                for (final p in report.problems) '$name · Close account: $p',
              ]);
              await tester.tap(find.text('Keep it'));
              await _settle(tester);
            }
            // ignore: avoid_print
            print('CHECK rows harbor $device $look ${problems.length}');
            expect(problems, isEmpty, reason: problems.join('\n'));
          },
          // The check reads drawn pixels (the goldens tag); on a desktop by
          // night it misreads on macOS, skipped until 0.2.0 ("design-sweep
          // reads": row tops).
          tags: const ['goldens'],
          skip: wide && look == 'night',
        );
      }
      if (look == 'day' && wide) {
        // ui_core's width check (the user, 16:34: "the width for dropdown
        // seems to be a common problem"): from 600 wide each select, button,
        // stepper and segmented control keeps to its content, at most 320.
        testWidgets('controls keep to their content at 600, 1024, 1440 and '
            '1920', (tester) async {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final problems = <String>[];
          for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
            final at = Size(width, 900);
            tester.view.physicalSize = at;
            await tester.pumpWidget(
              _Harness(
                key: ValueKey(width),
                brightness: brightness,
                backdrop: backdrop,
              ),
            );
            await _settle(tester);
            for (final screen in ['Activity', 'Settings']) {
              if (screen == 'Settings') {
                await tester.tap(find.text('Settings').first);
                await _settle(tester);
              }
              for (final part in _shown(screen, width >= 1024)) {
                await _painted(tester);
                final report = await const DesignWidthCheck(look: 'Frosted')
                    .check(tester.element(part), runAsync: tester.runAsync);
                problems.addAll([
                  for (final p in report.problems)
                    '${width.round()} · $screen: $p',
                ]);
              }
            }
          }
          // ignore: avoid_print
          print('CHECK widths harbor ${problems.length}');
          expect(problems, isEmpty, reason: problems.join('\n'));
        }, tags: const ['goldens']);
      }

      if (look == 'night') continue;
      if (look == 'day') {
        // ui_core's shared check (design6 P) over the same screens, beside
        // our own measure below.
        testWidgets('the shared keyline check on a $device', (tester) async {
          await pump(tester);
          final problems = <String>[];
          for (final screen in ['Activity', 'Settings']) {
            if (screen == 'Settings') {
              await tester.tap(find.text('Settings').first);
              await _settle(tester);
            }
            await _painted(tester);
            for (final part in _shown(screen, wide)) {
              await _painted(tester);
              final report = await const DesignKeylineCheck(look: 'Frosted')
                  .check(tester.element(part), runAsync: tester.runAsync);
              problems.addAll([for (final p in report.problems) '$screen: $p']);
            }
          }
          expect(problems, isEmpty, reason: problems.join('\n'));
        }, tags: const ['goldens']);

        // ui_core's label sweep over both screens under each density
        // Frosted ships: every labelled control's label and icon on the
        // middle of its face.
        testWidgets(
          'labels on a $device, standard and compact',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final problems = <String>[];
            for (final (name, density) in [
              ('standard', FrostedDensity.standard),
              ('compact', FrostedDensity.compact),
            ]) {
              tester.view.physicalSize = size;
              await tester.pumpWidget(
                _Harness(
                  key: ValueKey(name),
                  brightness: brightness,
                  backdrop: backdrop,
                  density: density,
                ),
              );
              await _settle(tester);
              for (final screen in ['Activity', 'Settings']) {
                if (screen == 'Settings') {
                  await tester.tap(find.text('Settings').first);
                  await _settle(tester);
                }
                await _painted(tester);
                for (final part in _shown(screen, wide)) {
                  await _painted(tester);
                  final report = await const DesignLabelCheck(
                    look: 'Frosted',
                    drawnTolerance: 0.5,
                  ).check(tester.element(part), runAsync: tester.runAsync);
                  problems.addAll([
                    for (final p in report.problems) '$name · $screen: $p',
                  ]);
                }
              }
            }
            expect(problems, isEmpty, reason: problems.join('\n'));
          },
          // The check reads drawn pixels (the goldens tag); on a desktop it
          // misreads on macOS, skipped until 0.2.0 ("design-sweep reads":
          // label middles, ui_core's cap-factor read).
          tags: const ['goldens'],
          skip: wide,
        );
      }
      testWidgets('keylines on a $device by $look', (tester) async {
        await pump(tester);
        final faults = <String>[];
        for (final screen in ['Activity', 'Settings']) {
          if (screen == 'Settings') {
            tester.view.physicalSize = size;
            await _settle(tester);
            await tester.tap(find.text('Settings').first);
            await _settle(tester);
          } else if (wide) {
            await tester.tap(find.text('Blue Fern Café').first);
            await _settle(tester);
          }
          await _growToPage(tester, size);
          final shot = await keyShot(tester, find.byKey(_screen));
          final containers = _containers();
          for (final MapEntry(key: kind, value: finder) in containers.entries) {
            final n = finder.evaluate().length;
            for (var i = 0; i < n; i++) {
              faults.addAll(
                keylineFaults(
                  '$screen $kind ${i + 1}',
                  tester,
                  finder.at(i),
                  shot,
                ),
              );
            }
          }
          await writeKeylines(
            tester,
            'harbor-$device-${look.replaceAll(' ', '-')}-'
            '${screen.toLowerCase()}',
            shot,
            containers,
          );
          shot.image.dispose();
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      }, tags: const ['goldens']);
    }
  }
}
