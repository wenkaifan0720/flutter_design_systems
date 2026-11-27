import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// Minimal's standard preset by day.
final MinimalThemeData dayTheme = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

/// Minimal's standard preset by night.
final MinimalThemeData nightTheme = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

/// [child] on a full-bleed page [width] wide at [scale].
Widget scaledPage(Widget child, {double width = 390, double scale = 1}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: dayTheme,
        dark: nightTheme,
        brightness: Brightness.light,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: navigator!,
        ),
      ),
      home: MinimalScaffold(
        padding: EdgeInsets.zero,
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

/// The view [size] at one device pixel a logical pixel, for this test.
void setViewSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A callback that does nothing, for a control that must be live.
void doNothing() {}
