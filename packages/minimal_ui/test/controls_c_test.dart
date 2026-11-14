import 'dart:ui' as ui;
import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The host stands above the Navigator, as an app mounts it, so overlays (a
// dialog, a toast) read the same tokens as the page.
Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        brightness: brightness,
        child: navigator!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

/// A 44 px row the swipe tests drag.
Widget _row(String name, {VoidCallback? onTap}) => GestureDetector(
  onTap: onTap,
  child: SizedBox(
    height: MinimalChromeMetrics.row,
    child: Align(alignment: Alignment.centerLeft, child: Text(name)),
  ),
);

void main() {
  group('MinimalSwipeActions', () {
    testWidgets('a drag past half reveals the trailing squares, and a '
        'tap on one performs it and closes the row', (tester) async {
      final handle = tester.ensureSemantics();
      var deleted = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  icon: LucideIcons.trash2,
                  destructive: true,
                  onPressed: () => deleted += 1,
                ),
              ],
              child: _row('Morning run'),
            ),
          ),
        ),
      );
      expect(find.text('Delete'), findsNothing);
      await tester.drag(find.text('Morning run'), const Offset(-60, 0));
      await tester.pumpAndSettle();
      final square = tester.getRect(find.bySemanticsLabel('Delete'));
      // At least its 64 px; the test face's wide glyphs widen it to the word.
      expect(
        square.width,
        greaterThanOrEqualTo(MinimalSwipeActions.actionWidth),
      );
      expect(square.height, MinimalChromeMetrics.row);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      expect(find.text('Delete'), findsNothing);
      handle.dispose();
    });

    testWidgets('a short drag snaps back closed', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [MinimalSwipeAction('Archive', onPressed: () {})],
              child: _row('Journal'),
            ),
          ),
        ),
      );
      await tester.timedDrag(
        find.text('Journal'),
        const Offset(-12, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      expect(find.text('Archive'), findsNothing);
    });

    testWidgets('while open, a tap on the row closes it instead of opening '
        'the row', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              initiallyOpen: true,
              leading: [
                MinimalSwipeAction(
                  'Done',
                  tone: MinimalTone.success,
                  onPressed: () {},
                ),
              ],
              child: _row('Meditate', onTap: () => opened += 1),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Done'), findsOneWidget);
      // The open row's own content ignores the tap: the handle takes it.
      await tester.tap(find.text('Meditate'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(find.text('Done'), findsNothing);
      await tester.tap(find.text('Meditate'));
      expect(opened, 1);
    });

    testWidgets('a full swipe performs the first action once, when opted '
        'in', (tester) async {
      var done = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              allowsFullSwipe: true,
              leading: [
                MinimalSwipeAction('Done', onPressed: () => done += 1),
                MinimalSwipeAction('Pin', onPressed: () {}),
              ],
              child: _row('Read 20 pages'),
            ),
          ),
        ),
      );
      await tester.drag(find.text('Read 20 pages'), const Offset(360, 0));
      await tester.pumpAndSettle();
      expect(done, 1);
    });

    testWidgets('every action is offered as a custom semantics action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var snoozed = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
                MinimalSwipeAction(
                  'Snooze',
                  tone: MinimalTone.warning,
                  onPressed: () => snoozed += 1,
                ),
              ],
              child: _row('Drink water'),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.text('Drink water'));
      final data = node.getSemanticsData();
      final labels = [
        for (final id in data.customSemanticsActionIds ?? const <int>[])
          CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, containsAll(<String>['Delete', 'Snooze']));
      tester.semantics.customAction(
        find.semantics.byLabel('Drink water'),
        const CustomSemanticsAction(label: 'Snooze'),
      );
      await tester.pump();
      expect(snoozed, 1);
      handle.dispose();
    });

    testWidgets('without a full swipe the row stops at its actions, the '
        'square butted against it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              trailing: [
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: () {},
                ),
              ],
              child: _row('Morning run'),
            ),
          ),
        ),
      );
      double start() => tester.getTopLeft(find.text('Morning run')).dx;
      final rest = start();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Morning run')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump();
      }
      final square = tester.getRect(find.bySemanticsLabel('Delete'));
      // 300 px of finger: the row goes no further than its square.
      expect(rest - start(), moreOrLessEquals(square.width, epsilon: 0.5));
      final row = tester.getRect(find.byType(MinimalSwipeActions));
      expect(square.right, moreOrLessEquals(row.right, epsilon: 0.5));
      expect(
        square.width,
        greaterThanOrEqualTo(MinimalSwipeActions.actionWidth),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(rest - start(), moreOrLessEquals(square.width, epsilon: 0.5));
      handle.dispose();
    });

    testWidgets('a revealed square keeps its glyph and its word at text '
        'scale 1.3', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: SizedBox(
                width: 390,
                child: MinimalSwipeActions(
                  initiallyOpen: true,
                  trailing: [
                    MinimalSwipeAction(
                      'Snooze',
                      icon: LucideIcons.alarmClock,
                      tone: MinimalTone.warning,
                      onPressed: () {},
                    ),
                  ],
                  child: _row('Drink water'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Snooze'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MinimalSwipeActions),
          matching: find.byType(MinimalIcon),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('at text scale 1.3 a square grows to its word rather than '
        'squeezing it to its edges', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: SizedBox(
                width: 390,
                child: MinimalSwipeActions(
                  initiallyOpen: true,
                  trailing: [
                    MinimalSwipeAction('Delete', onPressed: () {}),
                    MinimalSwipeAction('Snooze', onPressed: () {}),
                  ],
                  child: _row('Drink water'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final word = find.text('Snooze');
      // Shown at its own width (not shrunk), with air on both sides.
      expect(
        tester.getRect(word).width,
        moreOrLessEquals(tester.getSize(word).width, epsilon: 0.5),
      );
      // Delete, the first, stands at the trailing edge; the words keep apart.
      final delete = tester.getRect(find.text('Delete'));
      final row = tester.getRect(find.byType(MinimalSwipeActions));
      expect(delete.right, lessThan(row.right));
      expect(tester.getRect(word).right, lessThan(delete.left));
    });

    testWidgets('a revealed square is a control: the keyboard reaches it '
        'and Enter performs it', (tester) async {
      var pinned = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalSwipeActions(
              initiallyOpen: true,
              leading: [
                MinimalSwipeAction('Pin', onPressed: () => pinned += 1),
              ],
              child: _row('Journal'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(pinned, 1);
      expect(find.text('Pin'), findsNothing);
    });

    test('a swipe action resolves its tone, danger first', () {
      void noop() {}
      expect(
        MinimalSwipeAction('A', onPressed: noop).resolvedTone,
        MinimalTone.primary,
      );
      expect(
        MinimalSwipeAction(
          'B',
          tone: MinimalTone.success,
          destructive: true,
          onPressed: noop,
        ).resolvedTone,
        MinimalTone.destructive,
      );
      expect(
        MinimalSwipeAction(
          'C',
          tone: MinimalTone.neutral,
          onPressed: noop,
        ).resolvedTone,
        MinimalTone.neutral,
      );
    });
  });

  group('MinimalDismissible', () {
    testWidgets('a trailing swipe removes the row and reports it', (
      tester,
    ) async {
      final habits = ['Meditate', 'Journal'];
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 390,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final habit in habits)
                    MinimalDismissible(
                      key: ValueKey(habit),
                      onDismissed: () => setState(() => habits.remove(habit)),
                      child: _row(habit),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      // The wrong way does nothing: the leading edge is the back gesture's.
      await tester.fling(find.text('Journal'), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(habits, ['Meditate', 'Journal']);
      await tester.fling(find.text('Journal'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(habits, ['Meditate']);
    });

    testWidgets('the delete is offered as a custom semantics action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var dismissed = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            child: MinimalDismissible(
              key: const ValueKey('HAB-4'),
              label: 'Remove',
              onDismissed: () => dismissed += 1,
              child: _row('Morning run'),
            ),
          ),
        ),
      );
      tester.semantics.customAction(
        find.semantics.byLabel('Morning run'),
        const CustomSemanticsAction(label: 'Remove'),
      );
      expect(dismissed, 1);
      handle.dispose();
    });
  });

  group('MinimalComposer', () {
    testWidgets('sends the trimmed draft, then clears itself', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(SizedBox(width: 360, child: MinimalComposer(onSend: sent.add))),
      );
      await tester.enterText(find.byType(TextField), '  Knee held up.  ');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Send message'));
      await tester.pump();
      expect(sent, ['Knee held up.']);
      expect(find.text('Knee held up.'), findsNothing);
    });

    testWidgets('rests at a large control\'s 40 px and grows with the draft', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(SizedBox(width: 300, child: MinimalComposer(onSend: (_) {}))),
      );
      final rest = tester.getSize(find.byType(MinimalComposer)).height;
      expect(rest, 40);
      await tester.enterText(find.byType(TextField), 'one\ntwo\nthree');
      await tester.pump();
      expect(
        tester.getSize(find.byType(MinimalComposer)).height,
        greaterThan(rest),
      );
    });

    testWidgets('an empty draft offers no send; a draft does', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(SizedBox(width: 360, child: MinimalComposer(onSend: (_) {}))),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Send message')),
        matchesSemantics(
          label: 'Send message',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      await tester.enterText(find.byType(TextField), 'Done');
      await tester.pump();
      final ready = tester
          .getSemantics(find.bySemanticsLabel('Send message'))
          .getSemanticsData();
      expect(ready.flagsCollection.isEnabled, Tristate.isTrue);
      expect(ready.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('Cmd+Enter and Ctrl+Enter send from the keyboard', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(SizedBox(width: 360, child: MinimalComposer(onSend: sent.add))),
      );
      await tester.enterText(find.byType(TextField), 'First');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.enterText(find.byType(TextField), 'Second');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(sent, ['First', 'Second']);
    });

    testWidgets('busy turns send into stop', (tester) async {
      var stopped = 0;
      var sent = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: MinimalComposer(
              busy: true,
              onStop: () => stopped += 1,
              onSend: (_) => sent += 1,
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Send message'), findsNothing);
      // A solid square, never the outline glyph that reads as a checkbox.
      expect(
        find.descendant(
          of: find.byType(MinimalComposerAction),
          matching: find.byType(MinimalIcon),
        ),
        findsNothing,
      );
      await tester.tap(find.bySemanticsLabel('Stop response'));
      expect(stopped, 1);
      expect(sent, 0);
    });

    testWidgets('an empty draft with voice wired offers the mic', (
      tester,
    ) async {
      var voice = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: MinimalComposer(onVoice: () => voice += 1, onSend: (_) {}),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Voice message'));
      expect(voice, 1);
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.pump();
      expect(find.bySemanticsLabel('Voice message'), findsNothing);
      expect(find.bySemanticsLabel('Send message'), findsOneWidget);
    });

    testWidgets('attach, the attachment chip and its remove all answer', (
      tester,
    ) async {
      var attached = 0;
      var removed = 0;
      final sent = <String>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: MinimalComposer(
              attachment: 'run.gpx',
              onAttach: () => attached += 1,
              onRemoveAttachment: () => removed += 1,
              onSend: sent.add,
            ),
          ),
        ),
      );
      expect(find.text('run.gpx'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Add attachment'));
      await tester.tap(find.bySemanticsLabel('Remove attachment'));
      // An attachment alone is something to send.
      await tester.tap(find.bySemanticsLabel('Send message'));
      expect((attached, removed), (1, 1));
      expect(sent, ['']);
    });

    testWidgets('disabled takes no text and sends nothing, dimmed once', (
      tester,
    ) async {
      final sent = <String>[];
      final draft = TextEditingController(text: 'Held');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: MinimalComposer(
              controller: draft,
              enabled: false,
              onSend: sent.add,
            ),
          ),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      // Its controls cannot be used, so they say nothing.
      expect(find.bySemanticsLabel('Send message'), findsNothing);
      await tester.tap(find.byType(MinimalComposerAction), warnIfMissed: false);
      expect(sent, isEmpty);
      expect(draft.text, 'Held');
      // The box dims; the send square inside it does not dim again.
      final inner = tester.widgetList<AnimatedOpacity>(
        find.descendant(
          of: find.byType(MinimalComposerAction),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(inner.every((o) => o.opacity == 1), isTrue);
    });

    testWidgets('the comment box carries its toolbar and a flow-owned '
        'action replaces send', (tester) async {
      var model = 0;
      var dictate = 0;
      var replied = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: MinimalComposer(
              style: MinimalComposerStyle.assistant,
              model: 'Team only',
              onModel: () => model += 1,
              onDictate: () => dictate += 1,
              onSend: (_) {},
              action: MinimalComposerAction(
                icon: LucideIcons.cornerDownLeft,
                label: 'Reply',
                onPressed: () => replied += 1,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Leave a comment…'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Team only'));
      await tester.tap(find.bySemanticsLabel('Dictate message'));
      await tester.tap(find.bySemanticsLabel('Reply'));
      expect((model, dictate, replied), (1, 1, 1));
      expect(find.bySemanticsLabel('Send message'), findsNothing);
    });

    testWidgets('the layout docks the composer under the transcript', (
      tester,
    ) async {
      double? inset;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 390,
            height: 500,
            child: MinimalComposerLayout(
              composer: MinimalComposer(onSend: (_) {}),
              bodyBuilder: (context, bottomInset) {
                inset = bottomInset;
                return ListView(children: const [Text('Twelve days.')]);
              },
            ),
          ),
        ),
      );
      expect(inset, greaterThan(0));
      final transcript = tester.getRect(find.byType(ListView));
      final composer = tester.getRect(find.byType(MinimalComposer));
      expect(composer.top, greaterThanOrEqualTo(transcript.bottom));
    });
  });

  group('MinimalSignInButton', () {
    testWidgets('names the provider, taps, and is 40 px', (tester) async {
      final handle = tester.ensureSemantics();
      // On a phone's width, where a sign-in stack stands: the test's
      // stand-in face sets every glyph a full em wide, so a desktop's 320 px
      // measure would wrap the words to two lines (Geist sets them in 140).
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var taps = 0;
      await tester.pumpWidget(
        _host(MinimalSignInButton('apple', onPressed: () => taps += 1)),
      );
      final button = find.bySemanticsLabel('Continue with Apple');
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          label: 'Continue with Apple',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.getSize(button).height, MinimalChromeMetrics.controlLg);
      await tester.tap(button);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('email says so; a provider the app does not bundle draws '
        'a monogram', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalSignInButton('email', expand: false),
              MinimalSignInButton(
                'sso',
                label: 'Continue with SSO',
                expand: false,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Continue with email'), findsOneWidget);
      // Resolved by lookup in the app's vocabulary: no failed asset load.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('bundled marks resolve: brand, dark cut, mono mask', (
      tester,
    ) async {
      // The asset key the manifest lists: `assets/logos/…` where the app
      // bundles the marks (the package's own tests), under
      // `packages/minimal_ui/` in an app on the package.
      Future<String> asset(
        WidgetTester tester,
        Widget button, {
        Brightness brightness = Brightness.light,
      }) async {
        await tester.pumpWidget(_host(button, brightness: brightness));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        return (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName;
      }

      // Live buttons: a disabled one draws its mono cut.
      expect(
        await asset(tester, MinimalSignInButton('apple', onPressed: () {})),
        'assets/logos/apple_mark.png',
      );
      expect(
        await asset(
          tester,
          MinimalSignInButton('apple', onPressed: () {}),
          brightness: Brightness.dark,
        ),
        'assets/logos/apple_mark_dark.png',
      );
      expect(
        await asset(
          tester,
          const MinimalSignInButton('google', emphasis: true),
        ),
        'assets/logos/google_mark_mask.png',
      );
    });

    testWidgets('disabled, a brand mark turns to its mono cut in the '
        'label\'s ink, so it dims with the words', (tester) async {
      await tester.pumpWidget(_host(const MinimalSignInButton('google')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      final mark = tester.widget<Image>(find.byType(Image));
      expect(
        (mark.image as AssetImage).assetName,
        'assets/logos/google_mark_mask.png',
      );
      expect(
        mark.color,
        MinimalThemeData.preset('standard', Brightness.light).foreground,
      );
    });

    testWidgets('the kit\'s marks resolve where the kit ships them, and an '
        'app\'s own logo of the same name wins', (tester) async {
      // An app on the package lists the kit's marks under the package; an
      // app that bundles them itself lists them under its own folder.
      const kit = minimalFontPackage == null
          ? 'assets/logos/'
          : 'packages/$minimalFontPackage/assets/logos/';
      Future<String> asset(List<String> listed) async {
        await tester.pumpWidget(
          _host(
            DefaultAssetBundle(
              bundle: _LogoBundle(listed),
              child: const MinimalSignInButton('apple'),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        return (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName;
      }

      expect(await asset(['${kit}apple_mark.png']), '${kit}apple_mark.png');
      expect(
        await asset(['${kit}apple_mark.png', 'assets/logos/apple_mark.png']),
        'assets/logos/apple_mark.png',
      );
    });

    testWidgets('a mark the app bundles beyond the kit\'s resolves from its '
        'asset manifest', (tester) async {
      await tester.pumpWidget(
        _host(
          DefaultAssetBundle(
            bundle: _LogoBundle(const ['assets/logos/applepay_mark.png']),
            child: const MinimalSignInButton('applepay', label: 'Apple Pay'),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/logos/applepay_mark.png',
      );
    });

    testWidgets('a stack reports the provider chosen, and disables whole', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      String? chosen;
      await tester.pumpWidget(
        _host(
          MinimalSignInStack(const [
            'apple',
            'google',
            'email',
          ], onPressed: (provider) => chosen = provider),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Continue with Google'));
      expect(chosen, 'google');
      await tester.pumpWidget(
        _host(
          const MinimalSignInStack(['apple', 'google'], key: ValueKey('off')),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Continue with Google')),
        matchesSemantics(
          label: 'Continue with Google',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });
  });

  group('MinimalDialog', () {
    Future<Future<bool?>> raise(
      WidgetTester tester, {
      String? cancelLabel = 'Keep',
    }) async {
      late BuildContext page;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              page = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final answer = showMinimalDialog<bool>(
        page,
        builder: (_) => MinimalDialog(
          title: 'Delete habit?',
          message: 'Its history goes too.',
          confirmLabel: 'Delete',
          cancelLabel: cancelLabel,
          destructive: true,
        ),
      );
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('completes true on confirm', (tester) async {
      final answer = await raise(tester);
      expect(find.text('Its history goes too.'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(find.text('Delete habit?'), findsNothing);
    });

    testWidgets('completes false on cancel', (tester) async {
      final answer = await raise(tester);
      await tester.tap(find.bySemanticsLabel('Keep'));
      await tester.pumpAndSettle();
      expect(await answer, isFalse);
    });

    testWidgets('completes null on a tap on the scrim', (tester) async {
      final answer = await raise(tester);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await answer, isNull);
    });

    testWidgets('Enter confirms and Escape dismisses with null', (
      tester,
    ) async {
      var answer = await raise(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      answer = await raise(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await answer, isNull);
    });

    testWidgets('names its route and offers the confirm alone when asked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final answer = await raise(tester, cancelLabel: null);
      expect(find.bySemanticsLabel('Keep'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Delete habit?')),
        matchesSemantics(
          label: 'Delete habit?',
          scopesRoute: true,
          namesRoute: true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      handle.dispose();
    });

    testWidgets('the card stands in place, its buttons small', (tester) async {
      var confirmed = 0;
      var cancelled = 0;
      await tester.pumpWidget(
        _host(
          MinimalDialog(
            title: 'Archive Morning run?',
            confirmLabel: 'Archive',
            cancelLabel: 'Cancel',
            onConfirm: () => confirmed += 1,
            onCancel: () => cancelled += 1,
          ),
        ),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Archive')).height,
        MinimalChromeMetrics.controlSm,
      );
      expect(
        tester.getSize(find.byType(MinimalDialog)).width,
        lessThanOrEqualTo(MinimalDialog.maxWidth),
      );
      await tester.tap(find.bySemanticsLabel('Archive'));
      await tester.tap(find.bySemanticsLabel('Cancel'));
      expect((confirmed, cancelled), (1, 1));
    });

    Finder shadowed() => find.descendant(
      of: find.byType(MinimalDialog),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).boxShadow != null,
      ),
    );

    testWidgets('in place the card casts no shadow and is no route; raised '
        'it floats', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalDialog(
            title: 'Discard this draft?',
            confirmLabel: 'Discard',
            onConfirm: () {},
          ),
        ),
      );
      expect(shadowed(), findsNothing);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Discard this draft?'))
            .getSemanticsData()
            .flagsCollection
            .scopesRoute,
        isFalse,
      );
      await raise(tester);
      expect(shadowed(), findsOneWidget);
      handle.dispose();
    });
  });

  group('MinimalFilterBar', () {
    testWidgets('a filter announces its count and its selection, and taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var view = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => MinimalFilterBar(
              children: [
                for (final (i, (label, count)) in const [
                  ('All', 6),
                  ('Open', 2),
                  ('Done', 3),
                ].indexed)
                  MinimalFilter(
                    label,
                    count: count,
                    selected: i == view,
                    onPressed: () => setState(() => view = i),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('All, 6')),
        matchesSemantics(
          label: 'All, 6',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Done, 3'));
      await tester.pump();
      expect(view, 2);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Done, 3')),
        matchesSemantics(
          label: 'Done, 3',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a filter with no action is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MinimalFilter('Archived', count: 0)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Archived, 0')),
        matchesSemantics(
          label: 'Archived, 0',
          isButton: true,
          hasEnabledState: true,
          hasSelectedState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the keyboard reaches a filter and Enter selects it', (
      tester,
    ) async {
      var picked = '';
      await tester.pumpWidget(
        _host(
          MinimalFilterBar(
            children: [
              MinimalFilter('Open', onPressed: () => picked = 'Open'),
              MinimalFilter('Done', onPressed: () => picked = 'Done'),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'Done');
    });

    testWidgets('right to left, the trailing control holds the left end', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 360,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: MinimalFilterBar(
                trailing: MinimalIconButton(
                  LucideIcons.slidersHorizontal,
                  label: 'Display',
                  onPressed: () {},
                ),
                children: [
                  MinimalFilter('Open', count: 2, onPressed: () {}),
                  MinimalFilter('Done', count: 3, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(MinimalFilterBar));
      final display = tester.getRect(find.bySemanticsLabel('Display'));
      final open = tester.getRect(find.bySemanticsLabel('Open, 2'));
      expect(display.center.dx, lessThan(open.center.dx));
      expect(open.center.dx, greaterThan(bar.center.dx));
      // The strip's end inset sits on the left, outside the control.
      expect(
        display.left - bar.left,
        moreOrLessEquals(MinimalFilterBar.defaultPadding.end),
      );
    });

    testWidgets('filters that outrun the width scroll, and the trailing '
        'control stays put', (tester) async {
      var display = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 300,
            child: MinimalFilterBar(
              trailing: MinimalIconButton(
                LucideIcons.slidersHorizontal,
                label: 'Display',
                onPressed: () => display += 1,
              ),
              children: [
                for (final label in const [
                  'Backlog',
                  'Todo',
                  'In progress',
                  'In review',
                  'Done',
                  'Cancelled',
                ])
                  MinimalFilter(label, count: 3, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Display'));
      expect(display, 1);
    });
  });

  group('MinimalInputOtp', () {
    testWidgets('a long press offers Paste in Minimal\'s menu at the press, '
        'and Paste fills the code and closes it', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => switch (call.method) {
          'Clipboard.hasStrings' => <String, Object?>{'value': true},
          'Clipboard.getData' => <String, Object?>{'text': '1234'},
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final codes = <String>[];
      await tester.pumpWidget(
        _host(
          MinimalInputOtp(length: 4, label: 'Code', onCompleted: codes.add),
        ),
      );
      final press = tester.getCenter(find.byType(EditableText));
      await tester.longPressAt(press);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
      // The menu opens at the press: its one row just below and after it.
      final word = tester.getTopLeft(find.text('Paste'));
      expect(word.dx - press.dx, inInclusiveRange(0, 32));
      expect(word.dy - press.dy, inInclusiveRange(0, 32));

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      expect(codes, ['1234']);
      expect(find.text('Paste'), findsNothing);
    });

    testWidgets('its submit, formatters and autofill reach the input', (
      tester,
    ) async {
      final submitted = <String>[];
      final upper = TextInputFormatter.withFunction(
        (_, value) => value.copyWith(text: value.text.toUpperCase()),
      );
      await tester.pumpWidget(
        _host(
          MinimalInputOtp(
            length: 4,
            onSubmitted: submitted.add,
            inputFormatters: [upper],
            autofillHints: const [AutofillHints.creditCardSecurityCode],
          ),
        ),
      );
      final input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.inputFormatters, contains(upper));
      expect(input.autofillHints, const [AutofillHints.creditCardSecurityCode]);
      input.onSubmitted!('1234');
      expect(submitted, ['1234']);
    });
  });

  group('MinimalCombobox', () {
    testWidgets('words no option fits say so in the panel, in a row\'s '
        'place; Enter takes nothing and Escape hides it', (tester) async {
      final t = MinimalThemeData.preset('standard', Brightness.light);
      final taken = <String>[];
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 280,
            child: MinimalCombobox<String>(
              label: 'Assignee',
              options: const ['Ana Souza', 'Ben Okafor'],
              onSelected: taken.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'zz');
      await tester.pumpAndSettle();
      final said = find.text('No results');
      expect(said, findsOneWidget);
      expect(tester.widget<Text>(said).style?.color, t.mutedForeground);
      // As tall as an option's row, in the panel under the field.
      final row = find.ancestor(of: said, matching: find.byType(Container));
      expect(tester.getSize(row.first).height, 32);
      // The panel hugs it (the row, its 4 px inset and rim, 4 px off the
      // field), not the room the overlay offers.
      final surface = find.ancestor(
        of: said,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding ==
                  const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
        ),
      );
      expect(tester.getSize(surface.first).height, lessThan(64));
      expect(
        tester.getTopLeft(said).dy,
        greaterThan(tester.getBottomLeft(find.byType(EditableText)).dy),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(taken, isEmpty);
      expect(find.text('zz'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      expect(said, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(said, findsNothing);

      await tester.enterText(find.byType(EditableText), 'Ben');
      await tester.pumpAndSettle();
      expect(said, findsNothing);
      expect(find.text('Ben Okafor'), findsOneWidget);
    });
  });

  group('MinimalSplitButton', () {
    final t = MinimalThemeData.preset('standard', Brightness.light);

    Widget split() => MinimalSplitButton(
      'Save',
      onPressed: () {},
      actions: [MinimalMenuItem('Save as…', onPressed: () {})],
    );

    /// The halves' faces wearing the keyboard's ring.
    List<({Color ring, Color? ground})> rings(WidgetTester tester) => [
      for (final c in tester.widgetList<Container>(
        find.descendant(
          of: find.byType(MinimalSplitButton),
          matching: find.byType(Container),
        ),
      ))
        ?_ringOf(c.foregroundDecoration),
    ];

    /// The row of the two halves and the seam, in paint order.
    Row halves(WidgetTester tester) => tester.widget<Row>(
      find.descendant(
        of: find.byType(MinimalSplitButton),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Row &&
              w.children.length == 3 &&
              w.children[1] is KeyedSubtree,
        ),
      ),
    );

    bool holds(WidgetTester tester, Widget child, Finder target) => find
        .descendant(of: find.byWidget(child), matching: target)
        .evaluate()
        .isNotEmpty;

    for (final direction in TextDirection.values) {
      testWidgets('a focused half wears the button\'s ring outside its edge, '
          'painted over its neighbour (${direction.name})', (tester) async {
        await tester.pumpWidget(
          _host(Directionality(textDirection: direction, child: split())),
        );
        final save = tester.getRect(find.text('Save'));
        final chevron = tester.getRect(find.byType(MinimalIcon));
        expect(rings(tester), isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final ring = rings(tester).single;
        expect(ring.ring, t.ring);
        // Past a gap of the page it stands on.
        expect(ring.ground, t.background);
        // The main half paints last, over the seam and the chevron, and
        // neither half moved to get there.
        expect(
          holds(tester, halves(tester).children.last, find.text('Save')),
          isTrue,
        );
        expect(tester.getRect(find.text('Save')), save);
        expect(tester.getRect(find.byType(MinimalIcon)), chevron);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(rings(tester), hasLength(1));
        expect(
          holds(tester, halves(tester).children.last, find.byType(MinimalIcon)),
          isTrue,
        );
        expect(tester.getRect(find.text('Save')), save);
        expect(tester.getRect(find.byType(MinimalIcon)), chevron);
      });
    }

    /// How opaque each half paints: its words' and its chevron's opacities
    /// all the way up.
    List<double> dims(WidgetTester tester) => [
      for (final part in [find.text('Save'), find.byType(MinimalIcon)])
        tester
            .widgetList<Opacity>(
              find.ancestor(of: part, matching: find.byType(Opacity)),
            )
            .fold(1.0, (product, o) => product * o.opacity),
    ];

    testWidgets('disabled, both halves take the disabled ink and neither '
        'takes a press; with no main action only the main half does', (
      tester,
    ) async {
      var saved = 0;
      Widget build({bool enabled = true, bool main = true}) => _host(
        MinimalSplitButton(
          'Save',
          onPressed: enabled && main ? () => saved++ : null,
          actions: [if (enabled) MinimalMenuItem('Save as…', onPressed: () {})],
        ),
      );

      await tester.pumpWidget(build(enabled: false));
      expect(dims(tester), [0.45, 0.45]);
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.tap(find.byType(MinimalIcon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(saved, 0);
      expect(find.text('Save as…'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(rings(tester), isEmpty);

      await tester.pumpWidget(build(main: false));
      expect(dims(tester), [0.45, 1]);
      await tester.tap(find.byType(MinimalIcon));
      await tester.pumpAndSettle();
      expect(find.text('Save as…'), findsOneWidget);
    });
  });

  group('the focus ring', () {
    /// The colours along the row through the middle of [key]'s boundary,
    /// one per logical pixel.
    Future<List<Color>> row(WidgetTester tester, Key key) async {
      final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final shot = await tester.runAsync(() async {
        final image = await box.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final width = image.width;
        final y = image.height ~/ 2;
        image.dispose();
        return [
          for (var x = 0; x < width; x++)
            Color.fromARGB(
              data.getUint8((y * width + x) * 4 + 3),
              data.getUint8((y * width + x) * 4),
              data.getUint8((y * width + x) * 4 + 1),
              data.getUint8((y * width + x) * 4 + 2),
            ),
        ];
      });
      return shot!;
    }

    bool near(Color a, Color b) =>
        (a.r - b.r).abs() < 0.02 &&
        (a.g - b.g).abs() < 0.02 &&
        (a.b - b.b).abs() < 0.02;

    for (final (name, brightness, inCard) in [
      ('a primary button on the page, light', Brightness.light, false),
      ('a danger button in a card, dark', Brightness.dark, true),
    ]) {
      testWidgets('stands off a filled face by 2 px of the ground it stands '
          'on, so it reads on a face in its own ink: $name', (tester) async {
        final t = MinimalThemeData.preset('standard', brightness);
        const shot = Key('shot');
        final button = Padding(
          padding: const EdgeInsets.all(8),
          child: MinimalButton(
            'Save',
            variant: inCard
                ? MinimalButtonVariant.destructive
                : MinimalButtonVariant.primary,
            onPressed: () {},
          ),
        );
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: shot,
              child: inCard
                  ? MinimalCard(padding: EdgeInsets.zero, child: button)
                  : ColoredBox(color: t.background, child: button),
            ),
            brightness: brightness,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final face = inCard ? t.destructive : t.primary;
        final ground = inCard ? t.card : t.background;
        final line = await row(tester, shot);
        // From the start: the ground, then the ring, the gap, the face.
        final ring = line.indexWhere((c) => near(c, t.ring));
        expect(ring, greaterThan(0));
        expect(near(line[ring + 1], t.ring), isTrue);
        expect(near(line[ring + 2], ground), isTrue);
        expect(near(line[ring + 3], ground), isTrue);
        expect(near(line[ring + 4], face), isTrue);
      }, tags: 'goldens');
    }

    // Round 4: a flush form row's words line up with the form's labels, so
    // its wash and ring reach past them instead of starting on their first
    // pixel, as a list row's text stands inside its own fill.
    final rows = <String, Widget>{
      'MinimalSelect': MinimalSelect<String>(
        label: 'Plan',
        value: 'pro',
        options: const [
          MinimalSelectOption('free', 'Free'),
          MinimalSelectOption('pro', 'Pro'),
        ],
        onChanged: (_) {},
      ),
      'MinimalFormRow': MinimalFormRow(label: 'Plan', onPressed: () {}),
      'MinimalChoiceRow': MinimalChoiceRow(
        title: 'Plan',
        selected: false,
        onPressed: () {},
      ),
      'MinimalProperty': MinimalProperty(
        icon: LucideIcons.circleDot,
        label: 'Plan',
        value: 'Pro',
        onPressed: () {},
      ),
      'MinimalActivity': MinimalActivity(
        at: DateTime(2026, 8, 27, 7, 40),
        text: 'Plan',
        onPressed: () {},
      ),
    };
    for (final MapEntry(key: name, value: part) in rows.entries) {
      testWidgets('$name: the wash and the ring reach 12 px past the row, '
          'its words where they stand at rest', (tester) async {
        await tester.pumpWidget(_host(SizedBox(width: 280, child: part)));
        final pressable = find.byType(MinimalPressable).first;
        final box = tester.getRect(pressable);
        final reach = tester.getRect(
          find.descendant(
            of: pressable,
            matching: find.byWidgetPredicate(
              (w) => w is AnimatedContainer && w.child == null,
            ),
          ),
        );
        expect(
          reach,
          Rect.fromLTRB(box.left - 12, box.top, box.right + 12, box.bottom),
        );
        final words = tester.getRect(find.text('Plan'));
        // A form row's label stands at the row's edge, in line with the
        // form's other labels (a property's and an activity's after their
        // glyph and time columns).
        if (!{'MinimalProperty', 'MinimalActivity'}.contains(name)) {
          expect(words.left, box.left);
        }
        expect(words.left - reach.left, greaterThanOrEqualTo(12));
      });
    }

    for (final brightness in Brightness.values) {
      testWidgets('a select row\'s ring and press stand clear of its label, '
          '${brightness.name}', (tester) async {
        final t = MinimalThemeData.preset('standard', brightness);
        const shot = Key('shot');
        await tester.pumpWidget(
          _host(
            RepaintBoundary(
              key: shot,
              child: ColoredBox(
                color: t.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(width: 240, child: rows['MinimalSelect']),
                ),
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        final origin = tester.getTopLeft(find.byKey(shot));
        final label = (tester.getTopLeft(find.text('Plan')) - origin).dx;
        final idle = await row(tester, shot);

        final finger = await tester.startGesture(
          tester.getCenter(find.text('Plan')),
        );
        // Past the tap's press timeout, then past the wash's fade.
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 400));
        final pressed = await row(tester, shot);
        await finger.cancel();
        await tester.pumpAndSettle();
        // The wash covers the air before the label, 6 px out.
        final before = label.round() - 6;
        expect(near(idle[before], t.background), isTrue);
        expect(near(pressed[before], t.background), isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final focused = await row(tester, shot);
        final ring = focused.indexWhere((c) => near(c, t.ring));
        expect(ring, greaterThanOrEqualTo(0));
        expect(label - ring, greaterThanOrEqualTo(12));
      }, tags: 'goldens');
    }
  });
}

/// The keyboard ring a part's foreground decoration wears, and the ground
/// in the gap between it and the face; null when it wears none.
({Color ring, Color? ground})? _ringOf(Decoration? decoration) {
  if (decoration == null) return null;
  final properties = {
    for (final p in decoration.toDiagnosticsNode().getProperties())
      p.name: p.value,
  };
  final ring = properties['ring'];
  return ring is Color
      ? (ring: ring, ground: properties['ground'] as Color?)
      : null;
}

/// An asset bundle whose manifest lists exactly [assets], and that holds
/// nothing else.
class _LogoBundle extends CachingAssetBundle {
  _LogoBundle(this.assets);

  final List<String> assets;

  @override
  Future<ByteData> load(String key) async {
    if (key != 'AssetManifest.bin') throw FlutterError('No asset $key');
    return const StandardMessageCodec().encodeMessage(<String, Object>{
      for (final asset in assets)
        asset: [
          <String, Object>{'asset': asset},
        ],
    })!;
  }
}
