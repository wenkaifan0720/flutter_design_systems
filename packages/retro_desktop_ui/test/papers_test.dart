// Papers, the look's own application, as the example opens it: its keylines (design6 P) and what a person does in it.
//
// Keylines: in every window, every block that spans the content (a field, a popup, a list or table well, a group box, a
// radio group, a disclosure, a document) starts on one leading keyline and ends on one trailing keyline; a row of
// buttons ends on the trailing one; the buttons of a row share a height and a centre line. At 390 and 1440, day and
// night, Platinum and Chisel.
// The package emitter carries the example's own app into example/lib.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/papers.dart';

import 'support.dart';

bool _isBlock(Widget w) {
  final name = w.runtimeType.toString().split('<').first;
  return const {
    'RetroDesktopTextField',
    'RetroDesktopSelect',
    'RetroDesktopRadioGroup',
    'RetroDesktopListTable',
    'RetroDesktopTable',
    'RetroDesktopGroupBox',
    'RetroDesktopDisclosure',
    'RetroDesktopDocument',
  }.contains(name);
}

bool _isButton(Widget w) =>
    w is RetroDesktopButton ||
    w is RetroDesktopButton ||
    w is RetroDesktopButton;

Rect _rect(WidgetTester tester, Element e) =>
    tester.getRect(find.byElementPredicate((x) => identical(x, e)));

/// The keyline faults of every window on screen, one line each.
List<String> keylineFaults(WidgetTester tester) {
  final faults = <String>[];
  for (final window in find.byType(RetroDesktopWindow).evaluate()) {
    final title = (window.widget as RetroDesktopWindow).title;
    final inWindow = find.descendant(
      of: find.byElementPredicate((x) => identical(x, window)),
      matching: find.byWidgetPredicate(_isBlock),
    );
    // Only the outermost blocks: a field inside a group box keeps the box's own keyline.
    final rects = <Rect>[];
    for (final e in inWindow.evaluate()) {
      var nested = false;
      e.visitAncestorElements((a) {
        if (identical(a, window)) return false;
        if (_isBlock(a.widget)) {
          nested = true;
          return false;
        }
        return true;
      });
      if (!nested) rects.add(_rect(tester, e));
    }
    if (rects.isEmpty) continue;
    final starts = {for (final r in rects) r.left.round()};
    final ends = {for (final r in rects) r.right.round()};
    if (starts.length > 1) {
      faults.add('$title: ${starts.length} leading keylines $starts');
    }
    if (ends.length > 1) {
      faults.add('$title: ${ends.length} trailing keylines $ends');
    }
    final end = ends.first;
    // Buttons, in rows by their top; a lone one (the foot's small action) has no row to keep.
    // A row is the buttons whose heights overlap, so one taller or lower than
    // its neighbour still counts as in its row.
    final buttons = [
      for (final e
          in find
              .descendant(
                of: find.byElementPredicate((x) => identical(x, window)),
                matching: find.byWidgetPredicate(_isButton),
              )
              .evaluate())
        _rect(tester, e),
    ]..sort((a, b) => a.top.compareTo(b.top));
    final rows = <List<Rect>>[];
    for (final b in buttons) {
      if (rows.isNotEmpty &&
          rows.last.any((o) => o.top < b.bottom && b.top < o.bottom)) {
        rows.last.add(b);
      } else {
        rows.add([b]);
      }
    }
    for (final row in rows.where((r) => r.length > 1)) {
      final heights = {for (final b in row) b.height.round()};
      final centres = {for (final b in row) b.center.dy.round()};
      if (heights.length > 1) {
        faults.add('$title: one row of buttons in heights $heights');
      }
      if (centres.length > 1) {
        faults.add('$title: one row of buttons on centre lines $centres');
      }
      final last = row
          .map((b) => b.right.round())
          .reduce((a, b) => a > b ? a : b);
      if (last != end) {
        faults.add(
          '$title: a row of buttons ends at $last, the keyline at $end',
        );
      }
    }
  }
  return faults;
}

Future<void> _pump(
  WidgetTester tester,
  KitPapersWindow front, {
  required double width,
  bool dark = false,
  RetroDesktopAppearance appearance = RetroDesktopAppearance.platinum,
  RetroDesktopDensity? density,
  bool alone = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final base = RetroDesktopThemeData.preset(
    'classic',
    dark ? Brightness.dark : Brightness.light,
  ).copyWith(appearance: appearance, density: density);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('$front/$width/$dark/$appearance/$density/$alone'),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => RetroDesktopTheme(
        data: base.atWidth(MediaQuery.sizeOf(context).width),
        child: child!,
      ),
      home: KitPapers(front: front, alone: alone),
    ),
  );
  await tester.pumpAndSettle();
}

