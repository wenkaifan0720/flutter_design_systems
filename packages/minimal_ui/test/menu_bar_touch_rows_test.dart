import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

Future<double> _rowHeight(WidgetTester tester) async {
  await tester.pumpWidget(
    centredHost(
      MinimalMenuBar(
        menus: [
          MinimalMenuEntry(
            'File',
            children: [
              MinimalMenuEntry('New', onPressed: () {}),
              MinimalMenuEntry('Open…', onPressed: () {}),
            ],
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('File'));
  await tester.pumpAndSettle();
  final row = find.ancestor(
    of: find.text('New'),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'MinimalKitRow',
    ),
  );
  return tester.getSize(row).height;
}

void main() {
  testWidgets("a menu bar's rows stand a finger tall on touch", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(await _rowHeight(tester), MinimalLayout.tapTargets.touch.height);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets("a menu bar's rows stay 32 under a pointer", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      expect(await _rowHeight(tester), 32);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
