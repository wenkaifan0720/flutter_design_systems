// Every part a person acts on, in each state it has: idle, hovered, pressed,
// focused from the keyboard, selected, disabled and in error, by day and by
// night, at twice the size. Each state keeps the part's size (but for an
// error, whose message takes a line under the part). Hover gives a part with
// a lamp, a legend or an index its faintest light and leaves the rest as
// idle; every other state paints differently from idle, so a press, the
// focus light, a latch, a disabled face and an error can each be seen.
//
// Each cell is also a golden (test/goldens/states/<part>/<state>_<brightness>
// .png), tagged `goldens`. With STATE_MATRIX_OUT set to a directory, each
// cell is also written there as <part>/<state>_<brightness>.png.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

const _all = {
  'idle',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
  'error',
};

const _press = {'idle', 'hovered', 'pressed', 'focused', 'disabled'};

typedef _Build = Widget Function(bool selected, bool disabled, bool error);

class _Part {
  const _Part(
    this.name,
    this.build, {
    this.states = _press,
    this.target,
    this.width,
  });

  final String name;
  final _Build build;
  final Set<String> states;

  /// The cell the pointer goes to, else the part's middle.
  final Finder Function()? target;

  /// The width it stands in, else its own.
  final double? width;
}

void _none() {}

final _parts = <_Part>[
  _Part('Key', (s, d, e) => StudioButton('Save', onPressed: d ? null : _none)),
  _Part(
    'Key, lit',
    (s, d, e) => StudioButton.lit('Publish', onPressed: d ? null : _none),
  ),
  _Part(
    'Key, capless',
    (s, d, e) => StudioButton.text('Later', onPressed: d ? null : _none),
  ),
  _Part(
    'Key, destructive',
    (s, d, e) => StudioButton(
      'Discard',
      isDestructiveAction: true,
      onPressed: d ? null : _none,
    ),
  ),
  _Part(
    'Icon key',
    (s, d, e) => StudioIconButton(
      icon: const Icon(LucideIcons.heart),
      tooltip: 'Save',
      selected: s,
      onPressed: d ? null : _none,
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Transport key',
    (s, d, e) => StudioTransportKey(
      icon: const Icon(LucideIcons.play),
      tooltip: 'Play',
      lit: s,
      onPressed: d ? null : _none,
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Floating key',
    (s, d, e) => StudioFloatingKey(
      icon: const Icon(LucideIcons.mic),
      tooltip: 'Record',
      onPressed: d ? null : _none,
    ),
  ),
  _Part(
    'Link',
    (s, d, e) => StudioLink('Show notes', onPressed: d ? null : _none),
  ),
  _Part(
    'Checkbox',
    (s, d, e) => StudioCheckbox(
      value: s,
      isError: e,
      semanticLabel: 'Explicit',
      onChanged: d ? null : (_) {},
    ),
    states: _all,
  ),
  _Part(
    'Radio',
    (s, d, e) => StudioRadio<int>(
      value: 1,
      groupValue: s ? 1 : 0,
      semanticLabel: 'Stereo',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Switch',
    (s, d, e) => StudioSwitch(
      value: s,
      semanticLabel: 'Auto-download',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Chip',
    (s, d, e) => StudioChip(
      label: 'Interviews',
      selected: s,
      enabled: !d,
      onSelected: (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Segmented',
    (s, d, e) => StudioSegmentedButton<int>(
      semanticLabel: 'Speed',
      segments: const [
        StudioSegment(value: 0, label: '1×'),
        StudioSegment(value: 1, label: '1.5×'),
        StudioSegment(value: 2, label: '2×'),
      ],
      value: s ? 1 : 0,
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
    target: () => find.text('1.5×'),
  ),
  _Part(
    'Toggle bank',
    (s, d, e) => StudioToggleBank<String>(
      semanticLabel: 'Channel',
      options: const ['Mute', 'Solo', 'Arm'],
      selected: s ? const {'Solo'} : const {},
      labelOf: (o) => o,
      onSelectionChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
    target: () => find.text('Solo'),
  ),
  _Part(
    'Tabs',
    (s, d, e) => StudioTabBar(
      tabs: const ['Episodes', 'About', 'Clips'],
      selectedIndex: s ? 1 : 0,
      onChanged: (_) {},
    ),
    states: const {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('About'),
    width: 360,
  ),
  _Part(
    'Fader',
    (s, d, e) => StudioFader(
      value: 0.4,
      semanticLabel: 'Volume',
      onChanged: d ? null : (_) {},
    ),
    width: 280,
  ),
  _Part(
    'Knob',
    (s, d, e) => StudioKnob(
      value: 0.5,
      semanticLabel: 'Monitor',
      onChanged: d ? null : (_) {},
    ),
  ),
  _Part(
    'Text field',
    (s, d, e) => StudioTextField(
      label: 'Title',
      hint: 'Name the episode',
      enabled: !d,
      error: e ? 'Give the episode a title.' : null,
    ),
    states: const {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 320,
  ),
  _Part(
    'Select',
    (s, d, e) => StudioSelect<String>(
      label: 'Quality',
      value: 'High',
      error: e ? 'Choose one the feed allows.' : null,
      items: const [
        StudioSelectItem(value: 'Standard', label: 'Standard'),
        StudioSelectItem(value: 'High', label: 'High'),
      ],
      onChanged: d ? null : (_) {},
    ),
    states: _press.union({'error'}),
    width: 320,
  ),
  _Part(
    'Stepper',
    (s, d, e) => StudioStepper(
      value: 2,
      semanticLabel: 'Takes',
      onChanged: d ? null : (_) {},
    ),
    target: () => find.byIcon(LucideIcons.plus),
  ),
  _Part(
    'List row',
    (s, d, e) => StudioListGroup(
      children: [
        StudioListTile(
          title: 'Downloads',
          selected: s,
          enabled: !d,
          onTap: _none,
        ),
      ],
    ),
    states: _all.difference({'error'}),
    width: 320,
  ),
  _Part(
    'Rating',
    (s, d, e) => StudioRating(
      value: s ? 4 : 0,
      semanticLabel: 'Your rating',
      onChanged: d ? null : (_) {},
    ),
    // A pointer over the stars previews the score: hover shows on purpose.
    states: const {'idle', 'pressed', 'focused', 'selected', 'disabled'},
  ),
  _Part(
    'Calendar day',
    (s, d, e) => StudioCalendar(
      firstDate: DateTime(2026, 11),
      lastDate: DateTime(2026, 11, 30),
      currentDate: DateTime(2026, 11, 16),
      selectedDate: s ? DateTime(2026, 11, 20) : null,
      onDateChanged: (_) {},
    ),
    states: const {'idle', 'pressed', 'focused', 'selected'},
    target: () => find.text('20'),
    width: 328,
  ),
  _Part(
    'File drop',
    (s, d, e) => StudioFileDrop(
      label: 'Audio',
      hint: 'WAV or MP3',
      error: e ? 'That file is not audio.' : null,
      onChoose: d ? null : _none,
    ),
    states: _press.union({'error'}),
    target: () => find.text('Choose a file'),
    width: 320,
  ),
];

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : studioRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

String _slug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

const _stage = ValueKey('stage');

/// Compare saved images when they are available, or record them when requested.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

final String? _out = Platform.environment['STATE_MATRIX_OUT'];

// The stage's pixels at twice the size, and its PNG when one is wanted.
Future<(Size, Uint8List, Uint8List?)> _shoot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final raw = await image.toByteData();
      final png = _out == null
          ? null
          : await image.toByteData(format: ui.ImageByteFormat.png);
      return (
        boundary.size,
        raw!.buffer.asUint8List(),
        png?.buffer.asUint8List(),
      );
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  setUpAll(_loadFonts);
  for (final part in _parts) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${part.name} by ${brightness.name}: each state shows, at its size',
        (tester) => _matrix(tester, part, brightness, goldens: false),
      );
      testWidgets(
        '${part.name} by ${brightness.name}: each state matches its golden',
        (tester) => _matrix(tester, part, brightness, goldens: true),
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
        // leaves them out elsewhere.
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}

Future<void> _matrix(
  WidgetTester tester,
  _Part part,
  Brightness brightness, {
  required bool goldens,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(480 * 2, 520 * 2);
  addTearDown(tester.view.reset);
  Size? idleSize;
  Uint8List? idle;
  for (final state in _all.where(part.states.contains)) {
    final specimen = part.build(
      state == 'selected',
      state == 'disabled',
      state == 'error',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, page) => StudioTheme(
          data: brightness == Brightness.dark
              ? StudioThemeData.dark()
              : StudioThemeData.light(),
          child: page!,
        ),
        home: Builder(
          builder: (context) {
            final c = StudioTheme.of(context).colors;
            return ColoredBox(
              color: c.chassis,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: RepaintBoundary(
                  key: _stage,
                  child: ColoredBox(
                    color: c.chassis,
                    child: Padding(
                      padding: const EdgeInsets.all(StudioSpacing.large),
                      child: SizedBox(
                        width: part.width,
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          widthFactor: part.width == null ? 1 : null,
                          heightFactor: 1,
                          child: KeyedSubtree(
                            key: ValueKey('${part.name} $state'),
                            child: specimen,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final whole = find.byKey(_stage);
    final at = part.target == null
        ? tester.getCenter(
            find.descendant(of: whole, matching: find.byType(Padding)).first,
          )
        : tester.getCenter(
            find.descendant(of: whole, matching: part.target!()).first,
          );
    TestGesture? held;
    TestGesture? mouse;
    switch (state) {
      case 'hovered':
        // A pointer that hovers is a mouse, which a desktop shows hover
        // for; the test's default platform would start in touch mode.
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(at);
        await tester.pumpAndSettle();
      case 'pressed':
        held = await tester.startGesture(at);
        // The press lands after the tap's timeout, in the first pump;
        // the second lets its spring run.
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
      case 'focused':
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
    }
    if (goldens) {
      await expectLater(
        whole,
        matchesGoldenFile(
          'goldens/states/${_slug(part.name)}/${state}_${brightness.name}.png',
        ),
      );
    }
    final (size, pixels, png) = await _shoot(tester);
    expect(tester.takeException(), isNull, reason: state);
    final out = _out;
    if (out != null && png != null) {
      final file = File(
        '$out/${_slug(part.name)}/${state}_${brightness.name}.png',
      );
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(png);
    }
    if (state == 'idle') {
      idleSize = size;
      idle = pixels;
    } else {
      if (state == 'error') {
        expect(size.width, idleSize!.width, reason: 'error widened it');
      } else {
        expect(size, idleSize, reason: '$state changed the size');
      }
      final same = listEquals(pixels, idle);
      if (state == 'hovered') {
        const lights = {
          'Key',
          'Key, lit',
          'Key, capless',
          'Key, destructive',
          'Checkbox',
          'Radio',
          'Switch',
          'Chip',
          'Tabs',
          'Fader',
          'List row',
          // Its Choose a file key.
          'File drop',
        };
        expect(same, !lights.contains(part.name), reason: part.name);
      } else {
        expect(same, isFalse, reason: '$state paints as idle does');
      }
    }
    if (held != null) {
      // Slid off before letting go: a held press that leaves does
      // not act.
      await held.moveTo(const Offset(470, 510));
      await held.up();
    }
    if (mouse != null) {
      await mouse.removePointer();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    }
    await tester.pumpAndSettle();
  }
  // Leave nothing running: a tooltip's timer.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 3));
}