bool _ellipsed(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;

Finder _inWindow(String window, Finder what) => find.descendant(
  of: find.byKey(ValueKey('papers-window/$window')),
  matching: what,
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final front in [
    KitPapersWindow.documents,
    KitPapersWindow.details,
    KitPapersWindow.settings,
    KitPapersWindow.prints,
  ]) {
    for (final width in [390.0, 1440.0]) {
      for (final dark in [false, true]) {
        for (final appearance in RetroDesktopAppearance.values) {
          testWidgets(
            'keylines: ${front.name} at $width, dark=$dark, ${appearance.name}',
            (tester) async {
              await _pump(
                tester,
                front,
                width: width,
                dark: dark,
                appearance: appearance,
              );
              expect(tester.takeException(), isNull);
              expect(keylineFaults(tester), isEmpty);
            },
          );
        }
      }
    }
  }

  testWidgets(
    'at 1440 the list and the open document stand side by side, one active',
    (tester) async {
      await _pump(tester, KitPapersWindow.documents, width: 1440);
      final list = tester.getRect(
        find.byKey(const ValueKey('papers-window/documents')),
      );
      final doc = tester.getRect(
        find.byKey(const ValueKey('papers-window/document')),
      );
      expect(doc.left, greaterThan(list.right));
      expect(list.width, 600, reason: 'a window is as wide as what it holds');
      final scopes = tester.widgetList<RetroDesktopWindowScope>(
        find.byType(RetroDesktopWindowScope),
      );
      expect(scopes.where((s) => s.active), hasLength(1));
    },
  );

  // Design6, 11-12: on the desk the "Project notes" window showed the top half
  // of its title above the Settings and "Your details" title bars. A window
  // behind shows its title bar whole, or hides its title wholly under the
  // window in front: never words cut by another bar.
  for (final appearance in RetroDesktopAppearance.values) {
    for (final density in RetroDesktopDensity.values) {
      testWidgets('at 1440 a window behind shows its title bar whole '
          '(${appearance.name}, ${density.name})', (tester) async {
        final faults = <String>[];
        for (final front in [
          KitPapersWindow.details,
          KitPapersWindow.settings,
          KitPapersWindow.prints,
        ]) {
          await _pump(
            tester,
            front,
            width: 1440,
            appearance: appearance,
            density: density,
          );
          final windows = find.byType(RetroDesktopWindow).evaluate().toList();
          for (var i = 0; i < windows.length; i++) {
            final title = (windows[i].widget as RetroDesktopWindow).title;
            final window = find.byElementPredicate(
              (x) => identical(x, windows[i]),
            );
            final box = tester.getRect(window);
            final words = tester.getRect(
              find.descendant(of: window, matching: find.text(title)).first,
            );
            // The bar: the window's top to as far under the words as they
            // stand below it.
            final bar = Rect.fromLTRB(
              box.left,
              box.top,
              box.right,
              words.bottom + (words.top - box.top),
            );
            for (final later in windows.skip(i + 1)) {
              final over = tester.getRect(
                find.byElementPredicate((x) => identical(x, later)),
              );
              final shared = bar.intersect(over);
              if (shared.width <= 0 || shared.height <= 0) continue;
              final hidden =
                  over.contains(words.topLeft) &&
                  over.contains(words.bottomRight - const Offset(.1, .1));
              if (!hidden) {
                faults.add(
                  '${front.name}: "$title" ($bar) is cut by '
                  '"${(later.widget as RetroDesktopWindow).title}" at $over',
                );
              }
            }
          }
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      });
    }
  }

  testWidgets('a row is selected by a press and opened by a second, or Return', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.documents, width: 1440);
    await tester.tap(find.text('Team handbook'));
    await tester.pump();
    expect(_inWindow('document', find.text('Team handbook')), findsNothing);
    await tester.tap(find.text('Team handbook'));
    await tester.pumpAndSettle();
    expect(_inWindow('document', find.text('Team handbook')), findsWidgets);
    // The list keeps the focus: the arrows move the selection, Return opens it.
    await tester.tap(find.text('Reading list'));
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_inWindow('document', find.text('Quarterly plan')), findsWidgets);
  });

  testWidgets(
    'the default Open opens the selected row; on a phone a tap does',
    (tester) async {
      await _pump(tester, KitPapersWindow.documents, width: 1440);
      await tester.tap(find.text('Meeting summary'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(RetroDesktopButton, 'Open'));
      await tester.pumpAndSettle();
      expect(_inWindow('document', find.text('Meeting summary')), findsWidgets);

      await _pump(tester, KitPapersWindow.documents, width: 390, alone: true);
      await tester.tap(find.text('Reading list'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('papers-window/documents')),
        findsNothing,
      );
      expect(_inWindow('document', find.text('Reading list')), findsWidgets);
    },
  );

  testWidgets('a head sorts, and again the other way', (tester) async {
    await _pump(tester, KitPapersWindow.documents, width: 1440);
    double y(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(y('Meeting summary'), lessThan(y('Team handbook')));
    await tester.tap(find.text('Size'));
    await tester.pumpAndSettle();
    expect(
      y('Team handbook'),
      lessThan(y('Reading list')),
      reason: 'largest first',
    );
    await tester.tap(find.text('Size'));
    await tester.pumpAndSettle();
    expect(y('Reading list'), lessThan(y('Team handbook')));
  });

  // What the gate's captures showed (11-11): a band over the heads, a grow box beside the words, a field taller than the
  // popup under it.
  testWidgets('the heads stand flush on the list; sizes line up at their end', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.documents, width: 1440);
    final list = tester.getRect(find.byType(RetroDesktopListTable));
    final head = tester.getRect(find.text('Name'));
    expect(
      head.center.dy - list.top,
      lessThan(16),
      reason: 'no band over the heads',
    );
    final first = tester.getRect(find.text('Meeting summary'));
    expect(first.top - head.bottom, lessThan(20));
    final sizes = [
      for (final s in ['18 KB', '6 KB', '1.2 MB']) tester.getRect(find.text(s)),
    ];
    for (final s in sizes) {
      expect(s.right, closeTo(sizes.first.right, .5));
    }
    expect(find.text('Yesterday, 16:40'), findsOneWidget);
    expect(_ellipsed(tester, 'Yesterday, 16:40'), isFalse);
  });

  testWidgets('a menu is as wide as what it holds, under its title', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.documents, width: 1440);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('File'));
    final item = tester.getRect(find.text('Close window'));
    final keys = tester.getRect(find.text('Ctrl+W'));
    expect(keys.right - title.left, lessThan(400), reason: 'not the screen');
    expect(item.left, greaterThanOrEqualTo(title.left - 24));
  });

  testWidgets('the grow box stands in the window corner', (tester) async {
    await _pump(tester, KitPapersWindow.document, width: 1440);
    final window = tester.getRect(
      find.byKey(const ValueKey('papers-window/document')),
    );
    final words = tester.getRect(_inWindow('document', find.text('24 KB')));
    // The words keep their own width; the box is at the window's end, not after them.
    expect(window.right - words.right, greaterThan(100));
  });

  testWidgets('under a pointer a field is drawn as tall as the popup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _pump(tester, KitPapersWindow.details, width: 1440);
      final field = tester.getRect(find.byType(RetroDesktopTextField).first);
      final popup = tester.getRect(find.byType(RetroDesktopSelect<String>));
      expect(field.height, closeTo(popup.height, .01));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  // What the coordinator's read of the gate showed (11-11): the strip's and the foot's words off the content's
  // keylines, a field's words and a popup's at two insets, Cancel a bare word, a group's name 2 px off its rows, the
  // Advanced triangle's ink 3 px in.
  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets('a field\'s words and a popup\'s start one inset in, '
        '${appearance.name}', (tester) async {
      await _pump(
        tester,
        KitPapersWindow.details,
        width: 1440,
        appearance: appearance,
      );
      final field = tester.getRect(
        find.descendant(
          of: find.byType(RetroDesktopTextField).first,
          matching: find.byType(EditableText),
        ),
      );
      final popup = tester.getRect(
        find.descendant(
          of: find.byType(RetroDesktopSelect<String>),
          matching: find.text('This computer'),
        ),
      );
      expect(field.left, closeTo(popup.left, .5));
    });
  }

  for (final appearance in RetroDesktopAppearance.values) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets('the default button\'s ring, its outline, ends on the '
          'fields\' trailing edge, ${appearance.name} at $width', (
        tester,
      ) async {
        await _pump(
          tester,
          KitPapersWindow.details,
          width: width,
          appearance: appearance,
        );
        final field = tester.getRect(find.byType(RetroDesktopTextField).first);
        final save = tester.getRect(
          find.widgetWithText(RetroDesktopButton, 'Save'),
        );
        expect(save.right, closeTo(field.right, .5));
      });
    }
  }

  testWidgets('the strip\'s and the foot\'s words stand on the content\'s '
      'keylines', (tester) async {
    await _pump(tester, KitPapersWindow.settings, width: 1440);
    final list = tester.getRect(find.byType(RetroDesktopListTable));
    expect(
      tester.getRect(find.text('6 documents')).left,
      closeTo(list.left, .5),
    );
    expect(
      tester.getRect(find.text('1.2 GB available')).right,
      closeTo(list.right, .5),
    );
    final group = tester.getRect(find.byType(RetroDesktopGroupBox).first);
    expect(
      tester.getRect(find.text('Changes are kept as you make them')).left,
      closeTo(group.left, .5),
    );
  });

  testWidgets('a group\'s name stands on its rows\' keyline; the triangle\'s '
      'ink on the window\'s', (tester) async {
    await _pump(tester, KitPapersWindow.settings, width: 1440);
    final name = tester.getRect(_inWindow('settings', find.text('Documents')));
    final row = tester.getRect(find.byType(RetroDesktopCheckRow).first);
    expect(name.left, closeTo(row.left, .5));
    final group = tester.getRect(find.byType(RetroDesktopGroupBox).first);
    Rect mark() => tester.getRect(
      find.descendant(
        of: find.byType(RetroDesktopDisclosure),
        matching: find.byType(RetroDesktopTriangleMark),
      ),
    );
    // Drawn closed, the triangle's ink is 3 in from its 12 px box; open, 1.
    expect(mark().left + 3, closeTo(group.left, .5));
    final words = tester.getRect(find.text('Advanced')).left;
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(mark().left + 1, closeTo(group.left, .5));
    expect(
      tester.getRect(find.text('Advanced')).left,
      words,
      reason: 'the words stay put as it turns',
    );
  });

  testWidgets('the secondary button is the push button', (tester) async {
    for (final w in [KitPapersWindow.details, KitPapersWindow.prints]) {
      await _pump(tester, w, width: 1440);
      expect(
        _inWindow(w.name, find.widgetWithText(RetroDesktopButton, 'Cancel')),
        findsOneWidget,
      );
      // No text form (RetroDesktopButton.text draws no face at rest).
      expect(
        _inWindow(
          w.name,
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_ExtraButton',
          ),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('a desk icon is selected by a press and opened by a second', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.documents, width: 1440);
    expect(find.byKey(const ValueKey('papers-window/bin')), findsNothing);
    await tester.tap(find.text('Bin'));
    await tester.pump();
    expect(find.byKey(const ValueKey('papers-window/bin')), findsNothing);
    await tester.tap(find.text('Bin'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('papers-window/bin')), findsOneWidget);
  });

  testWidgets('a press on a window behind brings it to the front', (
    tester,
  ) async {
    await _pump(tester, KitPapersWindow.settings, width: 1440);
    bool active(String w) => tester
        .widget<RetroDesktopWindowScope>(
          find
              .ancestor(
                of: find.byKey(ValueKey('papers-window/$w')),
                matching: find.byType(RetroDesktopWindowScope),
              )
              .first,
        )
        .active;
    expect(active('settings'), isTrue);
    await tester.tap(find.text('1.2 GB available'));
    await tester.pumpAndSettle();
    expect(active('documents'), isTrue);
    expect(active('settings'), isFalse);
  });

  testWidgets(
    'the menu bar does its job: Window brings one forward, File closes it',
    (tester) async {
      await _pump(tester, KitPapersWindow.documents, width: 1440);
      await tester.tap(find.text('Window'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your details').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('papers-window/details')),
        findsOneWidget,
      );
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close window'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('papers-window/details')), findsNothing);
    },
  );

  testWidgets('the amount due is set apart, with its currency', (tester) async {
    await _pump(tester, KitPapersWindow.prints, width: 1440);
    expect(find.text('Amount due'), findsOneWidget);
    // Two bound copies of the two-page notes at \$4.00 each, and \$4.00 postage.
    expect(find.text('\$8.00'), findsOneWidget);
    expect(find.text('\$12.00'), findsOneWidget);
  });
}
