// Every list a select opens on the gallery's fields and selection pages and on
// Admit's settings, at a phone's and a desk's width, on paper and by night:
// ui_core's checkList (the list as wide as its field, on its edges, its words
// in line with the field's) finds nothing but the misreads Brutal declares
// ([uiCoreMisreads]: two selects in a padded list, whose own rule the check
// still reads as ground, and a list opened upward over another select whose
// rules stand in its columns).
// ignore_for_file: avoid_relative_lib_imports
@Tags(['goldens'])
library;

import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignWidthCheck;

import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';
import 'ui_core_checks.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  final targets = <({String id, Widget Function(Brightness) app})>[
    for (final s in everydayScreens)
      if (s.id == 'settings')
        (id: 'everyday-${s.id}', app: (b) => s.app(b, TextDirection.ltr)),
    for (final p in galleryPages)
      if (const {'fields', 'choices'}.contains(p.id)) (id: p.id, app: p.build),
  ];

  const configs = [
    (390.0, Brightness.light),
    (390.0, Brightness.dark),
    (1440.0, Brightness.light),
  ];

  for (final t in targets) {
    for (final (width, b) in configs) {
      testWidgets(
        '${t.id} at ${width.toInt()} ${b.name}: every list a select opens '
        'fits its field',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          addTearDown(tester.view.reset);
          Future<void> settle() async {
            for (var i = 0; i < 16; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          }

          Future<void> fresh() async {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(t.app(b));
            await settle();
          }

          final problems = <String>[];
          // The lists a press opens: a select's. A combobox's and a tag
          // input's text input reads its list's state too, but its list opens
          // as one types, not on a press.
          bool typedIn(Element e) {
            var found = false;
            void visit(Element child) {
              if (found) return;
              if (child.widget is EditableText) {
                found = true;
                return;
              }
              child.visitChildren(visit);
            }

            e.visitChildren(visit);
            return found;
          }

          final openers = find.byElementPredicate((e) {
            final w = e.widget;
            return w is Semantics &&
                w.properties.expanded == false &&
                w.properties.enabled != false &&
                !typedIn(e);
          });
          await fresh();
          final count = openers.evaluate().length;
          var checked = 0;
          for (var i = 0; i < count; i++) {
            await fresh();
            final all = openers.evaluate().toList();
            if (i >= all.length) break;
            final field = all[i];
            final pinned = find.byElementPredicate((e) => identical(e, field));
            if (pinned.hitTestable().evaluate().isEmpty) {
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
            // icon's, a split button's) is not a field's list.
            if (at.width < 96 || at.width < 2 * at.height) continue;
            final before = find.byType(BrutalSurface).evaluate().toSet();
            await tester.tapAt(at.center);
            await settle();
            if (!find
                .byType(BrutalSurface)
                .evaluate()
                .any((e) => !before.contains(e))) {
              continue;
            }
            checked++;
            final found = (await DesignWidthCheck(
              look: 'brutal',
              listWordsIndent: uiCoreChecks.listWordsIndent.$1,
            ).checkList(field, runAsync: tester.runAsync)).problems;
            problems.addAll([
              for (final p in found)
                if (!misreadSelects.any(
                  (m) => p.contains('select "${m.$1}"') && p.endsWith(m.$2),
                ))
                  '${t.id} ${width.toInt()} $i: $p',
            ]);
          }
          debugPrint('LISTS ${t.id} ${width.toInt()} ${b.name}: $checked');
          expect(problems, isEmpty, reason: problems.join('\n'));
        },
      );
    }
  }
}
