// A state cell shows its state, at idle's size: every pressed, disabled and error cell of the state matrix differs from
// idle pixel for pixel and keeps idle's size (an error may add its message below). Text fields, selects and sliders
// have no pressed look of their own, so their pressed cell is left out here as it is in the sheets; a part with no
// disabled state says so.
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void _tap() {}
void _drop(Object? _) {}

const Key _part = Key('part');

typedef _Stated = ({
  Widget Function({bool enabled, String? error}) build,
  bool presses,
  bool disables,
  bool errs,
  Finder? pressAt,
});

/// [pressAt]: where the finger goes, when the part's middle is not what presses (a number field's figure).
_Stated _stated(
  Widget Function({bool enabled, String? error}) build, {
  bool presses = true,
  bool disables = true,
  bool errs = false,
  Finder? pressAt,
}) => (
  build: build,
  presses: presses,
  disables: disables,
  errs: errs,
  pressAt: pressAt,
);

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => NeumorphicHost(
    light: NeumorphicThemeData.preset('porcelain', Brightness.light),
    darkData: NeumorphicThemeData.preset('porcelain', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: KeyedSubtree(
          key: _part,
          child: RepaintBoundary(child: child),
        ),
      ),
    ),
  ),
);

Future<({Size size, List<int> rgba})> _pixels(WidgetTester tester) async {
  final box = tester.renderObject<RenderRepaintBoundary>(
    find
        .descendant(
          of: find.byKey(_part),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final shot = await tester.runAsync(() async {
    final image = await box.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List().toList();
  });
  return (size: box.size, rgba: shot!);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Widget _wide(Widget child) => SizedBox(width: 280, child: child);

final Map<String, _Stated> _parts = {
  'NeumorphicButton': _stated(
    ({enabled = true, error}) =>
        NeumorphicButton('Save', onPressed: enabled ? _tap : null),
  ),
  'NeumorphicButton.filled': _stated(
    ({enabled = true, error}) =>
        NeumorphicButton.filled('Save', onPressed: enabled ? _tap : null),
  ),
  'NeumorphicButton.text': _stated(
    ({enabled = true, error}) =>
        NeumorphicButton.text('Save', onPressed: enabled ? _tap : null),
  ),
  'NeumorphicButton (destructive)': _stated(
    ({enabled = true, error}) => NeumorphicButton(
      'Delete',
      isDestructiveAction: true,
      onPressed: enabled ? _tap : null,
    ),
  ),
  'NeumorphicIconButton': _stated(
    ({enabled = true, error}) => NeumorphicIconButton(
      NeumorphicGlyphs.close,
      label: 'Close',
      onPressed: enabled ? _tap : null,
    ),
  ),
  'NeumorphicRoundButton': _stated(
    ({enabled = true, error}) => NeumorphicRoundButton(
      NeumorphicGlyphs.plus,
      label: 'Add',
      onPressed: enabled ? _tap : null,
    ),
  ),
  'NeumorphicSplitButton': _stated(
    ({enabled = true, error}) => NeumorphicSplitButton(
      'Start',
      onPressed: enabled ? _tap : null,
      actions: [NeumorphicSplitAction('Later', onPressed: _tap)],
    ),
  ),
  'NeumorphicChip': _stated(
    ({enabled = true, error}) =>
        NeumorphicChip('Warm', enabled: enabled, onPressed: _tap),
  ),
  'NeumorphicLink': _stated(
    ({enabled = true, error}) =>
        NeumorphicLink('Details', onPressed: enabled ? _tap : null),
  ),
  'NeumorphicCheckbox': _stated(
    ({enabled = true, error}) => NeumorphicCheckbox(
      value: false,
      label: 'Agree',
      error: error != null,
      onChanged: enabled ? _drop : null,
    ),
    errs: true,
  ),
  'NeumorphicSwitch': _stated(
    ({enabled = true, error}) => NeumorphicSwitch(
      value: false,
      label: 'Lamp',
      onChanged: enabled ? _drop : null,
    ),
  ),
  'NeumorphicRadioGroup': _stated(
    ({enabled = true, error}) => NeumorphicRadioGroup<String>(
      label: 'Room',
      value: 'a',
      options: const [NeumorphicRadio('a', 'A'), NeumorphicRadio('b', 'B')],
      onChanged: enabled ? _drop : null,
    ),
  ),
  'NeumorphicSegmentedButton': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicSegmentedButton<String>(
        label: 'View',
        value: 'a',
        segments: const [
          NeumorphicButtonSegment('a', 'Day'),
          NeumorphicButtonSegment('b', 'Week'),
        ],
        onChanged: enabled ? _drop : null,
      ),
    ),
  ),
  'NeumorphicToggleGroup': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicToggleGroup<String>(
        label: 'Rooms',
        selected: const {'a'},
        items: const [
          NeumorphicButtonSegment('a', 'Bed'),
          NeumorphicButtonSegment('b', 'Hall'),
        ],
        onChanged: enabled ? _drop : null,
      ),
    ),
  ),
  'NeumorphicRating': _stated(
    ({enabled = true, error}) => NeumorphicRating(
      label: 'Sleep',
      value: 3,
      onChanged: _drop,
      enabled: enabled,
    ),
  ),
  'NeumorphicNumberField': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicNumberField(
        value: '2',
        unit: 'Lamps',
        onIncrease: enabled ? _tap : null,
        onDecrease: enabled ? _tap : null,
      ),
    ),
    pressAt: find.byIcon(NeumorphicGlyphs.plus),
  ),
  'NeumorphicTextField': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicTextField(label: 'Name', enabled: enabled, error: error),
    ),
    presses: false,
    errs: true,
  ),
  'NeumorphicPasswordField': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicPasswordField(
        label: 'Password',
        enabled: enabled,
        error: error,
      ),
    ),
    presses: false,
    errs: true,
  ),
  'NeumorphicInputGroup': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicInputGroup(
        label: 'Site',
        prefix: 'https://',
        enabled: enabled,
        error: error,
      ),
    ),
    presses: false,
    errs: true,
  ),
  'NeumorphicCombobox': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicCombobox<String>(
        label: 'Room',
        options: const ['Bed', 'Hall'],
        enabled: enabled,
        error: error,
      ),
    ),
    presses: false,
    errs: true,
  ),
  'NeumorphicSelect': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicSelect<String>(
        label: 'Room',
        value: 'a',
        error: error,
        options: const [NeumorphicMenuItem('a', 'Bed')],
        onChanged: enabled ? _drop : null,
      ),
    ),
    presses: false,
    errs: true,
  ),
  'NeumorphicSlider': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicSlider(
        label: 'Warmth',
        value: .5,
        onChanged: enabled ? _drop : null,
      ),
    ),
    presses: false,
  ),
  'NeumorphicRangeSlider': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicRangeSlider(
        label: 'Comfort',
        values: const DesignRangeValues(.2, .8),
        onChanged: enabled ? _drop : null,
      ),
    ),
    presses: false,
  ),
  'NeumorphicWheelPicker': _stated(
    ({enabled = true, error}) => _wide(
      NeumorphicWheelPicker<int>(
        label: 'Lamps',
        items: const [1, 2, 3],
        value: 2,
        rows: 3,
        onChanged: enabled ? _drop : null,
      ),
    ),
    presses: false,
  ),
};

