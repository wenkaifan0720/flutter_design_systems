// Keylines (design6 P): the example's ordinary screens, opened the way a person opens them, at a phone's and a desk's
// width; every panel, card, section and the page body is a DesignKeylineRegion, and ui_core's check holds each one to
// one leading and one trailing keyline and each row of controls to one height and centre line.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:ui_core/alignment.dart';

// ignore_for_file: avoid_relative_lib_imports, avoid_print
import '../example/lib/kit_gallery/gate_screens.dart';
import '../example/lib/kit_gallery/demos/controls.dart'
    show kitSpecimenSelectField;
import '../example/lib/kit_gallery/kit.dart' show kitState;
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

/// Widgets the barrel keeps to itself (a menu's frame, ui_core's tag input), found by their type's name.
Finder _named(String type) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == type);

/// The ordinary screens the user judges a look on: Account, Settings, Library and Shop.
const _screens = ['form', 'settings', 'list', 'checkout'];

/// What the keyline check reads that is not the fault it hunts, by kind, as shared_checks_test's misreads: from 600 up
/// a row of choices keeps to its words (ui_core 0e25289dfd's DesignWidthKind.choiceGroup), so its end is ragged as a
/// wrapped line's is, while the check holds a run across two thirds of its region to both keylines. Matched by the
/// problem's shape and the part it names, the last choice on its line in a ComicChoices, never by a demo's label.
/// Reported to the coordinator.
bool _raggedChoice(WidgetTester tester, String problem, double width) {
  final m = RegExp(
    r'^[^:]+: a button "([^"]+)" ends [\d.]+ px in; the trailing keyline is ',
  ).firstMatch(problem);
  if (m == null || width < 600) return false;
  final label = m.group(1)!;
  bool names(String words) => label.endsWith('…')
      ? words.startsWith(label.substring(0, label.length - 1))
      : words == label;
  Rect at(Element e) => tester.getRect(find.byElementPredicate((x) => x == e));
  for (final e in find.byType(ComicChoiceBox).evaluate()) {
    Element? group;
    e.visitAncestorElements((a) {
      if (a.widget is! ComicChoices) return true;
      group = a;
      return false;
    });
    if (group == null) continue;
    final words = find
        .descendant(
          of: find.byElementPredicate((x) => x == e),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((t) => (t.widget as Text).data ?? '');
    if (!words.any(names)) continue;
    final box = at(e);
    final line = find
        .descendant(
          of: find.byElementPredicate((x) => x == group),
          matching: find.byType(ComicChoiceBox),
        )
        .evaluate()
        .map(at)
        .where((r) => (r.top - box.top).abs() < 1);
    final end = Directionality.of(e) == TextDirection.rtl
        ? line.every((r) => r.left >= box.left - .5)
        : line.every((r) => r.right <= box.right + .5);
    if (end) return true;
  }
  return false;
}

Future<void> _open(WidgetTester tester, String id, double width) async {
  if (width < 840) {
    await tester.tap(find.byKey(const ValueKey('nav/open')));
    await settle(tester);
  }
  final item = find.byKey(ValueKey('nav/$id'));
  await tester.ensureVisible(item);
  await settle(tester);
  await tester.tap(item);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final width in [390.0, 1440.0]) {
    for (final id in _screens) {
      testWidgets('$id keeps its keylines at ${width.toInt()}', (tester) async {
        tester.view.devicePixelRatio = 1;
        // Tall enough that the whole screen is on show: the check reads only what is painted.
        tester.view.physicalSize = Size(width, 2600);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const GalleryApp());
        await settle(tester);
        await _open(tester, id, width);
        final report = await const DesignKeylineCheck(look: 'Comic').check(
          tester.element(find.byKey(ValueKey('live/$id'))),
          runAsync: tester.runAsync,
        );
        final real = [
          for (final p in report.problems)
            if (!_raggedChoice(tester, p, width)) p,
        ];
        print(
          'keylines $id ${width.toInt()}: ${real.length} '
          '(${report.problems.length - real.length} misread)',
        );
        for (final problem in report.problems) {
          print(
            real.contains(problem)
                ? '  $problem'
                : '  misread (the end of a row of choices that keep to their words is ragged): $problem',
          );
        }
        expect(real, isEmpty, reason: real.join('\n'));
        // Read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to the macOS job).
      }, tags: 'goldens');
    }
  }

  // At a desk the page's title stands on the content's leading edge, as every look's does: the sidebar holds the
  // brand, the bar stands over the content (coordinator, g5: 'SETTINGS' stood over the sidebar, the panels at 247).
  for (final id in _screens) {
    testWidgets('$id puts its title on the content\'s leading edge at 1440', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      await _open(tester, id, 1440);
      final page = find.byKey(ValueKey('live/$id'));
      final content = [
        for (final e
            in find
                .descendant(
                  of: page,
                  matching: find.byWidgetPredicate(
                    (w) => w is ComicPanel || w is RichText,
                  ),
                )
                .evaluate())
          (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dx,
      ].reduce(math.min);
      final bar = find.byType(ComicAppBar);
      final title = find
          .descendant(of: bar, matching: find.byType(RichText))
          .evaluate()
          .map((e) => e.renderObject! as RenderBox)
          .map((b) => b.localToGlobal(Offset.zero).dx)
          .reduce(math.min);
      expect(
        (title - content).abs(),
        lessThan(0.5),
        reason: 'title at $title, content at $content',
      );
    });
  }

  // Boxed controls stacked in a panel (a text field, a select, a choice) put their words on one inner keyline, a
  // text field's (coordinator, g5 at 390: choice words at 53, field words at 48, boxes on one edge at 29).
  Future<void> pumpScreen(
    WidgetTester tester,
    double width,
    Widget Function() body,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 2600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ComicHost(child: ComicScaffold(body: body())),
      ),
    );
    await settle(tester);
  }

  double left(Element e) =>
      (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dx;
  Finder within(Element e, Finder matching) => find.descendant(
    of: find.byElementPredicate((x) => identical(x, e)),
    matching: matching,
  );

  for (final width in [390.0, 1440.0]) {
    for (final (name, body) in [('account', gateAccount), ('shop', gateShop)]) {
      testWidgets(
        '$name keeps its boxed words on one inner keyline at ${width.toInt()}',
        (tester) async {
          await pumpScreen(tester, width, body);
          final insets = <String, double>{
            for (final e in find.byType(ComicTextField).evaluate())
              'field ${(e.widget as ComicTextField).label}':
                  left(within(e, find.byType(EditableText)).evaluate().first) -
                  left(e),
            for (final e in find.byType(ComicSelectField).evaluate())
              'select ${(e.widget as ComicSelectField).value}':
                  left(within(e, find.byType(RichText)).evaluate().first) -
                  left(e),
            for (final e in find.byType(ComicChoiceBox).evaluate())
              'choice ${(e.widget as ComicChoiceBox).label}':
                  left(within(e, find.byType(RichText)).evaluate().first) -
                  left(e),
          };
          print('inner keyline $name ${width.toInt()}: $insets');
          final field = insets.entries
              .firstWhere((e) => e.key.startsWith('field'))
              .value;
          for (final MapEntry(:key, :value) in insets.entries) {
            expect(
              (value - field).abs(),
              lessThan(0.5),
              reason:
                  '$key words ${value.toStringAsFixed(1)} in, a field\'s ${field.toStringAsFixed(1)}',
            );
          }
        },
      );
    }
  }

  // A list that opens from a field sets its words on the field's.
  testWidgets('a select\'s list sets its words on the field\'s', (
    tester,
  ) async {
    await pumpScreen(tester, 390, gateAccount);
    final select = find.byType(ComicSelectField);
    final value = left(
      within(select.evaluate().first, find.byType(RichText)).evaluate().first,
    );
    await tester.tap(select);
    await settle(tester);
    final row = tester.getTopLeft(find.text('Express delivery')).dx;
    expect(
      (row - value).abs(),
      lessThan(0.5),
      reason: 'the list\'s words at $row, the field\'s at $value',
    );
  });

  // Every select and dropdown at 600, 1024, 1440 and 1920 (the user, 16:34: 'the width for dropdown seems to be a
  // common problem'): closed, its face at most about 320 at its column's start; open, its list at least as wide as
  // the face and on its leading edge.
  for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
    testWidgets('dropdowns keep their width at ${width.toInt()}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1400);
      addTearDown(tester.view.reset);
      const genres = ['Adventure', 'Comedy', 'Mystery'];
      await tester.pumpWidget(
        MaterialApp(
          home: ComicHost(
            child: ComicScaffold(
              body: kitState<List<String>>(
                const [],
                (context, chosen, choose) => ComicColumn(
                  gap: 24,
                  children: [
                    kitState(
                      'print',
                      (context, value, change) => ComicSelect<String>(
                        label: 'Format',
                        options: const [
                          ComicSelectOption('print', 'Print'),
                          ComicSelectOption('digital', 'Digital edition'),
                        ],
                        value: value,
                        onChanged: change,
                      ),
                    ),
                    kitSpecimenSelectField(),
                    const ComicCombobox<String>(
                      label: 'Find a genre',
                      options: genres,
                    ),
                    ComicMultiSelect<String>(
                      label: 'Genres',
                      options: genres,
                      values: chosen,
                      onChanged: choose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
      final column = tester.getTopLeft(find.byType(ComicColumn).first).dx;
      // A select field's drawn face (its press), not the room it stands in.
      Finder face(int i) => find
          .descendant(
            of: find.byType(ComicSelectField).at(i),
            matching: find.byType(ComicPressable),
          )
          .first;
      final faces = <String, Finder>{
        'select': face(0),
        'select field': face(1),
        'combobox': find.byType(ComicTextField),
        'multi-select': _named('DesignTagInput<String>'),
      };
      for (final MapEntry(key: name, value: face) in faces.entries) {
        final rect = tester.getRect(face);
        expect(
          rect.width,
          lessThanOrEqualTo(320.5),
          reason: '$name closed: ${rect.width} wide',
        );
        expect(
          (rect.left - column).abs(),
          lessThan(0.5),
          reason: '$name closed at ${rect.left}, the column at $column',
        );
      }
      Future<void> opens(
        String name,
        Finder face,
        Future<void> Function() open,
        Finder list,
      ) async {
        await open();
        await settle(tester);
        final f = tester.getRect(face), l = tester.getRect(list.first);
        expect(
          l.width,
          greaterThanOrEqualTo(f.width - 0.5),
          reason: '$name open: list ${l.width}, face ${f.width}',
        );
        expect(
          (l.left - f.left).abs(),
          lessThan(0.5),
          reason: '$name open: list at ${l.left}, face at ${f.left}',
        );
        await tester.tapAt(const Offset(4, 1390));
        await settle(tester);
      }

      await opens(
        'select',
        faces['select']!,
        () => tester.tap(faces['select']!),
        _named('ComicMenu<String>'),
      );
      await opens(
        'select field',
        faces['select field']!,
        () => tester.tap(faces['select field']!),
        _named('ComicMenu<String>'),
      );
      await opens(
        'combobox',
        faces['combobox']!,
        () => tester.enterText(
          find.descendant(
            of: faces['combobox']!,
            matching: find.byType(EditableText),
          ),
          'o',
        ),
        _named('ComicRaisedFrame'),
      );
      await opens(
        'multi-select',
        faces['multi-select']!,
        () => tester.enterText(
          find.descendant(
            of: faces['multi-select']!,
            matching: find.byType(EditableText),
          ),
          'o',
        ),
        _named('ComicRaisedFrame'),
      );
    });
  }

  // Buttons in a row (the user, 16:34, on Ledger: 'the button doesnt have the same height here?'): each of Comic's
  // boxed variants beside each other shows one top and one bottom by its drawn outline, on a page, in a panel, a
  // dialog and a sheet, by day and by night. The quiet button draws no box, only its words, and is left out.
  // COMIC_PICTURES=<dir> also writes each surface's picture there, at 2x.
  final variants = <String, Widget Function(Key, String)>{
    'act': (k, l) => ComicButton.filled(l, key: k, onPressed: () {}),
    'line': (k, l) => ComicButton(l, key: k, onPressed: () {}),
    'danger': (k, l) => ComicButton(
      l,
      isDestructiveAction: true,
      icon: ComicGlyphs.trash2,
      key: k,
      onPressed: () {},
    ),
  };
  const pairs = [('line', 'act'), ('act', 'danger'), ('line', 'danger')];
  List<Widget> pair(String surface, (String, String) p) => [
    variants[p.$1]!(ValueKey('$surface/${p.$1}-${p.$2}/a'), 'Cancel'),
    variants[p.$2]!(ValueKey('$surface/${p.$1}-${p.$2}/b'), 'Sign out'),
  ];
  Widget rowOf(String surface, (String, String) p) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      pair(surface, p)[0],
      const SizedBox(width: 12),
      pair(surface, p)[1],
    ],
  );
  final surfaces = <String, Widget Function()>{
    'page': () => ComicColumn(
      gap: 16,
      children: [for (final p in pairs) rowOf('page', p)],
    ),
    'panel': () => ComicPanel(
      caption: 'Account',
      child: ComicColumn(
        gap: 16,
        children: [for (final p in pairs) rowOf('panel', p)],
      ),
    ),
    'dialog': () => ComicColumn(
      gap: 16,
      children: [
        for (final p in pairs)
          SizedBox(
            width: 420,
            child: ComicDialog(
              title: 'Sign out?',
              message: 'You can sign in again any time.',
              actions: pair('dialog', p),
            ),
          ),
      ],
    ),
    'sheet': () => ComicColumn(
      gap: 16,
      children: [
        for (final p in pairs)
          SizedBox(
            width: 420,
            height: 300,
            child: ComicBottomSheet(
              title: 'Sign out',
              actions: pair('sheet', p),
              child: const Text('On this device only.'),
            ),
          ),
      ],
    ),
  };
  for (final night in [false, true]) {
    for (final MapEntry(key: surface, value: body) in surfaces.entries) {
      testWidgets(
        '$surface keeps a row of buttons to one drawn height ${night ? 'by night' : 'by day'}',
        (tester) async {
          const dpr = 2.0;
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = const Size(900 * dpr, 1100 * dpr);
          addTearDown(tester.view.reset);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              home: ComicHost(
                brightness: night ? Brightness.dark : Brightness.light,
                child: RepaintBoundary(
                  key: boundary,
                  child: ComicScaffold(body: body()),
                ),
              ),
            ),
          );
          await settle(tester);
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final origin = render.localToGlobal(Offset.zero);
          final (image, bytes) = (await tester.runAsync(() async {
            final image = await render.toImage(pixelRatio: dpr);
            return (
              image,
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
            );
          }))!;
          final dir = Platform.environment['COMIC_PICTURES'];
          if (dir != null) {
            final png = await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.png),
            );
            File('$dir/rows_${surface}_${night ? 'night' : 'day'}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png!.buffer.asUint8List());
          }
          final w = image.width;
          // The rows a button's drawn outline covers, read down a line just inside its leading edge.
          (int, int)? drawn(Rect r) {
            final x = ((r.left - origin.dx + 8) * dpr).round();
            final y0 = ((r.top - origin.dy - 6) * dpr).round();
            final y1 = ((r.bottom - origin.dy + 6) * dpr).round();
            List<int> rgb(int y) {
              final i = (y * w + x) * 4;
              return [
                bytes.getUint8(i),
                bytes.getUint8(i + 1),
                bytes.getUint8(i + 2),
              ];
            }

            final ground = rgb(y0);
            int? top, bottom;
            for (var y = y0; y <= y1; y++) {
              final c = rgb(y);
              final d =
                  (c[0] - ground[0]).abs() +
                  (c[1] - ground[1]).abs() +
                  (c[2] - ground[2]).abs();
              if (d > 48) {
                top ??= y;
                bottom = y;
              }
            }
            return top == null ? null : (top, bottom!);
          }

          // The columns a button's drawn outline spans, read across a line just under its top edge.
          (int, int)? across(Rect r) {
            final y = ((r.top - origin.dy + 6) * dpr).round();
            final x0 = ((r.left - origin.dx - 6) * dpr).round();
            final x1 = ((r.right - origin.dx + 6) * dpr).round();
            int at(int x, int k) => bytes.getUint8((y * w + x) * 4 + k);
            int? left, right;
            for (var x = x0; x <= x1; x++) {
              final d = [
                for (var k = 0; k < 3; k++) (at(x, k) - at(x0, k)).abs(),
              ].reduce((p, q) => p + q);
              if (d > 48) {
                left ??= x;
                right = x;
              }
            }
            return left == null ? null : (left, right!);
          }

          for (final p in pairs) {
            final ra = tester.getRect(
                  find.byKey(ValueKey('$surface/${p.$1}-${p.$2}/a')),
                ),
                rb = tester.getRect(
                  find.byKey(ValueKey('$surface/${p.$1}-${p.$2}/b')),
                );
            final a = drawn(ra), b = drawn(rb);
            // A sheet stacks its actions, full width, one under the other: there they keep one drawn height.
            final stacked = rb.top >= ra.bottom - 0.5;
            final name =
                '${p.$1} ${stacked ? 'over' : 'beside'} ${p.$2} on the $surface ${night ? 'by night' : 'by day'}';
            expect(
              a,
              isNotNull,
              reason: '$name: the ${p.$1} button draws no outline',
            );
            expect(
              b,
              isNotNull,
              reason: '$name: the ${p.$2} button draws no outline',
            );
            print('rows $name: ${p.$1} $a, ${p.$2} $b (device px)');
            if (stacked) {
              expect(
                ((a!.$2 - a.$1) - (b!.$2 - b.$1)).abs(),
                lessThanOrEqualTo(1),
                reason: '$name: drawn heights $a and $b',
              );
              final wa = across(ra), wb = across(rb);
              print('rows $name: across ${p.$1} $wa, ${p.$2} $wb (device px)');
              expect(
                wa != null &&
                    wb != null &&
                    (wa.$1 - wb.$1).abs() <= 1 &&
                    (wa.$2 - wb.$2).abs() <= 1,
                isTrue,
                reason: '$name: stacked actions span $wa and $wb',
              );
              continue;
            }
            expect(
              (a!.$1 - b!.$1).abs(),
              lessThanOrEqualTo(1),
              reason: '$name: tops $a and $b',
            );
            expect(
              (a.$2 - b.$2).abs(),
              lessThanOrEqualTo(1),
              reason: '$name: bottoms $a and $b',
            );
          }
        },
        tags: 'goldens', // drawn pixels
      );
    }
  }

  // A tier's picture cards are one height, and each card's tag stands at its foot: one line of tags across a row,
  // whatever the titles wrap to (msg_43d238b26dad: 'READY TO READ' at 404 in one card and 424 in the next).
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'a row of cards keeps its tags on one line at ${width.toInt()}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1200);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: ComicHost(
              child: ComicScaffold(
                body: ComicTier(
                  phone: ComicTierLayout.pairs,
                  children: [
                    // One row: a pair on a phone, quarters on a desk.
                    for (final (i, title) in [
                      'One line',
                      'A title long enough to wrap onto a second line',
                      if (width >= 600) ...['Third', 'Fourth'],
                    ].indexed)
                      ComicPictureCard(
                        slotId: 'card-$i',
                        image: const ComicArtBand(),
                        title: title,
                        trailing: ComicTag('Tag $i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        final tops = [
          for (final tag in find.byType(ComicTag).evaluate())
            tester.getRect(find.byWidget(tag.widget)).top,
        ];
        expect(tops, hasLength(width >= 600 ? 4 : 2));
        for (final top in tops) {
          expect((top - tops.first).abs(), lessThan(0.5), reason: '$tops');
        }
        final titles = [
          for (final t in [
            'One line',
            'A title long enough to wrap onto a second line',
          ])
            tester.getSize(find.text(t)).height,
        ];
        expect(
          titles[1],
          greaterThan(titles[0]),
          reason: 'the long title wraps',
        );
      },
    );
  }

  // The label sweep (ui_core fdd4fc74cc): every labelled control's label on the middle of its face, as laid out and as
  // drawn, under each density Comic ships.
  final densities = <String, DesignAlignmentTheme>{
    for (final (name, density) in [
      ('standard', ComicDensity.standard),
      ('compact', ComicDensity.compact),
    ])
      name: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ComicHost(
          light: ComicThemeData.offset().copyWith(density: density),
          child: child,
        ),
      ),
  };
  final screens = <String, Widget Function()>{
    'account': gateAccount,
    'settings': gateSettings,
    'library': gateLibrary,
    'shop': gateShop,
  };
  for (final width in [390.0, 1440.0]) {
    for (final MapEntry(key: name, value: body) in screens.entries) {
      testWidgets('$name keeps its labels on their faces at ${width.toInt()}', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 2600);
        addTearDown(tester.view.reset);
        final report =
            await const DesignLabelCheck(
              look: 'Comic',
              drawnTolerance: 0.5,
            ).checkDensities(
              densities: densities,
              screen: (context) => ComicScaffold(body: body()),
              pump: (widget) async {
                await tester.pumpWidget(widget);
                await settle(tester);
              },
              runAsync: tester.runAsync,
            );
        // Counts per density, as laid out and as drawn (the capitals, in device px), for the status.
        final problems = report.problems;
        String count(String density, bool drawn) =>
            '${problems.where((p) => p.startsWith('$density ·') && p.contains('as laid out') != drawn).length}';
        print(
          'labels $name ${width.toInt()}: ${problems.length}'
          ' (standard ${count('standard', false)} laid out, ${count('standard', true)} drawn;'
          ' compact ${count('compact', false)} laid out, ${count('compact', true)} drawn)',
        );
        for (final problem in problems) {
          print('  $problem');
        }
        report.verify();
      }, tags: 'goldens'); // the drawn capitals
    }
  }
}
