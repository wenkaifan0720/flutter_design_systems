// The description every public part gives of itself in the inspector and in a failing test's tree: each field it is
// built with, a field at its default hidden (ui_core's diagnostics test, for the look). And a value out of its range
// asserts.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// The widget classes of the look's public libraries, read from its source.
final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget)\b',
);

// The look's lib: an app that vendors it lays it under design_system/platinum/, the package under src/retro_desktop/.
Directory get _lib => [
  Directory('lib/src/retro_desktop'),
  Directory('lib/src/retro_desktop'),
].firstWhere((d) => d.existsSync());

// The (type, name) pairs a `  final T a, b;` line declares.
List<(String, String)> _declared(String line) {
  final m = RegExp(r'^  final ([^=]+);$').firstMatch(line);
  if (m == null) return const [];
  final parts = <String>[];
  var depth = 0;
  var current = StringBuffer();
  for (final ch in m.group(1)!.split('')) {
    if ('(<[{'.contains(ch)) depth++;
    if (')>]}'.contains(ch)) depth--;
    if (ch == ',' && depth == 0) {
      parts.add(current.toString().trim());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  parts.add(current.toString().trim());
  final first = parts.first;
  final space = first.lastIndexOf(' ');
  if (space < 0) return const [];
  final type = first.substring(0, space).trim();
  final names = [first.substring(space + 1), ...parts.skip(1)];
  if (!names.every(RegExp(r'^\w+$').hasMatch)) return const [];
  return [for (final name in names) (type, name)];
}

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
    final missing = <String>[];
    var widgets = 0;
    for (final file in _lib.listSync(recursive: true).whereType<File>()) {
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
          if (i > 0 && lines[i - 1].trim().startsWith('@Deprecated')) continue;
          for (final (type, name) in _declared(lines[i])) {
            if (name.startsWith('_')) continue;
            if (RegExp(r'^(Widget\??|List<Widget>)$').hasMatch(type)) continue;
            fields.add(name);
          }
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

  test('a button says what it is built with and hides its defaults', () {
    expect(_description(RetroDesktopButton('Save', onPressed: () {})), [
      'label: "Save"',
      'has onPressed',
    ]);
    expect(
      _description(
        RetroDesktopButton(
          'Delete',
          onPressed: () {},
          isDestructiveAction: true,
          wide: true,
        ),
      ),
      ['label: "Delete"', 'has onPressed', 'isDestructiveAction', 'wide'],
    );
  });

  test('a slider says its value and range set off their defaults', () {
    expect(
      _description(
        RetroDesktopSlider(
          label: 'Volume',
          value: 4,
          max: 10,
          divisions: 10,
          onChanged: (_) {},
        ),
      ),
      [
        'label: "Volume"',
        'value: 4.0',
        'max: 10.0',
        'divisions: 10',
        'has onChanged',
      ],
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a slider past its max': () =>
          RetroDesktopSlider(label: 'Volume', value: 2),
      'a tab bar before its first tab': () =>
          RetroDesktopTabBar(tabs: const ['One'], selectedIndex: -1),
      'a text field of no lines': () => RetroDesktopTextField(lines: 0),
      'a text of no lines': () =>
          RetroDesktopText('Words', style: const TextStyle(), maxLines: 0),
      'a divider of a negative indent': () => RetroDesktopDivider(indent: -1),
      'a tree row of a negative level': () =>
          RetroDesktopTreeRow('Row', '1', share: .5, level: -1),
    };
    for (final MapEntry(key: what, value: make) in cases.entries) {
      test(what, () => expect(make, throwsAssertionError));
    }
  });
}
