// Captures each control's interaction states in both appearances.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:gloss_ui/gloss_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Compare against local baselines when they are available.
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
    (s, d, e) => GlossButton('Share', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, filled',
    (s, d, e) => GlossButton.filled('Cook this', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, text',
    (s, d, e) => GlossButton.text('Later', onPressed: d ? null : _none),
  ),
  _Part(
    'Button, destructive',
    (s, d, e) => GlossButton(
      'Delete the plan',
      isDestructiveAction: true,
      onPressed: d ? null : _none,
    ),
  ),
  _Part(
    'Icon button',
    (s, d, e) => GlossIconButton(
      icon: const Icon(LucideIcons.heart),
      tooltip: 'Save',
      isSelected: s,
      onPressed: d ? null : _none,
    ),
    states: _all.difference({'error'}),
  ),
  _Part('Link', (s, d, e) => GlossLink('See all', onPressed: d ? null : _none)),
  _Part(
    'Checkbox',
    (s, d, e) => GlossCheckbox(
      value: s,
      isError: e,
      semanticLabel: 'Bought',
      onChanged: d ? null : (_) {},
    ),
    states: _all,
  ),
  _Part(
    'Radio',
    (s, d, e) => GlossRadio<int>(
      value: 1,
      groupValue: s ? 1 : 0,
      semanticLabel: 'Dinner',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Switch',
    (s, d, e) => GlossSwitch(
      value: s,
      semanticLabel: 'Reminders',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Chip',
    (s, d, e) =>
        GlossChip(label: 'Quick', selected: s, onSelected: d ? null : (_) {}),
    states: _all.difference({'error'}),
  ),
  _Part(
    'Segmented button',
    (s, d, e) => GlossSegmentedButton<String>(
      segments: const [
        GlossSegment(value: 'day', label: 'Day'),
        GlossSegment(value: 'week', label: 'Week'),
        GlossSegment(value: 'month', label: 'Month'),
      ],
      expanded: false,
      selected: s ? 'week' : 'day',
      onChanged: d ? null : (_) {},
    ),
    states: _all.difference({'error'}),
    target: () => find.text('Week'),
    tabs: 2,
  ),
  _Part(
    'Toggle group',
    (s, d, e) => GlossToggleGroup<String>(
      semanticLabel: 'Diet',
      toggles: [
        GlossToggle(value: 'veg', label: 'Vegetarian', enabled: !d),
        GlossToggle(value: 'gf', label: 'Gluten-free', enabled: !d),
      ],
      selected: s ? const {'veg'} : const {},
      onSelectionChanged: (_) {},
    ),
    states: _all.difference({'error'}),
    target: () => find.text('Vegetarian'),
  ),
  _Part(
    'Tab bar',
    (s, d, e) => GlossTabBar(
      tabs: const ['Method', 'Ingredients'],
      selectedIndex: s ? 1 : 0,
      onTap: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('Ingredients'),
    tabs: 2,
    width: 320,
  ),
  _Part(
    'Navigation bar',
    (s, d, e) => GlossNavigationBar(
      destinations: const [
        GlossDestination(icon: LucideIcons.chefHat, label: 'Recipes'),
        GlossDestination(icon: LucideIcons.calendarDays, label: 'Plan'),
        GlossDestination(icon: LucideIcons.settings, label: 'Settings'),
      ],
      selectedIndex: s ? 1 : 0,
      onDestinationSelected: (_) {},
    ),
    states: {'idle', 'hovered', 'pressed', 'focused', 'selected'},
    target: () => find.text('Plan'),
    tabs: 2,
    width: 360,
  ),
  _Part(
    'List row',
    (s, d, e) => GlossWell(
      children: [
        GlossListTile(
          title: 'Lemon risotto',
          subtitle: '35 min',
          trailingText: 'Serves 4',
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
    'Card',
    (s, d, e) => GlossCard(
      onTap: d ? null : _none,
      child: const Text('Tonight: lemon risotto'),
    ),
    width: 280,
  ),
  _Part(
    'Disclosure',
    (s, d, e) => GlossDisclosure(
      title: 'Storage',
      expanded: s,
      onExpansionChanged: d ? null : (_) {},
      child: const Text('Keeps three days in the fridge.'),
    ),
    states: _all.difference({'error'}),
    width: 320,
  ),
  _Part(
    'Text field',
    (s, d, e) => GlossTextField(
      labelText: 'Email',
      hintText: 'name@example.com',
      errorText: e ? 'Enter an email with an @.' : null,
      enabled: !d,
      onChanged: (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 320,
  ),
  _Part(
    'Search field',
    (s, d, e) => GlossSearchField(
      hintText: 'Search recipes',
      enabled: !d,
      onChanged: (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled'},
    width: 320,
  ),
  _Part(
    'Select',
    (s, d, e) => GlossSelect<String>(
      labelText: 'Course',
      value: 'main',
      errorText: e ? 'Pick a course.' : null,
      items: const [
        GlossSelectItem(value: 'main', label: 'Main'),
        GlossSelectItem(value: 'side', label: 'Side'),
      ],
      onChanged: d ? null : (_) {},
    ),
    states: {'idle', 'hovered', 'focused', 'disabled', 'error'},
    width: 320,
  ),
  _Part(
    'Slider',
    (s, d, e) => GlossSlider(
      value: 0.4,
      semanticLabel: 'Spice',
      onChanged: d ? null : (_) {},
    ),
    width: 320,
  ),
  _Part(
    'Range slider',
    (s, d, e) => GlossRangeSlider(
      values: const GlossRangeValues(15, 45),
      max: 90,
      startLabel: 'Shortest',
      endLabel: 'Longest',
      onChanged: d ? null : (_) {},
    ),
    width: 320,
  ),
  _Part(
    'Stepper',
    (s, d, e) => GlossStepper(
      value: 4,
      max: 12,
      semanticLabel: 'Servings',
      onChanged: d ? null : (_) {},
    ),
    target: () => find.byIcon(LucideIcons.plus),
    tabs: 2,
  ),
  _Part(
    'Rating',
    (s, d, e) => GlossRating(
      value: 3,
      semanticLabel: 'Your rating',
      onChanged: d ? null : (_) {},
    ),
  ),
  _Part(
    'Pagination',
    (s, d, e) => GlossPagination(
      page: 1,
      pageCount: 5,
      onPageChanged: d ? null : (_) {},
    ),
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
      family.startsWith('packages/') ? family : glossRegisteredFamily(family),
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
          addTearDown(
            () => FocusManager.instance.highlightStrategy =
                FocusHighlightStrategy.automatic,
          );
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
                    color: context.glossTheme.colors.page,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: RepaintBoundary(
                        key: _stage,
                        child: ColoredBox(
                          color: context.glossTheme.colors.page,
                          child: Padding(
                            padding: const EdgeInsets.all(GlossSpacing.large),
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
                // A pointer that hovers is a mouse, which a desktop shows
                // hover for; the test's default platform starts in touch
                // mode, where Flutter's radios show none.
                FocusManager.instance.highlightStrategy =
                    FocusHighlightStrategy.alwaysTraditional;
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
        },
        // Pixels recorded on macOS: `flutter test --exclude-tags goldens`
        // leaves them out elsewhere.
        skip: !_recorded,
        tags: const ['goldens'],
      );
    }
  }
}
