// Exercise the actual example, including the formerly fixed enabled controls.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/trip.dart';
import 'gallery_support.dart';

Future<void> _pump(WidgetTester tester, String page) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GalleryApp(key: ValueKey(page), initialPage: page));
  await settle(tester);
  expect(tester.takeException(), isNull);
}

/// Opens [destination] through the example's own navigation: the drawer
/// behind the app bar's menu button on a phone, the wide rail otherwise.
Future<void> _go(WidgetTester tester, String destination) async {
  // Fixed frames, not pumpAndSettle: some destinations open on an
  // indeterminate indicator, which never settles.
  final menu = _button('Open navigation');
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu);
    await settle(tester);
  }
  // The item, not its label: the item's state layers lie over the label.
  final item = find.ancestor(
    of: find.descendant(
      of: find.byType(ExpressiveNavigationRail),
      matching: find.text(destination),
    ),
    matching: find.byType(MergeSemantics),
  );
  // A long list of destinations scrolls under the rail's header.
  await tester.ensureVisible(item.first);
  await settle(tester);
  await tester.tap(item.first);
  await settle(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _show(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _show(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final pageScroll = find
        .descendant(of: find.byType(KitPage), matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(pageScroll).position;
    for (var i = 0; target.evaluate().isEmpty && i < 100; i++) {
      final previous = position.pixels;
      position.jumpTo(
        (position.pixels + 300).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pumpAndSettle();
      if (position.pixels == previous) break;
    }
    expect(target, findsWidgets);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder _key(String key) => find.byKey(ValueKey(key));

/// The example's icon button named [label]: its app bar's actions and its
/// menu button.
Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is ExpressiveIconButton && widget.semanticLabel == label,
);
Finder _inside(Finder root, Type type) =>
    find.descendant(of: root, matching: find.byType(type));

class _RecordingAssets extends CachingAssetBundle {
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) {
    loads.add(key);
    return rootBundle.load(key);
  }
}

void main() {
  setUpAll(loadExpressiveFonts);
  tearDown(() {
    kitShownTheme = null;
    kitShownPreset = 'baseline';
  });

  testWidgets('pending demo media does not request absent photos', (
    tester,
  ) async {
    final bundle = _RecordingAssets();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: const GalleryApp(initialPage: 'media'),
      ),
    );
    await settle(tester);
    expect(find.byType(ExpressiveImagePlaceholder), findsWidgets);
    expect(
      bundle.loads.where((key) => key.startsWith('assets/media/')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the live symbol browser pages and finds a final-page glyph', (
    tester,
  ) async {
    await _pump(tester, 'icons');
    final first = ExpressiveSymbols.byName.entries.first.key;
    final last = ExpressiveSymbols.byName.entries.last.key;
    expect(_key('gallery-symbol/$first'), findsOneWidget);
    await _tap(tester, _key('gallery-symbol-next'));
    expect(_key('gallery-symbol/$first'), findsNothing);
    final field = _key('gallery-symbol-filter');
    await _show(tester, field);
    await tester.enterText(
      _inside(field, EditableText),
      last.replaceAll('_', ' '),
    );
    await tester.pumpAndSettle();
    expect(_key('gallery-symbol/$last'), findsOneWidget);
    expect(
      tester.widget<ExpressiveButton>(_key('gallery-symbol-next')).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop references hold their column to the start edge and keep native '
    'picker widths',
    (tester) async {
      await _pump(tester, 'pickers');
      tester.view.physicalSize = const Size(1440, 1000);
      await settle(tester);
      final list = find
          .descendant(of: find.byType(KitPage), matching: find.byType(ListView))
          .first;
      final bounds = tester.getRect(list);
      expect(bounds.width, 960);
      // On the start edge of what the navigation rail leaves, where the
      // app bar title and the tabs start; the rest of the width stays free.
      final rail = tester.getRect(find.byType(ExpressiveNavigationRail));
      final page = tester.getRect(find.byType(KitPage));
      expect(page.left, greaterThanOrEqualTo(rail.right));
      expect(bounds.left, page.left);
      expect(
        tester.getSize(find.byType(ExpressiveDatePicker).first).width,
        360,
      );
      final range = find.byType(ExpressiveDateRangePicker);
      expect(range, findsNothing);
      await _show(tester, range);
      expect(tester.getSize(range).width, 360);
      await tester.tap(
        find
            .descendant(
              of: range,
              matching: find.bySemanticsLabel('Monday, 21 September 2026'),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExpressiveDateRangePicker>(range).start,
        DateTime(2026, 9, 21),
      );
      await tester.tap(
        find
            .descendant(
              of: range,
              matching: find.bySemanticsLabel('Wednesday, 23 September 2026'),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExpressiveDateRangePicker>(range).end,
        DateTime(2026, 9, 23),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('live filter and input chips change their actual values', (
    tester,
  ) async {
    await _pump(tester, 'chips');
    await _show(tester, _key('kit-section/Filter'));
    final takeout = find.byWidgetPredicate(
      (widget) => widget is ExpressiveChip && widget.label == 'Takeout',
    );
    expect(tester.widget<ExpressiveChip>(takeout).selected, isFalse);
    await _tap(tester, takeout);
    expect(tester.widget<ExpressiveChip>(takeout).selected, isTrue);
    await _show(tester, _key('kit-section/Input'));
    await _tap(tester, find.bySemanticsLabel('Remove Mara Quist'));
    expect(find.text('Mara Quist'), findsNothing);
    expect(find.text('Theo Lind'), findsOneWidget);
  });

  testWidgets(
    'live reference pages defer offscreen controls and preserve choices',
    (tester) async {
      await _pump(tester, 'pickers');
      expect(find.byType(ExpressiveTimeScroll), findsNothing);
      final calendar = find.byType(ExpressiveDatePicker).first;
      await _tap(
        tester,
        find.descendant(of: calendar, matching: find.text('21')),
      );
      expect(
        tester.widget<ExpressiveDatePicker>(calendar).selected,
        DateTime(2026, 9, 21),
      );
      await _show(tester, find.byType(ExpressiveTimeScroll));
      expect(find.byType(ExpressiveTimeScroll), findsOneWidget);
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(KitPage),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      scroll.jumpTo(scroll.minScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ExpressiveDatePicker>(calendar).selected,
        DateTime(2026, 9, 21),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('live app bars change size and save notes', (tester) async {
    await _pump(tester, 'app-bar');
    final bars = find.byWidgetPredicate(
      (widget) => widget is ExpressiveAppBar && widget.title == 'Field notes',
    );
    expect(
      tester.widget<ExpressiveAppBar>(bars).size,
      ExpressiveAppBarSize.small,
    );
    await _tap(tester, find.text('Large'));
    expect(
      tester.widget<ExpressiveAppBar>(bars).size,
      ExpressiveAppBarSize.large,
    );
    await _tap(tester, find.bySemanticsLabel('Save notes'));
    expect(find.text('1 saved note'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Unsave notes'));
    expect(find.text('No saved notes'), findsOneWidget);
  });

  testWidgets('the live navigation preview changes variant and destination', (
    tester,
  ) async {
    await _pump(tester, 'nav');
    final bar = find.byType(ExpressiveNavigationBar);
    expect(tester.widget<ExpressiveNavigationBar>(bar).destinations.length, 3);
    await tester.tapAt(
      tester.getCenter(find.descendant(of: bar, matching: find.text('Saved'))),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ExpressiveNavigationBar>(bar).selectedIndex, 1);
    await _tap(tester, _key('gallery-navigation-variant'));
    await _tap(tester, find.text('Four with badges').last);
    expect(tester.widget<ExpressiveNavigationBar>(bar).destinations.length, 4);
    await tester.tapAt(
      tester.getCenter(
        find.descendant(of: bar, matching: find.text('Updates')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ExpressiveNavigationBar>(bar).selectedIndex, 2);
    await _tap(tester, _key('gallery-navigation-variant'));
    await _tap(tester, find.text('Horizontal layout').last);
    expect(
      tester.widget<ExpressiveNavigationBar>(bar).itemPosition,
      ExpressiveNavItemPosition.start,
    );
  });

  testWidgets('the live picker menu opens a dialog and returns its choice', (
    tester,
  ) async {
    await _pump(tester, 'pickers');
    await _tap(tester, _key('gallery-picker-dialogs'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(ExpressiveMenuSurface),
        matching: find.text('Date'),
      ),
    );
    final dialog = find.byType(ExpressiveDatePickerDialog);
    expect(dialog, findsOneWidget);
    await _tap(
      tester,
      find.descendant(of: dialog, matching: find.text('21')).first,
    );
    await _tap(tester, find.descendant(of: dialog, matching: find.text('OK')));
    expect(dialog, findsNothing);
    expect(find.text('Date: 21 Sep 2026'), findsOneWidget);
  });

  testWidgets('reference navigation keeps its host and resets only the page', (
    tester,
  ) async {
    await _pump(tester, 'pickers');
    final navigator = find
        .descendant(
          of: find.byType(ExpressivePreview),
          matching: find.byType(Navigator),
        )
        .first;
    final host = tester.state<NavigatorState>(navigator);
    final calendar = find.byType(ExpressiveDatePicker).first;
    await _tap(
      tester,
      find.descendant(of: calendar, matching: find.text('21')),
    );
    await _tap(tester, _button('Dark theme'));
    expect(tester.state<NavigatorState>(navigator), same(host));
    expect(
      tester.widget<ExpressiveDatePicker>(calendar).selected,
      DateTime(2026, 9, 21),
    );
    await _go(tester, 'Selection');
    await _tap(
      tester,
      find.descendant(
        of: find.byType(ExpressiveTabBar),
        matching: find.text('Chips'),
      ),
    );
    expect(tester.state<NavigatorState>(navigator), same(host));
    expect(find.byType(ExpressiveDatePicker), findsNothing);
    await _go(tester, 'Pickers');
    expect(tester.state<NavigatorState>(navigator), same(host));
    expect(
      tester.widget<ExpressiveDatePicker>(calendar).selected,
      DateTime(2026, 9, 18),
    );
  });

  testWidgets(
    'reference navigation disposes outgoing controls after its fade',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(tester.view.reset);
      final picker = galleryExamplePages.singleWhere(
        (page) => page.id == 'pickers',
      );
      final chips = galleryExamplePages.singleWhere(
        (page) => page.id == 'chips',
      );
      await tester.pumpWidget(galleryBuildPage(picker, Brightness.light));
      await settle(tester);
      final calendar = find.byType(ExpressiveDatePicker).first;
      final point = tester.getCenter(
        find.descendant(of: calendar, matching: find.text('21')),
      );
      final day = find.descendant(
        of: calendar,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ExpressivePressable &&
              (widget.semanticLabel?.endsWith('21 September 2026') ?? false),
        ),
      );
      final focusWidget = find
          .descendant(
            of: day,
            matching: find.byWidgetPredicate((widget) => widget is Focus),
          )
          .first;
      final focusLeaf = find
          .descendant(
            of: focusWidget,
            matching: find.byWidgetPredicate((_) => true),
          )
          .last;
      final focus = Focus.of(tester.element(focusLeaf));
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(galleryBuildPage(chips, Brightness.light));
      expect(find.byType(KitPage), findsNWidgets(2));
      expect(focus.hasFocus, isFalse);
      await tester.tapAt(point);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(
        tester.widget<ExpressiveDatePicker>(calendar).selected,
        DateTime(2026, 9, 18),
      );
      // The default effects spring finishes inside the profile's 30 initial
      // frames, so disposal remains part of that page's measured interval.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(find.byType(KitPage), findsOneWidget);
      expect(find.byType(ExpressiveDatePicker), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dialog in [true, false]) {
    testWidgets(
      '${dialog ? "dialog" : "filled outlined text"} action labels share a centre line and target height',
      (tester) async {
        for (final brightness in Brightness.values) {
          for (final density in [
            ExpressiveDensity.standard,
            ExpressiveDensity.comfortable,
            ExpressiveDensity.compact,
          ]) {
            for (final width in [360.0, 600.0]) {
              for (final (scale, direction) in [
                for (final scale in [1.0, 1.3])
                  for (final direction in TextDirection.values)
                    (scale, direction),
              ]) {
                final labels = dialog
                    ? ['Archive', 'Keep project']
                    : ['Save', 'Preview', 'Cancel'];
                await tester.pumpWidget(
                  MaterialApp(
                    builder: (context, child) => ExpressiveTheme(
                      data: ExpressiveThemeData.preset(
                        'baseline',
                        brightness,
                      ).copyWith(density: density),
                      child: MediaQuery(
                        data: MediaQueryData(
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: Directionality(
                          textDirection: direction,
                          child: child!,
                        ),
                      ),
                    ),
                    home: Center(
                      child: SizedBox(
                        width: width,
                        child: dialog
                            ? const ExpressiveDialog(
                                title: 'Archive project?',
                                actions: [
                                  ExpressiveDialogAction(
                                    'Keep project',
                                    value: false,
                                  ),
                                  ExpressiveDialogAction(
                                    'Archive',
                                    value: true,
                                    filled: true,
                                  ),
                                ],
                              )
                            : Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  ExpressiveFilledButton(
                                    'Save',
                                    onPressed: () {},
                                  ),
                                  ExpressiveOutlinedButton(
                                    'Preview',
                                    onPressed: () {},
                                  ),
                                  ExpressiveTextButton(
                                    'Cancel',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final centres = [
                  for (final label in labels)
                    tester.getRect(find.text(label)).center.dy,
                ];
                final targets = [
                  for (final label in labels)
                    tester
                        .getSize(
                          find
                              .ancestor(
                                of: find.text(label),
                                matching: find.byType(ExpressivePressable),
                              )
                              .first,
                        )
                        .height,
                ];
                for (var i = 1; i < labels.length; i++) {
                  // The labels are drawn by their capitals (DesignCapCenter),
                  // each within half a device pixel of its face's middle, as
                  // the engine's whole-pixel baseline allows (here DPR 1).
                  expect(
                    centres[i],
                    closeTo(centres.first, .5),
                    reason:
                        '$labels $brightness $density $width $scale $direction',
                  );
                  expect(
                    targets[i],
                    closeTo(targets.first, .01),
                    reason:
                        '$labels $brightness $density $width $scale $direction',
                  );
                }
                expect(tester.takeException(), isNull);
              }
            }
          }
        }
      },
    );
  }

  testWidgets('the example opens on the overview, whose cards open their '
      'destinations', (tester) async {
    for (final width in [390.0, 1440.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(GalleryApp(key: ValueKey(width)));
      await settle(tester);
      expect(find.text('Material 3 Expressive'), findsOneWidget);
      // The rail at a wide window; the drawer's menu button on a phone.
      expect(
        find.byType(ExpressiveNavigationRail),
        width >= galleryRailWidth ? findsOneWidget : findsNothing,
      );
      expect(
        _button('Open navigation'),
        width >= galleryRailWidth ? findsNothing : findsOneWidget,
      );
      // Each card's icon and words stand inside it, 16dp in (a card draws
      // no padding of its own; the 11-09 review found them on its outline).
      for (final card in find.byType(ExpressiveCard).evaluate()) {
        final box = tester.getRect(
          find.byElementPredicate((e) => identical(e, card)),
        );
        for (final part
            in find
                .descendant(
                  of: find.byElementPredicate((e) => identical(e, card)),
                  matching: find.byWidgetPredicate(
                    (w) => w is Text || w is Icon,
                  ),
                )
                .evaluate()) {
          final r = tester.getRect(
            find.byElementPredicate((e) => identical(e, part)),
          );
          expect(
            box.deflate(ExpressiveSpacing.s16 - .5).contains(r.topLeft) &&
                box.deflate(ExpressiveSpacing.s16 - .5).contains(r.bottomRight),
            isTrue,
            reason: '${width.round()}: $r in the card $box',
          );
        }
      }
      // Fixed frames: the Overview's live parts never settle.
      await tester.ensureVisible(_key('overview/trip'));
      await settle(tester);
      await tester.tap(_key('overview/trip'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      // The trip planner stands alone in the window: its own bar, no
      // gallery around it.
      expect(_key('trip-card'), findsOneWidget);
      expect(find.text('Material 3 Expressive'), findsNothing);
    }
  });

  testWidgets('at a wide window the app bar title, the first tab and the '
      "page's content start on one edge", (tester) async {
    // The 11-09 review: the title, the tabs and a centred column made three
    // start edges beside the rail.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    final failures = <String>[];
    for (final d in galleryDestinations) {
      if (d.pages.first == TripScreens.home) continue;
      await _go(tester, d.title);
      final edge = tester
          .getRect(
            find
                .descendant(
                  of: find.byType(ExpressiveAppBar),
                  matching: find.text(d.title),
                )
                .first,
          )
          .left;
      final tabs = find.byKey(ValueKey('tabs/${d.title}'));
      if (tabs.evaluate().isNotEmpty) {
        final first = find
            .ancestor(
              of: find
                  .descendant(
                    of: tabs,
                    matching: find.text(galleryTabLabel(d.pages.first)),
                  )
                  .first,
              matching: find.byType(ExpressivePressable),
            )
            .first;
        final left = tester.getRect(first).left;
        if ((left - edge).abs() > 1) {
          failures.add('${d.title}: first tab at $left, title at $edge');
        }
      }
      // The page's first line of text: its heading or first section's (not
      // the Overview's live trip planner, a screen of its own in a frame).
      final live = find.byKey(const ValueKey('overview/live-trip'));
      final texts =
          find
              .descendant(
                of: find.byKey(const ValueKey('page')),
                matching: find.byType(Text),
              )
              .evaluate()
              .where(
                (e) => find
                    .descendant(
                      of: live,
                      matching: find.byElementPredicate((x) => identical(x, e)),
                    )
                    .evaluate()
                    .isEmpty,
              )
              .map(
                (e) => tester.getRect(
                  find.byElementPredicate((x) => identical(x, e)),
                ),
              )
              .where((r) => r.height > 0 && r.top >= 0)
              .toList()
            ..sort((a, b) => a.top.compareTo(b.top));
      if (texts.isNotEmpty && (texts.first.left - edge).abs() > 1) {
        failures.add(
          '${d.title}: content at ${texts.first.left}, title at $edge',
        );
      }
    }
    expect(failures, isEmpty);
  });

  testWidgets('every page stands in one destination, and the drawer and the '
      'tabs reach it', (tester) async {
    final placed = [for (final d in galleryDestinations) ...d.pages];
    expect(placed.toSet(), hasLength(placed.length), reason: 'a page twice');
    expect(placed.toSet(), {
      galleryOverview,
      for (final page in galleryExamplePages)
        if (!galleryPlainRoutes.contains(page.id)) page.id,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    for (final d in galleryDestinations) {
      // The trip planner opens as its own app (trip_app_test.dart).
      if (d.pages.first == TripScreens.home) continue;
      await _go(tester, d.title);
      expect(
        find.descendant(
          of: find.byType(ExpressiveAppBar),
          matching: find.text(d.title),
        ),
        findsOneWidget,
      );
      expect(
        find
            .byType(ExpressiveTabBar)
            .evaluate()
            .where(
              (e) => (e.widget.key as ValueKey?)?.value == 'tabs/${d.title}',
            ),
        d.pages.length > 1 ? hasLength(1) : isEmpty,
      );
    }
  });

  testWidgets('both dialog actions close and report their actual result', (
    tester,
  ) async {
    await _pump(tester, 'everyday-dialog');
    for (final (label, result) in [
      ('Keep trip', 'Trip kept.'),
      ('Archive', 'Trip archived.'),
    ]) {
      await _tap(tester, _key('everyday-open-dialog'));
      expect(find.byType(ExpressiveDialog), findsOneWidget);
      await _tap(tester, find.text(label));
      expect(find.byType(ExpressiveDialog), findsNothing);
      expect(find.text(result), findsOneWidget);
    }
  });

  testWidgets('tabs update their selection and the visible content', (
    tester,
  ) async {
    await _pump(tester, 'everyday-tabs');
    expect(find.text('Lisbon weekend'), findsOneWidget);
    await _tap(tester, _key('everyday-tab-saved'));
    expect(
      tester
          .widget<ExpressiveTabBar>(
            find.ancestor(
              of: _key('everyday-tab-saved'),
              matching: find.byType(ExpressiveTabBar),
            ),
          )
          .selectedIndex,
      1,
    );
    expect(find.text('Kyoto idea'), findsOneWidget);
    expect(find.text('Lisbon weekend'), findsNothing);
    await _tap(tester, _key('everyday-tab-past'));
    expect(find.text('Porto in May'), findsOneWidget);
  });

  testWidgets('a card click selects the place', (tester) async {
    await _pump(tester, 'everyday-cards');
    await _tap(tester, _key('everyday-card-Lisbon'));
    expect(find.text('Lisbon is selected for your next plan.'), findsOneWidget);
  });

  testWidgets('ordinary cards fit their content at phone and desktop widths', (
    tester,
  ) async {
    for (final width in [390.0, 1440.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GalleryApp(key: ValueKey(width), initialPage: 'everyday-cards'),
      );
      await settle(tester);
      final cards = find.byType(ExpressiveCard);
      final rectangles = [
        for (var i = 0; i < cards.evaluate().length; i++)
          tester.getRect(cards.at(i)),
      ];
      expect(rectangles, hasLength(6));
      expect(
        rectangles.where((r) => (r.top - rectangles.first.top).abs() < .01),
        hasLength(width == 390 ? 2 : 3),
      );
      // A row's cards share its tallest card's height; that card fits its
      // content, and no card's content comes nearer its edge than padding.
      final columns = width == 390 ? 2 : 3;
      for (var row = 0; row < rectangles.length; row += columns) {
        final gaps = <double>[];
        for (var i = row; i < row + columns && i < rectangles.length; i++) {
          expect(
            rectangles[i].height,
            moreOrLessEquals(rectangles[row].height, epsilon: .01),
          );
          final content = find.descendant(
            of: cards.at(i),
            matching: find.byType(Text),
          );
          final gap =
              rectangles[i].bottom - tester.getRect(content.last).bottom;
          expect(gap, greaterThanOrEqualTo(15.9));
          gaps.add(gap);
        }
        expect(
          gaps.reduce((a, b) => a < b ? a : b),
          inInclusiveRange(15.9, 24),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'enabled checkbox matrix cells respond while their initial states stay distinct',
    (tester) async {
      await _pump(tester, 'selection');
      await _show(tester, _key('kit-section/Checkbox'));
      final cells = _inside(_key('kit-section/Checkbox'), ExpressiveCheckbox);
      expect(cells, findsWidgets);
      for (var i = 0; i < cells.evaluate().length; i++) {
        final before = tester.widget<ExpressiveCheckbox>(cells.at(i));
        if (!before.enabled) continue;
        await _tap(tester, cells.at(i));
        expect(
          tester.widget<ExpressiveCheckbox>(cells.at(i)).value,
          isNot(before.value),
        );
      }
    },
  );

  testWidgets('standalone choice tiles transfer selection', (tester) async {
    await _pump(tester, 'choice');
    await _tap(tester, find.text('Morning'));
    final morning = find.byWidgetPredicate(
      (w) => w is ExpressiveChoiceTile && w.title == 'Morning',
    );
    final evening = find.byWidgetPredicate(
      (w) => w is ExpressiveChoiceTile && w.title == 'Evening',
    );
    expect(tester.widget<ExpressiveChoiceTile>(morning).selected, isTrue);
    expect(tester.widget<ExpressiveChoiceTile>(evening).selected, isFalse);
  });

  testWidgets('the inline open-menu reference chooses and updates its field', (
    tester,
  ) async {
    await _pump(tester, 'select');
    final open = _key('kit-section/Open');
    await _tap(tester, find.descendant(of: open, matching: find.text('Large')));
    expect(
      tester
          .widget<ExpressiveTextField>(_inside(open, ExpressiveTextField))
          .controller!
          .text,
      'Large',
    );
  });

  testWidgets('the inline time dialog switches between input and dial', (
    tester,
  ) async {
    await _pump(tester, 'pickers');
    final section = _key('kit-section/Time dialog, laid out in place');
    await _show(tester, section);
    final toggle = _inside(section, ExpressiveTimePickerModeToggle);
    expect(_inside(section, ExpressiveTimeInput), findsOneWidget);
    await _tap(tester, toggle);
    expect(_inside(section, ExpressiveTimePicker), findsOneWidget);
    expect(_inside(section, ExpressiveTimeInput), findsNothing);
  });

  testWidgets('the existing tab reference changes its indicator selection', (
    tester,
  ) async {
    await _pump(tester, 'nav');
    await _show(tester, _key('kit-section/Primary tabs'));
    final bar = _inside(
      _key('kit-section/Primary tabs'),
      ExpressiveTabBar,
    ).first;
    await _tap(tester, find.descendant(of: bar, matching: find.text('Hotels')));
    expect(tester.widget<ExpressiveTabBar>(bar).selectedIndex, 1);
  });

  testWidgets('customizing the trip planner keeps what was typed', (
    tester,
  ) async {
    await _pump(tester, TripScreens.plan);
    await tester.enterText(
      _inside(_key('plan-name'), EditableText),
      'Big Sur long weekend',
    );
    await settle(tester);
    await tester.tap(_button('Show menu').first);
    await settle(tester);
    await tester.tap(find.text('Customize'));
    await settle(tester);
    await tester.tap(find.text('Teal'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<ExpressiveTextField>(_key('plan-name')).controller!.text,
      'Big Sur long weekend',
    );
  });

  testWidgets('the live Sheet page opens on its notes; the trail log rises '
      'only when asked', (tester) async {
    // The web build opened the tab under the raised trail log, its scrim
    // over the page the tab named (11-09 22:40).
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.reset);
    final sheet = galleryExamplePages.singleWhere((page) => page.id == 'sheet');
    await tester.pumpWidget(galleryBuildPage(sheet, Brightness.light));
    await settle(tester);
    expect(find.text('Trail log · 14 March'), findsNothing);
    await tester.tap(find.text('Open the trail log'));
    await settle(tester);
    expect(find.text('Trail log · 14 March'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Shape page breaks a token name only between its words', (
    tester,
  ) async {
    // The web build at 390 broke "extraSma ll" and "semiCircl e" (11-09).
    tester.view.devicePixelRatio = 1;
    // Tall, so every swatch is built: only the width breaks a name.
    tester.view.physicalSize = const Size(390, 4000);
    addTearDown(tester.view.reset);
    final shape = galleryExamplePages.singleWhere((page) => page.id == 'shape');
    await tester.pumpWidget(galleryBuildPage(shape, Brightness.light));
    await settle(tester);
    for (final name in ['extraSmall', 'extraLargeIncreased', 'semiCircle']) {
      final label = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == name,
      );
      expect(label, findsOneWidget, reason: name);
      // One paragraph, a zero-width space before each word after the first:
      // a line may break there and nowhere inside a word.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: label, matching: find.byType(RichText)),
      );
      final plain = paragraph.text.toPlainText();
      final words = plain.split('\u200B');
      expect(words, hasLength(greaterThanOrEqualTo(2)), reason: name);
      var start = 0;
      for (final word in words) {
        final tops = {
          for (final box in paragraph.getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + word.length),
          ))
            box.top,
        };
        expect(tops, hasLength(1), reason: '$name: "$word" wrapped');
        start += word.length + 1;
      }
    }
    expect(tester.takeException(), isNull);
  });
}
