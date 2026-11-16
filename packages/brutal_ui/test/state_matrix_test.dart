// Every part a person acts on, in each state it has: idle, hovered, pressed,
// focused from the keyboard, selected, disabled and in error, by day and by
// night, at twice the size. Each is a golden (the state matrix the design
// review reads); hovered must paint as idle does, but where a pointer
// shows something on purpose (a rating's preview).
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

/// The goldens are kept beside the catalog and laid here by the package
/// build; a published or vendored copy goes without them, and compares
/// nothing.
final bool _recorded =
    autoUpdateGoldenFiles || Directory('test/goldens').existsSync();

const _all = {
  'idle',
  'hovered',
  'pressed',
  'focused',
  'selected',
  'disabled',
  'error',
};

typedef _Build = Widget Function(bool selected, bool disabled, bool error);

class _Part {
  const _Part(
    this.name,
    this.build, {
    this.states = const {'idle', 'hovered', 'pressed', 'focused', 'disabled'},
    this.target,
    this.tabs = 1,
    this.width,
  });

  final String name;
  final _Build build;
  final Set<String> states;

  /// The cell the pointer goes to, else the part's middle.
  final Finder Function()? target;

  /// How many Tabs bring the keyboard to it.
  final int tabs;
  final double? width;
}

void _none() {}

