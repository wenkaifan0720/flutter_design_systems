// The behaviour law, run over a table of parts by behaviour_test.dart (the package's parts) and by the source's own
// test of the parts the package leaves out (the page patterns and the sign-in buttons). Every part that takes a
// callback is enumerated from the source, so a new one fails until it is named in a table. Each one: Tab reaches it,
// its focus ring paints, Enter and Space press it, with no callback it takes no focus and its face is told it is
// disabled, a hover reaches its face's states, and with animations disabled nothing it does leaves a running
// animation. Each part lays out with no exception at 390, 768, 1024 and 1440, at text scale 2.0 and right to left.
library;

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

/// One interactive part: [build] wires its main callback to `hit`, or none when `hit` is null.
class LawPart {
  const LawPart(
    this.build, {
    this.keys = true,
    this.focus = true,
    this.pressable = true,
    this.disables = true,
  });
  final Widget Function(VoidCallback? hit) build;

  /// Enter and Space on its first focus stop call its main callback.
  final bool keys;

  /// Tab stops on it. False for a part that takes no focus by design.
  final bool focus;

  /// It stands on the design kit's pressable, so its face is handed the states.
  final bool pressable;

  /// With no callback it takes no focus (a text field still takes text).
  final bool disables;
}

/// [hit] as a value callback that ignores its value.
ValueChanged<T>? lawOn<T>(VoidCallback? hit) =>
    hit == null ? null : (_) => hit();

/// A text field: Tab reaches it, and it takes text with or without a callback.
LawPart lawText(Widget Function(VoidCallback? hit) build) =>
    LawPart(build, keys: false, pressable: false, disables: false);

/// Whether [path] (a library file) holds a part the package leaves out: the page patterns, which are the app's, and
/// the sign-in buttons, which draw vendor marks.
bool lawLeftOut(String path) =>
    path.contains('/patterns/') || path.contains('/sign_in/');

/// Parts that take a callback but are not placed by a page (the plumbing of a part in the table), or that only hold one.
const _notPlaced = {
  'Fluent2Account',
  'Fluent2FieldButton',
  'Fluent2FieldEditor',
  'Fluent2FieldPopover',
  'Fluent2KeyFocus',
  'Fluent2OptionRow',
  'Fluent2SheetShell',
  // A split button's menu choice, data the button lays out (the button is in the table).
  'Fluent2SplitAction',
};

/// Public parts that take a callback, read from the library files [reads] picks.
Set<String> _interactive(bool Function(String path) reads) {
  final found = <String>{};
  final cls = RegExp(
    r'^class (Fluent2\w+)[^{]*\{(.*?)^\}',
    multiLine: true,
    dotAll: true,
  );
  final cb = RegExp(
    r'final (?:VoidCallback|ValueChanged<[^>]+>|void Function\([^)]*\))\? \w+',
  );
  for (final file in Directory(
    'lib/src/fluent2_design',
  ).listSync(recursive: true).whereType<File>()) {
    final path = file.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart') || path.contains('/kit_parts/')) continue;
    if (!reads(path)) continue;
    for (final m in cls.allMatches(file.readAsStringSync())) {
      if (cb.hasMatch(m[2]!)) found.add(m[1]!);
    }
  }
  return found.difference(_notPlaced);
}

Widget _host(
  Widget child, {
  bool still = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: still, textScaler: TextScaler.linear(scale)),
    child: Fluent2Host(
      brightness: Brightness.light,
      child: Directionality(textDirection: direction, child: page!),
    ),
  ),
  home: Material(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: KeyedSubtree(key: _part, child: child),
      ),
    ),
  ),
);

Future<void> _size(
  WidgetTester tester,
  double width, [
  double height = 1000,
]) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _part = ValueKey('part');

bool _focusInPart(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final part = find.byKey(_part).evaluate().single;
  var inside = false;
  focused.visitAncestorElements((e) {
    if (e == part) inside = true;
    return !inside;
  });
  return inside;
}

/// Every error a build reports, each with the library line of the widget that raised it, so a failure names its
/// place rather than only the first of several.
Future<List<String>> _faults(Future<void> Function() body) async {
  final seen = <String>[];
  final before = FlutterError.onError;
  FlutterError.onError = (d) {
    final at = RegExp(r'lib/src/[\w/]+\.dart:\d+')
        .firstMatch(d.toString())
        ?.group(0);
    seen.add(
      '${d.exceptionAsString().split('\n').first} (${at ?? 'no place'})',
    );
  };
  try {
    await body();
  } finally {
    FlutterError.onError = before;
  }
  return seen;
}

