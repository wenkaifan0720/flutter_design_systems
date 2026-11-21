// Every list a field opens on slipway's screens and the gallery pages that
// have one, at a phone's and a desk's width, at night and on paper, and
// right to left on a phone: ui_core's checkList (the list as wide as its
// field, on its edges, its words in line with the field's) finds nothing,
// on paper as by night (three selects' menus on paper are read by
// menu_ground_test.dart; see insetFrameOnPaper).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignWidthCheck;

// The example's screens and pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';
import 'ui_core_checks.dart';

void main() {
  setUpAll(loadFaces);

  final targets =
      <({String id, Widget Function(Brightness, TextDirection) app})>[
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

  // On paper, ui_core_test's checkList takes the inset frame of a select's
  // raised menu for the menu's drawn edges, and finds a menu as wide as its
  // field 4 px narrower than it. These menus' ground and frame are checked
  // on the painted pixels in menu_ground_test.dart instead.
  const insetFrameOnPaper = {
    'everyday-settings 390 0',
    'everyday-settings 390 rtl 0',
    'everyday-settings 1440 0',
    'settings 390 0',
    'settings 390 rtl 0',
    'settings 1440 0',
    'fields 390 1',
    'fields 390 rtl 1',
    'fields 1440 1',
  };

  const configs = [
    (390.0, TextDirection.ltr, Brightness.light),
    (390.0, TextDirection.ltr, Brightness.dark),
    (390.0, TextDirection.rtl, Brightness.light),
    (1440.0, TextDirection.ltr, Brightness.light),
    (1440.0, TextDirection.ltr, Brightness.dark),
  ];

  for (final t in targets) {
    for (final (width, dir, b) in configs) {
      final where = '${width.toInt()}${dir == TextDirection.rtl ? ' rtl' : ''}';
      testWidgets(
        '${t.id} at $where ${b.name}: every list a field opens fits it',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          addTearDown(tester.view.reset);
          addTearDown(() => kitShownDirection = TextDirection.ltr);
          Future<void> settle() async {
            for (var i = 0; i < 16; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          }

          Future<void> fresh() async {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(t.app(b, dir));
            await settle();
          }

          final problems = <String>[];
          void report(String opener, List<String> found) {
            final key = '${t.id} $where $opener';
            for (final p in found) {
              problems.add('$key: $p');
            }
          }

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
            if (pinned.hitTestable().evaluate().isEmpty) {
              // Below the fold: scrolled to, as a reader would.
              try {
                await tester.ensureVisible(pinned);
                await settle();
              } on Object {
                // Not in a scroller.
              }
            }
            if (pinned.hitTestable().evaluate().isEmpty) continue;
            final at = tester.getRect(pinned);
            // A field's list is checked; a menu from a narrower control (an
            // icon's, a menu bar's) is not a field's list.
            if (at.width < 96 || at.width < 2 * at.height) continue;
            if (b == Brightness.light &&
                insetFrameOnPaper.contains('${t.id} $where $i')) {
              continue;
            }
            final before = find.byType(TermPane).evaluate().toSet();
            await tester.tapAt(at.center);
            await settle();
            if (!find
                .byType(TermPane)
                .evaluate()
                .any((e) => !before.contains(e))) {
              continue;
            }
            report(
              '$i',
              (await DesignWidthCheck(
                look: 'terminal',
                listWordsIndent: uiCoreChecks.listWordsIndent.$1,
              ).checkList(field, runAsync: tester.runAsync)).problems,
            );
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
            if (entry.evaluate().isEmpty) continue;
            if (entry.hitTestable().evaluate().isEmpty) {
              try {
                await tester.ensureVisible(entry.first);
                await settle();
              } on Object {
                // Not in a scroller.
              }
            }
            if (entry.hitTestable().evaluate().isEmpty) continue;
            final before = find.byType(TermPane).evaluate().toSet();
            tester.testTextInput.register();
            await tester.showKeyboard(entry.first);
            for (final letter in const ['a', 'e', 'm', 'i']) {
              await tester.enterText(entry.first, letter);
              await settle();
              if (find
                  .byType(TermPane)
                  .evaluate()
                  .any((e) => !before.contains(e))) {
                break;
              }
            }
            if (!find
                .byType(TermPane)
                .evaluate()
                .any((e) => !before.contains(e))) {
              continue;
            }
            report(
              't$i',
              (await DesignWidthCheck(
                look: 'terminal',
                listWordsIndent: uiCoreChecks.listWordsIndent.$1,
              ).checkList(host, runAsync: tester.runAsync)).problems,
            );
          }

          expect(problems, isEmpty, reason: problems.join('\n'));
        },
        // The check reads drawn pixels, which depend on the rasterizer as a
        // golden does.
        tags: const ['goldens'],
      );
    }
  }
}