final _parts = <_Part>[
  _Part(
    'Button',
    (s, d, e) => BrutalButton('Share', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, filled',
    (s, d, e) =>
        BrutalButton.filled('Buy tickets', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, text',
    (s, d, e) => BrutalButton.text('Later', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, destructive',
    (s, d, e) => BrutalButton(
      'Cancel tickets',
      isDestructiveAction: true,
      onPressed: d ? null : _none,
    ),
  ),
  _Part(
    'Icon button',
    (s, d, e) => BrutalIconButton(
      icon: const Icon(LucideIcons.heart),
      tooltip: 'Save',
      selected: s,
      onPressed: d ? null : _none,
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Link',
    (s, d, e) => BrutalLink('See all', onPressed: d ? null : _none),
  ),
  _Part(
    'Checkbox',
    (s, d, e) => BrutalCheckbox(
      value: s,
      isError: e,
      semanticLabel: 'Free events only',
      onChanged: d ? null : (_) {},
    ),
    states: _all,
  ),
  _Part(
    'Radio',
    (s, d, e) => BrutalRadio<int>(
      value: 1,
      groupValue: s ? 1 : 0,
      semanticLabel: 'Card',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Switch',
    (s, d, e) => BrutalSwitch(
      value: s,
      semanticLabel: 'Reminders',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Chip',
    (s, d, e) =>
        BrutalChip(label: 'Music', selected: s, onSelected: d ? null : (_) {}),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Segmented button',
    (s, d, e) => BrutalSegmentedButton<String>(
      segments: const [
        BrutalSegment(value: 'all', label: 'All'),
        BrutalSegment(value: 'talks', label: 'Talks'),
        BrutalSegment(value: 'film', label: 'Film'),
      ],
      expand: false,
      value: s ? 'talks' : 'all',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
    target: () => find.text('Talks'),
    tabs: 2,
  ),
  _Part(
    'Tab bar',
    (s, d, e) => BrutalTabBar(
      tabs: const ['Upcoming', 'Past'],
      selectedIndex: s ? 1 : 0,
      onSelected: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('Past'),
    tabs: 2,
    width: 320,
  ),
  _Part(
    'Navigation bar',
    (s, d, e) => BrutalNavigationBar(
      destinations: const [
        BrutalDestination(icon: LucideIcons.house, label: 'Home'),
        BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
        BrutalDestination(icon: LucideIcons.settings, label: 'Settings'),
      ],
      selectedIndex: s ? 1 : 0,
      onSelected: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    // The bar draws its labels in capitals.
    target: () => find.text('TICKETS'),
    tabs: 2,
    width: 360,
  ),
  _Part(
    'List row',
    (s, d, e) => BrutalListGroup(
      children: [
        BrutalListTile(
          title: 'Standing',
          subtitle: 'Hall 4',
          trailingText: '6 left',
          showChevron: true,
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
    'Block',
    (s, d, e) => BrutalBlock(
      onTap: d ? null : _none,
      child: const Text('Tonight: Low Tide, Hall 4'),
    ),
    width: 280,
  ),
  _Part(
    'Disclosure',
    (s, d, e) => BrutalDisclosure(
      title: 'Refunds',
      expanded: s,
      onChanged: d ? null : (_) {},
      child: const Text('Up to a day before the doors open.'),
    ),
    states: _all.difference({'error'}),
    width: 320,
  ),
  _Part(
    'Text field',
    (s, d, e) => BrutalTextField(
      label: 'Email',
      hint: 'name@example.com',
      error: e ? 'Enter an email with an @.' : null,
      enabled: !d,
      onChanged: (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 320,
  ),
  _Part(
    'Search field',
    (s, d, e) => BrutalSearchField(
      hint: 'Search the week',
      enabled: !d,
      onChanged: (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled'},
    width: 320,
  ),
  _Part(
    'Select',
    (s, d, e) => BrutalSelect<String>(
      label: 'Seat',
      value: 'standing',
      error: e ? 'Pick a seat.' : null,
      items: const [
        BrutalSelectItem(value: 'standing', label: 'Standing'),
        BrutalSelectItem(value: 'balcony', label: 'Balcony'),
      ],
      onChanged: d ? null : (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 320,
  ),
  _Part(
    'Slider',
    (s, d, e) => BrutalSlider(
      value: 0.4,
      semanticLabel: 'Volume',
      onChanged: d ? null : (_) {},
    ),
    width: 320,
  ),
  _Part(
    'Stepper',
    (s, d, e) => BrutalStepper(
      value: 2,
      max: 8,
      semanticLabel: 'Tickets',
      onChanged: d ? null : (_) {},
    ),
    target: () => find.byIcon(LucideIcons.plus),
    tabs: 2,
  ),
  _Part(
    'Rating',
    (s, d, e) => BrutalRating(
      value: 3,
      semanticLabel: 'Your rating',
      onChanged: d ? null : (_) {},
    ),
  ),
  _Part(
    'Pagination',
    (s, d, e) =>
        BrutalPagination(page: 2, pageCount: 5, onChanged: d ? null : (_) {}),
    target: () => find.text('3'),
    width: 360,
  ),
];

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
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

void main() {
  setUpAll(_loadFonts);
  for (final part in _parts) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${part.name} by ${brightness.name}: each state matches its golden',
        (tester) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(480 * 2, 260 * 2);
          addTearDown(tester.view.reset);
          for (final state in _all.where(part.states.contains)) {
            final specimen = part.build(
              state == 'selected',
              state == 'disabled',
              state == 'error',
            );
            await tester.pumpWidget(
              kitApp(
                brightness: brightness,
                home: Builder(
                  builder: (context) => ColoredBox(
                    color: context.brutalTheme.colors.paper,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: RepaintBoundary(
                        key: _stage,
                        child: ColoredBox(
                          color: context.brutalTheme.colors.paper,
                          child: Padding(
                            padding: const EdgeInsets.all(BrutalSpacing.large),
                            child: SizedBox(
                              width: part.width,
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                widthFactor: part.width == null ? 1 : null,
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
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final whole = find.byKey(_stage);
            final at = part.target == null
                ? tester.getCenter(
                    find
                        .descendant(of: whole, matching: find.byType(Padding))
                        .first,
                  )
                : tester.getCenter(
                    find.descendant(of: whole, matching: part.target!()).first,
                  );
            TestGesture? held;
            TestGesture? mouse;
            switch (state) {
              case 'hovered':
                mouse = await tester.createGesture(
                  kind: PointerDeviceKind.mouse,
                );
                await mouse.addPointer(location: Offset.zero);
                await mouse.moveTo(at);
                await tester.pumpAndSettle();
              case 'pressed':
                held = await tester.startGesture(at);
                await tester.pump(const Duration(milliseconds: 400));
              case 'focused':
                for (var i = 0; i < part.tabs; i++) {
                  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                }
                await tester.pumpAndSettle();
            }
            await expectLater(
              whole,
              matchesGoldenFile(
                'goldens/states/${_slug(part.name)}/${state}_${brightness.name}.png',
              ),
            );
            expect(tester.takeException(), isNull, reason: state);
            if (held != null) {
              // Slid off before letting go: a held press that leaves does
              // not act.
              await held.moveTo(const Offset(470, 250));
              await held.up();
            }
            if (mouse != null) await mouse.removePointer();
            await tester.pumpAndSettle();
          }
          // Leave nothing running: a tooltip's timer.
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 3));
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
        // leaves them out elsewhere.
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}
