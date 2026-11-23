// The state matrix, on what is painted: for every pressable part, by day and
// by night, a pointer over it changes nothing but the cursor (Keycap's
// keys show no hover: a key is pressed or not); pressing, keyboard focus and
// disabling each change the face; and none of them moves the part by a
// pixel. A field's focus and error mark its well, hover leaves it. Each
// part at rest, held, focused and disabled is also a golden, at twice the
// size.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _frame = ValueKey('frame');

void _none() {}

typedef _Spec = ({String name, Widget Function(bool enabled) build});

final _specs = <_Spec>[
  (
    name: 'button',
    build: (on) =>
        KeycapButton(onPressed: on ? _none : null, child: const Text('Save')),
  ),
  (
    name: 'accent button',
    build: (on) => KeycapButton.accent(
      onPressed: on ? _none : null,
      child: const Text('Save'),
    ),
  ),
  (
    name: 'modifier button',
    build: (on) => KeycapButton.modifier(
      onPressed: on ? _none : null,
      child: const Text('Shift'),
    ),
  ),
  (
    name: 'text button',
    build: (on) => KeycapButton.text(
      onPressed: on ? _none : null,
      child: const Text('Skip'),
    ),
  ),
  (
    name: 'icon button',
    build: (on) => KeycapIconButton(
      icon: const Icon(LucideIcons.pin),
      semanticLabel: 'Pin',
      onPressed: on ? _none : null,
    ),
  ),
  (
    name: 'link',
    build: (on) => KeycapLink(
      onPressed: on ? _none : null,
      child: const Text('Formatting help'),
    ),
  ),
  (
    name: 'split button',
    build: (on) => KeycapSplitButton(
      label: 'Export',
      onPressed: on ? _none : null,
      menuLabel: 'More ways to export',
      actions: const [RawSplitAction(label: 'Export as PDF', onPressed: _none)],
    ),
  ),
  (
    name: 'checkbox',
    build: (on) => KeycapCheckbox(
      value: false,
      semanticLabel: 'Sow the beans',
      onChanged: on ? (_) {} : null,
    ),
  ),
  (
    name: 'radio',
    build: (on) => KeycapRadio<String>(
      value: 'a',
      groupValue: 'b',
      semanticLabel: 'List',
      onChanged: on ? (_) {} : null,
    ),
  ),
  (
    name: 'switch',
    build: (on) => KeycapSwitch(
      value: true,
      semanticLabel: 'Sync',
      onChanged: on ? (_) {} : null,
    ),
  ),
  (
    name: 'chip',
    build: (on) => KeycapChip('Pinned', enabled: on, onSelected: (_) {}),
  ),
  (
    name: 'list row',
    build: (on) => SizedBox(
      width: 320,
      child: KeycapListGroup(
        children: [
          KeycapListTile(
            title: 'Save drafts',
            value: 'Every minute',
            onTap: on ? _none : null,
          ),
        ],
      ),
    ),
  ),
  (
    name: 'select',
    build: (on) => SizedBox(
      width: 280,
      child: KeycapSelect<String>(
        labelText: 'Sort by',
        items: const [
          KeycapSelectItem(value: 'edited', label: 'Last edited'),
          KeycapSelectItem(value: 'title', label: 'Title'),
        ],
        value: 'edited',
        onChanged: on ? (_) {} : null,
      ),
    ),
  ),
  (
    name: 'segmented',
    build: (on) => KeycapSegmentedButton<String>(
      segments: const [
        KeycapSegment(value: 'a', label: 'All'),
        KeycapSegment(value: 'b', label: 'Drafts'),
        KeycapSegment(value: 'c', label: 'Pinned'),
      ],
      selected: const {'b'},
      onSelectionChanged: on ? (_) {} : null,
    ),
  ),
  (
    name: 'toggle group',
    build: (on) => KeycapToggleGroup<String>(
      options: [
        KeycapToggleOption(value: 'b', label: 'Bold', enabled: on),
        KeycapToggleOption(value: 'i', label: 'Italic', enabled: on),
      ],
      selected: const {'i'},
      onSelectionChanged: (_) {},
    ),
  ),
];

