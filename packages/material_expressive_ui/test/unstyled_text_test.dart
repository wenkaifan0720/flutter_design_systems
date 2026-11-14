// No text ever falls back to Flutter's debug style: the red, double yellow
// underlined face MaterialApp gives a paragraph nothing else styles, or the
// unsized engine default under a bare WidgetsApp. Every overlay is opened
// under a WidgetsApp that mounts only the package's theme: with no app text
// style and with MaterialApp's error style, the theme once in the app's
// builder and once inside the first route. Every page of the example is
// scanned, and the example app's own chrome and menus.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_support.dart';
import 'overlay_fixtures.dart';

/// The style MaterialApp hands WidgetsApp for text nothing else styles.
const materialErrorTextStyle = TextStyle(
  color: Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48,
  fontWeight: FontWeight.w900,
  decoration: TextDecoration.underline,
  decorationColor: Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double,
);

/// Flutter's fallback: the double yellow underline, or no size at all (no
/// DefaultTextStyle above, so the engine's default face).
bool isFallbackStyle(TextStyle style) =>
    style.fontSize == null ||
    (style.decorationStyle == TextDecorationStyle.double &&
        style.decorationColor == const Color(0xFFFFFF00) &&
        (style.decoration?.contains(TextDecoration.underline) ?? false));

String _owner(Element element) {
  var owner = element.widget.runtimeType.toString();
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString();
    if (name.startsWith('Expressive') || name.startsWith('Kit')) {
      owner = name;
      return false;
    }
    return true;
  });
  return owner;
}

/// Every painted run of words, on stage or off, whose style is the fallback.
List<String> fallbackText(WidgetTester tester) {
  final failures = <String>[];
  for (final element in find.byType(RichText, skipOffstage: false).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    void walk(InlineSpan span, TextStyle parent) {
      final style = span.style == null ? parent : parent.merge(span.style);
      if (span is TextSpan) {
        final words = span.text ?? '';
        if (words.trim().isNotEmpty && isFallbackStyle(style)) {
          failures.add('${_owner(element)}: "$words"');
        }
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child, style);
        }
      }
    }

    walk(paragraph.text, const TextStyle());
  }
  for (final element
      in find.byType(EditableText, skipOffstage: false).evaluate()) {
    final field = element.widget as EditableText;
    if (isFallbackStyle(field.style)) {
      failures.add('${_owner(element)}: field "${field.controller.text}"');
    }
  }
  return failures;
}

void expectNoFallbackText(WidgetTester tester, String where) {
  final failures = fallbackText(tester);
  expect(failures, isEmpty, reason: '$where\n${failures.join('\n')}');
}

enum _Mount { builder, home }

enum _Ground { bare, materialError }

final _theme = ExpressiveThemeData.preset('baseline', Brightness.light);

/// A WidgetsApp with no Material and only the theme; on [_Ground.bare] no
/// text style at all, on [_Ground.materialError] MaterialApp's error style.
Widget _bare(
  _Mount mount,
  WidgetBuilder home, {
  _Ground ground = _Ground.materialError,
  ExpressiveThemeData? theme,
}) {
  final data = theme ?? _theme;
  Widget themed(Widget child) => ExpressiveTheme(data: data, child: child);
  return WidgetsApp(
    color: data.colors.primary,
    textStyle: ground == _Ground.materialError ? materialErrorTextStyle : null,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
    builder: mount == _Mount.builder
        ? (context, child) => themed(child!)
        : null,
    home: mount == _Mount.home
        ? themed(Builder(builder: home))
        : Builder(builder: home),
  );
}

Future<void> _open(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadExpressiveFonts);
  tearDown(() {
    kitShownTheme = null;
    kitShownPreset = 'baseline';
  });

  testWidgets('the check finds the fallback where nothing sets a style', (
    tester,
  ) async {
    for (final ground in _Ground.values) {
      await tester.pumpWidget(
        WidgetsApp(
          key: ValueKey(ground),
          color: const Color(0xFF000000),
          textStyle: ground == _Ground.materialError
              ? materialErrorTextStyle
              : null,
          builder: (context, _) => const Text('Unstyled'),
        ),
      );
      expect(fallbackText(tester), [
        contains('"Unstyled"'),
      ], reason: ground.name);
    }
  });

  for (final ground in _Ground.values) {
    for (final mount in _Mount.values) {
      group('${ground.name} ground, theme in the app ${mount.name}', () {
        for (final MapEntry(key: name, value: open) in overlayRoutes.entries) {
          testWidgets('$name text is styled', (tester) async {
            tester.view.physicalSize = const Size(412, 915);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _bare(
                ground: ground,
                mount,
                (context) => Center(
                  child: GestureDetector(
                    key: const ValueKey('open'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => open(context),
                    child: const SizedBox.square(dimension: 48),
                  ),
                ),
              ),
            );
            await tester.tap(find.byKey(const ValueKey('open')));
            await _open(tester);
            expect(tester.takeException(), isNull);
            expectNoFallbackText(tester, '$name, theme in ${mount.name}');
          });
        }

        for (final MapEntry(key: name, value: (widget, raise))
            in raisedOverlays.entries) {
          testWidgets('$name text is styled', (tester) async {
            tester.view.physicalSize = const Size(412, 915);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _bare(
                ground: ground,
                mount,
                (context) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: SizedBox(width: 280, child: widget),
                  ),
                ),
              ),
            );
            await _open(tester);
            expectNoFallbackText(tester, '$name at rest');
            await raise(tester);
            await _open(tester);
            expect(tester.takeException(), isNull);
            expectNoFallbackText(tester, '$name, theme in ${mount.name}');
          });
        }
      });
    }
  }

  testWidgets('every example page is styled under a bare WidgetsApp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final failures = <String>[];
    for (final page in galleryExamplePages) {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('${page.id}/${brightness.name}'),
            child: _bare(
              _Mount.builder,
              (_) => galleryBuildPage(page, brightness),
              theme: ExpressiveThemeData.preset('baseline', brightness),
            ),
          ),
        );
        await settle(tester);
        tester.takeException();
        failures.addAll([
          for (final f in fallbackText(tester))
            '${page.id}/${brightness.name}: $f',
        ]);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets('the example app chrome and its open menus are styled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    expectNoFallbackText(tester, 'example at rest');
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is ExpressiveIconButton &&
            widget.semanticLabel == 'Customize',
      ),
    );
    await settle(tester);
    expectNoFallbackText(tester, 'example with Customize open');
    final select = find.ancestor(
      of: find.text('Preset'),
      matching: find.byType(ExpressiveSelect<String>),
    );
    await tester.tap(select.first);
    await settle(tester);
    expectNoFallbackText(tester, 'example with the Preset menu open');
    await tester.tapAt(const Offset(1400, 980));
    await settle(tester);
    // On a phone: the drawer.
    tester.view.physicalSize = const Size(390, 844);
    await settle(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is ExpressiveIconButton &&
            widget.semanticLabel == 'Open navigation',
      ),
    );
    await settle(tester);
    expectNoFallbackText(tester, 'example with the drawer open');
  });
}
