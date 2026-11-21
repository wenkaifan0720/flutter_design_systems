// Compare enabled, selected, disabled and error states in both themes,
// including frames reached with actual pointer and keyboard input.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Compare reference images when they are available in the test bundle.
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

const _choiceGroup = ValueKey('choice group');

Widget _siblingRadios({
  required List<String> options,
  required String? value,
  required ValueChanged<String> change,
  Set<String> disabled = const {},
  Map<String, FocusNode> callerNodes = const {},
  Axis direction = Axis.vertical,
}) => RadioGroup<String>(
  groupValue: value,
  onChanged: (next) => change(next!),
  child: RadioGroupKeyboardFix<String>(
    child: Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          BrutalRadio<String>(
            key: ValueKey(option),
            value: option,
            enabled: !disabled.contains(option),
            focusNode: callerNodes[option],
            semanticLabel: option,
          ),
      ],
    ),
  ),
);

Future<void> _pumpChoices(
  WidgetTester tester, {
  required FocusNode before,
  required Widget child,
  FocusNode? after,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Directionality(
        textDirection: direction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(focusNode: before, child: const Text('Before')),
            SizedBox(width: 360, key: _choiceGroup, child: child),
            Focus(focusNode: after, child: const Text('After')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _checkChoices(WidgetTester tester, FocusNode before) async {
  final report = await const DesignRadioGroupCheck(look: 'Brutal').check(
    tester.element(find.byKey(_choiceGroup)),
    before: before,
    sendKeyEvent: tester.sendKeyEvent,
    pump: tester.pump,
  );
  report.verify();
}

void _testRadioGroups() {
  for (final direction in TextDirection.values) {
    // The third chosen, nothing chosen, the first chosen, and the disabled B
    // chosen; in a column and in a row (where Left moves on, right to left).
    for (final axis in Axis.values) {
      for (final initial in <String?>['C', null, 'A', 'B']) {
        testWidgets(
          'radio siblings in a ${axis.name} ${direction.name} with initial choice $initial',
          (tester) async {
            final before = FocusNode();
            addTearDown(before.dispose);
            var chosen = initial;
            await _pumpChoices(
              tester,
              direction: direction,
              before: before,
              child: StatefulBuilder(
                builder: (context, setState) => _siblingRadios(
                  options: const ['A', 'B', 'C', 'D'],
                  disabled: const {'B'},
                  value: chosen,
                  direction: axis,
                  change: (next) => setState(() => chosen = next),
                ),
              ),
            );
            await _checkChoices(tester, before);
          },
        );
      }
    }

    for (final (labels, initial) in [
      (['Standing', 'Balcony'], 'Standing'),
      (['Today', 'This week', 'Month'], 'This week'),
    ]) {
      testWidgets(
        '${labels.first} segments expose each checked state in ${direction.name}',
        (tester) async {
          final before = FocusNode();
          addTearDown(before.dispose);
          var chosen = initial;
          await _pumpChoices(
            tester,
            direction: direction,
            before: before,
            child: StatefulBuilder(
              builder: (context, setState) => BrutalSegmentedButton<String>(
                segments: [
                  for (final label in labels)
                    BrutalSegment(value: label, label: label),
                ],
                value: chosen,
                onChanged: (next) => setState(() => chosen = next),
              ),
            ),
          );
          for (final label in labels) {
            final flags = tester
                .getSemantics(find.bySemanticsLabel(label))
                .getSemanticsData()
                .flagsCollection;
            expect(
              flags.isChecked,
              label == initial ? CheckedState.isTrue : CheckedState.isFalse,
            );
            expect(flags.isInMutuallyExclusiveGroup, isTrue);
            expect(flags.isButton, isFalse);
          }
          await _checkChoices(tester, before);
        },
      );
    }
  }

  testWidgets('Home and End choose the first and last segments', (
    tester,
  ) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    var chosen = 'This week';
    await _pumpChoices(
      tester,
      before: before,
      child: StatefulBuilder(
        builder: (context, setState) => BrutalSegmentedButton<String>(
          segments: const [
            BrutalSegment(value: 'Today', label: 'Today'),
            BrutalSegment(value: 'This week', label: 'This week'),
            BrutalSegment(value: 'Month', label: 'Month'),
          ],
          value: chosen,
          onChanged: (next) => setState(() => chosen = next),
        ),
      ),
    );
    FocusNode nodeOf(String label) =>
        Focus.of(tester.element(find.text(label)));
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    before.requestFocus();
    await tester.pumpAndSettle();
    await press(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, same(nodeOf('This week')));
    await press(LogicalKeyboardKey.end);
    expect(chosen, 'Month');
    expect(FocusManager.instance.primaryFocus, same(nodeOf('Month')));
    await press(LogicalKeyboardKey.home);
    expect(chosen, 'Today');
    expect(FocusManager.instance.primaryFocus, same(nodeOf('Today')));
  });

  testWidgets('a selected filter chip reads as a button that is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
          home: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalChip(label: 'Talks', selected: true, onSelected: (_) {}),
              BrutalChip(label: 'Films', selected: false, onSelected: (_) {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Talks')),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasToggledState: false,
          hasCheckedState: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Films')),
        isSemantics(isButton: true, isSelected: false, hasToggledState: false),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Enter and Space keep the chosen segment and radio chosen', (
    tester,
  ) async {
    final before = FocusNode();
    final radio = FocusNode();
    addTearDown(before.dispose);
    addTearDown(radio.dispose);
    final presses = <String>[];
    await _pumpChoices(
      tester,
      before: before,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrutalSegmentedButton<String>(
            segments: const [
              BrutalSegment(value: 'Today', label: 'Today'),
              BrutalSegment(value: 'Month', label: 'Month'),
            ],
            value: 'Today',
            onChanged: (next) => presses.add('segment $next'),
          ),
          RadioGroup<String>(
            groupValue: 'Card',
            onChanged: (next) => presses.add('radio $next'),
            child: RadioGroupKeyboardFix<String>(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrutalRadio<String>(
                    value: 'Card',
                    focusNode: radio,
                    semanticLabel: 'Card',
                  ),
                  const BrutalRadio<String>(
                    value: 'Cash',
                    semanticLabel: 'Cash',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    before.requestFocus();
    await tester.pumpAndSettle();
    await press(LogicalKeyboardKey.tab);
    await press(LogicalKeyboardKey.enter);
    await press(LogicalKeyboardKey.space);
    await press(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, same(radio));
    await press(LogicalKeyboardKey.enter);
    await press(LogicalKeyboardKey.space);
    // As Flutter's radios and segmented button, the chosen one stays chosen
    // and reports nothing; an arrow chooses the next.
    expect(presses, isEmpty);
    await press(LogicalKeyboardKey.arrowDown);
    expect(presses, ['radio Cash']);
  });

  testWidgets('a null segment value can be the selected All option', (
    tester,
  ) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    String? chosen;
    await _pumpChoices(
      tester,
      before: before,
      child: StatefulBuilder(
        builder: (context, setState) => BrutalSegmentedButton<String?>(
          segments: const [
            BrutalSegment(value: null, label: 'All'),
            BrutalSegment(value: 'talks', label: 'Talks'),
          ],
          value: chosen,
          onChanged: (next) => setState(() => chosen = next),
        ),
      ),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('All'))
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    await _checkChoices(tester, before);
  });

  testWidgets(
    'radio siblings retain caller focus nodes across rebuilds and removal',
    (tester) async {
      final before = FocusNode();
      final after = FocusNode();
      final first = FocusNode();
      final replacement = FocusNode();
      for (final node in [before, after, first, replacement]) {
        addTearDown(node.dispose);
      }
      var notifications = 0;
      first.addListener(() => notifications++);
      replacement.addListener(() => notifications++);
      var active = first;
      var order = ['A', 'B'];
      var chosen = 'B';
      late StateSetter rebuild;
      await _pumpChoices(
        tester,
        before: before,
        after: after,
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return _siblingRadios(
              options: order,
              value: chosen,
              callerNodes: {'B': active},
              change: (next) => setState(() => chosen = next),
            );
          },
        ),
      );
      Future<void> focus(FocusNode node) async {
        final previous = notifications;
        node.requestFocus();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(node));
        expect(notifications, greaterThan(previous));
      }

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      await focus(first);
      rebuild(() => order = ['B', 'A']);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(first));
      rebuild(() => active = replacement);
      await tester.pumpAndSettle();
      before.requestFocus();
      await tester.pumpAndSettle();
      await focus(replacement);
      await press(LogicalKeyboardKey.arrowDown);
      expect(chosen, 'A');
      await press(LogicalKeyboardKey.arrowUp);
      expect(chosen, 'B');
      expect(FocusManager.instance.primaryFocus, same(replacement));
      await press(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, same(after));
      rebuild(() => order = ['A']);
      await tester.pumpAndSettle();
      expect(replacement.parent, isNull);
      await _pumpChoices(
        tester,
        before: before,
        child: Column(
          children: [
            Focus(focusNode: first, child: const Text('First')),
            Focus(focusNode: replacement, child: const Text('Replacement')),
          ],
        ),
      );
      await focus(first);
      await focus(replacement);
    },
  );
}

void main() {
  setUpAll(_loadFonts);
  _testRadioGroups();
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