/// What the screen paints, as its paint record: a ring shows as calls that were not there before, whichever painter
/// draws it.
String _painters(WidgetTester tester) {
  final canvas = TestRecordingCanvas();
  final context = TestRecordingPaintingContext(canvas);
  tester.binding.renderViews.first.child!.paint(context, Offset.zero);
  final record = canvas.invocations.map((i) => '$i').join('\n');
  context.dispose();
  return record;
}

List<DesignPressableState> _pressables(WidgetTester tester) => tester
    .stateList<DesignPressableState>(find.byType(DesignPressable))
    .toList();

/// The law over [parts], which names every part that takes a callback in the library files [reads] picks.
void behaviourLaw(
  Map<String, LawPart> parts, {
  required bool Function(String path) reads,
}) {
  test('every part that takes a callback is named in the table', () {
    final found = _interactive(reads);
    expect(
      found.difference(parts.keys.toSet()),
      isEmpty,
      reason: 'a new control: add it to the table',
    );
    expect(
      parts.keys.toSet().difference(found),
      isEmpty,
      reason: 'gone from the library: take it out',
    );
  });

  for (final MapEntry(key: name, value: part) in parts.entries) {
    group(name, () {
      if (part.focus) {
        testWidgets(
          'Tab reaches it and its ring paints; Enter and Space press it',
          (tester) async {
            await _size(tester, 390);
            var hits = 0;
            await tester.pumpWidget(
              _host(part.build(() => hits++), still: true),
            );
            await tester.pump();
            FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.alwaysTraditional;
            addTearDown(
              () => FocusManager.instance.highlightStrategy =
                  FocusHighlightStrategy.automatic,
            );
            final unringed = _painters(tester);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            expect(
              _focusInPart(tester),
              isTrue,
              reason: 'Tab did not reach $name',
            );
            if (part.pressable) {
              expect(
                _pressables(tester)
                    .any((s) => s.states.contains(WidgetState.focused)),
                isTrue,
                reason: 'the focused press was not told to ring',
              );
              expect(
                _painters(tester),
                isNot(unringed),
                reason: 'no ring painted',
              );
            }
            if (part.keys) {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pump();
              final afterEnter = hits;
              expect(afterEnter, greaterThan(0), reason: 'Enter did nothing');
              if (_focusInPart(tester)) {
                await tester.sendKeyEvent(LogicalKeyboardKey.space);
                await tester.pump();
                expect(
                  hits,
                  greaterThan(afterEnter),
                  reason: 'Space did nothing',
                );
              }
            }
            await tester.pumpWidget(const SizedBox());
          },
        );
      }

      if (part.disables) {
        testWidgets('with no callback it takes no focus and its face is told', (
          tester,
        ) async {
          await _size(tester, 390);
          await tester.pumpWidget(_host(part.build(null), still: true));
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(
            _focusInPart(tester),
            isFalse,
            reason: 'a disabled $name took focus',
          );
          for (final s in _pressables(tester)) {
            expect(s.states, contains(WidgetState.disabled));
          }
        });
      }

      if (part.pressable) {
        testWidgets('a hover reaches its face', (tester) async {
          await _size(tester, 390);
          await tester.pumpWidget(_host(part.build(() {}), still: true));
          await tester.pump();
          final first = find.byType(DesignPressable).first;
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(tester.getCenter(first));
          await tester.pump();
          expect(
            tester.state<DesignPressableState>(first).states,
            contains(WidgetState.hovered),
          );
        });
      }

      testWidgets('with animations disabled a press leaves nothing running', (
        tester,
      ) async {
        await _size(tester, 390);
        await tester.pumpWidget(_host(part.build(() {}), still: true));
        await tester.pump();
        if (part.pressable) {
          await tester.tap(
            find.byType(DesignPressable).first,
            warnIfMissed: false,
          );
        }
        await tester.pump();
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.takeException(), isNull);
      });

      for (final width in const [390.0, 768.0, 1024.0, 1440.0]) {
        testWidgets('lays out at $width, at 2.0 text, and right to left', (
          tester,
        ) async {
          await _size(tester, width, 1400);
          expect(
            await _faults(() async {
              await tester.pumpWidget(_host(part.build(() {}), still: true));
              await tester.pump();
            }),
            isEmpty,
          );
          expect(
            await _faults(() async {
              await tester.pumpWidget(
                _host(part.build(() {}), still: true, scale: 2),
              );
              await tester.pump();
            }),
            isEmpty,
            reason: 'at 2.0 text',
          );
          expect(
            await _faults(() async {
              await tester.pumpWidget(
                _host(
                  part.build(() {}),
                  still: true,
                  direction: TextDirection.rtl,
                ),
              );
              await tester.pump();
            }),
            isEmpty,
            reason: 'right to left',
          );
        });
      }
    });
  }
}
