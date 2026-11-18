// The description every public part gives of itself in the inspector and
// in a failing test's tree: each field it is built with, a field at its
// default hidden (ui_core 0.2.0's template). And the values a part cannot
// take, refused by an assert where they are made.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// The look's own source: under design_system/ in drip, under src/ in the
// published package.
Directory _look() => [
  Directory('lib/src/material_expressive'),
  Directory('lib/src/material_expressive'),
].firstWhere((d) => d.existsSync());

// The widget classes of the look's public libraries, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

// A number made at run time: a constant out of range trips the assert when
// the test compiles, not when it runs.
double _n(double value) => value;
int _i(int value) => value;

const Widget _box = SizedBox();

void main() {
  test('every public widget describes every public field it is built with', () {
    final missing = <String>[];
    var widgets = 0;
    for (final file in _look().listSync(recursive: true).whereType<File>()) {
      // Not internal/, and not the kit parts (kit_parts/), which the catalog
      // lays beside the look in its compositions only and kit-parts/test
      // covers.
      if (!file.path.endsWith('.dart') ||
          file.path.contains('/internal/') ||
          file.path.contains('/kit_parts/')) {
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
    expect(widgets, greaterThan(100));
    expect(missing, isEmpty, reason: 'fields left out of debugFillProperties');
  });

  test('a button says what it is and hides its defaults', () {
    expect(_description(ExpressiveFilledButton('Save', onPressed: () {})), [
      'kind: filled',
      'label: "Save"',
      'has onPressed',
    ]);
  });

  test('a slider says each field set off its default', () {
    expect(
      _description(
        ExpressiveSlider(
          value: .5,
          onChanged: (_) {},
          max: 2,
          steps: 4,
          centered: true,
          semanticLabel: 'Volume',
          autofocus: true,
        ),
      ),
      [
        'value: 0.5',
        'has onChanged',
        'max: 2.0',
        'steps: 4',
        'centered',
        'semanticLabel: "Volume"',
        'autofocus',
      ],
    );
  });

  test('the style classes name each of their fields', () {
    const red = Color(0xFFFF0000);
    final styles = <Diagnosticable, List<String>>{
      const ExpressiveCardColors(
        container: red,
        content: red,
        disabledContainer: red,
        disabledContent: red,
      ): [
        'container',
        'content',
        'disabledContainer',
        'disabledContent',
        'outline',
        'disabledOutline',
      ],
      const ExpressiveToggleButtonColors(): [
        'container',
        'content',
        'checkedContainer',
        'checkedContent',
      ],
      const ExpressivePressShapes(shape: StadiumBorder()): [
        'shape',
        'pressed',
        'selected',
        'focused',
        'hovered',
      ],
      ExpressiveStateLayers.tokens: [
        'hoverOpacity',
        'focusOpacity',
        'pressedOpacity',
        'draggedOpacity',
      ],
    };
    for (final MapEntry(key: style, value: fields) in styles.entries) {
      expect(
        [for (final p in style.toDiagnosticsNode().getProperties()) p.name],
        fields,
        reason: '${style.runtimeType}',
      );
    }
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a slider past its max': () =>
          ExpressiveSlider(value: _n(2), onChanged: null),
      'a slider below its min': () =>
          ExpressiveVerticalSlider(value: _n(-1), onChanged: null),
      'a slider whose min passes its max': () =>
          ExpressiveSlider(value: .5, min: _n(1), max: 0, onChanged: null),
      'a range whose start passes its end': () =>
          ExpressiveRangeSlider(start: _n(.8), end: .2, onChanged: null),
      'a range past its max': () =>
          ExpressiveRangeSlider(start: .2, end: _n(1.5), onChanged: null),
      'a navigation bar before its first destination': () =>
          ExpressiveNavigationBar(
            destinations: const [],
            selectedIndex: _i(-1),
            onDestinationSelected: (_) {},
          ),
      'a tab bar before its first tab': () => ExpressiveTabBar(
        tabs: const [],
        selectedIndex: _i(-1),
        onChanged: (_) {},
      ),
      'a timeline before its first step': () =>
          ExpressiveTimeline(entries: const [], currentStep: _i(-1)),
      'a split past its end': () => ExpressiveResizable(
        first: _box,
        second: _box,
        initialFraction: _n(1.5),
      ),
      'a pane of less than no room': () =>
          ExpressiveResizable(first: _box, second: _box, minFirst: _n(-1)),
      'a multi-select that takes no values': () =>
          ExpressiveMultiSelect<String>(
            options: const [],
            values: const [],
            onChanged: (_) {},
            maxValues: _i(0),
          ),
      'a chart range upside down': () => ExpressiveChartDomain.fixed(_n(10), 0),
      'a chart step of nothing': () => ExpressiveChartDomain.data(step: _n(0)),
      'a rating past its max': () => ExpressiveRating(value: _n(6)),
      'page dots past their count': () =>
          ExpressivePageDots(count: 2, selectedIndex: _i(2)),
      'a step progress past its last step': () =>
          ExpressiveStepProgress(count: 3, currentStep: _i(4)),
      'a pagination before its first page': () =>
          ExpressivePagination(page: _i(0), count: 3, onChanged: (_) {}),
      'a breadcrumb that shows too few': () =>
          ExpressiveBreadcrumb(items: const [], maxShown: _i(2)),
    };
    for (final MapEntry(key: what, value: build) in cases.entries) {
      test(what, () => expect(build, throwsAssertionError));
    }
  });
}

List<String> _description(Diagnosticable part) {
  return [
    for (final p in part.toDiagnosticsNode().getProperties())
      if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
  ];
}
