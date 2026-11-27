// A page held to a measure (MinimalScaffold.maxWidth): the bar's actions
// and the footer end where the body ends, on the start edge, both ways.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _body = Key('body');
const _foot = Key('foot');

Widget _page(TextDirection direction) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: Directionality(textDirection: direction, child: app!),
  ),
  home: Builder(
    builder: (context) => MinimalScaffold(
      maxWidth: MinimalLayout.contentWidth(context),
      topBar: MinimalAppBar(
        title: 'Books',
        actions: [
          MinimalIconButton(
            LucideIcons.plus,
            semanticLabel: 'Add',
            onPressed: () {},
          ),
        ],
      ),
      footer: const SizedBox(key: _foot, height: 40),
      body: const SizedBox(key: _body, height: 40),
    ),
  ),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'at 1440 the bar and the footer end on the body (${direction.name})',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_page(direction));
        await tester.pumpAndSettle();

        final body = tester.getRect(find.byKey(_body));
        final foot = tester.getRect(find.byKey(_foot));
        final add = tester.getRect(find.byType(MinimalIconButton));
        final title = tester.getRect(find.text('Books'));
        final ltr = direction == TextDirection.ltr;
        // The body keeps the 840 measure on its start edge.
        expect(body.width, 840 - MinimalInsets.screen.horizontal);
        if (ltr) {
          expect(add.right, body.right);
          expect(foot.right, body.right);
          expect(title.left, body.left);
        } else {
          expect(add.left, body.left);
          expect(foot.left, body.left);
          expect(title.right, body.right);
        }
      },
    );
  }

  testWidgets('without a measure the page spans the window', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          brightness: Brightness.light,
          child: app!,
        ),
        home: MinimalScaffold(
          topBar: MinimalAppBar(
            title: 'Books',
            actions: [
              MinimalIconButton(
                LucideIcons.plus,
                semanticLabel: 'Add',
                onPressed: () {},
              ),
            ],
          ),
          body: const SizedBox(key: _body, height: 40),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(_body)).right,
      1440 - MinimalInsets.screen.right,
    );
    expect(
      tester.getRect(find.byType(MinimalIconButton)).right,
      1440 - MinimalChromeMetrics.barInsetEnd,
    );
  });
}
