/// A state cell shows its state (coverage4.md, 11-10 05:30): for every part
/// of the review's state matrix that an app can press, disable or mark
/// wrong, the pressed, disabled and error faces keep idle's size (an error
/// may add its message below: the same width, no shorter) and differ from
/// idle pixel for pixel. Disabling a part never moves the layout and never
/// leaves it looking enabled.
///
/// A part's disabled face is the switch an app turns: `enabled: false` where
/// the part has it, else a null handler. A checkbox, radio or switch is
/// disabled by a null handler, as Flutter's are (coordinator, 11-10), so
/// theirs drop it here; the bare mark a row puts inside itself is `.mark`.
/// Parts with no such state say why in [_Part.why].
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

void _noop() {}

void _drop(Object? _) {}

const _segments = <ExpressiveButtonSegment<String>>[
  ExpressiveButtonSegment('start', 'Start'),
  ExpressiveButtonSegment('center', 'Centre'),
  ExpressiveButtonSegment('end', 'End'),
];

const _sizes = <ExpressiveSelectOption<String>>[
  ExpressiveSelectOption('s', 'Small'),
  ExpressiveSelectOption('m', 'Medium'),
  ExpressiveSelectOption('l', 'Large'),
];

const _destinations = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
  ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
  ExpressiveNavItem(ExpressiveSymbols.person, 'Profile'),
];

typedef _Part = ({
  String name,
  Widget Function(bool enabled, bool error) build,
  bool press,
  bool disable,
  bool error,
  String why,
});

_Part _p(
  String name,
  Widget Function(bool enabled, bool error) build, {
  bool press = true,
  bool disable = true,
  bool error = false,
  String why = '',
}) => (
  name: name,
  build: build,
  press: press,
  disable: disable,
  error: error,
  why: why,
);

/// Text fields and selects show no press of their own: a press focuses
/// them (coverage4 leaves those cells blank).
const _noPress = 'a press focuses the field; it has no pressed face';

