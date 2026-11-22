// The description every public part of the look gives of itself in the inspector and in a failing test's tree: each
// field it is built with, a field at its default hidden. And a value out of its range asserts where the part is made.
// The source scan is the same as ui_core's own.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// The widget classes of the package's public libraries, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

List<String> _description(Widget part) {
  final builder = DiagnosticPropertiesBuilder();
  part.debugFillProperties(builder);
  return [
    for (final p in builder.properties)
      if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
  ];
}

void main() {
  test('every public widget describes every public field it is built with', () {
    // The look's source folder (whose lib holds other modules' parts too), or the package's lib once exported.
    final look = Directory('lib/src/neumorphism');
    final lib = look.existsSync() ? look : Directory('lib');
    final missing = <String>[];
    var widgets = 0;
    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('/internal/')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final m in RegExp(
        r'^(?:abstract |final |base )*class ([A-Z]\w*)[^{]*?'
        r'\b(?:extends|with|implements)\b([^{]*)\{',
        multiLine: true,
      ).allMatches(source)) {
        if (!_widgetSupers.hasMatch(m.group(2)!)) continue;
        final end = source.indexOf('\n}\n', m.end);
        final body = source.substring(m.end, end < 0 ? source.length : end);
        final lines = body.split('\n');
        final fields = <String>[];
        for (var i = 0; i < lines.length; i++) {
          final f = RegExp(r'^  final (.+) (\w+);$').firstMatch(lines[i]);
          if (f == null || f.group(2)!.startsWith('_')) continue;
          if (i > 0 && lines[i - 1].trim().startsWith('@Deprecated')) continue;
          final type = f.group(1)!;
          if (RegExp(r'^(Widget\??|List<Widget>)$').hasMatch(type)) continue;
          fields.add(f.group(2)!);
        }
        if (fields.isEmpty) continue;
        widgets++;
        for (final field in fields) {
          if (!body.contains("'$field'")) missing.add('${m.group(1)}.$field');
        }
      }
    }
    expect(widgets, greaterThan(150));
    expect(missing, isEmpty, reason: 'fields left out of debugFillProperties');
  });

  test('a part says the fields set off their defaults, and only those', () {
    expect(_description(const NeumorphicLed()), isEmpty);
    expect(_description(const NeumorphicLed(size: 12)), ['size: 12.0']);
    expect(
      _description(
        NeumorphicRoundButton(
          NeumorphicGlyphs.close,
          label: 'Close',
          onPressed: () {},
        ),
      ),
      unorderedEquals([
        'icon: IconData(U+${NeumorphicGlyphs.close.codePoint.toRadixString(16).toUpperCase().padLeft(5, '0')})',
        'label: "Close"',
        'has onPressed',
      ]),
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a led of no size': () => NeumorphicLed(size: 0),
      'a round key of no size': () =>
          NeumorphicRoundButton(NeumorphicGlyphs.close, size: -4),
      'progress past its end': () => NeumorphicProgress(value: 1.5),
      'a thirteenth month': () => NeumorphicMonth(year: 2026, month: 13),
      'a gauge whose min passes its max': () =>
          NeumorphicGauge(value: 5, min: 10, max: 0, figure: '5', name: 'Hum'),
      'a text area of no lines': () => NeumorphicTextArea(lines: 0),
      'a grid of no columns': () =>
          NeumorphicGridOf(columns: 0, children: const []),
      'a split past its whole': () => NeumorphicResizable(
        first: const SizedBox(),
        second: const SizedBox(),
        initialFraction: 1.2,
      ),
      'a negative gap': () => NeumorphicCard(gap: -1, children: const []),
    };
    for (final MapEntry(key: what, value: build) in cases.entries) {
      test(what, () => expect(build, throwsAssertionError));
    }
  });

  testWidgets('the theme outside a NeumorphicTheme is the default, '
      'and maybeOf says there is none', (tester) async {
    late NeumorphicThemeData theme;
    NeumorphicThemeData? maybe;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          theme = NeumorphicTheme.of(context);
          maybe = NeumorphicTheme.maybeOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(maybe, isNull);
    expect(theme.colors.ground, NeumorphicThemeData.porcelain().colors.ground);
    expect(tester.takeException(), isNull);
  });
}
