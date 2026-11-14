// A state cell shows its state (coverage4.md, 11-10 05:30): for every part of
// the review's state matrix that an app can press, disable or mark wrong, the
// pressed, disabled and error faces keep idle's size (an error may add its
// message below: the same width, no shorter) and differ from idle pixel for
// pixel, and the face under a resting pointer is idle's own (polish3 §1).
//
// A part's disabled face is the switch an app turns: `enabled: false` where
// the part has it, else a null handler. Parts with no such state say why in
// [StatePart.why], and DECISIONS.md carries the same reasons.
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void _noop() {}

void _drop(Object? _) {}

const _segments = <FrostedButtonSegment<String>>[
  FrostedButtonSegment('d', 'Day'),
  FrostedButtonSegment('w', 'Week'),
];

const _sizes = <FrostedSelectOption<String>>[
  FrostedSelectOption('s', 'Small'),
  FrostedSelectOption('m', 'Medium'),
];

const _places = <FrostedNavItem>[
  FrostedNavItem(FrostedGlyphs.house, 'Home'),
  FrostedNavItem(FrostedGlyphs.person, 'You'),
];

/// A part of the review's state matrix: how to build it enabled or not and
/// wrong or not, which faces it has, and why it lacks the others.
typedef StatePart = ({
  String name,
  Widget Function(bool enabled, bool error) build,
  bool press,
  bool disable,
  bool error,
  bool hover,
  String why,
});

StatePart _p(
  String name,
  Widget Function(bool enabled, bool error) build, {
  bool press = true,
  bool disable = true,
  bool error = false,
  bool hover = true,
  String why = '',
}) => (
  name: name,
  build: build,
  press: press,
  disable: disable,
  error: error,
  hover: hover,
  why: why,
);

/// Fields and selects show no press of their own: a press focuses them
/// (coverage4 leaves those cells blank).
const _noPress = 'a press focuses the field; it has no pressed face';

/// A page's place is never greyed: a destination the app can't go to is one
/// it leaves out.
const _destination = 'a destination is left out, never greyed';