final _parts = <_Part>[
  for (final (name, make)
      in <(String, ExpressiveButton Function(VoidCallback?))>[
        (
          'Button · filled',
          (on) => ExpressiveFilledButton('Book', onPressed: on),
        ),
        (
          'Button · tonal',
          (on) => ExpressiveFilledButton.tonal('Book', onPressed: on),
        ),
        (
          'Button · outlined',
          (on) => ExpressiveOutlinedButton('Book', onPressed: on),
        ),
        ('Button · text', (on) => ExpressiveTextButton('Book', onPressed: on)),
        (
          'Button · elevated',
          (on) => ExpressiveElevatedButton('Book', onPressed: on),
        ),
      ])
    _p(name, (enabled, error) => make(enabled ? _noop : null)),
  _p(
    'Toggle button',
    (enabled, error) => ExpressiveToggleButton(
      value: false,
      onChanged: enabled ? _drop : null,
      label: 'Pin',
      icon: ExpressiveSymbols.pushPin,
    ),
  ),
  _p(
    'Icon button',
    (enabled, error) => ExpressiveIconButton(
      ExpressiveSymbols.edit,
      semanticLabel: 'Edit',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Icon button · filled',
    (enabled, error) => ExpressiveIconButton.filled(
      ExpressiveSymbols.edit,
      semanticLabel: 'Edit',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Icon toggle',
    (enabled, error) => ExpressiveIconToggleButton(
      ExpressiveSymbols.favorite,
      value: false,
      onChanged: enabled ? _drop : null,
      semanticLabel: 'Favourite',
    ),
  ),
  _p(
    'FAB',
    (enabled, error) => ExpressiveFloatingActionButton(
      icon: ExpressiveSymbols.add,
      semanticLabel: 'Add',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Extended FAB',
    (enabled, error) => ExpressiveFloatingActionButton.extended(
      icon: ExpressiveSymbols.add,
      label: 'New trip',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Split button',
    (enabled, error) => ExpressiveSplitButton(
      'Send',
      icon: ExpressiveSymbols.send,
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Chip · filter',
    (enabled, error) => ExpressiveChip.filter(
      'Vegan',
      selected: false,
      onPressed: _noop,
      enabled: enabled,
    ),
  ),
  _p(
    'Checkbox',
    (enabled, error) => ExpressiveCheckbox(
      value: true,
      onChanged: enabled ? _drop : null,
      isError: error,
      semanticLabel: 'Agree',
    ),
    error: true,
  ),
  _p(
    'Radio',
    (enabled, error) => ExpressiveRadio(
      selected: true,
      onPressed: enabled ? _noop : null,
      semanticLabel: 'Email',
    ),
  ),
  _p(
    'Switch',
    (enabled, error) => ExpressiveSwitch(
      value: true,
      onChanged: enabled ? _drop : null,
      semanticLabel: 'Wi-Fi',
    ),
  ),
  _p(
    'Slider',
    (enabled, error) => SizedBox(
      width: 240,
      child: ExpressiveSlider(
        value: .4,
        onChanged: enabled ? _drop : null,
        semanticLabel: 'Volume',
      ),
    ),
  ),
  _p(
    'Checkbox row',
    (enabled, error) => SizedBox(
      width: 320,
      child: ExpressiveCheckboxRow(
        label: 'Send reminders',
        value: true,
        onChanged: _drop,
        enabled: enabled,
        isError: error,
      ),
    ),
    error: true,
  ),
  _p(
    'Switch row',
    (enabled, error) => SizedBox(
      width: 320,
      child: ExpressiveSwitchRow(
        label: 'Trip reminders',
        value: true,
        onChanged: _drop,
        enabled: enabled,
      ),
    ),
  ),
  _p(
    'List item',
    (enabled, error) => SizedBox(
      width: 320,
      child: ExpressiveListTile(
        leading: const Icon(ExpressiveSymbols.description),
        title: const Text('Train tickets'),
        onTap: _noop,
        enabled: enabled,
      ),
    ),
  ),
  _p(
    'Card',
    (enabled, error) => ExpressiveCard(
      onPressed: enabled ? _noop : null,
      child: const SizedBox(width: 200, height: 64, child: Text('Lisbon')),
    ),
    disable: false,
    why: "a card without onPressed is a plain surface, as Flutter's Card",
  ),
  _p(
    'Text field',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressiveTextField(
        label: 'Full name',
        enabled: enabled,
        errorText: error ? 'Enter your name.' : null,
        helperText: error ? null : 'As on your passport.',
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Select',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressiveSelect<String>(
        label: 'Size',
        value: 'm',
        options: _sizes,
        onChanged: enabled ? _drop : null,
        enabled: enabled,
        errorText: error ? '' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Search bar',
    (enabled, error) => const SizedBox(
      width: 320,
      child: ExpressiveSearchBar(hintText: 'Search trips'),
    ),
    disable: false,
    why:
        'no disabled state: Material 3 gives the search bar none (no '
        'disabled tokens) and the bar has no enabled switch',
  ),
  _p(
    'Menu item',
    (enabled, error) => SizedBox(
      width: 220,
      child: ExpressiveMenuSurface(
        groups: <ExpressiveMenuGroup>[
          ExpressiveMenuGroup(<ExpressiveMenuEntry>[
            ExpressiveMenuItem(
              'Copy',
              icon: ExpressiveSymbols.contentCopy,
              onPressed: enabled ? _noop : null,
            ),
          ]),
        ],
      ),
    ),
  ),
  _p(
    'Link',
    (enabled, error) =>
        ExpressiveLink('house rules', onPressed: enabled ? _noop : null),
  ),
  _p(
    'Rating',
    (enabled, error) =>
        ExpressiveRating(value: 3, onChanged: enabled ? _drop : null),
    disable: false,
    why:
        'a rating without onChanged is the read-only display, not a '
        'disabled input',
  ),
  // Round 4's components.
  _p(
    'Toggle group',
    (enabled, error) => ExpressiveToggleGroup<String>(
      label: 'Alignment',
      value: 'center',
      onChanged: enabled ? _drop : null,
      segments: _segments,
    ),
  ),
  _p(
    'Segmented button',
    (enabled, error) => ExpressiveSegmentedButton<String>(
      value: 'center',
      onChanged: enabled ? _drop : null,
      expand: false,
      segments: _segments,
    ),
  ),
  _p(
    'Password field',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressivePasswordField(
        label: 'Password',
        enabled: enabled,
        errorText: error ? 'Too short: 5 of 8 characters' : null,
        helperText: error ? null : 'At least 8 characters',
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Input group',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressiveInputGroup(
        hintText: 'example.com',
        semanticLabel: 'Website',
        enabled: enabled,
        isError: error,
        leading: <Widget>[ExpressiveInputGroup.text('https://')],
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Form field',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressiveFormField(
        label: 'Notify me',
        help: error ? null : 'At most once a day',
        error: error ? 'Turn this on to get reminders' : null,
        enabled: enabled,
        child: ExpressiveSwitch(value: true, onChanged: enabled ? _drop : null),
      ),
    ),
    error: true,
  ),
  _p(
    'Multi-select',
    (enabled, error) => SizedBox(
      width: 280,
      child: ExpressiveMultiSelect<String>(
        label: 'Sizes',
        options: _sizes,
        values: const <String>['s', 'm'],
        isError: error,
        onChanged: enabled ? _drop : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Colour picker',
    (enabled, error) => ExpressiveColorPicker(
      value: const Color(0xFF6750A4),
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Navigation drawer',
    (enabled, error) => const SizedBox(
      width: 320,
      child: ExpressiveNavigationDrawer(
        destinations: _destinations,
        selectedIndex: 1,
        onDestinationSelected: _drop,
      ),
    ),
    disable: false,
    why: 'a destination is never disabled (Compose has no disabled item)',
  ),
];

const _capture = ValueKey('state-cell');

Widget _stage(Brightness brightness, Widget part) {
  final theme = ExpressiveThemeData.preset('baseline', brightness);
  return MaterialApp(
    home: ExpressiveHost(
      light: theme,
      dark: theme,
      brightness: brightness,
      child: ColoredBox(
        color: theme.colors.surface,
        child: Center(
          child: RepaintBoundary(
            key: _capture,
            child: ColoredBox(
              color: theme.colors.surface,
              child: Padding(padding: const EdgeInsets.all(12), child: part),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _frames(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 34) {
    await tester.pump(const Duration(milliseconds: 34));
  }
}

/// The part's own size and its picture's pixels, built fresh, pressed at
/// its first pressable's centre while [press].
Future<(Size, Uint8List)> _cell(
  WidgetTester tester,
  String key,
  Brightness brightness,
  Widget part, {
  bool press = false,
}) async {
  await tester.pumpWidget(SizedBox(key: ValueKey(key)));
  await tester.pumpWidget(_stage(brightness, part));
  await _frames(tester, 600);
  TestGesture? finger;
  if (press) {
    final pressable = find.descendant(
      of: find.byKey(_capture),
      matching: find.byType(ExpressivePressable),
    );
    final at = pressable.evaluate().isEmpty
        ? tester.getCenter(find.byKey(_capture))
        : tester.getCenter(pressable.first);
    finger = await tester.startGesture(at);
    await _frames(tester, 240);
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  final size = boundary.size;
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  await finger?.cancel();
  await _frames(tester, 400);
  expect(tester.takeException(), isNull, reason: key);
  return (size, pixels!);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'every pressed, disabled and error face keeps idle\'s size '
      'and shows the state (${brightness.name})',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(600, 500);
        addTearDown(tester.view.reset);
        final faults = <String>[];
        for (final part in _parts) {
          final name = part.name;
          final (idleSize, idle) = await _cell(
            tester,
            '$name idle',
            brightness,
            part.build(true, false),
          );
          Future<void> face(
            String state,
            Widget widget, {
            bool press = false,
          }) async {
            final (size, pixels) = await _cell(
              tester,
              '$name $state',
              brightness,
              widget,
              press: press,
            );
            final grows = state == 'error';
            if (grows
                ? size.width != idleSize.width || size.height < idleSize.height
                : size != idleSize) {
              faults.add('$name $state is $size, idle $idleSize');
            }
            if (listEquals(pixels, idle)) faults.add('$name $state looks idle');
          }

          if (part.press) {
            await face('pressed', part.build(true, false), press: true);
          }
          if (part.disable) {
            await face('disabled', part.build(false, false));
          }
          if (part.error) {
            await face('error', part.build(true, true));
          }
        }
        expect(faults, isEmpty);
        // Drawn pixels are the rasterizer's, as a golden's: macOS runs it.
      },
      timeout: const Timeout(Duration(minutes: 5)),
      tags: const ['goldens'],
    );
  }

  test('a part without a face says why', () {
    for (final part in _parts) {
      if (!part.press || !part.disable) {
        expect(part.why, isNotEmpty, reason: part.name);
      }
    }
  });
}
