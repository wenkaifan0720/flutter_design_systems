// Every widget the package exports is live on a gallery page (polish3 §4): a part no page builds is one the user
// can't find. Each page is built at a phone's width and a desktop's (a phone shows the bottom bar, a desktop the nav
// pane), and every widget in its tree is counted, offstage ones too. The few a page's first frame does not build are
// named in [onDemand], each with where the gallery shows it: raised on a press, built round every page by the example
// app, or a row of the inventory's lazy list, built as it is scrolled to.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';

/// Exported widgets a page's first frame does not build: the widget, and where the gallery shows it.
const Map<String, String> onDemand = {
  'Fluent2FieldContextMenu':
      'entries: a right-click, or a long press, in any field',
  'Fluent2Sheet': 'inventory: the Sheet (side) row, scrolled to',
  'AnimatedFluent2Theme':
      'the example app, round every page (the Customize panel animates it)',
  'Fluent2Toaster': 'the example app, round every page (the states page raises its snack bar)',
  'Fluent2FocusRing':
      'every page: the ring round the control the keyboard moves to (Tab)',
};

/// The widgets the package's barrel exports from its own files, read from the source.
Set<String> exportedWidgets() {
  final result = <String>{};
  final barrel = File('lib/src/fluent2_design.dart').readAsStringSync();
  for (final export in RegExp(
    r"export '([^']+)'([^;]*);",
    dotAll: true,
  ).allMatches(barrel)) {
    if (export[1]!.startsWith('package:')) continue;
    final clause = export[2]!;
    final shown = RegExp(r'show ([\w,\s]+)').firstMatch(clause)?[1];
    final hidden = RegExp(r'hide ([\w,\s]+)').firstMatch(clause)?[1];
    Set<String> names(String? list) =>
        list == null ? {} : list.split(',').map((s) => s.trim()).toSet();
    final file = File('lib/src/${export[1]}');
    for (final declaration in RegExp(
      r'^(?:final )?class (\w+)([^\{]+)\{',
      multiLine: true,
    ).allMatches(file.readAsStringSync())) {
      final name = declaration[1]!;
      if (name.startsWith('_') || names(hidden).contains(name)) continue;
      if (shown != null && !names(shown).contains(name)) continue;
      if (RegExp(
        r'extends (StatelessWidget|StatefulWidget|ImplicitlyAnimatedWidget|InheritedWidget|InheritedTheme|SingleChildRenderObjectWidget|MultiChildRenderObjectWidget|ParentDataWidget|LeafRenderObjectWidget)',
      ).hasMatch(declaration[2]!)) {
        result.add(name);
      }
    }
  }
  return result;
}

void main() {
  setUpAll(loadFluent2TestFonts);

  test('the barrel exports widgets to check', () {
    expect(exportedWidgets().length, greaterThan(100));
  });

  testWidgets('every exported widget is built by a gallery page', (t) async {
    final built = <String>{};
    for (final width in const [390.0, 1440.0]) {
      for (final page in galleryPages) {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 1000);
        addTearDown(t.view.reset);
        await t.pumpWidget(
          KeyedSubtree(
            key: ValueKey('${page.id}/$width'),
            child: page.build(Brightness.light),
          ),
        );
        await settle(t);
        expect(t.takeException(), isNull, reason: '${page.id} at $width');
        for (final e
            in find
                .byWidgetPredicate((_) => true, skipOffstage: false)
                .evaluate()) {
          built.add(e.widget.runtimeType.toString().split('<').first);
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 2));
      }
    }
    final missing = exportedWidgets()
        .difference(built)
        .difference(onDemand.keys.toSet());
    expect(
      missing,
      isEmpty,
      reason:
          'built by no gallery page: ${missing.toList()..sort()}; add each to a '
          'page, or to onDemand with the page whose button raises it',
    );
  });
}