void main() {
  setUpAll(loadNeumorphicFonts);

  group('a state cell shows its state, at idle\'s size', () {
    for (final MapEntry(key: name, value: part) in _parts.entries) {
      testWidgets(name, (tester) async {
        Future<({Size size, List<int> rgba})> cell(Widget child) async {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_host(child));
          await tester.pump(const Duration(milliseconds: 400));
          return _pixels(tester);
        }

        final idle = await cell(part.build());
        if (part.presses) {
          final finger = await tester.startGesture(
            tester.getCenter(part.pressAt ?? find.byKey(_part)),
            kind: PointerDeviceKind.touch,
          );
          await tester.pump(const Duration(milliseconds: 150));
          await tester.pump(const Duration(milliseconds: 400));
          final pressed = await _pixels(tester);
          await finger.cancel();
          await tester.pump(const Duration(milliseconds: 400));
          expect(pressed.size, idle.size, reason: 'pressed keeps idle\'s size');
          expect(
            _same(pressed.rgba, idle.rgba),
            isFalse,
            reason: 'pressed looks pressed',
          );
        }
        if (part.disables) {
          final off = await cell(part.build(enabled: false));
          expect(off.size, idle.size, reason: 'disabled keeps idle\'s size');
          expect(
            _same(off.rgba, idle.rgba),
            isFalse,
            reason: 'disabled looks disabled',
          );
        }
        if (part.errs) {
          final wrong = await cell(part.build(error: 'Required'));
          expect(wrong.size.width, idle.size.width, reason: 'error width');
          expect(
            wrong.size.height,
            greaterThanOrEqualTo(idle.size.height),
            reason: 'an error only adds below',
          );
          // The look has no error colour: a field in error keeps its face and says so in the words and mark below it.
          expect(
            _same(wrong.rgba, idle.rgba),
            isFalse,
            reason: 'error looks like an error',
          );
        }
      }, tags: ['goldens']);
    }
  });

  // A list beside its detail marks the open row: its band goes in, as a bank's chosen cell does, at idle's size; it is
  // announced selected; and choosing it keeps the row mounted, so a row chosen from the keyboard keeps its focus.
  group('a chosen list row', () {
    for (final grouped in [true, false]) {
      testWidgets(grouped ? 'in a grouped list' : 'on its own', (tester) async {
        Widget rows(bool chosen) {
          final tiles = [
            NeumorphicListTile(
              key: const Key('first'),
              title: 'Floor lamp',
              subtitle: 'Living room',
              isFirst: true,
              onPressed: _tap,
            ),
            NeumorphicListTile(
              key: const Key('chosen'),
              title: 'Pendants',
              subtitle: 'Kitchen',
              selected: chosen,
              onPressed: _tap,
            ),
          ];
          return _wide(
            grouped
                ? NeumorphicListSection(children: tiles)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: NeumorphicColumn(gap: 0, children: tiles),
                  ),
          );
        }

        Future<({Size size, List<int> rgba})> cell(bool chosen) async {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_host(rows(chosen)));
          await tester.pump(const Duration(milliseconds: 400));
          return _pixels(tester);
        }

        final idle = await cell(false);
        final chosen = await cell(true);
        expect(chosen.size, idle.size, reason: 'chosen keeps idle\'s size');
        expect(
          _same(chosen.rgba, idle.rgba),
          isFalse,
          reason: 'chosen looks chosen',
        );

        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Pendants')),
          isSemantics(isSelected: true, isButton: true),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Floor lamp')),
          isNot(isSemantics(isSelected: true)),
        );
        handle.dispose();

        // Focus the row, then choose it: it stays mounted and keeps its focus.
        await tester.pumpWidget(_host(rows(false)));
        final node = Focus.of(
          tester.element(
            find
                .descendant(
                  of: find.byKey(const Key('chosen')),
                  matching: find.text('Pendants'),
                )
                .first,
          ),
        );
        node.requestFocus();
        await tester.pump();
        expect(node.hasFocus, isTrue);
        await tester.pumpWidget(_host(rows(true)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(node.hasFocus, isTrue, reason: 'choosing a row keeps its focus');
      }, tags: ['goldens']);
    }
  });
}
