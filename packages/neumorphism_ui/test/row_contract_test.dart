// Two classes the user met in other looks' builds (11-11 16:34, design6 P):
// - "the width for dropdown seems to be a common problem": from 600 up a dropdown's closed face takes its content's
//   width, at most 320, and the list it opens is at least as wide as the face and starts on its leading edge.
// - "the button doesnt have the same height here?": controls sharing a row show one top and one bottom, whatever
//   their variant, at each density, by day and by night. A face here is what the look marks as drawn
//   (DesignKeylineFace: the box its relief is cast around); a quiet button shows no face at rest.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

const _densities = {
  'standard': NeumorphicDensity.standard,
  'comfortable': NeumorphicDensity.comfortable,
  'compact': NeumorphicDensity.compact,
};

Widget _host(NeumorphicDensity density, Brightness brightness, Widget child) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => NeumorphicHost(
        light: NeumorphicThemeData.porcelain().copyWith(density: density),
        darkData: NeumorphicThemeData.preset(
          'porcelain',
          Brightness.dark,
        ).copyWith(density: density),
        brightness: brightness,
        child: navigator!,
      ),
      home: Scaffold(body: child),
    );

Rect _face(WidgetTester tester, Finder control) => tester.getRect(
  find.descendant(of: control, matching: find.byType(DesignKeylineFace)).first,
);

// The open list: the outermost painted box around [option] that is narrower than the window.
Rect _panel(WidgetTester tester, Finder option, double window) {
  RenderObject? r = tester.renderObject(option);
  Rect? best;
  while (r != null) {
    if (r is RenderCustomPaint && r.painter != null && r.hasSize) {
      final g = r.localToGlobal(Offset.zero) & r.size;
      if (g.width < window - 1) best = g;
    }
    r = r.parent;
  }
  return best!;
}

String _r(Rect r) =>
    '${r.left.toStringAsFixed(1)}+${r.width.toStringAsFixed(1)} '
    '(${r.top.toStringAsFixed(1)}..${r.bottom.toStringAsFixed(1)})';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in [600.0, 1024.0, 1440.0, 1920.0]) {
    testWidgets('dropdowns keep their width and open to it at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);
      final faults = <String>[];
      await tester.pumpWidget(
        _host(
          NeumorphicDensity.standard,
          Brightness.light,
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeumorphicSelect<String>(
                  key: const Key('select'),
                  label: 'Space',
                  options: const [
                    NeumorphicMenuItem('quiet', 'Quiet room'),
                    NeumorphicMenuItem('hall', 'The long hall'),
                  ],
                  value: 'quiet',
                  onChanged: (_) {},
                ),
                const SizedBox(height: 24),
                NeumorphicCombobox<String>(
                  key: const Key('combo'),
                  label: 'Town',
                  options: const ['Bath', 'Bristol', 'Brighton'],
                  onSelected: (_) {},
                ),
                const SizedBox(height: 24),
                NeumorphicMultiSelect<String>(
                  key: const Key('multi'),
                  label: 'Guests',
                  values: const ['Ana'],
                  onChanged: (_) {},
                  options: const ['Ana', 'Ben', 'Cleo'],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (key, open, option) in [
        ('select', null, 'The long hall'),
        ('combo', 'B', 'Bristol'),
        ('multi', 'C', 'Cleo'),
      ]) {
        final control = find.byKey(Key(key));
        final face = _face(tester, control);
        if (face.width > 320.5) {
          faults.add('$key: closed face ${face.width} wide (at most 320)');
        }
        final entry = find.descendant(
          of: control,
          matching: find.byType(EditableText),
        );
        await tester.tap(
          open != null && entry.evaluate().isNotEmpty
              ? entry
              : find
                    .descendant(
                      of: control,
                      matching: find.byType(DesignKeylineFace),
                    )
                    .first,
        );
        await tester.pumpAndSettle();
        if (open != null) {
          await tester.enterText(
            find.descendant(of: control, matching: find.byType(EditableText)),
            open,
          );
          await tester.pumpAndSettle();
        }
        final shown = find.text(option);
        if (shown.evaluate().isEmpty) {
          faults.add('$key: its list did not open');
          continue;
        }
        final panel = _panel(tester, shown.last, width);
        // ignore: avoid_print
        print('DROPDOWN $key $width: face ${_r(face)} list ${_r(panel)}');
        if ((panel.left - face.left).abs() > 1) {
          faults.add(
            '$key: its list starts ${(panel.left - face.left).toStringAsFixed(1)} px from the face\'s leading edge',
          );
        }
        if (panel.width < face.width - .5) {
          faults.add(
            '$key: its list is ${panel.width.toStringAsFixed(1)} wide under a ${face.width.toStringAsFixed(1)} face',
          );
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });
  }

  for (final MapEntry(key: name, value: density) in _densities.entries) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'controls in a row show one height, $name, ${brightness.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(1440, 600);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _host(
              density,
              brightness,
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicButton(
                      'Cancel',
                      key: const Key('line'),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    NeumorphicButton.filled(
                      'Sign out',
                      key: const Key('act'),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 220,
                      child: NeumorphicTextField(
                        key: Key('field'),
                        hint: 'Search',
                      ),
                    ),
                    const SizedBox(width: 12),
                    NeumorphicSelect<String>(
                      key: const Key('select'),
                      options: const [NeumorphicMenuItem('a', 'Any room')],
                      value: 'a',
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final faces = {
            for (final k in ['line', 'act', 'field', 'select'])
              k: _face(tester, find.byKey(Key(k))),
          };
          // ignore: avoid_print
          print(
            'ROW $name ${brightness.name}: '
            '${faces.entries.map((e) => '${e.key} ${_r(e.value)}').join(', ')}',
          );
          final a = faces['act']!;
          final faults = [
            for (final MapEntry(:key, :value) in faces.entries)
              if ((value.top - a.top).abs() > .5 ||
                  (value.bottom - a.bottom).abs() > .5)
                '$key shows ${_r(value)} beside the act\'s ${_r(a)}',
          ];
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
      );
    }
  }
}
