// Widgets expose their constructor properties in the inspector, hide default
// values, and reject parameters outside their supported ranges.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

/// Directory containing the widget implementations.
final String _lib = Directory('lib/src/fluent2_design').existsSync()
    ? 'lib/src/fluent2_design'
    : 'lib/src/fluent2_design';

// The widget classes of the lib, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

/// What [part] says of itself at the inspector's usual level.
List<String> _description(Widget part) {
  final builder = DiagnosticPropertiesBuilder();
  part.debugFillProperties(builder);
  return [
    for (final p in builder.properties)
      if (!p.isFiltered(DiagnosticLevel.info)) p.toString(),
  ];
}

// A number the analyzer cannot fold, so an out-of-range case is built at run
// time and asserts there.
double _d(double value) => value;
int _i(int value) => value;

void main() {
  test('every public widget describes every public field it is built with', () {
    final missing = <String>[];
    var widgets = 0;
    for (final file in Directory(
      _lib,
    ).listSync(recursive: true).whereType<File>()) {
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
          if (RegExp(r'^(Widget\??|List<Widget>)$').hasMatch(f.group(1)!)) {
            continue;
          }
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

  test('a part built with what it requires says that alone', () {
    expect(_description(const Fluent2Avatar(name: 'Ines Duarte')), [
      'name: "Ines Duarte"',
    ]);
    expect(
      _description(const Fluent2ProgressBar(value: .62, label: 'Uploading')),
      ['value: 0.6', 'label: "Uploading"'],
    );
  });

  test('a part says each field set off its default', () {
    expect(
      _description(
        Fluent2Slider(
          value: 30,
          onChanged: (_) {},
          label: 'Volume',
          step: 10,
          autofocus: true,
        ),
      ),
      unorderedEquals([
        'value: 30.0',
        'has onChanged',
        'label: "Volume"',
        'step: 10.0',
        'autofocus',
      ]),
    );
    expect(
      _description(
        const Fluent2Avatar(
          name: 'Ines Duarte',
          size: 48,
          color: Fluent2AvatarColor.colorful,
          presence: Fluent2Presence.busy,
        ),
      ),
      [
        'name: "Ines Duarte"',
        'size: 48.0',
        'color: colorful',
        'presence: busy',
      ],
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'page dots past their count': () => Fluent2PageDots(
        count: 3,
        selectedIndex: 3,
        label: 'Photos',
        onChanged: (_) {},
      ),
      'a rating past its max': () =>
          Fluent2Rating(value: 6, onChanged: (_) {}, label: 'Rate'),
      'a rating shown below none': () => Fluent2RatingDisplay(value: _d(-1)),
      'progress past its max': () => Fluent2ProgressBar(value: _d(1.5)),
      'a slider of no step': () =>
          Fluent2Slider(value: 5, onChanged: (_) {}, label: 'Volume', step: 0),
      'a slider whose min passes its max': () => Fluent2Slider(
        value: 5,
        onChanged: (_) {},
        label: 'Volume',
        min: 10,
        max: 0,
      ),
      'a negative count': () => Fluent2Badge(_i(-1)),
      'a group of no faces': () =>
          Fluent2AvatarGroup(people: const [], max: _i(0)),
      'a negative segment': () => Fluent2SegmentBarPart('Photos', _d(-2)),
      'a spinner past done': () => Fluent2Spinner(value: _d(1.5)),
      'a placeholder of no size': () => Fluent2SkeletonItem(size: _d(0)),
      'a density past its range': () =>
          Fluent2Density(horizontal: _d(5), vertical: 0),
      'a page past the last': () =>
          Fluent2Pagination(page: _i(13), pages: 12, onChanged: (_) {}),
      'a time at 25 o\'clock': () => Fluent2Time(_i(25), 0),
    };
    for (final MapEntry(key: what, value: build) in cases.entries) {
      test(what, () => expect(build, throwsAssertionError));
    }
  });
}
