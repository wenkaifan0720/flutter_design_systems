// A toast stands above a page's foot (StudioScreen's footer, its strip of the
// bar's metal), as a Scaffold keeps a snackbar above its persistent footer
// buttons: on a phone "Changes saved" stood over the page's Save.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _height = 844.0;

Future<GlobalKey> _page(
  WidgetTester tester, {
  required double width,
  TextDirection direction = TextDirection.ltr,
  bool footer = true,
}) async {
  tester.view.physicalSize = Size(width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: StudioHost(brightness: Brightness.light, child: navigator!),
      ),
      home: StudioScreen(
        key: page,
        topBar: const StudioAppBar(title: 'Task details'),
        footer: footer
            ? StudioButton.lit('Save changes', onPressed: () {})
            : null,
        body: const Text('Proof the studio map'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

// The foot's strip: the metal round Save, the page's width, at its foot.
Rect _foot(WidgetTester tester, double width) => find
    .ancestor(
      of: find.text('Save changes'),
      matching: find.byType(StudioSurface),
    )
    .evaluate()
    .map((e) => tester.getRect(find.byWidget(e.widget)))
    .singleWhere(
      (r) => r.width == width && r.bottom == _height && r.height < _height,
    );

// The toast's box, and how far its shadow's box reaches below it.
(Rect, double) _toast(WidgetTester tester) {
  final box = find
      .ancestor(
        of: find.text('Changes saved'),
        matching: find.byType(DecoratedBox),
      )
      .evaluate()
      .map((e) => e.widget as DecoratedBox)
      .firstWhere((b) {
        final d = b.decoration;
        return d is BoxDecoration && (d.boxShadow?.isNotEmpty ?? false);
      });
  final reach = (box.decoration as BoxDecoration).boxShadow!
      .map((s) => s.offset.dy + s.spreadRadius)
      .reduce((a, b) => a > b ? a : b);
  return (tester.getRect(find.byWidget(box)), reach);
}

void main() {
  for (final width in const [390.0, 900.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${width.round()}, ${direction.name}: a toast stands '
          'above the page foot', (tester) async {
        final page = await _page(tester, width: width, direction: direction);
        final foot = _foot(tester, width);
        final save = tester.getRect(find.text('Save changes'));
        expect(foot.top, lessThan(save.top), reason: 'the foot');
        final handle = showStudioToast(
          page.currentContext!,
          'Changes saved',
          duration: null,
        );
        await tester.pumpAndSettle();
        final (toast, reach) = _toast(tester);
        expect(
          toast.bottom + reach,
          lessThanOrEqualTo(foot.top),
          reason: 'toast $toast, its shadow $reach below; foot from $foot',
        );
        handle.dismiss();
        await tester.pumpAndSettle();
        expect(find.text('Changes saved'), findsNothing);
      });
    }
  }

  testWidgets('with no foot, a toast stands at the screen foot', (
    tester,
  ) async {
    final page = await _page(tester, width: 390, footer: false);
    final handle = showStudioToast(
      page.currentContext!,
      'Changes saved',
      duration: null,
    );
    await tester.pumpAndSettle();
    final (toast, _) = _toast(tester);
    expect(toast.bottom, _height - 16);
    handle.dismiss();
    await tester.pumpAndSettle();
  });
}