Widget _app(Brightness brightness, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => KeycapHost(brightness: brightness, child: app!),
  home: KeycapScreen(
    body: Align(
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        key: _frame,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Compare saved images when they are available, or record them when
/// requested.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

/// The first thing in the frame that presses: its face, not its label.
Finder _presses() => find
    .descendant(
      of: find.byKey(_frame),
      matching: find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
      ),
    )
    .first;

/// The part under the frame's padding.
Finder _part() => find
    .descendant(of: find.byKey(_frame), matching: find.byType(Padding))
    .first;

Size _size(WidgetTester tester) => tester.getSize(_part());

void main() {
  for (final brightness in Brightness.values) {
    for (final spec in _specs) {
      testWidgets('${spec.name} (${brightness.name}): hover changes nothing; '
          'press, focus and disabled do; nothing moves', (tester) async {
        tester.view.physicalSize = const Size(480, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );

        await tester.pumpWidget(_app(brightness, spec.build(true)));
        await _settle(tester);
        final idle = await _pixels(tester);
        final size = _size(tester);
        final centre = tester.getCenter(_presses());

        // A pointer over it: the cursor says it presses; the face stays.
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          pointer: 1,
        );
        await mouse.addPointer(location: const Offset(1, 1));
        await mouse.moveTo(centre);
        await _settle(tester);
        expect(
          await _pixels(tester),
          idle,
          reason: '${spec.name} lit on hover',
        );
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.click,
        );
        expect(_size(tester), size);

        // Pressed: it goes down.
        await mouse.down(centre);
        await _settle(tester);
        expect(
          await _pixels(tester),
          isNot(idle),
          reason: 'pressing it changed nothing',
        );
        expect(_size(tester), size, reason: 'pressing it moved it');
        await mouse.up();
        await mouse.moveTo(const Offset(1, 1));
        await mouse.removePointer();
        // The press may have chosen or toggled (or opened a menu); let it
        // settle, then idle again by a fresh build.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_app(brightness, spec.build(true)));
        await _settle(tester);
        expect(await _pixels(tester), idle);

        // Keyboard focus shows, and keeps the part in place.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _settle(tester);
        expect(
          await _pixels(tester),
          isNot(idle),
          reason: 'keyboard focus showed nothing',
        );
        expect(_size(tester), size, reason: 'keyboard focus moved it');

        // Disabled: it looks it, at the same size.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_app(brightness, spec.build(false)));
        await _settle(tester);
        expect(
          await _pixels(tester),
          isNot(idle),
          reason: 'disabled looks enabled',
        );
        expect(_size(tester), size, reason: 'disabling it moved it');
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a field marks focus and error in its well, not hover, '
        'in ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(480, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget field({String? error, bool enabled = true}) => SizedBox(
        width: 320,
        child: KeycapTextField(
          labelText: 'Folder name',
          helperText: error == null ? 'Shown in the sidebar' : null,
          errorText: error,
          enabled: enabled,
        ),
      );
      await tester.pumpWidget(_app(brightness, field()));
      await _settle(tester);
      final idle = await _pixels(tester);
      final size = _size(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(find.byType(EditableText)));
      await _settle(tester);
      expect(await _pixels(tester), idle, reason: 'the well lit on hover');
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text,
      );
      await mouse.removePointer();

      await tester.showKeyboard(find.byType(EditableText));
      await _settle(tester);
      expect(await _pixels(tester), isNot(idle));
      expect(_size(tester), size);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _app(brightness, field(error: 'Name the folder')),
      );
      await _settle(tester);
      expect(await _pixels(tester), isNot(idle));
      expect(_size(tester), size, reason: 'the error message moved the page');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(brightness, field(enabled: false)));
      await _settle(tester);
      expect(await _pixels(tester), isNot(idle));
      expect(_size(tester), size);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final brightness in Brightness.values) {
    for (final spec in _specs) {
      testWidgets(
        '${spec.name} (${brightness.name}): each state matches its golden',
        (tester) async {
          tester.view.physicalSize = const Size(480 * 2, 400 * 2);
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
          Future<void> shot(String state) => expectLater(
            find.byKey(_frame),
            matchesGoldenFile(
              'goldens/states/${_slug(spec.name)}/'
              '${state}_${brightness.name}.png',
            ),
          );

          await tester.pumpWidget(_app(brightness, spec.build(true)));
          await _settle(tester);
          await shot('rest');

          // Held by a finger, then slid off before letting go (a press that
          // leaves does not act).
          final held = await tester.startGesture(tester.getCenter(_presses()));
          await _settle(tester);
          await shot('pressed');
          await held.moveTo(const Offset(470, 390));
          await held.up();

          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_app(brightness, spec.build(true)));
          await _settle(tester);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await _settle(tester);
          await shot('focused');

          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_app(brightness, spec.build(false)));
          await _settle(tester);
          await shot('disabled');
          await tester.pumpWidget(const SizedBox());
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
        // leaves them out elsewhere.
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}
