// The lists the fields on slipway's screens and the gallery's pages open, one
// at a time, as list_check_test.dart and menu_ground_test.dart read them.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens and pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';

/// A screen or page that holds fields with lists, by its id, built in a
/// brightness and a direction.
typedef FieldListPage = ({
  String id,
  Widget Function(Brightness, TextDirection) app,
});

/// slipway's screens and the gallery's pages that hold a field with a list.
final fieldListPages = <FieldListPage>[
  for (final s in everydayScreens)
    if (const {'runs', 'deploy', 'settings', 'search'}.contains(s.id))
      (id: 'everyday-${s.id}', app: s.app),
  for (final p in galleryPages)
    if (const {
      'runs',
      'deploy',
      'settings',
      'fields',
      'inputs',
      'inventory',
      'actions',
      'navigation',
      'wayfinding',
      'overlays',
    }.contains(p.id))
      (
        id: p.id,
        app: (Brightness b, TextDirection d) {
          kitShownDirection = d;
          return p.build(b);
        },
      ),
];

/// Opens each list a field on [app] opens, on a fresh screen each time, and
/// hands [check] the list's key, the field and the list's pane.
///
/// A press opens a select's list or a field's menu: its key is the field's
/// index among the controls that open one. Typing opens a combobox's or a
/// tag input's: its key is `t` and the entry's index. A field below the fold
/// is scrolled to first, as a reader would; a menu from a narrower control
/// (an icon's, a menu bar's) is not a field's list.
Future<void> openEachFieldList(
  WidgetTester tester,
  Widget Function() app,
  Future<void> Function(String key, Element field, Element pane) check,
) async {
  Future<void> settle() async {
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> fresh() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await settle();
  }

  Future<bool> onScreen(Finder f) async {
    if (f.hitTestable().evaluate().isEmpty) {
      try {
        await tester.ensureVisible(f);
        await settle();
      } on Object {
        // Not in a scroller.
      }
    }
    return f.hitTestable().evaluate().isNotEmpty;
  }

  Element? opened(Set<Element> before) => find
      .byType(TermPane)
      .evaluate()
      .where((e) => !before.contains(e))
      .firstOrNull;

  // The lists a press opens: a select's, a field's menu.
  final openers = find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        w.properties.expanded == false &&
        w.properties.enabled != false,
  );
  await fresh();
  final count = openers.evaluate().length;
  for (var i = 0; i < count; i++) {
    await fresh();
    final all = openers.evaluate().toList();
    if (i >= all.length) break;
    final field = all[i];
    final pinned = find.byElementPredicate((e) => identical(e, field));
    if (!await onScreen(pinned)) continue;
    final at = tester.getRect(pinned);
    if (at.width < 96 || at.width < 2 * at.height) continue;
    final before = find.byType(TermPane).evaluate().toSet();
    await tester.tapAt(at.center);
    await settle();
    if (opened(before) case final pane?) await check('$i', field, pane);
  }

  // The lists typing opens (a combobox's, a tag input's).
  final typed = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('RawAutocomplete<'),
  );
  await fresh();
  final typedCount = typed.evaluate().length;
  for (var i = 0; i < typedCount; i++) {
    await fresh();
    final all = typed.evaluate().toList();
    if (i >= all.length) break;
    final host = all[i];
    final entry = find.descendant(
      of: find.byElementPredicate((e) => identical(e, host)),
      matching: find.byType(EditableText),
    );
    if (entry.evaluate().isEmpty || !await onScreen(entry.first)) continue;
    final before = find.byType(TermPane).evaluate().toSet();
    tester.testTextInput.register();
    await tester.showKeyboard(entry.first);
    Element? pane;
    for (final letter in const ['a', 'e', 'm', 'i']) {
      await tester.enterText(entry.first, letter);
      await settle();
      pane = opened(before);
      if (pane != null) break;
    }
    if (pane != null) await check('t$i', host, pane);
  }
}
