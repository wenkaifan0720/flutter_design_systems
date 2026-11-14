/// A state cell shows its state (coverage4.md, 11-10 05:30): for every part
/// of the review's state matrix that an app can press, disable or mark
/// wrong, the pressed, disabled and error faces keep idle's size (an error
/// may add its message below: the same width, no shorter) and differ from
/// idle pixel for pixel. Disabling a part never moves the layout and never
/// leaves it looking enabled.
///
/// A part's disabled face is the switch an app turns: a null handler, as
/// Flutter's, or `enabled: false` where the part has one. Fluent 2 keeps its
/// own hover faces (its spec is its idiom, as Material 3 is Material
/// Expressive's), so no hover check stands beside this one. Parts with no
/// such state say why in [_Part.why].
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

void _noop() {}

void _drop(Object? _) {}

const _sizes = [
  Fluent2Option('s', 'Small'),
  Fluent2Option('m', 'Medium'),
  Fluent2Option('l', 'Large'),
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

/// Text fields show no press of their own: a press puts the caret in them
/// (coverage4 leaves those cells blank).
const _noPress = 'a press focuses the field; Fluent gives it no pressed face';

Widget _w(double width, Widget child) => SizedBox(width: width, child: child);

final _parts = <_Part>[
  for (final a in Fluent2ButtonAppearance.values)
    _p(
      'Button · ${a.name}',
      (enabled, error) => Fluent2Button(
        'Share',
        appearance: a,
        onPressed: enabled ? _noop : null,
      ),
    ),
  _p(
    'Icon button',
    (enabled, error) => Fluent2IconButton(
      Fluent2Icons.share,
      label: 'Share',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Toggle button',
    (enabled, error) => Fluent2ToggleButton(
      'Bold',
      value: false,
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Compound button',
    (enabled, error) => Fluent2CompoundButton(
      'Share',
      secondary: 'With the team',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Menu button',
    (enabled, error) =>
        Fluent2MenuButton('Sort', onPressed: enabled ? _noop : null),
  ),
  _p(
    'Split button',
    (enabled, error) => Fluent2SplitButton(
      'Publish',
      onPressed: enabled ? _noop : null,
      actions: [
        if (enabled) const Fluent2SplitAction('Schedule', onPressed: _noop),
      ],
    ),
  ),
  _p(
    'Link',
    (enabled, error) =>
        Fluent2Link('Read the guide', onPressed: enabled ? _noop : null),
  ),
  _p(
    'Floating action button',
    (enabled, error) => Fluent2FloatingActionButton(
      icon: Fluent2Icons.add,
      label: 'New',
      onPressed: enabled ? _noop : null,
    ),
  ),
  _p(
    'Chip',
    (enabled, error) =>
        Fluent2InteractionTag('Shared', onPressed: enabled ? _noop : null),
  ),
  _p(
    'Tag · dismissible',
    (enabled, error) => Fluent2Tag('Draft', onDeleted: _noop, enabled: enabled),
  ),
  _p(
    'Checkbox',
    (enabled, error) => Fluent2Checkbox(
      value: true,
      label: 'Agree',
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Radio group',
    (enabled, error) => Fluent2RadioGroup<String>(
      value: 'a',
      options: const [Fluent2Radio('a', 'Email'), Fluent2Radio('b', 'Phone')],
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Switch',
    (enabled, error) => Fluent2Switch(
      value: true,
      label: 'Sync',
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Completion check',
    (enabled, error) => Fluent2CompletionCheck(
      value: false,
      label: 'Review the deck',
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Slider',
    (enabled, error) => _w(
      240,
      Fluent2Slider(
        value: 40,
        label: 'Volume',
        onChanged: enabled ? _drop : null,
      ),
    ),
    press: false,
    why: 'a press moves the thumb to the finger; the drag is the state',
  ),
  _p(
    'Rating',
    (enabled, error) => Fluent2Rating(
      value: 3,
      label: 'Rating',
      onChanged: enabled ? _drop : null,
    ),
    press: false,
    why:
        "Fluent's rating has no pressed face: a press chooses the value, and "
        'the stars it fills are the state',
  ),
  _p(
    'List tile',
    (enabled, error) => _w(
      320,
      Fluent2ListItem(
        leading: const Icon(Fluent2Icons.document),
        title: 'Budget',
        onTap: _noop,
        enabled: enabled,
      ),
    ),
  ),
  _p(
    'Card',
    (enabled, error) => _w(
      240,
      Fluent2Card(
        onPressed: enabled ? _noop : null,
        label: 'Budget',
        children: const [Text('Budget')],
      ),
    ),
    disable: false,
    why:
        "Fluent's card has no disabled state: without onPressed it is a "
        'static card, not a disabled one',
  ),
  _p(
    'Navigation drawer item',
    (enabled, error) => _w(
      260,
      Fluent2NavigationDrawerItem(
        icon: Fluent2Icons.home,
        label: 'Home',
        selected: false,
        onPressed: enabled ? _noop : null,
      ),
    ),
  ),
  _p(
    'Tab bar',
    (enabled, error) => Fluent2TabList(
      tabs: const ['Files', 'Shared'],
      selectedIndex: 0,
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Segmented button',
    (enabled, error) => Fluent2SegmentedButton<String>(
      label: 'View',
      value: 'a',
      segments: const [
        Fluent2ButtonSegment('a', 'List'),
        Fluent2ButtonSegment('b', 'Board'),
      ],
      onChanged: enabled ? _drop : null,
    ),
  ),
  _p(
    'Pagination',
    (enabled, error) =>
        Fluent2Pagination(page: 2, pages: 5, onChanged: enabled ? _drop : null),
  ),
  _p(
    'Text field',
    (enabled, error) => _w(
      280,
      Fluent2TextField(
        label: 'Name',
        value: 'Ana Ruiz',
        onChanged: enabled ? _drop : null,
        invalid: error,
        validationMessage: error ? 'Enter your full name.' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Text area',
    (enabled, error) => _w(
      280,
      Fluent2TextArea(
        label: 'Notes',
        value: 'Bring the deck',
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Search field',
    (enabled, error) => _w(
      280,
      Fluent2SearchBox(hint: 'Search files', onChanged: enabled ? _drop : null),
    ),
    press: false,
    why: _noPress,
  ),
  _p(
    'Password field',
    (enabled, error) => _w(
      280,
      Fluent2PasswordField(
        label: 'Password',
        value: 'secret',
        onChanged: enabled ? _drop : null,
        invalid: error,
        validationMessage: error ? 'Too short: 6 of 8 characters.' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Input group',
    (enabled, error) => _w(
      280,
      Fluent2InputGroup(
        label: 'Website',
        hint: 'example.com',
        onChanged: _drop,
        enabled: enabled,
        invalid: error,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Number field',
    (enabled, error) => Fluent2SpinButton(
      label: 'Copies',
      value: 2,
      onChanged: enabled ? _drop : null,
      invalid: error,
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Select',
    (enabled, error) => _w(
      280,
      Fluent2Select<String>(
        label: 'Size',
        value: 'm',
        options: _sizes,
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    error: true,
  ),
  _p(
    'Combobox',
    (enabled, error) => _w(
      280,
      Fluent2Combobox<String>(
        label: 'Size',
        value: 'm',
        options: _sizes,
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Multi select',
    (enabled, error) => _w(
      280,
      Fluent2MultiSelect<String>(
        label: 'Sizes',
        options: _sizes,
        selected: const ['s'],
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Date picker',
    (enabled, error) => _w(
      280,
      Fluent2DatePicker(
        label: 'Due',
        value: DateTime(2026, 6, 14),
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    error: true,
  ),
  _p(
    'Time picker',
    (enabled, error) => _w(
      280,
      Fluent2TimePicker(
        label: 'Starts',
        value: const Fluent2Time(9, 30),
        onChanged: enabled ? _drop : null,
        invalid: error,
      ),
    ),
    error: true,
  ),
];

const _capture = ValueKey('state-cell');

Widget _stage(Brightness brightness, Widget part) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Fluent2Host(brightness: brightness, child: page!),
  home: Builder(
    builder: (context) {
      final ground = context.fluent2Theme.background;
      return Material(
        color: ground,
        child: Center(
          child: RepaintBoundary(
            key: _capture,
            child: ColoredBox(
              color: ground,
              child: Padding(padding: const EdgeInsets.all(12), child: part),
            ),
          ),
        ),
      );
    },
  ),
);

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
      matching: find.byType(DesignPressable),
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
        // Compares drawn pixels (the rasterizer's, as a golden's): run where
        // the goldens run.
      },
      timeout: const Timeout(Duration(minutes: 8)),
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
