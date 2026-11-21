// Compare control geometry and paint across their interactive states.
// An intermediate animation frame should lie between its two endpoints.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

const _part = ValueKey('part');
const _stage = ValueKey('stage');

void _none() {}

Future<void> _pump(WidgetTester tester, Widget part, {Brightness? brightness}) {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    kitApp(
      brightness: brightness ?? Brightness.light,
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: RepaintBoundary(
          key: _stage,
          child: Padding(
            // Room for the focus ring outside the part.
            padding: const EdgeInsets.all(CivicSpacing.s16),
            child: SizedBox(width: 320, child: part),
          ),
        ),
      ),
    ),
  );
}

Future<Uint8List> _picture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

/// Each state's picture and size, after it has settled.
Future<Map<String, (Size, Uint8List)>> _states(
  WidgetTester tester,
  Map<String, Widget Function()> states,
) async {
  // The keyboard's look: a focus shows as it does from Tab.
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  final out = <String, (Size, Uint8List)>{};
  for (final MapEntry(:key, :value) in states.entries) {
    // A fresh tree for each state, so an autofocus is a first build's.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, value());
    await tester.pumpAndSettle();
    out[key] = (tester.getSize(find.byKey(_part)), await _picture(tester));
  }
  return out;
}

void _expectMatrix(Map<String, (Size, Uint8List)> looks) {
  final names = looks.keys.toList();
  final rest = looks[names.first]!;
  for (final name in names.skip(1)) {
    expect(
      looks[name]!.$1,
      rest.$1,
      reason: '$name keeps the size of ${names.first}',
    );
  }
  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      expect(
        listEquals(looks[names[i]]!.$2, looks[names[j]]!.$2),
        isFalse,
        reason: '${names[i]} and ${names[j]} look different',
      );
    }
  }
}

WidgetStatesController _with(WidgetState state) =>
    WidgetStatesController({state});

