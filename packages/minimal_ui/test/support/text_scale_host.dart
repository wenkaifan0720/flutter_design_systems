import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// [child] on a page that scrolls, 18 px in, at text scale [scale], under a
/// MinimalHost that stands above the Navigator, as an app mounts it, so
/// overlays read the same tokens as the page.
Widget textScaleHost(Widget child, {double scale = 1}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ),
    ),
  ),
);

/// Where [text]'s first letter starts on the screen, whatever the width of
/// the box it is set in.
double startOf(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return p.localToGlobal(Offset(boxes.first.left, 0)).dx;
}
