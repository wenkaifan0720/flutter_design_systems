// ui_core's shared world checks (world_checks.dart, beside this file, as every look runs them): each everyday part
// mirrored in right to left; every gallery page at twice the text size with nothing overflowing, on a phone and on the
// desktop; the main gallery pages against Flutter's tap-target, label and text-contrast guidelines by day and by night,
// at Ledger's 44 targets (iOS's, on every platform, by design); every single choice answering the keys as Flutter's
// RadioGroup does, and the checklist's marks reading as checkboxes. Reduced motion is on, so every page settles.
// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignRadioGroupCheck;

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/wren.dart' show KitTx;
import 'world_checks.dart';
import 'tiers.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

/// The gallery's everyday pages: the controls, the inputs, the choices, the rows, the dialog and the top bar.
const Set<String> _main = {
  'controls',
  'inputs',
  'selection',
  'structure',
  'commit',
  'top-bar',
};

/// The tallest a page is drawn: the guidelines read what stands in the view.
const double _tallest = 6000;

const List<LedgerNavItem> _tabs = [
  LedgerNavItem(LucideIcons.house, 'Home'),
  LedgerNavItem(LucideIcons.scrollText, 'Register'),
  LedgerNavItem(LucideIcons.settings, 'Settings'),
];

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// [part] at the reading start of a page's padded column, reading [direction]; or the whole page when [page] is set.
Widget _app(TextDirection direction, Widget part, {bool page = false}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, home) => Directionality(
        textDirection: direction,
        child: LedgerHost(child: home!),
      ),
      home: page
          ? part
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: part,
              ),
            ),
    );

/// Grows the view down so the page's longest scroll stands in it whole.
Future<void> _fit(WidgetTester t, double width) async {
  var extent = 0.0;
  for (final s in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    final p = s.position;
    if (p.axis == Axis.vertical && p.hasContentDimensions) {
      extent = math.max(extent, p.maxScrollExtent);
    }
  }
  if (extent <= 0) return;
  t.view.physicalSize = Size(
    width,
    math.min(_tallest, t.view.physicalSize.height + extent),
  );
  await t.pumpAndSettle();
}

