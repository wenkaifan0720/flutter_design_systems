// The scoring sweep: every screen of a candidate app, under every condition
// a reader brings, through ui_core_test's checks; and the pictures a
// reviewer reads. A scorer copies this file into the candidate's test/
// folder and calls [sweepScreens] and [shootScreens] from a test (see
// README.md).

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show GlobalMaterialLocalizations, MaterialApp;
import 'package:ui_core/ui_core.dart' show RawInput, RawWidgetsLocalizations;
import 'package:ui_core_test/ui_core_test.dart';

/// Puts [child] under the app's design for [brightness], with whatever its
/// screens need above them: what the app puts in its `MaterialApp.builder`.
typedef DesignHost = Widget Function(
  BuildContext context,
  Widget child,
  Brightness brightness,
);

/// One reader's conditions.
class SweepCondition {
  /// A condition at [width], in [brightness], [direction] and [textScale].
  const SweepCondition(
    this.width,
    this.brightness,
    this.direction,
    this.textScale,
  );

  /// The screen's width in logical pixels.
  final double width;

  /// The screen's height: a phone's below 600 wide, a tablet's to 1200,
  /// else a desktop window's.
  double get height => width < 600
      ? 844
      : width < 1200
      ? 768
      : 900;

  /// Day or night.
  final Brightness brightness;

  /// Reading direction.
  final TextDirection direction;

  /// Text scale.
  final double textScale;

  /// Whether a finger reaches the screen (a phone's width).
  bool get touch => width < 600;

  @override
  String toString() =>
      '${width.round()} ${brightness.name} ${direction.name} ${textScale}x';
}

/// Every combination of [widths], day and night, left to right and right to
/// left, and 1x and 2x text.
List<SweepCondition> sweepConditions(List<double> widths) => [
  for (final width in widths)
    for (final brightness in Brightness.values)
      for (final direction in TextDirection.values)
        for (final textScale in [1.0, 2.0])
          SweepCondition(width, brightness, direction, textScale),
];

Widget _app(
  SweepCondition c,
  DesignHost host,
  WidgetBuilder screen, {
  Key? key,
}) => MaterialApp(
  key: key,
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: RawWidgetsLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: c.textScale,
    maxScaleFactor: c.textScale,
    child: Directionality(
      textDirection: c.direction,
      child: host(context, child!, c.brightness),
    ),
  ),
  home: Builder(builder: screen),
);

/// Pumps each of [screens] under each condition of [widths], under [host],
/// with the app's fonts loaded, and returns one line per problem found: a
/// layout exception (an overflow), or a ui_core_test check's finding. Empty
/// when every screen holds everywhere.
Future<List<String>> sweepScreens(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> screens,
  required DesignHost host,
  List<double> widths = const [390, 1024],
  String name = 'App',
}) async {
  final found = <String>[];
  final fonts = _Fonts(tester);
  addTearDown(tester.view.reset);
  await fonts.prime(screens, host);
  for (final condition in sweepConditions(widths)) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(condition.width, condition.height) * 2;
    for (final MapEntry(key: id, value: screen) in screens.entries) {
      final at = '$id at $condition';
      await tester.pumpWidget(_app(condition, host, screen, key: ValueKey(at)));
      await _settle(tester);
      final thrown = tester.takeException();
      if (thrown != null) {
        found.add('$at: threw ${'$thrown'.split('\n').first}');
        continue;
      }
      final context = tester.element(find.byType(Navigator).first);
      final reports = [
        DesignCheckableCheck(look: name).check(context),
        DesignTextFieldNameCheck(look: name).check(context),
        DesignFieldSemanticsCheck(look: name).check(context),
        DesignTapTargetCheck(
          look: name,
          input: condition.touch ? RawInput.touch : RawInput.pointer,
        ).check(context),
        if (!condition.touch) DesignCursorCheck(look: name).check(context),
        DesignOverflowCheck(look: name).check(context),
        DesignClipCheck(look: name).check(context),
        DesignWordBreakCheck(look: name).check(context),
      ];
      for (final report in reports) {
        found.addAll(report.problems.map((p) => '$at: $p'));
      }
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
  return found;
}

/// The conditions [shootScreens] draws each screen in: a phone by day, a
/// phone by night right to left at twice the text size, and the widest of
/// the app's widths by day and by night.
List<SweepCondition> shootConditions(List<double> widths) => [
  const SweepCondition(390, Brightness.light, TextDirection.ltr, 1),
  const SweepCondition(390, Brightness.dark, TextDirection.rtl, 2),
  if (widths.any((w) => w >= 600)) ...[
    SweepCondition(widths.reduce(_max), Brightness.light, TextDirection.ltr, 1),
    SweepCondition(widths.reduce(_max), Brightness.dark, TextDirection.ltr, 1),
  ],
];

double _max(double a, double b) => a > b ? a : b;

/// Draws each of [screens] for a reviewer, into [outDir] as PNG files at
/// twice their size: whole, in each of [shootConditions]; and on a phone by
/// day and by night after [tabs] presses of Tab, so the keyboard's focus
/// shows on a part. Returns the files written.
Future<List<String>> shootScreens(
  WidgetTester tester, {
  required Map<String, WidgetBuilder> screens,
  required DesignHost host,
  required String outDir,
  List<double> widths = const [390, 1024],
  int tabs = 3,
}) async {
  final written = <String>[];
  addTearDown(tester.view.reset);
  final fonts = _Fonts(tester);
  await fonts.prime(screens, host);
  Future<void> shoot(String path) async {
    final boundary =
        tester.renderObject(find.byKey(_frame)) as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    written.add(path);
  }

  for (final c in shootConditions(widths)) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(c.width, c.height);
    for (final MapEntry(key: id, value: screen) in screens.entries) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _frame,
          child: _app(c, host, screen, key: ValueKey('$id $c')),
        ),
      );
      await _settle(tester);
      tester.takeException();
      await shoot(
        '$outDir/${_file(id)}_${c.width.round()}_${c.brightness.name}_'
        '${c.direction.name}_${c.textScale}x.png',
      );
    }
  }
  for (final brightness in Brightness.values) {
    final c = SweepCondition(390, brightness, TextDirection.ltr, 1);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(c.width, c.height);
    for (final MapEntry(key: id, value: screen) in screens.entries) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _frame,
          child: _app(c, host, screen, key: ValueKey('focus $id $c')),
        ),
      );
      await _settle(tester);
      for (var i = 0; i < tabs; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await _settle(tester);
      tester.takeException();
      await shoot('$outDir/focus_${_file(id)}_${brightness.name}.png');
    }
  }
  await tester.pumpWidget(const SizedBox.shrink());
  return written;
}