void main() {
  for (final brightness in Brightness.values) {
    for (final switchControl in [true, false]) {
      final name = switchControl ? 'switch' : 'tab';
      testWidgets('$name shows hover and held press in ${brightness.name}', (
        tester,
      ) async {
        var changes = 0;
        var on = false;
        var tabIndex = 0;
        final part = StatefulBuilder(
          builder: (context, setState) => switchControl
              ? CivicSwitch(
                  value: on,
                  labelText: 'Larger text',
                  onChanged: (next) => setState(() {
                    on = next;
                    changes++;
                  }),
                )
              : CivicTabBar(
                  tabs: const ['Details', 'Documents'],
                  selectedIndex: tabIndex,
                  onTap: (next) => setState(() {
                    tabIndex = next;
                    changes++;
                  }),
                ),
        );
        await _pump(tester, part, brightness: brightness);
        await tester.pumpAndSettle();
        final target = switchControl
            ? tester.getRect(find.byType(CivicSwitch)).centerRight -
                  Offset(CivicSwitch.trackSize.width / 2, 0)
            : tester.getCenter(find.text('Documents'));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        final rest = await _picture(tester);
        await mouse.moveTo(target);
        await tester.pumpAndSettle();
        final hover = await _picture(tester);
        expect(listEquals(hover, rest), isFalse);
        await mouse.down(target);
        await tester.pumpAndSettle();
        final held = await _picture(tester);
        expect(listEquals(held, hover), isFalse);
        expect(listEquals(held, rest), isFalse);
        expect(changes, 0);
        await mouse.up();
        await tester.pumpAndSettle();
        expect(changes, 1);
      });
    }
  }

  group('the state matrix', () {
    for (final (kind, build)
        in <(String, Widget Function(VoidCallback?, WidgetStatesController?))>[
          (
            'primary',
            (on, c) => CivicButton(
              key: _part,
              onPressed: on,
              statesController: c,
              child: const Text('Continue'),
            ),
          ),
          (
            'secondary',
            (on, c) => CivicButton.secondary(
              key: _part,
              onPressed: on,
              statesController: c,
              child: const Text('Save for later'),
            ),
          ),
          (
            'start',
            (on, c) => CivicButton.start(
              key: _part,
              onPressed: on,
              statesController: c,
              child: const Text('Start now'),
            ),
          ),
          (
            'destructive',
            (on, c) => CivicButton(
              key: _part,
              onPressed: on,
              isDestructiveAction: true,
              statesController: c,
              child: const Text('Cancel the permit'),
            ),
          ),
        ]) {
      testWidgets('a $kind button', (tester) async {
        _expectMatrix(
          await _states(tester, {
            'rest': () => build(_none, null),
            'pressed': () => build(_none, _with(WidgetState.pressed)),
            'focused': () => build(_none, _with(WidgetState.focused)),
            'disabled': () => build(null, null),
          }),
        );
      });
    }

    testWidgets('a link', (tester) async {
      Widget link(VoidCallback? on, WidgetStatesController? c) => CivicLink(
        key: _part,
        onPressed: on,
        statesController: c,
        child: const Text('Change your address'),
      );
      _expectMatrix(
        await _states(tester, {
          'rest': () => link(_none, null),
          'pressed': () => link(_none, _with(WidgetState.pressed)),
          'focused': () => link(_none, _with(WidgetState.focused)),
        }),
      );
    });

    testWidgets('an icon button', (tester) async {
      Widget button(VoidCallback? on, WidgetStatesController? c) =>
          CivicIconButton(
            key: _part,
            icon: LucideIcons.x,
            semanticLabel: 'Close',
            onPressed: on,
            statesController: c,
          );
      _expectMatrix(
        await _states(tester, {
          'rest': () => button(_none, null),
          'hovered': () => button(_none, _with(WidgetState.hovered)),
          'pressed': () => button(_none, _with(WidgetState.pressed)),
          'focused': () => button(_none, _with(WidgetState.focused)),
          'disabled': () => button(null, null),
        }),
      );
    });

    testWidgets('a text field', (tester) async {
      Widget field({
        bool enabled = true,
        bool error = false,
        bool focus = false,
      }) => CivicTextField(
        key: _part,
        labelText: 'Postcode',
        widthInCharacters: 10,
        enabled: enabled,
        isError: error,
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': field,
          'focused': () => field(focus: true),
          'error': () => field(error: true),
          'disabled': () => field(enabled: false),
        }),
      );
    });

    testWidgets('a checkbox', (tester) async {
      Widget box({
        bool value = false,
        bool enabled = true,
        bool focus = false,
      }) => CivicCheckbox(
        key: _part,
        value: value,
        onChanged: enabled ? (_) {} : null,
        labelText: 'Email me a reminder',
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': box,
          'selected': () => box(value: true),
          'focused': () => box(focus: true),
          'disabled': () => box(enabled: false),
        }),
      );
    });

    testWidgets('a switch', (tester) async {
      Widget toggle({
        bool value = false,
        bool enabled = true,
        bool focus = false,
      }) => CivicSwitch(
        key: _part,
        value: value,
        onChanged: enabled ? (_) {} : null,
        labelText: 'Text me when it is ready',
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': toggle,
          'selected': () => toggle(value: true),
          'focused': () => toggle(focus: true),
          'disabled': () => toggle(enabled: false),
        }),
      );
    });

    testWidgets('a select', (tester) async {
      Widget select({bool enabled = true, bool focus = false}) =>
          CivicSelect<String>(
            key: _part,
            labelText: 'Zone',
            value: 'a',
            onChanged: enabled ? (_) {} : null,
            autofocus: focus,
            items: const [
              CivicSelectItem(value: 'a', label: 'Zone A'),
              CivicSelectItem(value: 'b', label: 'Zone B'),
            ],
          );
      _expectMatrix(
        await _states(tester, {
          'rest': select,
          'focused': () => select(focus: true),
          'disabled': () => select(enabled: false),
        }),
      );
    });
  });

  group("the state matrix of 0.3's inputs", () {
    testWidgets('a chip', (tester) async {
      Widget chip({bool on = false, bool enabled = true, bool focus = false}) =>
          CivicChip(
            key: _part,
            label: 'Open now',
            selected: on,
            onSelected: enabled ? (_) {} : null,
            autofocus: focus,
          );
      _expectMatrix(
        await _states(tester, {
          'rest': chip,
          'selected': () => chip(on: true),
          'focused': () => chip(focus: true),
          'disabled': () => chip(enabled: false),
        }),
      );
    });

    testWidgets('a toggle group', (tester) async {
      Widget group({
        Set<String> on = const {},
        bool enabled = true,
        bool error = false,
      }) => CivicToggleGroup<String>(
        key: _part,
        segments: const [
          CivicSegment(value: 'a', label: 'Drafts'),
          CivicSegment(value: 'b', label: 'Sent'),
        ],
        selected: on,
        onSelectionChanged: enabled ? (_) {} : null,
        errorText: error ? 'Choose what to show' : null,
      );
      final looks = await _states(tester, {
        'rest': group,
        'selected': () => group(on: {'a'}),
        'disabled': () => group(enabled: false),
      });
      _expectMatrix(looks);
    });

    testWidgets('a text area', (tester) async {
      Widget area({
        bool enabled = true,
        bool error = false,
        bool focus = false,
      }) => CivicTextArea(
        key: _part,
        labelText: 'Why do you need a permit?',
        maxLength: 200,
        enabled: enabled,
        errorText: error ? 'Say why you need a permit' : null,
        autofocus: focus,
      );
      final looks = await _states(tester, {
        'rest': area,
        'focused': () => area(focus: true),
        'disabled': () => area(enabled: false),
      });
      _expectMatrix(looks);
    });

    testWidgets('a code field', (tester) async {
      Widget code({bool enabled = true, bool focus = false}) => CivicCodeField(
        key: _part,
        labelText: 'Security code',
        enabled: enabled,
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': code,
          'focused': () => code(focus: true),
          'disabled': () => code(enabled: false),
        }),
      );
    });

    testWidgets('a number field', (tester) async {
      Widget number({bool enabled = true, bool focus = false}) =>
          CivicNumberField(
            key: _part,
            labelText: 'Visitor days',
            value: 3,
            min: 1,
            max: 30,
            onChanged: enabled ? (_) {} : null,
            autofocus: focus,
          );
      _expectMatrix(
        await _states(tester, {
          'rest': number,
          'focused': () => number(focus: true),
          'disabled': () => number(enabled: false),
        }),
      );
    });

    testWidgets('a slider', (tester) async {
      Widget slider({bool enabled = true, bool focus = false}) => CivicSlider(
        key: _part,
        labelText: 'Text size',
        value: 150,
        min: 100,
        max: 200,
        onChanged: enabled ? (_) {} : null,
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': slider,
          'focused': () => slider(focus: true),
          'disabled': () => slider(enabled: false),
        }),
      );
    });

    testWidgets('a rating: the focus on the mark the keys move', (
      tester,
    ) async {
      Widget rating({bool enabled = true, bool focus = false}) => CivicRating(
        key: _part,
        labelText: 'How easy was it?',
        value: 3,
        onChanged: enabled ? (_) {} : null,
        autofocus: focus,
      );
      _expectMatrix(
        await _states(tester, {
          'rest': rating,
          'focused': () => rating(focus: true),
          'disabled': () => rating(enabled: false),
        }),
      );
    });

    testWidgets('a date picker', (tester) async {
      Widget date({bool enabled = true, bool focus = false}) => CivicDatePicker(
        key: _part,
        labelText: 'Start date',
        value: DateTime(2026, 11, 24),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: enabled ? (_) {} : null,
        autofocus: focus,
      );
      // (The error's words stand over the well, so its error look is the
      // text field's, held there.)
      _expectMatrix(
        await _states(tester, {
          'rest': date,
          'focused': () => date(focus: true),
          'disabled': () => date(enabled: false),
        }),
      );
    });

    testWidgets('a wheel picker', (tester) async {
      Widget wheel({bool enabled = true, bool focus = false}) =>
          CivicWheelPicker(
            key: _part,
            labelText: 'Hour',
            columns: (_) => [
              RawPickerColumn(itemCount: 24, itemLabel: (i) => '$i'),
            ],
            selection: const [9],
            onChanged: enabled ? (_) {} : null,
            autofocus: focus,
          );
      _expectMatrix(
        await _states(tester, {
          'rest': wheel,
          'focused': () => wheel(focus: true),
          'disabled': () => wheel(enabled: false),
        }),
      );
    });
  });

  group("the state matrix of 0.3's containers", () {
    testWidgets('a card that is a link', (tester) async {
      Widget card([WidgetState? state]) => CivicCard(
        key: _part,
        title: 'Resident permit',
        onPressed: _none,
        url: Uri.parse('/permits/resident'),
        statesController: state == null ? null : _with(state),
        child: const Text('Valid until 31 March'),
      );
      _expectMatrix(
        await _states(tester, {
          'rest': card,
          'hovered': () => card(WidgetState.hovered),
          'pressed': () => card(WidgetState.pressed),
          'focused': () => card(WidgetState.focused),
        }),
      );
    });

    testWidgets('an accordion section, shut and open', (tester) async {
      Widget accordion({bool open = false}) => CivicAccordion(
        key: _part,
        sections: const [
          CivicAccordionSection(
            title: 'Who can apply',
            child: Text('Residents of the zone'),
          ),
        ],
        expanded: open ? const {0} : const {},
        onExpandedChanged: (_) {},
      );
      final looks = await _states(tester, {
        'shut': accordion,
        'open': () => accordion(open: true),
      });
      // Open, the section shows its words: it grows, as it should.
      expect(
        listEquals(looks['shut']!.$2, looks['open']!.$2),
        isFalse,
        reason: 'open looks different from shut',
      );
    });

    testWidgets('a tree row', (tester) async {
      Widget tree({bool selected = false}) {
        final c = DesignTreeController<String>(
          roots: const ['Parking', 'Bins'],
          childrenOf: (_) => const [],
        );
        addTearDown(c.dispose);
        if (selected) c.select('Parking');
        return CivicTree<String>(key: _part, controller: c, labelOf: (s) => s);
      }

      _expectMatrix(
        await _states(tester, {
          'rest': tree,
          'selected': () => tree(selected: true),
        }),
      );
    });
  });

  group('motion', () {
    testWidgets('a press moves on a spring: a frame in, it stands between', (
      tester,
    ) async {
      final c = WidgetStatesController();
      addTearDown(c.dispose);
      Widget button() => CivicButton(
        key: _part,
        onPressed: _none,
        statesController: c,
        child: const Text('Continue'),
      );
      await _pump(tester, button());
      await tester.pumpAndSettle();
      final rest = await _picture(tester);
      c.update(WidgetState.pressed, true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final between = await _picture(tester);
      await tester.pumpAndSettle();
      final pressed = await _picture(tester);
      expect(listEquals(rest, pressed), isFalse);
      expect(listEquals(between, rest), isFalse, reason: 'it has moved');
      expect(listEquals(between, pressed), isFalse, reason: 'not yet there');
    });

    testWidgets('a focus arrives on a spring too', (tester) async {
      final c = WidgetStatesController();
      addTearDown(c.dispose);
      await _pump(
        tester,
        CivicLink(
          key: _part,
          onPressed: _none,
          statesController: c,
          child: const Text('Change your address'),
        ),
      );
      await tester.pumpAndSettle();
      final rest = await _picture(tester);
      c.update(WidgetState.focused, true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final between = await _picture(tester);
      await tester.pumpAndSettle();
      final focused = await _picture(tester);
      expect(listEquals(between, rest), isFalse);
      expect(listEquals(between, focused), isFalse);
    });

    testWidgets("a rating's focus arrives on a spring", (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      await _pump(
        tester,
        CivicRating(key: _part, value: 2, focusNode: node, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      final rest = await _picture(tester);
      node.requestFocus();
      // The focus lands a frame later than a state set on a controller.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final between = await _picture(tester);
      await tester.pumpAndSettle();
      final focused = await _picture(tester);
      expect(listEquals(between, rest), isFalse, reason: 'it has moved');
      expect(listEquals(between, focused), isFalse, reason: 'not yet there');
    });

    testWidgets('a check settles within half a second', (tester) async {
      var value = false;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => CivicCheckbox(
            key: _part,
            value: value,
            onChanged: (v) => setState(() => value = v ?? false),
            labelText: 'Email me a reminder',
          ),
        ),
      );
      await tester.tap(find.byKey(_part));
      // Frame by frame, as a screen runs it: the press shows for its least
      // time, then the halo and the tick settle.
      for (var t = 0; t < 500; t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
