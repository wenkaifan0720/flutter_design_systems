// The description every public Comic part gives of itself in the inspector and in a failing test's tree: each field
// it is built with, a field at its default hidden (ui_core's diagnostics test, its scan copied). And a value out of
// its range asserts, as ui_core's parts do.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

void main() {
  test('every public widget describes every public field it is built with', () {
    // Comic's lib and, in an app that vendors it, ui_core's beside it
    // (design_system/ and design_kit/); the package's lib is Comic's alone.
    // Such an app lays its own code and kit parts in lib too, which are
    // neither's.
    final roots = [
      for (final dir in const ['lib/design_system', 'lib/design_kit'])
        if (Directory(dir).existsSync()) Directory(dir),
    ];
    final missing = <String>[];
    var widgets = 0;
    for (final file in [
      for (final lib in roots.isEmpty ? [Directory('lib')] : roots)
        ...lib.listSync(recursive: true),
    ].whereType<File>()) {
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

  test('a button says what it is built with, its defaults hidden', () {
    expect(_description(const ComicButton('Save')), ['label: "Save"']);
    expect(
      _description(
        ComicButton.filled(
          'Delete',
          onPressed: () {},
          size: ComicButtonSize.large,
          busy: true,
          isDestructiveAction: true,
        ),
      ),
      [
        'label: "Delete"',
        'has onPressed',
        'size: large',
        'busy',
        'isDestructiveAction',
      ],
    );
  });

  group('a value out of its range asserts', () {
    final cases = <String, Object? Function()>{
      'a field of no lines': () => ComicTextField(maxLines: 0),
      'a field whose minLines pass its maxLines': () =>
          ComicTextField(maxLines: 2, minLines: 3),
      'a note of no lines': () => ComicTextArea(maxLines: 0),
      'a number field that steps by nothing': () =>
          ComicNumberField(value: 1, step: 0, onChanged: (_) {}),
      'a dropped file past done': () =>
          ComicDroppedFile('a.png', progress: 1.5),
      'lettering of no lines': () => ComicLetters('Pow', maxLines: 0),
      'a resizable pane past the whole': () => ComicResizable(
        first: const SizedBox(),
        second: const SizedBox(),
        fraction: 2,
      ),
      'a row of no people': () => ComicPeople(const [], max: 0),
      'a bar list out of nothing': () => ComicBarList(entries: const [], of: 0),
      'a badge below nothing': () => ComicBadge(-1),
      'a review of six stars': () => ComicSpeech(
        person: const ComicPerson(initials: 'AB'),
        text: 'Great',
        rating: 6,
      ),
    };
    for (final MapEntry(key: name, value: make) in cases.entries) {
      test(name, () => expect(make, throwsAssertionError));
    }
  });
}

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
