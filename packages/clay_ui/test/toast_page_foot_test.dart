// A toast stands above a page's foot (ClayScreen's footer, the page's one
// coral key), as a Scaffold keeps a snackbar above its persistent footer
// buttons: on a phone "Changes saved" stood over the page's Save. Its shadow
// keeps off the foot too.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _height = 844.0;
final _stage = GlobalKey();

Future<GlobalKey> _page(
  WidgetTester tester, {
  required double width,
  required Brightness brightness,
  TextDirection direction = TextDirection.ltr,
  bool footer = true,
}) async {
  tester.view.physicalSize = Size(width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final page = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => RepaintBoundary(
        key: _stage,
        child: Directionality(
          textDirection: direction,
          child: ClayHost(brightness: brightness, child: navigator!),
        ),
      ),
      home: ClayScreen(
        key: page,
        topBar: const ClayTopBar(title: 'Task details'),
        footer: footer
            ? ClayButton.filled('Save changes', onPressed: () {})
            : null,
        body: const Text('Proof the studio map'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return page;
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

/// How many pixels of the rows [top] to [bottom] differ between [a] and [b]
/// by more than a step or two.
int _changed(Uint8List a, Uint8List b, int width, int top, int bottom) {
  var n = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      if ((a[i] - b[i]).abs() > 2 ||
          (a[i + 1] - b[i + 1]).abs() > 2 ||
          (a[i + 2] - b[i + 2]).abs() > 2) {
        n++;
      }
    }
  }
  return n;
}

Rect _toast(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Changes saved'),
        matching: find.byType(ClaySurface),
      )
      .first,
);

void main() {
  for (final brightness in Brightness.values) {
    for (final width in const [390.0, 900.0, 1440.0]) {
      for (final direction in TextDirection.values) {
        testWidgets('at ${width.round()}, ${brightness.name}, '
            '${direction.name}: a toast and its shadow stand above the page '
            'foot', (tester) async {
          final page = await _page(
            tester,
            width: width,
            brightness: brightness,
            direction: direction,
          );
          // The foot: the page's Save key and the room above and below it.
          final save = tester.getRect(
            find
                .ancestor(
                  of: find.text('Save changes'),
                  matching: find.byType(ClaySurface),
                )
                .first,
          );
          final footTop = save.top - ClaySpacing.medium;
          final before = await _pixels(tester);
          final handle = showClayToast(
            page.currentContext!,
            'Changes saved',
            duration: null,
          );
          await tester.pumpAndSettle();
          final toast = _toast(tester);
          expect(
            toast.bottom,
            lessThanOrEqualTo(footTop),
            reason: 'toast $toast, foot from $footTop',
          );
          final after = await _pixels(tester);
          expect(
            _changed(
              before,
              after,
              width.round(),
              footTop.round(),
              _height.round(),
            ),
            0,
            reason: "the toast's shadow reaches the foot (from $footTop)",
          );
          handle.dismiss();
          await tester.pumpAndSettle();
          expect(find.text('Changes saved'), findsNothing);
        });
      }
    }
  }

  testWidgets('with no foot, a toast stands at the screen foot', (
    tester,
  ) async {
    final page = await _page(
      tester,
      width: 390,
      brightness: Brightness.light,
      footer: false,
    );
    final handle = showClayToast(
      page.currentContext!,
      'Changes saved',
      duration: null,
    );
    await tester.pumpAndSettle();
    expect(_toast(tester).bottom, _height - ClaySpacing.large);
    handle.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsNothing);
  });
}
