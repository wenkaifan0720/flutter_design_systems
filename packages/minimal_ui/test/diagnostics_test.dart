// The description every public part gives of itself in the inspector and
// in a failing test's tree: each field it is built with, a field at its
// default hidden. (ui_core's diagnostics test, over Minimal's lib.)
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

final _widgetSupers = RegExp(
  r'\b(StatelessWidget|StatefulWidget|RenderObjectWidget|'
  r'SingleChildRenderObjectWidget|LeafRenderObjectWidget|'
  r'MultiChildRenderObjectWidget|InheritedWidget|InheritedTheme|'
  r'InheritedNotifier|ProxyWidget|PreferredSizeWidget)\b',
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
    expect(widgets, greaterThan(120));
    expect(missing, isEmpty, reason: 'fields left out of debugFillProperties');
  });

  test('a button says what it is built with, its defaults hidden', () {
    expect(_description(const MinimalButton('Save')), ['label: "Save"']);
    expect(
      _description(
        MinimalButton(
          'Delete',
          onPressed: () {},
          variant: MinimalButtonVariant.destructive,
          size: MinimalButtonSize.small,
          busy: true,
        ),
      ),
      [
        'label: "Delete"',
        'has onPressed',
        'variant: destructive',
        'size: small',
        'busy',
      ],
    );
  });

  test('a slider says each field set off its default', () {
    expect(
      _description(
        MinimalSlider(
          label: 'Volume',
          value: 4,
          max: 10,
          divisions: 10,
          unit: 'dB',
          showLabel: false,
          onChanged: (_) {},
        ),
      ),
      [
        'label: "Volume"',
        'showLabel: false',
        'value: 4.0',
        'has onChanged',
        'max: 10.0',
        'divisions: 10',
        'unit: "dB"',
      ],
    );
  });
}
