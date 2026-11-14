// The parts the coverage round added (INVENTORY rows painted on 11-09):
// what each does when used, what it announces, its keys, right-to-left and
// Reduce Motion, and that each holds at 200% text on a phone. Their outlines
// and highlights are shape_contract_test's.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The host stands above the Navigator, as an app mounts it.
Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool still = false,
  double width = 800,
  double scale = 1,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: still,
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(textDirection: direction, child: navigator!),
    ),
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

/// A parent that owns a value, as a page does, for controls that report
/// changes rather than keep them.
class _Owner<T> extends StatefulWidget {
  const _Owner({required this.initial, required this.builder});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

SemanticsNode _node(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label));

void main() {
  group('MinimalButtonGroup', () {
    testWidgets('each cell runs its own action; one with none does nothing', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalButtonGroup(
            items: [
              MinimalButtonGroupItem(
                label: 'Day',
                onPressed: () => pressed.add('Day'),
              ),
              MinimalButtonGroupItem(
                label: 'Week',
                onPressed: () => pressed.add('Week'),
              ),
              const MinimalButtonGroupItem(label: 'Year'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Week'));
      await tester.tap(find.text('Day'));
      await tester.tap(find.text('Year'), warnIfMissed: false);
      expect(pressed, ['Week', 'Day']);
    });

    testWidgets('expand shares the width out evenly', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalButtonGroup(
            expand: true,
            items: [
              for (final l in const ['A', 'Longer', 'C'])
                MinimalButtonGroupItem(label: l, onPressed: () {}),
            ],
          ),
        ),
      );
      double cell(String l) => tester
          .getSize(
            find
                .ancestor(of: find.text(l), matching: find.byType(Expanded))
                .first,
          )
          .width;
      // Shares in whole pixels: the leftover pixels go one each to the
      // first cells, so two cells differ by a pixel at most.
      expect(cell('A'), moreOrLessEquals(cell('Longer'), epsilon: 1));
      expect(cell('C'), moreOrLessEquals(cell('Longer'), epsilon: 1));
    });

    testWidgets('a button group and a toggle group keep their words\' widths '
        'where they fit, give way in a narrow column, and sit in an '
        'IntrinsicWidth', (tester) async {
      Widget groups([CrossAxisAlignment cross = CrossAxisAlignment.start]) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: [
              MinimalButtonGroup(
                items: [
                  for (final l in const ['Previous', 'Today', 'Next week'])
                    MinimalButtonGroupItem(label: l, onPressed: () {}),
                ],
              ),
              MinimalToggleGroup<String>(
                selected: const {'list'},
                onChanged: (_) {},
                items: const [
                  MinimalToggleItem('list', label: 'List'),
                  MinimalToggleItem('board', label: 'Board'),
                  MinimalToggleItem('calendar', label: 'Calendar'),
                ],
              ),
            ],
          );
      Finder group(Type type) => find.byType(type);
      await tester.pumpWidget(_host(groups()));
      final wide = {
        for (final t in [MinimalButtonGroup, MinimalToggleGroup<String>])
          t: tester.getSize(group(t)).width,
      };
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(_host(groups(), width: 180, scale: 2));
      expect(tester.takeException(), isNull, reason: 'no overflow at 200%');
      for (final t in [MinimalButtonGroup, MinimalToggleGroup<String>]) {
        expect(
          tester.getSize(group(t)).width,
          lessThanOrEqualTo(132),
          reason: '$t',
        );
        expect(
          tester.getSize(group(t)).width,
          lessThan(wide[t]!),
          reason: '$t',
        );
      }

      await tester.pumpWidget(_host(IntrinsicWidth(child: groups())));
      expect(tester.takeException(), isNull);
      for (final t in [MinimalButtonGroup, MinimalToggleGroup<String>]) {
        expect(
          tester.getSize(group(t)).width,
          moreOrLessEquals(wide[t]!, epsilon: 1),
          reason: '$t',
        );
      }

      // A column that stretches its children: each frame still hugs its
      // cells rather than drawing an empty tail.
      await tester.pumpWidget(_host(groups(CrossAxisAlignment.stretch)));
      expect(tester.takeException(), isNull);
      for (final (t, framing) in [
        (MinimalButtonGroup, Container),
        (MinimalToggleGroup<String>, MinimalHitTarget),
      ]) {
        final frame = find
            .descendant(of: group(t), matching: find.byType(framing))
            .first;
        expect(
          tester.getSize(frame).width,
          moreOrLessEquals(wide[t]!, epsilon: 1),
          reason: '$t',
        );
      }
    });

    testWidgets('an input group\'s add-ons give way to its field in a narrow '
        'column, and it still sits in an IntrinsicWidth', (tester) async {
      const group = MinimalInputGroup(
        hint: 'site',
        prefixText: 'https://',
        suffixText: '.example.com',
      );
      await tester.pumpWidget(_host(group, width: 180, scale: 2));
      expect(tester.takeException(), isNull, reason: 'no overflow at 200%');
      // The host's 24 px margins leave the group 132 px.
      expect(tester.getSize(find.byType(MinimalInputGroup)).width, 132);
      expect(
        tester.getSize(find.byType(TextField)).width,
        greaterThanOrEqualTo(MinimalLayout.minHitTarget),
        reason: 'the field keeps a touch target\'s width',
      );

      await tester.pumpWidget(_host(const IntrinsicWidth(child: group)));
      expect(tester.takeException(), isNull);
    });
  });

  group('MinimalLink', () {
    testWidgets('a live link announces a link and runs on tap', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpWidget(
        _host(MinimalLink('Terms', onPressed: () => opened++, external: true)),
      );
      await tester.tap(find.text('Terms'));
      expect(opened, 1);
      expect(
        _node(tester, 'Terms'),
        isSemantics(isLink: true, isButton: false, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('with no action it is words, not a dimmed control', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MinimalLink('Terms')));
      expect(find.byType(FocusableActionDetector), findsNothing);
      final text = tester.widget<Text>(find.text('Terms'));
      expect(text.style?.decoration, TextDecoration.none);
    });
  });

  group('MinimalTextArea', () {
    testWidgets('reports what is typed and shows its error', (tester) async {
      final typed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalTextArea(
            label: 'Notes',
            hint: 'Anything to remember',
            error: 'Too long',
            onChanged: typed.add,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Bring water');
      expect(typed.last, 'Bring water');
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Too long'), findsOneWidget);
    });

    testWidgets('grows with its lines up to maxLines', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(MinimalTextArea(controller: controller, maxLines: 4)),
      );
      final one = tester.getSize(find.byType(EditableText)).height;
      controller.text = List.filled(8, 'line').join('\n');
      await tester.pump();
      final four = tester.getSize(find.byType(EditableText)).height;
      controller.text = List.filled(12, 'line').join('\n');
      await tester.pump();
      expect(four, greaterThan(one));
      expect(tester.getSize(find.byType(EditableText)).height, four);
    });
  });

  group('MinimalFileUpload', () {
    const files = [
      MinimalUploadFile(name: 'receipt.pdf', bytes: 52000, progress: 0.4),
      MinimalUploadFile(name: 'photo.jpg', error: 'Over 10 MB'),
    ];

    testWidgets('the zone browses; each file has its own remove', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var browsed = 0;
      final removed = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalFileUpload(
            title: 'Drop files here',
            hint: 'PDF or JPG, up to 10 MB',
            onBrowse: () => browsed++,
            files: files,
            onRemove: (f) => removed.add(f.name),
          ),
        ),
      );
      await tester.tap(find.text('Drop files here'));
      expect(browsed, 1);
      await tester.tap(find.bySemanticsLabel('Remove photo.jpg'));
      expect(removed, ['photo.jpg']);
      expect(find.text('Over 10 MB'), findsOneWidget);
      expect(find.byType(MinimalLinearProgressIndicator), findsOneWidget);
      expect(
        _node(tester, 'Drop files here. PDF or JPG, up to 10 MB'),
        isSemantics(isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('without onBrowse the zone is shown disabled', (tester) async {
      await tester.pumpWidget(
        _host(const MinimalFileUpload(title: 'Drop files here')),
      );
      final dim = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(MinimalFileUpload),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(dim.opacity, lessThan(1));
    });
  });

  group('MinimalRadioGroup', () {
    Widget group(ValueChanged<String> seen) => _Owner<String?>(
      initial: 'free',
      builder: (v, set) => MinimalRadioGroup<String>(
        label: 'Plan',
        value: v,
        onChanged: (next) {
          seen(next);
          set(next);
        },
        options: const [
          MinimalRadioOption(value: 'free', label: 'Free'),
          MinimalRadioOption(
            value: 'pro',
            label: 'Pro',
            description: 'Unlimited projects',
          ),
          MinimalRadioOption(value: 'team', label: 'Team', enabled: false),
        ],
      ),
    );

    testWidgets('a tap on the words chooses; a disabled option refuses', (
      tester,
    ) async {
      final seen = <String>[];
      await tester.pumpWidget(_host(group(seen.add)));
      await tester.tap(find.text('Unlimited projects'));
      await tester.pump();
      await tester.tap(find.text('Team'), warnIfMissed: false);
      await tester.pump();
      expect(seen, ['pro']);
      final radios = tester
          .widgetList<MinimalRadio>(find.byType(MinimalRadio))
          .toList();
      expect([for (final r in radios) r.selected], [false, true, false]);
    });

    testWidgets('arrows walk the options and Space chooses', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(_host(group(seen.add)));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.space);
      expect(seen, ['pro']);
    });
  });

  group('MinimalRating', () {
    Widget rating(List<int> seen, {bool clear = false}) => _Owner<double>(
      initial: 2,
      builder: (v, set) => MinimalRating(
        value: v,
        label: 'Your rating',
        allowClear: clear,
        onChanged: (n) {
          seen.add(n);
          set(n.toDouble());
        },
      ),
    );

    testWidgets('announces a slider with its value and both steps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(rating([])));
      expect(
        _node(tester, 'Your rating'),
        isSemantics(
          isSlider: true,
          value: '2 of 5',
          increasedValue: '3 of 5',
          decreasedValue: '1 of 5',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a tap sets the stars; tapping the set star clears it', (
      tester,
    ) async {
      final seen = <int>[];
      await tester.pumpWidget(_host(rating(seen, clear: true)));
      final stars = find.descendant(
        of: find.byType(MinimalRating),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(stars.at(3));
      await tester.pump();
      await tester.tap(stars.at(3));
      await tester.pump();
      expect(seen, [4, 0]);
    });

    testWidgets('arrows step it, Home and End jump, mirrored right to left', (
      tester,
    ) async {
      final seen = <int>[];
      await tester.pumpWidget(_host(rating(seen)));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.end);
      await _key(tester, LogicalKeyboardKey.home);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(seen, [3, 5, 1, 2]);

      final rtl = <int>[];
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(rating(rtl), direction: TextDirection.rtl));
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(rtl, [3]);
    });

    testWidgets('read only, it states the value and takes no input', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            child: const MinimalRating(value: 3.5, label: 'Average'),
          ),
        ),
      );
      final node = _node(tester, 'Average');
      expect(node, isSemantics(value: '3.5 of 5', isSlider: false));
      expect(
        find.descendant(
          of: find.byType(MinimalRating),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
      handle.dispose();
    });
  });

  group('MinimalTimePicker', () {
    testWidgets('the time row prints the 24-hour clock by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalTimePicker(
            label: 'Reminder',
            value: DateTime(2026, 1, 1, 7, 5),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('07:05'), findsOneWidget);
    });
  });

  group('MinimalNavigationRail and MinimalNavigationDrawer', () {
    const items = [
      MinimalNavItem(Icons.home, 'Home'),
      MinimalNavItem(Icons.inbox, 'Inbox'),
      MinimalNavItem(Icons.settings, 'Settings'),
    ];

    testWidgets('the rail selects by tap and announces the current one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 400,
            child: MinimalNavigationRail(
              destinations: items,
              selectedIndex: 1,
              onDestinationSelected: seen.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Settings'));
      expect(seen, [2]);
      expect(_node(tester, 'Inbox'), isSemantics(isSelected: true));
      expect(_node(tester, 'Home'), isSemantics(isSelected: false));
      handle.dispose();
    });

    testWidgets('the arrows walk the rail', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 400,
            child: MinimalNavigationRail(
              destinations: items,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      final first = FocusManager.instance.primaryFocus;
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(FocusManager.instance.primaryFocus, isNot(first));
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(FocusManager.instance.primaryFocus, first);
    });

    testWidgets('the drawer counts its destinations across sections', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 500,
            child: MinimalNavigationDrawer(
              selectedIndex: 3,
              onDestinationSelected: seen.add,
              sections: const [
                MinimalNavigationSection(title: 'Work', destinations: items),
                MinimalNavigationSection(
                  title: 'Account',
                  destinations: [
                    MinimalNavItem(Icons.person, 'Profile'),
                    MinimalNavItem(Icons.logout, 'Sign out'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sign out'));
      expect(seen, [4]);
      expect(_node(tester, 'Account'), isSemantics(isHeader: true));
      expect(_node(tester, 'Profile'), isSemantics(isSelected: true));
      handle.dispose();
    });
  });

  group('MinimalPagination', () {
    Widget pages(List<int> seen, {int page = 4, double width = 800}) => _host(
      _Owner<int>(
        initial: page,
        builder: (p, set) => MinimalPagination(
          page: p,
          pageCount: 12,
          onPageChanged: (next) {
            seen.add(next);
            set(next);
          },
        ),
      ),
      width: width,
    );

    testWidgets('shows the ends and the neighbours, an ellipsis per gap', (
      tester,
    ) async {
      await tester.pumpWidget(pages([]));
      for (final n in const ['1', '4', '5', '6', '12']) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      final gaps = find.byWidgetPredicate(
        (w) => w is MinimalIcon && w.icon == LucideIcons.ellipsis,
      );
      expect(gaps, findsNWidgets(2));
      // A centred glyph, not a text ellipsis, whose dots sit on the
      // baseline below the numbers' middle.
      expect(find.text('…'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(
        tester.getCenter(gaps.first).dy,
        moreOrLessEquals(
          tester.getCenter(find.byType(MinimalIconButton).last).dy,
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('previous, next and a number move it; the ends stop', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(pages(seen, page: 0));
      expect(_node(tester, 'Previous page'), isSemantics(isEnabled: false));
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.pump();
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(seen, [1, 11]);
      expect(_node(tester, 'Next page'), isSemantics(isEnabled: false));
      handle.dispose();
    });

    testWidgets('the current page announces itself as the selected one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(pages([]));
      expect(
        _node(tester, 'Page 5 of 12'),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        _node(tester, 'Page 6 of 12'),
        isSemantics(isSelected: false, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('narrow, it folds to "Page n of m" between the arrows', (
      tester,
    ) async {
      await tester.pumpWidget(pages([], width: 340));
      expect(find.text('Page 5 of 12'), findsOneWidget);
      expect(find.text('6'), findsNothing);
    });

    testWidgets('right to left, Previous stands on the right', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalPagination(page: 4, pageCount: 12, onPageChanged: (_) {}),
          direction: TextDirection.rtl,
        ),
      );
      final buttons = find.byType(MinimalIconButton);
      final previous = tester.getCenter(buttons.first).dx;
      final next = tester.getCenter(buttons.last).dx;
      expect(previous, greaterThan(next));
    });
  });

  group('MinimalPageDots and MinimalStepProgress', () {
    testWidgets('dots say where the reader is and jump on a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(MinimalPageDots(count: 4, selectedIndex: 1, onChanged: seen.add)),
      );
      expect(find.bySemanticsLabel('Page 2 of 4'), findsWidgets);
      final dots = find.byType(MinimalPressable);
      expect(dots, findsNWidgets(4));
      await tester.tap(dots.at(3));
      await tester.tap(dots.at(1), warnIfMissed: false);
      expect(seen, [3]);
      handle.dispose();
    });

    testWidgets('steps name their state; only a finished one goes back', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        _host(
          MinimalStepProgress(
            steps: const ['Account', 'Plan', 'Pay'],
            current: 1,
            onStepPressed: seen.add,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Step 1 of 3, Account, completed'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Step 2 of 3, Plan, current'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Step 1 of 3')));
      await tester.tap(
        find.bySemanticsLabel(RegExp('^Step 3 of 3')),
        warnIfMissed: false,
      );
      expect(seen, [0]);
      handle.dispose();
    });

    testWidgets('narrow, the steps fold to the current one by name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalStepProgress(
            steps: ['Account', 'Plan', 'Pay', 'Confirm', 'Done'],
            current: 2,
          ),
          width: 300,
        ),
      );
      expect(find.text('Step 3 of 5 · Pay'), findsOneWidget);
    });

    testWidgets('the line between steps stands on a whole pixel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalStepProgress(
            steps: ['Account', 'Plan', 'Pay'],
            current: 1,
          ),
        ),
      );
      final lines = find.descendant(
        of: find.byType(MinimalStepProgress),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxHeight == 1,
        ),
      );
      expect(lines, findsNWidgets(2));
      final origin = tester.getTopLeft(find.byType(MinimalStepProgress)).dy;
      for (final line in lines.evaluate()) {
        final box = line.renderObject! as RenderBox;
        // The coloured pixel row under the margin, from the part's top.
        final ink =
            box.localToGlobal(Offset.zero).dy + box.size.height - 1 - origin;
        expect(ink, ink.roundToDouble());
      }
    });
  });

  group('MinimalDisclosure', () {
    testWidgets('a tap opens and closes it, and it says which', (tester) async {
      final handle = tester.ensureSemantics();
      final seen = <bool>[];
      await tester.pumpWidget(
        _host(
          MinimalDisclosure(
            title: 'Shipping',
            onChanged: seen.add,
            child: const Text('Two to four days.'),
          ),
          still: true,
        ),
      );
      expect(find.text('Two to four days.').hitTestable(), findsNothing);
      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();
      expect(find.text('Two to four days.').hitTestable(), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Shipping, ')), findsOneWidget);
      final open = _node(tester, 'Shipping, ${_expanded(tester, true)}');
      expect(open, isSemantics(isButton: true));
      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
      handle.dispose();
    });

    testWidgets('controlled, it shows what its owner says', (tester) async {
      await tester.pumpWidget(
        _host(
          const MinimalDisclosure(
            title: 'Shipping',
            expanded: true,
            child: Text('Two to four days.'),
          ),
          still: true,
        ),
      );
      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();
      expect(find.text('Two to four days.').hitTestable(), findsOneWidget);
    });
  });

  group('MinimalDivider, MinimalBadge and MinimalMeter', () {
    testWidgets('a labelled divider prints its words between two rules', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MinimalDivider(label: 'or')));
      expect(find.text('or'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MinimalDivider)).width,
        greaterThan(600),
      );
    });

    testWidgets('a vertical divider runs the height it stands in', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [MinimalDivider.vertical()],
            ),
          ),
        ),
      );
      final rule = find.descendant(
        of: find.byType(MinimalDivider),
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(rule).height, 24);
    });

    testWidgets('a badge caps its count and says it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(container: true, child: const MinimalBadge(count: 3)),
              const SizedBox(width: 16),
              Semantics(
                container: true,
                child: const MinimalBadge(count: 120, label: '120 unread'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.bySemanticsLabel('120 unread'), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a count's numerals clear 4.5:1 on its fill in either mode", (
      tester,
    ) async {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance() + 0.05;
        final y = b.computeLuminance() + 0.05;
        return x > y ? x / y : y / x;
      }

      for (final brightness in Brightness.values) {
        final t = MinimalThemeData.preset('standard', brightness);
        await tester.pumpWidget(
          MaterialApp(
            home: MinimalHost(
              light: MinimalThemeData.preset('standard', Brightness.light),
              dark: MinimalThemeData.preset('standard', Brightness.dark),
              brightness: brightness,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MinimalBadge(count: 12, tone: MinimalTone.neutral),
                    MinimalBadge(count: 3),
                    MinimalAvatarGroup([
                      'Hanna Berg',
                      'Oskar Lind',
                      'Ines Duarte',
                    ], max: 1),
                  ],
                ),
              ),
            ),
          ),
        );
        // The host cross-fades between modes: read the settled colours.
        await tester.pumpAndSettle();
        Color ink(String count) =>
            tester.widget<Text>(find.text(count)).style!.color!;
        // The capsule the count stands on: its nearest framed box.
        Color fill(String count) => switch (tester
            .widget<Container>(
              find
                  .ancestor(
                    of: find.text(count),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration) {
          BoxDecoration(:final color?) => color,
          ShapeDecoration(:final color?) => color,
          _ => throw StateError('no fill under $count'),
        };
        for (final count in const ['12', '3']) {
          expect(
            contrast(ink(count), fill(count)),
            greaterThanOrEqualTo(4.5),
            reason: '$count, $brightness',
          );
        }
        // A plain count stands on the muted fill, not a mid-grey.
        expect(fill('12'), t.muted, reason: '$brightness');
        // A stack's overflow count is in the ink, as a face's initials are.
        expect(ink('+2'), t.foreground, reason: '$brightness');
      }
    });

    testWidgets('a meter reads its value, by words or by percentage', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                container: true,
                child: const MinimalMeter(
                  label: 'Storage',
                  value: 7.2,
                  max: 10,
                  valueLabel: '7.2 of 10 GB',
                  warningAt: 0.8,
                ),
              ),
              Semantics(
                container: true,
                child: const MinimalMeter(label: 'Seats', value: 0.25),
              ),
            ],
          ),
        ),
      );
      expect(_node(tester, 'Storage'), isSemantics(value: '7.2 of 10 GB'));
      expect(_node(tester, 'Seats'), isSemantics(value: '25%'));
      handle.dispose();
    });
  });

  group('MinimalTooltip, MinimalBanner and MinimalActionSheet', () {
    testWidgets('a long press shows the tooltip', (tester) async {
      await tester.pumpWidget(
        _host(
          const MinimalTooltip(
            message: 'Copy link',
            child: SizedBox(key: ValueKey('anchor'), width: 40, height: 40),
          ),
          still: true,
        ),
      );
      expect(find.text('Copy link'), findsNothing);
      await tester.longPress(find.byKey(const ValueKey('anchor')));
      await tester.pump();
      expect(find.text('Copy link'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a banner dismisses only with onDismissed', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalBanner(
                title: 'Trial ends Friday',
                message: 'Choose a plan to keep your projects.',
                tone: MinimalTone.warning,
                onDismissed: () => dismissed++,
              ),
              const MinimalBanner(title: 'Saved'),
            ],
          ),
        ),
      );
      final close = find.byType(MinimalIconButton);
      expect(close, findsOneWidget);
      await tester.tap(close);
      expect(dismissed, 1);
    });

    testWidgets('an action closes the sheet, then runs; Cancel only closes', (
      tester,
    ) async {
      final ran = <String>[];
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MinimalButton(
              'More',
              onPressed: () => showMinimalActionSheet(
                context,
                title: 'Photo',
                actions: [
                  MinimalActionSheetAction(
                    'Share',
                    onPressed: () => ran.add(
                      ModalRoute.of(context)!.isCurrent ? 'closed' : 'open',
                    ),
                  ),
                  MinimalActionSheetAction(
                    'Delete',
                    destructive: true,
                    onPressed: () => ran.add('delete'),
                  ),
                ],
              ),
            ),
          ),
          still: true,
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Photo'), findsOneWidget);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Photo'), findsNothing);
      expect(ran, ['closed']);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Photo'), findsNothing);
      expect(ran, ['closed']);
    });
  });

  group('Progress, skeleton and status views', () {
    testWidgets('the spinner says Loading, or its share when determinate', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                container: true,
                child: const MinimalCircularProgressIndicator(),
              ),
              Semantics(
                container: true,
                child: const MinimalCircularProgressIndicator(
                  value: 0.4,
                  label: 'Upload',
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(_node(tester, 'Upload'), isSemantics(value: '40%'));
      handle.dispose();
    });

    testWidgets('Reduce Motion stills the spinner and the skeleton', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalCircularProgressIndicator(),
              MinimalSkeleton(width: 120),
              MinimalSkeleton.text(),
              MinimalSkeleton.circle(),
            ],
          ),
          still: true,
        ),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('moving, they keep asking for frames', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalCircularProgressIndicator(),
              MinimalSkeleton(width: 120),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('the four status views, each by name', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 400,
            child: MinimalStatusView.success(
              title: 'Invite sent',
              message: 'Ana will get an email in a minute.',
              actionLabel: 'Done',
              onAction: () => done++,
            ),
          ),
        ),
      );
      expect(find.text('Invite sent'), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(done, 1);
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 400,
            child: MinimalStatusView.empty(title: 'No invites'),
          ),
        ),
      );
      expect(find.text('No invites'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 400,
            child: MinimalStatusView.error(
              title: 'Could not send',
              onAction: () {},
              actionLabel: 'Try again',
            ),
          ),
        ),
      );
      expect(find.text('Could not send'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          const SizedBox(height: 400, child: MinimalStatusView.loading()),
          still: true,
        ),
      );
      expect(find.byType(MinimalStatusView), findsOneWidget);
    });
  });

  group('Series charts', () {
    const runs = MinimalChartSeries('Runs', [3, 5, 2, 6]);
    const walks = MinimalChartSeries('Walks', [1, 2, 4, 3]);
    const days = ['Mon', 'Tue', 'Wed', 'Thu'];
    String whole(double v) => '${v.round()}';

    testWidgets('the arrows walk the readout, Escape puts it away', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalLineChart(
            series: const [runs, walks],
            labels: days,
            semanticLabel: 'This week',
            format: whole,
          ),
        ),
      );
      expect(find.text('Runs'), findsOneWidget, reason: 'two series: legend');
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(
        _node(tester, 'This week'),
        isSemantics(value: 'Mon: Runs 3, Walks 1'),
      );
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(
        _node(tester, 'This week'),
        isSemantics(value: 'Tue: Runs 5, Walks 2'),
      );
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_node(tester, 'This week').value, isEmpty);
      handle.dispose();
    });

    testWidgets('right to left, the forward arrow is the left one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalAreaChart(
            series: const [runs],
            labels: days,
            semanticLabel: 'This week',
            format: whole,
          ),
          direction: TextDirection.rtl,
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_node(tester, 'This week'), isSemantics(value: 'Mon: Runs 3'));
      handle.dispose();
    });

    testWidgets('empty and loading charts say so and take no focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalLineChart(series: [], emptyLabel: 'No runs yet'),
              MinimalAreaChart(series: [runs], loading: true),
            ],
          ),
        ),
      );
      expect(find.text('No runs yet'), findsOneWidget);
      expect(find.byType(MinimalSkeleton), findsOneWidget);
      // The placeholder spans the chart, as the empty state does: no
      // gutter for axis labels that are not drawn.
      expect(
        tester.getSize(find.byType(MinimalSkeleton)).width,
        tester.getSize(find.byType(MinimalAreaChart)).width,
      );
      // A plot-sized block wears the chart's corners, not a text line's.
      expect(
        tester.widget<MinimalSkeleton>(find.byType(MinimalSkeleton)).shape,
        MinimalThemeData.preset('standard', Brightness.light).shapes.small,
      );
      // An empty plot keeps its rules, not one hairline that reads as a
      // stray divider.
      expect(
        find
            .descendant(
              of: find.byType(MinimalLineChart),
              matching: find.byType(CustomPaint),
            )
            .first,
        paints
          ..line()
          ..line()
          ..line()
          ..line(),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<Focus>().having((f) => f.onKeyEvent, 'keys', isNotNull)),
      );
    });

    testWidgets('thinned, the labels keep the first and the last', (
      tester,
    ) async {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
      // 200 px of chart: room for only some of the months.
      await tester.pumpWidget(
        _host(
          const MinimalAreaChart(
            series: [
              MinimalChartSeries('Revenue', [4, 5, 5, 6, 6, 7, 7, 8]),
            ],
            labels: months,
          ),
          width: 248,
        ),
      );
      final plot = find
          .descendant(
            of: find.byType(MinimalAreaChart),
            matching: find.byType(CustomPaint),
          )
          .first;
      final size = tester.getSize(plot);
      var labels = 0;
      var last = false;
      expect(
        plot,
        paints..everything((method, args) {
          if (method != #drawParagraph) return true;
          final at = args[1] as Offset;
          // The scale's figures stand beside the plot; the labels under it.
          if (at.dy <= size.height - 20) return true;
          labels++;
          final end = at.dx + (args[0] as ui.Paragraph).maxIntrinsicWidth;
          // The last label, centred on the last point, ends at the end edge.
          if ((size.width - end).abs() <= 1.01) last = true;
          return true;
        }),
      );
      expect(labels, inInclusiveRange(2, months.length - 1));
      expect(last, isTrue, reason: 'the last month is labelled');
    });

    testWidgets("the donut's legend figures stand just past the labels", (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalPieChart(
            slices: [
              MinimalChartSlice('Design', 14),
              MinimalChartSlice('Build', 18),
              MinimalChartSlice('Review', 6),
              MinimalChartSlice('Meetings', 4),
            ],
          ),
        ),
      );
      final label = find.text('Meetings');
      final words = tester
          .renderObject<RenderBox>(label)
          .getMaxIntrinsicWidth(double.infinity);
      final gap =
          tester.getTopLeft(find.text('4')).dx -
          (tester.getTopLeft(label).dx + words);
      expect(gap, lessThan(MinimalSpacing.s16 + 12));
    });

    testWidgets('the donut walks its slices with the arrows, round', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalPieChart(
            semanticLabel: 'Spend',
            format: whole,
            slices: const [
              MinimalChartSlice('Rent', 60),
              MinimalChartSlice('Food', 30),
              MinimalChartSlice('Fun', 10),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_node(tester, 'Spend').value, startsWith('Rent '));
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_node(tester, 'Spend').value, startsWith('Fun '));
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_node(tester, 'Spend').value, 'Rent 60, Food 30, Fun 10');
      handle.dispose();
    });
  });

  testWidgets('every new part holds at 200% text on a phone', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const nav = [
      MinimalNavItem(Icons.home, 'Home'),
      MinimalNavItem(Icons.inbox, 'Inbox'),
      MinimalNavItem(Icons.settings, 'Settings'),
    ];
    const runs = MinimalChartSeries('Runs', [3, 5, 2, 6]);
    const walks = MinimalChartSeries('Walks', [1, 2, 4, 3]);
    final parts = <String, Widget Function()>{
      'MinimalButtonGroup': () => MinimalButtonGroup(
        items: [
          for (final l in const ['Day', 'Week', 'Month'])
            MinimalButtonGroupItem(label: l, onPressed: () {}),
        ],
      ),
      'MinimalLink': () =>
          MinimalLink('Terms of service', onPressed: () {}, external: true),
      'MinimalTextArea': () => const MinimalTextArea(
        label: 'Notes',
        hint: 'Anything to remember',
        helper: 'Only you can see these',
      ),
      'MinimalFileUpload': () => MinimalFileUpload(
        title: 'Drop files here',
        hint: 'PDF or JPG, up to 10 MB',
        onBrowse: () {},
        onRemove: (_) {},
        files: const [
          MinimalUploadFile(name: 'receipt-2026-11.pdf', bytes: 52000),
          MinimalUploadFile(name: 'photo.jpg', error: 'Over 10 MB'),
        ],
      ),
      'MinimalRadioGroup': () => MinimalRadioGroup<String>(
        value: 'pro',
        onChanged: (_) {},
        options: const [
          MinimalRadioOption(value: 'free', label: 'Free'),
          MinimalRadioOption(
            value: 'pro',
            label: 'Pro',
            description: 'Unlimited projects and guests',
          ),
        ],
      ),
      'MinimalRating': () =>
          MinimalRating(value: 3, label: 'Rating', onChanged: (_) {}),
      'MinimalTimePicker': () => MinimalTimePicker(
        label: 'Reminder',
        value: DateTime(2026, 1, 1, 7, 30),
        onChanged: (_) {},
      ),
      'MinimalNavigationRail': () => SizedBox(
        height: 600,
        child: MinimalNavigationRail(
          destinations: nav,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
      'MinimalNavigationDrawer': () => SizedBox(
        height: 600,
        child: MinimalNavigationDrawer(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          sections: const [
            MinimalNavigationSection(title: 'Workspace', destinations: nav),
          ],
        ),
      ),
      'MinimalPagination': () =>
          MinimalPagination(page: 4, pageCount: 12, onPageChanged: (_) {}),
      'MinimalPageDots': () =>
          MinimalPageDots(count: 4, selectedIndex: 1, onChanged: (_) {}),
      'MinimalStepProgress': () => const MinimalStepProgress(
        steps: ['Account', 'Plan', 'Payment', 'Done'],
        current: 1,
      ),
      'MinimalDisclosure': () => const MinimalDisclosure(
        title: 'Shipping and returns',
        subtitle: 'Two to four days',
        initiallyExpanded: true,
        child: Text('Free returns within 30 days.'),
      ),
      'MinimalDivider': () => const MinimalDivider(label: 'or continue with'),
      'MinimalBanner': () => MinimalBanner(
        title: 'Your trial ends on Friday',
        message: 'Choose a plan to keep your projects.',
        tone: MinimalTone.warning,
        onDismissed: () {},
      ),
      'MinimalActionSheet': () => MinimalActionSheet(
        title: 'Photo',
        message: 'Shared with your team',
        onCancel: () {},
        actions: [
          MinimalActionSheetAction('Share', onPressed: () {}),
          MinimalActionSheetAction(
            'Delete',
            destructive: true,
            onPressed: () {},
          ),
        ],
      ),
      'MinimalCircularProgressIndicator': () =>
          const MinimalCircularProgressIndicator(),
      'MinimalSkeleton': () => const MinimalSkeleton.text(),
      'MinimalMeter': () => const MinimalMeter(
        label: 'Storage',
        value: 7.2,
        max: 10,
        valueLabel: '7.2 of 10 GB',
      ),
      'MinimalBadge': () =>
          const MinimalBadge(count: 120, child: Icon(Icons.inbox)),
      'MinimalStatusView': () => SizedBox(
        height: 600,
        child: MinimalStatusView.success(
          title: 'Invite sent',
          message: 'Ana will get an email in a minute.',
          actionLabel: 'Done',
          onAction: () {},
        ),
      ),
      'MinimalLineChart': () => const MinimalLineChart(
        series: [runs, walks],
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
      ),
      'MinimalAreaChart': () => const MinimalAreaChart(
        series: [runs],
        labels: ['Mon', 'Tue', 'Wed', 'Thu'],
      ),
      'MinimalPieChart': () => const MinimalPieChart(
        centerLabel: 'Spent',
        centerValue: r'$1,240',
        slices: [
          MinimalChartSlice('Rent', 60),
          MinimalChartSlice('Food', 30),
          MinimalChartSlice('Fun', 10),
        ],
      ),
    };
    final broken = <String>[];
    for (final MapEntry(key: name, value: build) in parts.entries) {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(child: build()),
          width: 390,
          scale: 2,
          still: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final error = tester.takeException();
      if (error != null) broken.add('$name: ${'$error'.split('\n').first}');
      await tester.pumpWidget(const SizedBox());
    }
    expect(broken, isEmpty);
  });
}

String _expanded(WidgetTester tester, bool expanded) =>
    MinimalLocalizations.of(tester.element(find.byType(MinimalDisclosure)))
        .expandedState(expanded: expanded);
