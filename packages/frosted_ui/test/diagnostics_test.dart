// The description every public part gives of itself in the inspector and in
// a failing test's tree: each field it is built with, a field at its default
// hidden. And the ranges the parts hold their values to (ui_core's template).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The widget classes of the package's public libraries, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

List<String> _description(Diagnosticable part) => [
  for (final p in part.toDiagnosticsNode().getProperties())
    if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
];

void _changed(Object? _) {}

void main() {
  test('every public widget describes every public field it is built with', () {
    final lib = Directory('lib');
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

  test('a part says what it is built with and hides its defaults', () {
    expect(
      _description(
        const FrostedSlider(
          value: .5,
          onChanged: _changed,
          label: 'Volume',
          divisions: 4,
        ),
      ),
      ['value: 0.5', 'has onChanged', 'label: "Volume"', 'divisions: 4'],
    );
    expect(
      _description(
        const FrostedSlider(
          value: 3,
          onChanged: null,
          label: 'Volume',
          min: 1,
          max: 5,
          autofocus: true,
        ),
      ),
      ['value: 3.0', 'autofocus', 'label: "Volume"', 'min: 1.0', 'max: 5.0'],
    );
    expect(
      _description(const FrostedButton('Save', onPressed: null)),
      contains('label: "Save"'),
    );
    expect(
      _description(
        FrostedTheme(data: FrostedThemeData.opal(), child: const SizedBox()),
      ),
      [startsWith('data: ')],
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a slider past its max': () =>
          FrostedSlider(value: 2, onChanged: null, label: 'Volume'),
      'a slider whose max is its min': () =>
          FrostedSlider(value: 0, min: 0, max: 0, onChanged: null, label: 'V'),
      'a slider of no divisions': () => FrostedSlider(
        value: .5,
        divisions: 0,
        onChanged: null,
        label: 'Volume',
      ),
      'a range slider whose max passes its min': () => FrostedRangeSlider(
        values: const RawRangeValues(.2, .4),
        min: 1,
        max: 0,
        onChanged: null,
      ),
      'a rating past its max': () =>
          FrostedRating(value: 6, label: 'Your rating'),
      'a progress bar past full': () =>
          FrostedLinearProgressIndicator(label: 'Upload', value: 1.5),
      'a number field below its min': () => FrostedNumberField(
        value: -10,
        onChanged: _changed,
        labelText: 'the budget',
      ),
      'a number field of no step': () => FrostedNumberField(
        value: 10,
        step: 0,
        onChanged: _changed,
        labelText: 'the budget',
      ),
      'a page past the last': () =>
          FrostedPagination(pageCount: 3, selectedIndex: 3),
      'page dots past the last': () =>
          FrostedPageDots(pageCount: 4, selectedIndex: 4, label: 'Welcome'),
      'a pane share past whole': () => FrostedResizable(
        first: const SizedBox(),
        second: const SizedBox(),
        initialFraction: 1.2,
      ),
      'a code of no digits': () => FrostedInputOtp(length: 0),
      'a badge counting below zero': () => FrostedBadge(-1),
      'a skeleton of no lines': () => FrostedSkeleton.text(lines: 0),
      'a meter filled below empty': () =>
          FrostedMeter(-.1, hue: FrostedThemeData.opal().hues.azure),
    };
    for (final MapEntry(key: name, value: make) in cases.entries) {
      test(name, () => expect(make, throwsAssertionError));
    }
  });
}
