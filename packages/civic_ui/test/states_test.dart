// The state matrix (polish3 §1): each control's states (pressed, focused,
// disabled, selected, error) look different from its rest and from each
// other, and none changes its size, so nothing on the page moves when a
// state comes or goes. And motion (design6 O): a state change moves on a
// spring, so a frame after the change stands between the two looks.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/foundation.dart';
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
