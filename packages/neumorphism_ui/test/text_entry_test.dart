// design6 I3: every text entry is one structure, the look's box around a bare editable. As iOS and as macOS (where an
// app's Material theme is compact and its targets shrink-wrapped), under an app's own theme that sets an input
// decoration theme (padding, isDense, constraints, a fill and an outline) and at text scale 1.5, each entry keeps the
// size and the line place it has on Android at the same look density, and its one line, typed or hint, is centred in its box
// within half a pixel. A text area's first line stands where a field's line does.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// Each entry, with its hint; [typed] is false where the words are a part's own (a tag field's editor).
final _entries =
    <
      String,
      ({
        Widget Function(TextEditingController text) build,
        String hint,
        bool typed,
      })
    >{
      'field': (
        build: (c) => NeumorphicTextField(controller: c, hint: 'Name'),
        hint: 'Name',
        typed: true,
      ),
      'composer': (
        build: (c) => NeumorphicTextField(
          controller: c,
          hint: 'Ask',
          trailing: NeumorphicSendButton(onPressed: () {}),
        ),
        hint: 'Ask',
        typed: true,
      ),
      'search': (
        build: (c) => NeumorphicSearchField(controller: c, hint: 'Search'),
        hint: 'Search',
        typed: true,
      ),
      'password': (
        build: (c) => NeumorphicPasswordField(controller: c, hint: 'Secret'),
        hint: 'Secret',
        typed: true,
      ),
      'input group': (
        build: (c) => NeumorphicInputGroup(
          controller: c,
          hint: 'site',
          prefix: 'https://',
          suffix: '.com',
        ),
        hint: 'site',
        typed: true,
      ),
      'multi-select': (
        build: (_) => NeumorphicMultiSelect<String>(
          values: const [],
          options: const ['Hall', 'Den'],
          hint: 'Rooms',
          onChanged: (_) {},
        ),
        hint: 'Rooms',
        typed: false,
      ),
    };

/// The host theme an app might put between the look and its fields.
const _hostile = InputDecorationTheme(
  contentPadding: EdgeInsets.all(20),
  isDense: true,
  constraints: BoxConstraints(minHeight: 56),
  filled: true,
  fillColor: Color(0xFFFF00FF),
  border: OutlineInputBorder(),
);

typedef _Place = ({Rect box, Rect line, Rect? hint});

Future<_Place> _place(
  WidgetTester tester,
  Widget entry, {
  required NeumorphicDensity density,
  required double scale,
  required bool hostile,
  String? hint,
  String? type,
}) async {
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: hostile
          ? ThemeData(
              inputDecorationTheme: _hostile,
              visualDensity: VisualDensity.compact,
            )
          : null,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: NeumorphicTheme(
          data: NeumorphicThemeData.porcelain().copyWith(density: density),
          child: Center(child: SizedBox(width: 360, child: entry)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (type != null) {
    await tester.enterText(find.byType(EditableText).first, type);
    await tester.pumpAndSettle();
  }
  return (
    box: tester.getRect(find.byType(NeumorphicFieldBox).first),
    line: tester.getRect(find.byType(EditableText).first),
    hint: hint == null ? null : tester.getRect(find.text(hint).first),
  );
}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final (densityName, density) in [
    ('standard', NeumorphicDensity.standard),
    ('comfortable', NeumorphicDensity.comfortable),
    ('compact', NeumorphicDensity.compact),
  ]) {
    for (final scale in [1.0, 1.5]) {
      for (final hostile in [false, true]) {
        final config =
            '$densityName ×$scale${hostile ? ' under an app input theme' : ''}';
        testWidgets('text entries hold their line: $config', (tester) async {
          addTearDown(tester.view.reset);
          final faults = <String>[];
          void near(String what, double a, double b) {
            if ((a - b).abs() > .5) {
              faults.add(
                '$what: ${a.toStringAsFixed(2)} vs ${b.toStringAsFixed(2)}',
              );
            }
          }

          final byPlatform = <TargetPlatform, Map<String, _Place>>{};
          for (final platform in [
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ]) {
            debugDefaultTargetPlatformOverride = platform;
            try {
              final places = byPlatform[platform] = {};
              final os = platform.name;
              for (final MapEntry(key: name, value: e) in _entries.entries) {
                final text = TextEditingController();
                final empty = await _place(
                  tester,
                  e.build(text),
                  density: density,
                  scale: scale,
                  hostile: hostile,
                  hint: e.hint,
                );
                places[name] = empty;
                // The line is centred by its capitals (DesignCapCenter), not its line box: ui_core's
                // DesignTextEntryCheck holds that (inline_alignment_test). Here the hint on the line it stands for.
                near(
                  '$name · $os: hint on its line',
                  empty.hint!.center.dy,
                  empty.line.center.dy,
                );
                if (e.typed) {
                  final typed = await _place(
                    tester,
                    e.build(text),
                    density: density,
                    scale: scale,
                    hostile: hostile,
                    type: 'Pepper',
                  );
                  near(
                    '$name · $os: typed line where the empty one stood',
                    typed.line.center.dy - typed.box.top,
                    empty.line.center.dy - empty.box.top,
                  );
                  near(
                    '$name · $os: box height typed',
                    typed.box.height,
                    empty.box.height,
                  );
                }
                text.dispose();
              }
              // Several lines: the first stands where a field's one line does.
              final area = await _place(
                tester,
                const NeumorphicTextArea(hint: 'Notes', lines: 3),
                density: density,
                scale: scale,
                hostile: hostile,
              );
              final field = places['field']!;
              // One line is centred by its capitals, several start where they are laid out: the first of several
              // stands within a pixel of where one line does (0.9 at ×1.5, the capitals' shift).
              final first = area.line.top - area.box.top;
              final one = field.line.top - field.box.top;
              if ((first - one).abs() > 1) {
                faults.add(
                  'text area · $os: first line from the top: '
                  '${first.toStringAsFixed(2)} vs ${one.toStringAsFixed(2)}',
                );
              }
            } finally {
              debugDefaultTargetPlatformOverride = null;
            }
          }
          // A box and its line are where they are on Android: the least target is 48 on every platform.
          for (final other in [TargetPlatform.iOS, TargetPlatform.macOS]) {
            for (final name in _entries.keys) {
              final a = byPlatform[TargetPlatform.android]![name]!;
              final m = byPlatform[other]![name]!;
              near(
                '$name: box height, ${other.name} vs android',
                m.box.height,
                a.box.height,
              );
              near(
                '$name: line from the top, ${other.name} vs android',
                m.line.top - m.box.top,
                a.line.top - a.box.top,
              );
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        });
      }
    }
  }
}