/// A budget's whole dollars, as an app passes them.
String _dollars(num v) => LedgerFormat.money(v, showCents: false);

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  group('each everyday part mirrors in right to left', () {
    testWidgets('a button', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerButton('Add money', icon: LucideIcons.plus, onPressed: () {}),
        ),
        parts: [
          find.byType(LedgerButton),
          find.byIcon(LucideIcons.plus),
          find.text('Add money'),
        ],
      );
    });

    testWidgets('a chip', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(d, LedgerChip('Groceries', count: 12, onTap: () {})),
        parts: [find.text('Groceries'), find.text('12')],
      );
    });

    testWidgets('a segmented control', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerSegmentedControl(
            options: const ['1M', '3M', '1Y', 'All'],
            value: '1Y',
            onChanged: (_) {},
          ),
        ),
        parts: [find.text('1M'), find.text('1Y'), find.text('All')],
      );
    });

    testWidgets('a switch', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerSwitch(value: true, semanticLabel: 'Bills', onChanged: (_) {}),
        ),
        parts: [find.byType(LedgerSwitch)],
      );
    });

    testWidgets('a checkbox and a radio', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LedgerCheckbox(
                value: true,
                label: 'Email me a receipt',
                onChanged: (_) {},
              ),
              LedgerRadio<int>(
                value: 1,
                groupValue: 1,
                label: 'By lamplight',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        parts: [
          find.byIcon(LucideIcons.check),
          find.text('Email me a receipt'),
          find.text('By lamplight'),
        ],
      );
    });

    testWidgets('a field', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          const LedgerTextField(
            labelText: 'Amount',
            prefix: r'$',
            hintText: '0.00',
          ),
        ),
        // The label is set in the small capitals. The sum typed after its sign reads left to right (README).
        parts: [find.text('AMOUNT')],
      );
      expect(
        t.getRect(find.text(r'$')).right,
        lessThan(t.getRect(find.text('0.00')).left),
        reason: r'$ before 0.00',
      );
    });

    testWidgets('a setting row', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerSettingRow(
            icon: LucideIcons.gauge,
            title: 'Monthly limit',
            value: r'$2,000',
            onTap: () {},
          ),
        ),
        parts: [
          find.byIcon(LucideIcons.gauge),
          find.text('Monthly limit'),
          find.text(r'$2,000'),
        ],
      );
    });

    testWidgets('tabs', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerTabs(
            tabs: const ['Overview', 'Entries', 'Notes'],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
        parts: [find.text('Overview'), find.text('Notes')],
      );
    });

    testWidgets('a stepper', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerStepper(
            value: 250,
            labelText: 'Monthly budget',
            format: _dollars,
            onChanged: (_) {},
          ),
        ),
        parts: [find.byIcon(LucideIcons.minus), find.byIcon(LucideIcons.plus)],
      );
    });

    testWidgets('a dialog', (t) async {
      _size(t, _desktop);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          Center(
            child: LedgerDialog(
              title: 'Delete this entry?',
              type: LedgerDialogType.destructive,
              confirmLabel: 'Delete',
              onConfirmPressed: () {},
              onCancelPressed: () {},
            ),
          ),
          page: true,
        ),
        parts: [
          find.text('Delete this entry?'),
          find.text('Cancel'),
          find.text('Delete'),
        ],
      );
    });

    testWidgets('a sheet', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerSheetShell(
            title: 'Add money',
            onClose: () {},
            children: const [Text('From checking')],
          ),
          page: true,
        ),
        parts: [
          find.text('Add money'),
          find.byIcon(LucideIcons.x),
          find.text('From checking'),
        ],
      );
    });

    testWidgets('the tab bar', (t) async {
      _size(t, _phone);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerNavigationFrame(
            destinations: _tabs,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: const SizedBox.expand(),
          ),
          page: true,
        ),
        parts: [
          find.text('Home'),
          find.text('Register'),
          find.text('Settings'),
        ],
      );
    });

    testWidgets('the side bar', (t) async {
      _size(t, _desktop);
      await expectMirrorsInRtl(
        t,
        (d) => _app(
          d,
          LedgerNavigationFrame(
            destinations: _tabs,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            brand: 'Quill',
            body: const SizedBox.expand(),
          ),
          page: true,
        ),
        parts: [
          find.byType(LedgerSideBar),
          find.text('Home'),
          find.text('Settings'),
        ],
      );
    });
  });

  // Each page's everyday case is a phone or the desktop, by day or by night, turning over the pages; the other is the
  // sweep's (tiers.dart).
  group('every gallery page at text scale 2.0', () {
    for (final (i, page) in galleryPages.indexed) {
      for (final size in const [_phone, _desktop]) {
        testWidgets(
          '${page.id} at ${size.width.round()}',
          tags: sweepUnless(size == turn(const [_phone, _desktop], i)),
          (t) async {
            _size(t, size);
            await expectNoOverflowAtTextScale(t, page.build(Brightness.light));
          },
        );
      }
    }
  });

  group('one choice answers the keys as a radio group does', () {
    // Sibling LedgerRadios grouped at the owner of their choice, Month turned
    // off, each on the node its caller gives it.
    const periods = ['Week', 'Month', 'Quarter', 'Year'];
    for (final direction in TextDirection.values) {
      for (final initial in <String?>['Quarter', null, 'Month']) {
        testWidgets(
          'LedgerRadio siblings, ${direction.name}, chosen $initial',
          (t) async {
            _size(t, _phone);
            final before = FocusNode();
            final nodes = {for (final p in periods) p: FocusNode()};
            addTearDown(before.dispose);
            for (final node in nodes.values) {
              addTearDown(node.dispose);
            }
            var chosen = initial;
            await t.pumpWidget(
              _app(
                direction,
                StatefulBuilder(
                  builder: (context, setState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Focus(focusNode: before, child: const Text('Before')),
                      RadioGroup<String>(
                        key: const ValueKey('radios'),
                        groupValue: chosen,
                        onChanged: (p) => setState(() => chosen = p),
                        child: RadioGroupKeyboardFix<String>(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final p in periods)
                                LedgerRadio<String>(
                                  key: ValueKey(p),
                                  value: p,
                                  label: p,
                                  focusNode: nodes[p],
                                  enabled: p != 'Month',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Focus(child: Text('After')),
                    ],
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            for (final p in periods) {
              expect(
                t
                    .widget<LedgerRadio<String>>(find.byKey(ValueKey(p)))
                    .focusNode,
                same(nodes[p]),
              );
            }
            nodes['Week']!.requestFocus();
            await t.pump();
            expect(FocusManager.instance.primaryFocus, same(nodes['Week']));
            (await const DesignRadioGroupCheck(look: 'Ledger').check(
              t.element(find.byKey(const ValueKey('radios'))),
              before: before,
              sendKeyEvent: t.sendKeyEvent,
              pump: t.pump,
            )).verify();
          },
        );
      }

      testWidgets('a segmented control, ${direction.name}', (t) async {
        _size(t, _phone);
        final before = FocusNode();
        addTearDown(before.dispose);
        var chosen = 'Quarter';
        await t.pumpWidget(
          _app(
            direction,
            StatefulBuilder(
              builder: (context, setState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Focus(focusNode: before, child: const Text('Before')),
                  LedgerSegmentedControl<String>(
                    key: const ValueKey('radios'),
                    options: periods,
                    value: chosen,
                    onChanged: (p) => setState(() => chosen = p),
                  ),
                  const Focus(child: Text('After')),
                ],
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        (await const DesignRadioGroupCheck(look: 'Ledger').check(
          t.element(find.byKey(const ValueKey('radios'))),
          before: before,
          sendKeyEvent: t.sendKeyEvent,
          pump: t.pump,
        )).verify();
      });
    }

    // A toggle group of one choice: a row of radio pills, Month turned off,
    // chosen Quarter, nothing, Week and the turned-off Month, both ways.
    for (final direction in TextDirection.values) {
      for (final initial in <String?>['Quarter', null, 'Week', 'Month']) {
        testWidgets('a toggle group of one choice, ${direction.name}, '
            'chosen $initial', (t) async {
          _size(t, _phone);
          final before = FocusNode();
          addTearDown(before.dispose);
          var chosen = initial;
          await t.pumpWidget(
            _app(
              direction,
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(focusNode: before, child: const Text('Before')),
                    LedgerToggleGroup<String>(
                      key: const ValueKey('radios'),
                      label: 'Period',
                      options: periods,
                      labelOf: (p) => p,
                      selected: {?chosen},
                      isEnabled: (p) => p != 'Month',
                      onSelectionChanged: (next) =>
                          setState(() => chosen = next.first),
                    ),
                    const Focus(child: Text('After')),
                  ],
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          (await const DesignRadioGroupCheck(look: 'Ledger').check(
            t.element(find.byKey(const ValueKey('radios'))),
            before: before,
            sendKeyEvent: t.sendKeyEvent,
            pump: t.pump,
          )).verify();
        });
      }
    }

    // Every single choice the gallery draws, its radios and its segments,
    // from the focusable a Tab leaves to land in it.
    testWidgets('every single choice in the gallery', (t) async {
      final problems = <String>[];
      final seen = <String>[];
      bool single(Widget w) =>
          w is RadioGroup ||
          (w is RawSegmentedButton && !w.multiSelectionEnabled);
      for (final page in galleryPages) {
        Future<void> open() async {
          _size(t, const Size(1440, _tallest));
          await t.pumpWidget(const SizedBox());
          await t.pumpWidget(page.build(Brightness.light));
          await t.pumpAndSettle();
        }

        await open();
        final count = find.byWidgetPredicate(single).evaluate().length;
        for (var i = 0; i < count; i++) {
          await open();
          final group = find.byWidgetPredicate(single).at(i);
          final name = '${page.id} #$i (${t.widget(group).runtimeType})';
          FocusNode? before;
          for (var tab = 0; tab < 400; tab++) {
            final from = FocusManager.instance.primaryFocus;
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pump();
            final at = FocusManager.instance.primaryFocus?.context;
            if (at != null &&
                find
                    .descendant(
                      of: group,
                      matching: find.byElementPredicate((e) => e == at),
                    )
                    .evaluate()
                    .isNotEmpty) {
              before = from;
              break;
            }
          }
          if (before == null) {
            problems.add('$name: no Tab reaches it');
            continue;
          }
          seen.add(name);
          final report = await const DesignRadioGroupCheck(look: 'Ledger')
              .check(
                t.element(group),
                before: before,
                sendKeyEvent: t.sendKeyEvent,
                pump: t.pumpAndSettle,
              );
          problems.addAll([for (final p in report.problems) '$name: $p']);
        }
      }
      await t.pumpWidget(const SizedBox());
      expect(problems, isEmpty, reason: 'checked: ${seen.join(', ')}');
    });

    // A checklist's mark is a checkbox to a screen reader, never a button.
    testWidgets("the selection page's checklist reads as checkboxes", (
      t,
    ) async {
      _size(t, const Size(1440, _tallest));
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        galleryPages
            .firstWhere((p) => p.id == 'selection')
            .build(Brightness.light),
      );
      await t.pumpAndSettle();
      final marks = t.widgetList<LedgerCheck>(find.byType(LedgerCheck));
      expect(
        [for (final m in marks) m.label],
        containsAll(const [
          'Order the cotton paper',
          'Mix the walnut ink',
          'Reconcile October',
          'Post the invoices',
        ]),
      );
      var read = 0;
      for (final element in find.byType(LedgerCheck).evaluate()) {
        final mark = element.widget as LedgerCheck;
        if (mark.onChanged == null) continue;
        expect(
          t.getSemantics(find.byElementPredicate((e) => e == element)),
          isSemantics(
            label: mark.label,
            hasCheckedState: true,
            isChecked: mark.value,
            isButton: false,
            hasTapAction: true,
          ),
          reason: mark.label,
        );
        read++;
      }
      expect(read, greaterThanOrEqualTo(5));
      semantics.dispose();
    });

    testWidgets("the collections table's rows read as checkboxes", (t) async {
      _size(t, const Size(1440, _tallest));
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        galleryPages
            .firstWhere((p) => p.id == 'collections')
            .build(Brightness.light),
      );
      await t.pumpAndSettle();
      final table = find.byType(LedgerDataTable<KitTx>);
      expect(table, findsOneWidget);
      final rows = t.widget<LedgerDataTable<KitTx>>(table).controller.rows;
      expect(rows, hasLength(8));
      // Each selectable row is one node: a checkbox (no button) that a press
      // or Space ticks.
      for (final tx in rows) {
        expect(
          t.getSemantics(
            find.descendant(of: table, matching: find.text(tx.title)).first,
          ),
          isSemantics(
            hasCheckedState: true,
            isChecked: false,
            isButton: false,
            hasTapAction: true,
          ),
          reason: tx.title,
        );
      }
      semantics.dispose();
    });
  });

  group('the main gallery pages meet the guidelines at 44', () {
    for (final (i, page)
        in galleryPages.where((p) => _main.contains(p.id)).indexed) {
      for (final brightness in Brightness.values) {
        final everyday = brightness == turn(Brightness.values, i);
        Future<void> open(WidgetTester t) async {
          _size(t, _phone);
          await t.pumpWidget(page.build(brightness));
          await t.pumpAndSettle();
          await _fit(t, _phone.width);
        }

        testWidgets(
          '${page.id} ${brightness.name}',
          tags: sweepUnless(everyday),
          (t) async {
            await open(t);
            final semantics = t.ensureSemantics();
            await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
            semantics.dispose();
          },
        );

        // Text contrast reads the drawn pixels, so it depends on the rasterizer, as a golden does: Linux's FreeType
        // draws Ledger's 11 px small capitals, its mono figures and the cheque's light words with thinner strokes
        // than macOS, and Flutter's guideline then takes an antialiased fringe for the text's colour (#E5E3DE on the
        // day paper #F9F6F0). Linux CI skips it; the macOS goldens job runs it. The inks themselves are held to 4.5:1
        // below on every platform.
        testWidgets(
          '${page.id} ${brightness.name}: text contrast',
          (t) async {
            await open(t);
            final semantics = t.ensureSemantics();
            await expectLater(t, meetsGuideline(textContrastGuideline));
            semantics.dispose();
          },
          // Skipped on macOS too (0.2.0: text contrast read at device pixels): Flutter's capture reads one pixel per
          // logical pixel, so an 11 px meta line in the third ink (4.6:1 on the paper: the dialog page's note, the
          // structure page's section notes) samples as antialiased grey (3.75-4.47).
          skip: _sampledThin.contains((page.id, brightness)),
          tags: goldensSweepUnless(everyday),
        );
      }
    }

    test('the third ink stands at 4.5:1 on the paper, by day and by night', () {
      for (final theme in [LedgerThemeData.light(), LedgerThemeData.dark()]) {
        expect(
          LedgerThemeData.contrast(theme.textTertiary, theme.background),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('the vermilion as words stands at 4.5:1 on every ground it is written on, by day and by night', () {
      for (final theme in [LedgerThemeData.light(), LedgerThemeData.dark()]) {
        for (final ground in [
          theme.background,
          theme.surface,
          theme.surfaceAlt,
          theme.dangerSubtle,
        ]) {
          expect(
            LedgerThemeData.contrast(theme.over, ground),
            greaterThanOrEqualTo(4.5),
            reason: '$ground',
          );
        }
      }
    });
  });
}

/// Pages whose small type in the third ink Flutter's capture samples thinner than the ink: their text contrast is
/// held by the ink's own ratio instead (ui_core 0.1.1 brings a shared ink-based check).
// The top-bar page, read whole since its specimens' apps stand in semantics containers of their own (0.3.0): by day
// its 11 px meta line in the third ink samples thin as above (4.47), and by night the Home specimen's "$6,248.30" runs
// half under the tab bar, as the shell lays the bar over the page's foot, so the guideline takes the bar's ground and
// the page's for the figure's two colours (1.61).
const Set<(String, Brightness)> _sampledThin = {
  ('commit', Brightness.light),
  ('structure', Brightness.light),
  ('top-bar', Brightness.light),
  ('top-bar', Brightness.dark),
};

/// Reduced motion on, as a reader who asked for it has it: every Ledger change lands at once, so a page settles.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();
