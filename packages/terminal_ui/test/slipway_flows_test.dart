// Slipway's public gallery flows, exercised with the bundled terminal faces.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/overview.dart';
import '../example/lib/kit_gallery/slipway.dart';
import '../example/lib/kit_gallery/slipway_pages.dart';
import 'faces.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _open(
  WidgetTester tester,
  Widget app,
  double width, {
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, width == 390 ? 844 : 900);
  addTearDown(tester.view.reset);
  kitTextScale = scale;
  addTearDown(() => kitTextScale = 1);
  await tester.pumpWidget(app);
  await _settle(tester);
}

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is TermButton && w.label == label);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

void main() {
  setUpAll(loadFaces);

  for (final width in [390.0, 1440.0]) {
    testWidgets('overview opens the selected run at $width', (tester) async {
      await _open(tester, overviewApp(Brightness.light), width);
      await _tap(tester, find.text('#911 web-console'));
      final run = tester.widget<RunSummary>(find.byType(RunSummary)).run;
      expect(
        (run.number, run.commit, run.status),
        (911, '2be8f90', RunStatus.passed),
      );
      expect(find.textContaining('2be8f90 merge:'), findsOneWidget);
    });

    testWidgets(
      'the production command targets production and asks before queuing at $width',
      (tester) async {
        await _open(
          tester,
          slipwayApp(Brightness.dark, place: SlipwayPlace.palette),
          width,
        );
        final search = find.descendant(
          of: find.byType(TermCommandPalette),
          matching: find.byType(EditableText),
        );
        await tester.enterText(search, 'deploy atlas-api to production');
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _settle(tester);
        final field = find.byWidgetPredicate(
          (w) => w is TermSelect<String> && w.labelText == 'environment',
        );
        expect(tester.widget<TermSelect<String>>(field).value, 'production');
        await _tap(tester, _button('deploy'));
        expect(find.byType(TermConfirmDialog), findsOneWidget);
        await _tap(tester, _button('no'));
        expect(find.textContaining('deploy #1490 queued'), findsNothing);
        await _tap(tester, _button('deploy'));
        await _tap(
          tester,
          find.descendant(
            of: find.byType(TermConfirmDialog),
            matching: _button('deploy'),
          ),
        );
        await _tap(tester, _button('watch'));
        final run = tester.widget<RunSummary>(find.byType(RunSummary)).run;
        expect(
          (run.number, run.status, run.message),
          (1490, RunStatus.queued, 'deploy to production'),
        );
      },
    );
  }

  testWidgets('a blank ref stays in the form and valid input is trimmed', (
    tester,
  ) async {
    await _open(
      tester,
      slipwayApp(Brightness.light, place: SlipwayPlace.deploy),
      390,
    );
    final branch = find.byType(EditableText);
    await tester.enterText(branch, '   ');
    await _tap(tester, _button('deploy'));
    expect(find.text('enter a branch or commit'), findsOneWidget);
    expect(tester.widget<EditableText>(branch).focusNode.hasFocus, isTrue);
    expect(find.textContaining('queued:'), findsNothing);
    await tester.enterText(branch, '  main  ');
    await tester.pump();
    expect(find.text('enter a branch or commit'), findsNothing);
    await _tap(tester, _button('deploy'));
    expect(
      find.text('deploy #1490 queued: atlas-api main → staging'),
      findsOneWidget,
    );
  });

  testWidgets(
    'cancel stops a running run in the detail, log, history and home',
    (tester) async {
      await _open(
        tester,
        slipwayApp(Brightness.dark, place: SlipwayPlace.run),
        1440,
      );
      await _tap(tester, _button('cancel'));
      final run = tester.widget<RunSummary>(find.byType(RunSummary)).run;
      expect((run.number, run.status), (1482, RunStatus.canceled));
      expect(_button('cancel'), findsNothing);
      expect(slipwayLogOf(run).last, 'run canceled during test');
      expect(slipwayStepsOf(run).first.status, RunStatus.passed);
      expect(
        slipwayStepsOf(run).firstWhere((s) => s.name == 'test').status,
        RunStatus.canceled,
      );
      final tile = find.ancestor(
        of: find.text('#1482 atlas-api').first,
        matching: find.byType(TermListTile),
      );
      final glyph = find.descendant(
        of: tile,
        matching: find.byType(StatusGlyph),
      );
      expect(tester.widget<StatusGlyph>(glyph).status, RunStatus.canceled);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(TermSideBar),
          matching: find.text('home'),
        ),
      );
      expect(find.text('no runs in progress'), findsOneWidget);
    },
  );

  testWidgets(
    'cancel discards the edited deploy and Escape returns to the originating run',
    (tester) async {
      await _open(
        tester,
        slipwayApp(Brightness.light, place: SlipwayPlace.run),
        1440,
      );
      final deployNav = find.descendant(
        of: find.byType(TermSideBar),
        matching: find.text('deploy'),
      );
      await _tap(tester, deployNav);
      await _tap(tester, find.text('canary'));
      await _tap(tester, _button('cancel'));
      expect(find.byType(DeployPage), findsNothing);
      expect(
        tester.widget<RunSummary>(find.byType(RunSummary)).run.number,
        1482,
      );
      await _tap(tester, deployNav);
      final rolling = find.byWidgetPredicate(
        (w) => w is TermRadio<String> && w.value == 'rolling',
      );
      expect(
        RadioGroup.maybeOf<String>(tester.element(rolling))?.groupValue,
        'rolling',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(RunSummary), findsOneWidget);
    },
  );

  testWidgets(
    'enlarged RTL runs keep the search and filters inside their page',
    (tester) async {
      await _open(
        tester,
        slipwayApp(
          Brightness.dark,
          direction: TextDirection.rtl,
          place: SlipwayPlace.runs,
        ),
        1440,
        scale: 2,
      );
      final side = tester.getRect(find.byType(TermSideBar));
      final search = find.byWidgetPredicate(
        (w) => w is TermTextField && w.labelText == 'search',
      );
      for (final part in [search.first, find.byType(TermTabBar).first]) {
        final rect = tester.getRect(part);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(side.left));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the enlarged overview title stays on one line beside the caret',
    (tester) async {
      await _open(tester, overviewApp(Brightness.light), 390, scale: 2);
      final title = find
          .ancestor(
            of: find.byType(TermCaret).first,
            matching: find.byType(Row),
          )
          .first;
      final name = find.descendant(
        of: title,
        matching: find.text('terminal_ui'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(name);
      expect(
        paragraph.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(paragraph.size.width + 0.5),
      );
      expect(
        tester.getCenter(name).dy,
        closeTo(tester.getCenter(find.byType(TermCaret).first).dy, 1),
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'the enlarged deletion warning opens at the start and its disabled action is an ordinary key, still read, on ${brightness.name}',
      (tester) async {
        await _open(
          tester,
          slipwayApp(brightness, place: SlipwayPlace.confirm),
          390,
          scale: 2,
        );
        final statement = find.text(
          'atlas-api, its 1482 runs and their logs go for good.',
        );
        final scroll = Scrollable.of(tester.element(statement));
        expect(
          scroll.position.pixels,
          closeTo(scroll.position.minScrollExtent, 0.01),
        );
        final action = _button('delete');
        expect(tester.widget<TermButton>(action).onPressed, isNull);
        final tex = tester.widget<Text>(
          find.descendant(of: action, matching: find.text('delete')),
        );
        final painter =
            tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: action,
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter is TermBracketPainter,
                        ),
                      ),
                    )
                    .painter
                as TermBracketPainter;
        final theme = TermTheme.of(tester.element(action));
        // An ordinary key on the dialog's ground, its words in the ink of
        // every key that can't be pressed: fainter than a live key's, and
        // still read.
        expect(painter.fill, isNull);
        expect(
          RawPalette.contrastRatio(tex.style!.color!, theme.surface),
          greaterThanOrEqualTo(3),
        );
      },
    );
  }
  testWidgets(
    'deleting a project removes its runs, status and deployment target',
    (tester) async {
      await _open(
        tester,
        slipwayApp(Brightness.light, place: SlipwayPlace.confirm),
        1440,
      );
      final dialog = find.byType(TermConfirmDialog);
      final field = find.descendant(
        of: dialog,
        matching: find.byType(EditableText),
      );
      await tester.enterText(field, 'atlas-api');
      await tester.pump();
      await _tap(
        tester,
        find.descendant(of: dialog, matching: _button('delete')),
      );
      expect(find.text('atlas-api deleted'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('atlas-api'), findsNothing);
      expect(find.text('web-console'), findsWidgets);
      final nav = find.byType(TermSideBar);
      await _tap(tester, find.descendant(of: nav, matching: find.text('runs')));
      expect(find.textContaining('#1482 atlas-api'), findsNothing);
      expect(
        tester.widget<RunSummary>(find.byType(RunSummary)).run.project,
        'web-console',
      );
      await _tap(
        tester,
        find.descendant(of: nav, matching: find.text('deploy')),
      );
      final project = tester.widget<TermSelect<String>>(
        find.byWidgetPredicate(
          (w) => w is TermSelect<String> && w.labelText == 'project',
        ),
      );
      expect(project.items.map((p) => p.value), isNot(contains('atlas-api')));
      expect(project.value, 'web-console');
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      'the progress percentage and every toggle fit the pane in ${direction.name}',
      (tester) async {
        final selections = <String>{'build'};
        await _open(
          tester,
          kitApp(
            brightness: Brightness.dark,
            direction: direction,
            home: Center(
              child: SizedBox(
                width: 354,
                child: TermPane(
                  title: 'atlas-api',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TermProgressBar(value: .62),
                      TermToggleGroup<String>(
                        options: const ['build', 'test', 'deploy'],
                        selected: selections,
                        labelOf: (name) => name,
                        multiSelectionEnabled: true,
                        onSelectionChanged: (value) {
                          selections
                            ..clear()
                            ..addAll(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          390,
          scale: 2,
        );
        final pane = tester.getRect(find.byType(TermPane));
        final percentage = tester.getRect(find.text('62%'));
        final track = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is TermBlocksPainter,
          ),
        );
        for (final box in [
          track,
          percentage,
          tester.getRect(find.text('deploy')),
        ]) {
          expect(pane.contains(box.topLeft), isTrue);
          expect(pane.contains(box.centerRight), isTrue);
        }
        expect(track.overlaps(percentage), isFalse);
        await _tap(tester, find.text('deploy'));
        expect(selections, contains('deploy'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a long confirmation title is visible in full on a large-text phone',
    (tester) async {
      await _open(
        tester,
        kitApp(
          brightness: Brightness.light,
          home: Builder(
            builder: (context) => Center(
              child: TermButton(
                label: 'open',
                onPressed: () => showTermConfirmDialog(
                  context: context,
                  title: 'deploy to production',
                  message: 'deploy atlas-api to production?',
                  confirmLabel: 'deploy',
                ),
              ),
            ),
          ),
        ),
        390,
        scale: 2,
      );
      await _tap(tester, _button('open'));
      final title = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').replaceAll(RegExp('[\u2068\u2069]'), '') ==
                'deploy to production',
      );
      expect(title, findsOneWidget);
      final para = tester.renderObject<RenderParagraph>(title);
      expect(
        para.getBoxesForSelection(
          const TextSelection(baseOffset: 19, extentOffset: 20),
        ),
        isNotEmpty,
      );
      await _tap(tester, _button('no'));
    },
  );
}