const _frame = ValueKey('sweep frame');

String _file(String id) =>
    id.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');

/// Pumps until no frame is scheduled, or for three seconds of the test's
/// clock: an indeterminate progress indicator never settles, and is read
/// mid-turn.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Loads the fonts an app draws with, so checks measure and pictures show
/// its real type: every family in the app's font manifest, Roboto and
/// Material's icons from the Flutter SDK, and Roboto under any other family
/// [names] asks for.
Future<void> loadAppFonts(WidgetTester tester, [Set<String>? names]) async {
  final sdk = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts';
  Future<ByteData> file(String path) =>
      File(path).readAsBytes().then(ByteData.sublistView);
  final roboto = [
    for (final w in ['Thin', 'Light', 'Regular', 'Medium', 'Bold', 'Black'])
      '$sdk/material_fonts/Roboto-$w.ttf',
  ];
  await tester.runAsync(() async {
    final loaded = <String>{'Roboto', 'MaterialIcons'};
    try {
      final manifest = jsonDecode(
        await rootBundle.loadString('FontManifest.json'),
      ) as List<Object?>;
      for (final family in manifest.cast<Map<String, Object?>>()) {
        final name = family['family']! as String;
        final loader = FontLoader(name);
        for (final font
            in (family['fonts']! as List<Object?>)
                .cast<Map<String, Object?>>()) {
          loader.addFont(rootBundle.load(font['asset']! as String));
        }
        await loader.load();
        loaded.add(name);
      }
    } on FlutterError {
      // No manifest: the app bundles no fonts.
    }
    final robotoLoader = FontLoader('Roboto');
    for (final f in roboto) {
      robotoLoader.addFont(file(f));
    }
    await robotoLoader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(file('$sdk/material_fonts/MaterialIcons-Regular.otf'))).load();
    for (final name in {...?names}.difference(loaded)) {
      final alias = FontLoader(name);
      for (final f in roboto) {
        alias.addFont(file(f));
      }
      await alias.load();
    }
  });
}

/// The font families the paragraphs under [context] ask for.
Set<String> appFamilies(BuildContext context) {
  final names = <String>{};
  void visit(RenderObject node) {
    if (node is RenderParagraph) {
      node.text.visitChildren((span) {
        final family = span.style?.fontFamily;
        if (family != null) names.add(family);
        return true;
      });
    }
    node.visitChildren(visit);
  }

  final root = context.findRenderObject();
  if (root != null) visit(root);
  return names;
}

class _Fonts {
  _Fonts(this.tester);

  final WidgetTester tester;

  /// Pumps each screen once and loads every family it asks for, before any
  /// screen is measured or drawn: a part that measures its words as it
  /// builds keeps the test font's measure.
  Future<void> prime(
    Map<String, WidgetBuilder> screens,
    DesignHost host,
  ) async {
    final names = <String>{};
    const c = SweepCondition(390, Brightness.light, TextDirection.ltr, 1);
    for (final screen in screens.values) {
      await tester.pumpWidget(_app(c, host, screen));
      await _settle(tester);
      tester.takeException();
      names.addAll(appFamilies(tester.element(find.byType(Navigator).first)));
    }
    await tester.pumpWidget(const SizedBox.shrink());
    tester.takeException();
    await loadAppFonts(tester, names);
  }
}
