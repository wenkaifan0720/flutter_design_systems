// The scoring sweep: every part a look's inventory carries, alone on a
// screen, under every condition a reader brings, through ui_core_test's
// checks; and the pictures a reviewer reads. A scorer copies this file into
// the candidate's example/test/ folder and calls [sweepInventory] and
// [shootInventory] from a test (see README.md).

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core/inventory.dart';
import 'package:ui_core/ui_core.dart' show DesignInput, RawWidgetsLocalizations;
import 'package:ui_core_test/ui_core_test.dart';

/// Puts [child] under the look's theme for [brightness]: what the
/// candidate's app puts in `MaterialApp.builder`.
typedef LookHost = Widget Function(
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

  /// The screen's width in logical pixels (the height is 900).
  final double width;

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

/// Every combination of 390 and 1440 wide, day and night, left to right and
/// right to left, and 1x and 2x text.
final List<SweepCondition> sweepConditions = [
  for (final width in [390.0, 1440.0])
    for (final brightness in Brightness.values)
      for (final direction in TextDirection.values)
        for (final textScale in [1.0, 2.0])
          SweepCondition(width, brightness, direction, textScale),
];

/// Pumps each present entry of [inventory] alone under each of [conditions],
/// under [host], with the look's fonts loaded, and returns one line per
/// problem found: a layout exception (an overflow), or a ui_core_test check's
/// finding. Empty when every part holds everywhere.
Future<List<String>> sweepInventory(
  WidgetTester tester, {
  required DesignInventory inventory,
  required LookHost host,
  List<SweepCondition>? conditions,
}) async {
  final look = inventory.look;
  final found = <String>[];
  final fonts = _Fonts(tester);
  addTearDown(tester.view.reset);
  for (final condition in conditions ?? sweepConditions) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(condition.width, 900) * 2;
    for (final entry in inventory.entries.where((e) => e.isPresent)) {
      final at = '${entry.row} at $condition';
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(at),
          localizationsDelegates: const [RawWidgetsLocalizations.delegate],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: condition.textScale,
            maxScaleFactor: condition.textScale,
            child: Directionality(
              textDirection: condition.direction,
              child: host(context, child!, condition.brightness),
            ),
          ),
          home: Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              key: key,
              padding: const EdgeInsets.all(24),
              child: Builder(builder: entry.builder!),
            ),
          ),
        ),
      );
      await _settle(tester);
      if (await fonts.under(key.currentContext!)) {
        await tester.pump();
        await _settle(tester);
      }
      final thrown = tester.takeException();
      if (thrown != null) {
        found.add('$at: threw ${'$thrown'.split('\n').first}');
        continue;
      }
      final screen = key.currentContext!;
      final reports = [
        DesignCheckableCheck(look: look).check(screen),
        DesignTextFieldNameCheck(look: look).check(screen),
        DesignFieldSemanticsCheck(look: look).check(screen),
        DesignTapTargetCheck(
          look: look,
          input: condition.touch ? DesignInput.touch : DesignInput.pointer,
        ).check(screen),
        if (!condition.touch) DesignCursorCheck(look: look).check(screen),
        DesignClipCheck(look: look).check(screen),
        DesignWordBreakCheck(look: look).check(screen),
      ];
      for (final report in reports) {
        found.addAll(report.problems.map((p) => '$at: $p'));
      }
    }
  }
  return found;
}

/// The conditions [shootInventory] draws the gallery in: a phone by day, a
/// phone by night right to left at twice the text size, and a desk by day
/// and by night.
final List<SweepCondition> shootConditions = [
  const SweepCondition(390, Brightness.light, TextDirection.ltr, 1),
  const SweepCondition(390, Brightness.dark, TextDirection.rtl, 2),
  const SweepCondition(1440, Brightness.light, TextDirection.ltr, 1),
  const SweepCondition(1440, Brightness.dark, TextDirection.ltr, 1),
];

