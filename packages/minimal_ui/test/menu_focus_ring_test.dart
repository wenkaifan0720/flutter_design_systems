// A row's menu opened with a mouse, an item chosen that opens a page, and
// the page closed with the mouse: the screen is as it was before the click,
// no focus ring or wash left on the row or its key, as nothing came from the
// keys. After a Tab the keyboard's place shows. Run as a desktop (macOS),
// and as the web with semantics on, where a click first focuses the clicked
// control's node.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _shot = ValueKey('screen');

/// The screen's pixels.
Future<Uint8List> _screen(WidgetTester tester) async {
  final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  return (await tester.runAsync(() async {
    final image = await box.toImage();
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  for (final web in [false, true]) {
    testWidgets(
      'a mouse-opened menu leaves no ring on the row${web ? ' (web, semantics on)' : ''}',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => RepaintBoundary(
              key: _shot,
              child: MinimalHost(brightness: Brightness.light, child: app!),
            ),
            home: Builder(
              builder: (context) => MinimalScaffold(
                padding: EdgeInsets.zero,
                body: MinimalListSection(
                  children: [
                    MinimalListTile(
                      title: 'Dune',
                      onTap: () {},
                      trailing: MinimalMenu.button(
                        LucideIcons.ellipsis,
                        semanticLabel: 'Dune actions',
                        items: [
                          MinimalMenuItem(
                            'Edit',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const MinimalScaffold(
                                  topBar: MinimalAppBar(title: 'Edit'),
                                  body: SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final untouched = await _screen(tester);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        Future<void> click(Finder finder) async {
          if (web) {
            // The browser focuses the clicked element's node first.
            final node = tester.getSemantics(finder);
            if (node.getSemanticsData().hasAction(SemanticsAction.focus)) {
              tester.binding.performSemanticsAction(
                SemanticsActionEvent(
                  type: SemanticsAction.focus,
                  viewId: tester.view.viewId,
                  nodeId: node.id,
                ),
              );
              await tester.pump();
            }
          }
          await mouse.moveTo(tester.getCenter(finder));
          await mouse.down(tester.getCenter(finder));
          await mouse.up();
          await tester.pumpAndSettle();
        }

        await click(find.byType(MinimalMenu));
        await click(find.text('Edit'));
        expect(find.text('Edit'), findsOneWidget);
        // Back with the mouse, on the app bar's back key.
        await click(find.bySemanticsLabel('Back').last);
        await tester.pumpAndSettle();
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        // Nothing left on the row: no ring, no wash, no key face.
        expect(await _screen(tester), untouched);

        // A key shows it again.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(await _screen(tester), isNot(untouched));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  }
}