/// Every part an app can press, disable or mark wrong.
final stateParts = <StatePart>[
  for (final glass in [false, true])
    _p(
      'Button · ${glass ? 'glass' : 'ink'}',
      (on, _) => glass
          ? FrostedButton.glass('Book', onPressed: on ? _noop : null)
          : FrostedButton('Book', onPressed: on ? _noop : null),
    ),
  _p(
    'Icon button',
    (on, _) => FrostedIconButton(
      FrostedGlyphs.add,
      label: 'Add',
      onPressed: on ? _noop : null,
    ),
  ),
  _p(
    'Button group',
    (on, _) => FrostedButtonGroup(
      items: [
        FrostedButtonGroupItem(label: 'Day', onPressed: on ? _noop : null),
        FrostedButtonGroupItem(label: 'Week', onPressed: on ? _noop : null),
      ],
    ),
  ),
  // The strip stands at its toggles' width; centred, the press at the
  // cell's middle lands on its middle toggle.
  _p(
    'Toggle group',
    (on, _) => Center(
      heightFactor: 1,
      child: FrostedToggleGroup<String>(
        segments: const [..._segments, FrostedButtonSegment('m', 'Month')],
        selected: const {'d'},
        onChanged: on ? _drop : null,
      ),
    ),
  ),
  _p(
    'Split button',
    (on, _) => FrostedSplitButton(
      label: 'Save',
      onPressed: on ? _noop : null,
      actions: const [FrostedSplitAction(label: 'Save as', onPressed: _noop)],
    ),
  ),
  _p(
    'Link',
    (on, _) => FrostedLink(
      'Read the terms',
      link: 'terms',
      onPressed: on ? _noop : null,
    ),
  ),
  _p(
    'Segmented button',
    (on, _) => FrostedSegmentedButton<String>(
      segments: _segments,
      value: 'd',
      label: 'Range',
      onChanged: on ? _drop : null,
    ),
  ),
  _p('Chip', (on, _) => FrostedChip('Vegan', onPressed: _noop, isEnabled: on)),
  _p(
    'Checkbox',
    (on, wrong) => FrostedCheckbox(
      value: false,
      label: 'Agree',
      error: wrong,
      onChanged: on ? _drop : null,
    ),
    error: true,
  ),
  _p(
    'Check row',
    (on, _) => FrostedCheckRow(
      label: 'Agree',
      value: false,
      onChanged: _drop,
      enabled: on,
    ),
  ),
  _p(
    'Radio group',
    (on, wrong) => FrostedRadioGroup<String>(
      label: 'Plan',
      value: 'a',
      options: [
        FrostedRadio('a', 'Monthly', enabled: on),
        FrostedRadio('b', 'Yearly', enabled: on),
      ],
      error: wrong ? 'Pick a plan' : null,
      onChanged: _drop,
    ),
    error: true,
  ),
  _p(
    'Choices',
    (on, _) => FrostedChoices<String>(
      label: 'Size',
      options: _sizes,
      value: 'm',
      onChanged: on ? _drop : null,
    ),
  ),
  _p(
    'Filter chips',
    (on, _) => SizedBox(
      width: 320,
      child: FrostedFilterChipGroup<String>(
        options: const [
          FrostedFilterOption('a', 'All'),
          FrostedFilterOption('b', 'Some'),
        ],
        value: 'a',
        onChanged: on ? _drop : null,
      ),
    ),
  ),
  _p(
    'Switch',
    (on, _) => FrostedSwitch(
      value: false,
      label: 'Wi-Fi',
      onChanged: on ? _drop : null,
    ),
  ),
  _p(
    'Switch row',
    (on, _) => FrostedSwitchRow(
      label: 'Wi-Fi',
      value: false,
      onChanged: on ? _drop : null,
    ),
  ),
  _p(
    'Slider',
    (on, _) => SizedBox(
      width: 240,
      child: FrostedSlider(
        value: .4,
        label: 'Volume',
        onChanged: on ? _drop : null,
      ),
    ),
    press: false,
    why: 'a press on a slider moves its value; it has no pressed face',
  ),
  _p(
    'Range slider',
    (on, _) => SizedBox(
      width: 240,
      child: FrostedRangeSlider(
        values: const DesignRangeValues(.2, .7),
        onChanged: on ? _drop : null,
      ),
    ),
    press: false,
    why: 'a press on a slider moves its value; it has no pressed face',
  ),
  _p(
    'Rating',
    (on, _) => FrostedRating(
      value: 3,
      label: 'Your rating',
      onChanged: on ? _drop : null,
    ),
    press: false,
    hover: false,
    disable: false,
    why:
        'a press on a star sets the value; it has no pressed face; with no '
        'onChanged it states the score, read only, as a display',
  ),
  _p(
    'Option',
    (on, _) => SizedBox(
      width: 280,
      child: FrostedOption(label: 'Monthly', onPressed: on ? _noop : null),
    ),
  ),
  _p(
    'List tile',
    (on, _) => SizedBox(
      width: 320,
      child: FrostedListTile(
        title: 'Wi-Fi',
        meta: 'Home',
        onPressed: _noop,
        enabled: on,
      ),
    ),
  ),
  _p(
    'Text field',
    (on, wrong) => SizedBox(
      width: 280,
      child: FrostedTextField(
        label: 'Name',
        value: 'Maya',
        enabled: on,
        error: wrong ? 'Enter your name' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Text area',
    (on, wrong) => SizedBox(
      width: 280,
      child: FrostedTextArea(
        label: 'Notes',
        value: 'Maya',
        enabled: on,
        error: wrong ? 'Too long' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Password field',
    (on, wrong) => SizedBox(
      width: 280,
      child: FrostedPasswordField(
        label: 'Password',
        value: 'secret',
        enabled: on,
        error: wrong ? 'Too short' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Input group',
    (on, wrong) => SizedBox(
      width: 280,
      child: FrostedInputGroup(
        label: 'Website',
        prefix: const Text('https://'),
        value: 'maya',
        enabled: on,
        error: wrong ? 'Not a site' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Code field',
    (on, wrong) => SizedBox(
      width: 320,
      child: FrostedInputOtp(
        length: 4,
        label: 'Code',
        enabled: on,
        error: wrong ? 'That code has expired' : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Select',
    (on, wrong) => SizedBox(
      width: 280,
      child: FrostedSelect<String>(
        label: 'Size',
        value: 'm',
        options: _sizes,
        error: wrong ? 'Pick a size' : null,
        onChanged: on ? _drop : null,
      ),
    ),
    press: false,
    error: true,
    why: _noPress,
  ),
  _p(
    'Number field',
    (on, _) => FrostedNumberField(
      value: 2,
      label: 'Guests',
      onChanged: on ? _drop : null,
    ),
    press: false,
    why: 'its two step buttons press; the field between them does not',
  ),
  _p(
    'File upload',
    (on, wrong) => SizedBox(
      width: 320,
      child: FrostedFileUpload(
        label: 'Attachments',
        error: wrong ? 'Too large' : null,
        onPressed: on ? _noop : null,
      ),
    ),
    error: true,
  ),
  _p(
    'Form field',
    (on, wrong) => FrostedFormField(
      label: 'Notify me',
      error: wrong ? 'Pick one' : null,
      enabled: on,
      child: FrostedChip('Email', onPressed: _noop, isEnabled: on),
    ),
    press: false,
    error: true,
    why: 'the field frames its control; the control has the pressed face',
  ),
  _p(
    'Wheel picker',
    (on, _) => FrostedWheelPicker<String>(
      options: _sizes,
      value: 'm',
      label: 'Size',
      onChanged: on ? _drop : null,
    ),
    press: false,
    why: 'a wheel has no pressed face; a drag or the arrow keys turn it',
  ),
  _p(
    'Pagination',
    (on, _) => FrostedPagination(
      pageCount: 4,
      selectedIndex: 1,
      onChanged: on ? _drop : null,
    ),
  ),
  _p(
    'Tab bar',
    // Live, so that Tab reaches it: an inert bar takes no focus.
    (on, _) => const FrostedTabBar(tabs: ['One', 'Two'], onChanged: _drop),
    press: false,
    disable: false,
    why: _destination,
  ),
  _p(
    'Navigation bar',
    (on, _) => SizedBox(
      width: 360,
      child: FrostedNavigationBar(items: _places, onDestinationSelected: _drop),
    ),
    press: false,
    disable: false,
    why: _destination,
  ),
  _p(
    'Search field',
    (on, _) =>
        const SizedBox(width: 280, child: FrostedSearchField(hint: 'Search')),
    press: false,
    disable: false,
    why: 'search is how an app finds what it holds; none turns it off',
  ),
];

const _capture = ValueKey('state-cell');

Widget _stage(Brightness brightness, Widget part) {
  final theme = FrostedThemeData.preset('opal', brightness);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? page) =>
        FrostedHost(brightness: brightness, child: page!),
    home: ColoredBox(
      color: theme.colorScheme.background,
      child: Center(
        child: RepaintBoundary(
          key: _capture,
          child: ColoredBox(
            color: theme.colorScheme.background,
            child: Padding(padding: const EdgeInsets.all(12), child: part),
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

/// The part's own size and its picture's pixels, built fresh, pressed or
/// under a resting pointer at its first pressable's centre.
Future<(Size, Uint8List)> _cell(
  WidgetTester tester,
  String key,
  Brightness brightness,
  Widget part, {
  bool press = false,
  bool hover = false,
}) async {
  await tester.pumpWidget(SizedBox(key: ValueKey(key)));
  await tester.pumpWidget(_stage(brightness, part));
  await _frames(tester, 600);
  final pressable = find.descendant(
    of: find.byKey(_capture),
    matching: find.byWidgetPredicate(
      (w) =>
          w is FrostedPressable || w is FrostedCheckbox || w is FrostedSwitch,
    ),
  );
  final at = pressable.evaluate().isEmpty
      ? tester.getCenter(find.byKey(_capture))
      : tester.getCenter(pressable.first);
  TestGesture? finger;
  if (press) {
    finger = await tester.startGesture(at);
    await _frames(tester, 240);
  } else if (hover) {
    finger = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await finger.addPointer(location: Offset.zero);
    await finger.moveTo(at);
    await _frames(tester, 400);
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
  if (press) await finger?.cancel();
  if (hover) await finger?.removePointer();
  await _frames(tester, 400);
  expect(tester.takeException(), isNull, reason: key);
  return (size, pixels!);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      "every pressed, disabled and error face keeps idle's size and shows "
      'the state; a resting pointer changes nothing (${brightness.name})',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(600, 500);
        addTearDown(tester.view.reset);
        final faults = <String>[];
        for (final part in stateParts) {
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
            if (listEquals(pixels, idle)) {
              faults.add('$name $state looks idle');
            }
          }

          if (part.hover) {
            final (_, pixels) = await _cell(
              tester,
              '$name hovered',
              brightness,
              part.build(true, false),
              hover: true,
            );
            if (!listEquals(pixels, idle)) {
              faults.add('$name changes under a resting pointer');
            }
          }
          if (part.press) {
            await face('pressed', part.build(true, false), press: true);
          }
          if (part.disable) await face('disabled', part.build(false, false));
          if (part.error) await face('error', part.build(true, true));
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 8)),
      tags: const ['goldens'],
    );
  }

  test('a part without a face says why', () {
    for (final part in stateParts) {
      if (!part.press || !part.disable) {
        expect(part.why, isNotEmpty, reason: part.name);
      }
    }
  });

  // On a desktop a scroll view raises its scrollbar under a resting pointer
  // (the wheel picker did, at 1440): the rule holds there too.
  testWidgets(
    'under a desktop platform a resting pointer changes nothing',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 500);
      addTearDown(tester.view.reset);
      final faults = <String>[];
      for (final part in stateParts.where((p) => p.hover)) {
        final (_, idle) = await _cell(
          tester,
          '${part.name} idle',
          Brightness.light,
          part.build(true, false),
        );
        final (_, hovered) = await _cell(
          tester,
          '${part.name} hovered',
          Brightness.light,
          part.build(true, false),
          hover: true,
        );
        if (!listEquals(hovered, idle)) {
          faults.add('${part.name} changes under a resting pointer');
        }
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    timeout: const Timeout(Duration(minutes: 8)),
    tags: const ['goldens'],
  );
}