/// Pumps until no frame is scheduled, or for three seconds of the test's
/// clock: an indeterminate progress indicator never settles, and is read
/// mid-turn.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Loads the fonts a look draws with, so checks measure and pictures show its
/// real type: every family in the app's font manifest, Roboto and Material's
/// icons from the Flutter SDK, and Roboto under any other family [names] asks
/// for.
Future<void> loadLookFonts(WidgetTester tester, [Set<String>? names]) async {
  final sdk = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts';
  Future<ByteData> file(String path) =>
      File(path).readAsBytes().then(ByteData.sublistView);
  final roboto = [
    for (final w in ['Regular', 'Medium', 'Bold'])
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
Set<String> lookFamilies(BuildContext context) {
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

/// The fonts loaded so far in one test.
class _Fonts {
  _Fonts(this.tester);

  final WidgetTester tester;
  Set<String>? _loaded;

  /// Loads what the paragraphs under [context] ask for, if any of it is new;
  /// true when it loaded (the screen then needs another frame).
  Future<bool> under(BuildContext context) async {
    final names = lookFamilies(context);
    final loaded = _loaded;
    if (loaded != null && names.difference(loaded).isEmpty) return false;
    _loaded = {...?loaded, ...names};
    await loadLookFonts(tester, _loaded);
    return true;
  }
}

Future<void> _savePng(
  WidgetTester tester,
  GlobalKey key,
  String path,
  double ratio,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Draws the look's present parts for a reviewer, into [outDir] as PNG files
/// at twice their size: a gallery of [perPage] parts a page, each under its
/// row id, in each of [conditions]; and each part alone after one Tab press
/// (keyboard focus on its first stop), at 1440 wide by day and by night.
/// Returns the files written.
Future<List<String>> shootInventory(
  WidgetTester tester, {
  required DesignInventory inventory,
  required LookHost host,
  required String outDir,
  List<SweepCondition>? conditions,
  int perPage = 8,
}) async {
  final written = <String>[];
  final present = inventory.entries.where((e) => e.isPresent).toList();
  addTearDown(tester.view.reset);
  Widget app(SweepCondition c, Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [RawWidgetsLocalizations.delegate],
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: c.textScale,
      maxScaleFactor: c.textScale,
      child: Directionality(
        textDirection: c.direction,
        child: host(context, child!, c.brightness),
      ),
    ),
    home: home,
  );
  const caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11,
    color: Color(0xFF888888),
  );
  final fonts = _Fonts(tester);

  for (final c in conditions ?? shootConditions) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(c.width, 6000);
    for (var page = 0; page * perPage < present.length; page++) {
      final key = GlobalKey();
      final entries = present.skip(page * perPage).take(perPage);
      Widget sheet() => Align(
        alignment: AlignmentDirectional.topStart,
        child: RepaintBoundary(
          key: key,
          child: Builder(
            builder: (context) => ColoredBox(
              color: c.brightness == Brightness.dark
                  ? const Color(0xFF000000)
                  : const Color(0xFFFFFFFF),
              child: SizedBox(
                width: c.width,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in entries) ...[
                        Text(e.row, style: caption),
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Builder(builder: e.builder!),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(c, sheet()));
      await _settle(tester);
      if (await fonts.under(key.currentContext!)) {
        await tester.pump();
        await _settle(tester);
      }
      tester.takeException();
      final path =
          '$outDir/gallery_${c.width.round()}_${c.brightness.name}_'
          '${c.direction.name}_${c.textScale}x_p${page + 1}.png';
      await _savePng(tester, key, path, 2);
      written.add(path);
    }
  }

  for (final brightness in Brightness.values) {
    final c = SweepCondition(1440, brightness, TextDirection.ltr, 1);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    for (final e in present) {
      final key = GlobalKey();
      final before = FocusNode();
      await tester.pumpWidget(
        app(
          c,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Focus(focusNode: before, child: const SizedBox(height: 1)),
                RepaintBoundary(
                  key: key,
                  child: ColoredBox(
                    color: brightness == Brightness.dark
                        ? const Color(0xFF000000)
                        : const Color(0xFFFFFFFF),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Builder(builder: e.builder!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await _settle(tester);
      if (await fonts.under(key.currentContext!)) await tester.pump();
      before.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _settle(tester);
      tester.takeException();
      final path = '$outDir/focus_${brightness.name}_${e.row}.png';
      await _savePng(tester, key, path, 2);
      written.add(path);
      await tester.pumpWidget(const SizedBox.shrink());
      before.dispose();
    }
  }
  return written;
}
