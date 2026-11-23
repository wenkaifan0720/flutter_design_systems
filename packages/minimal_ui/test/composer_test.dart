import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'faces.dart';
import 'support/centred_host.dart';

void main() {
  group('MinimalComposer', () {
    testWidgets('sends the trimmed draft, then clears itself', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        centredHost(
          SizedBox(width: 360, child: MinimalComposer(onSend: sent.add)),
        ),
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
        centredHost(
          SizedBox(width: 300, child: MinimalComposer(onSend: (_) {})),
        ),
      );
      // The box rests at 40, in a band the floor tall at a finger.
      final rest = faceOf(tester, find.byType(MinimalComposer)).height;
      expect(rest, 40);
      expect(tester.getSize(find.byType(MinimalComposer)).height, 44);
      await tester.enterText(find.byType(TextField), 'one\ntwo\nthree');
      await tester.pump();
      expect(
        faceOf(tester, find.byType(MinimalComposer)).height,
        greaterThan(rest),
      );
    });

    testWidgets('an empty draft offers no send; a draft does', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        centredHost(
          SizedBox(width: 360, child: MinimalComposer(onSend: (_) {})),
        ),
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
        centredHost(
          SizedBox(width: 360, child: MinimalComposer(onSend: sent.add)),
        ),
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
        centredHost(
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
        centredHost(
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
        centredHost(
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

    // A grown draft and a chip leave air over the seats: it is theirs, so
    // attach and send reach a finger's height however tall the box stands.
    testWidgets('attach and send take a tap over their seats', (tester) async {
      final draft = TextEditingController(
        text:
            'Ran 5.2 km before 8. Knee felt fine on the hills, slower on '
            'the flat. Keeping the streak going tomorrow.',
      );
      addTearDown(draft.dispose);
      for (final chip in [false, true]) {
        var attached = 0;
        var removed = 0;
        final sent = <String>[];
        await tester.pumpWidget(
          centredHost(
            SizedBox(
              width: 360,
              child: MinimalComposer(
                key: ValueKey(chip),
                controller: chip ? null : draft,
                attachment: chip ? 'run.gpx' : null,
                onAttach: () => attached += 1,
                onRemoveAttachment: () => removed += 1,
                onSend: sent.add,
              ),
            ),
          ),
        );
        final what = chip ? 'under a chip' : 'beside a grown draft';
        if (!chip) {
          expect(
            tester.getSize(find.byType(TextField)).height,
            greaterThan(40),
            reason: 'a grown draft',
          );
        }
        Offset over(String label) =>
            tester.getRect(find.bySemanticsLabel(label)).topCenter -
            const Offset(0, 6);
        await tester.tapAt(over('Add attachment'));
        await tester.pump();
        expect(attached, 1, reason: what);
        await tester.tapAt(over('Send message'));
        await tester.pump();
        expect(sent, hasLength(1), reason: what);
        expect(removed, 0, reason: what);
      }
    });

    testWidgets('disabled takes no text and sends nothing, dimmed once', (
      tester,
    ) async {
      final sent = <String>[];
      final draft = TextEditingController(text: 'Held');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        centredHost(
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
        centredHost(
          SizedBox(
            width: 360,
            child: MinimalComposer(
              variant: MinimalComposerVariant.assistant,
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
        centredHost(
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
}
