// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/papers.dart';
import 'support.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, width == 390 ? 844 : 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(),
          child: app!,
        ),
      ),
      home: Directionality(textDirection: direction, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

List<SemanticsData> _nodes(WidgetTester tester) {
  final data = <SemanticsData>[];
  bool visit(SemanticsNode node) {
    data.add(node.getSemanticsData());
    node.visitChildren(visit);
    return true;
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return data;
}

Future<void> _press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  testWidgets(
    'balancing a Hebrew document heading keeps each word together at twice text size',
    (tester) async {
      const title = 'הערות הפרויקט';
      await _show(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 336,
            child: RetroDesktopDocument(title: title),
          ),
        ),
        direction: TextDirection.rtl,
        scale: 2,
      );
      final p = tester.renderObject<RenderParagraph>(find.text(title));
      for (final start in [0, title.indexOf(' ') + 1]) {
        final end = start == 0 ? title.indexOf(' ') : title.length;
        final boxes = p.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        );
        expect(boxes.map((box) => box.top).toSet(), hasLength(1));
      }
    },
  );
  for (final dir in TextDirection.values) {
    testWidgets(
      'segment labels and URL parts keep the requested text size at 390 in $dir',
      (tester) async {
        String chosen = 'PC';
        await _show(
          tester,
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 332,
              child: StatefulBuilder(
                builder: (context, update) => Column(
                  children: [
                    RetroDesktopSegmentedButton<String>(
                      label: 'Appearance',
                      value: chosen,
                      segments: const [
                        RetroDesktopButtonSegment('PC', 'Chisel (95-era PC)'),
                        RetroDesktopButtonSegment(
                          'Mac',
                          'Platinum (classic Mac)',
                        ),
                      ],
                      onChanged: (value) => update(() => chosen = value),
                    ),
                    const RetroDesktopInputGroup(
                      labelText: 'Site',
                      prefix: 'https://',
                      hintText: 'studio',
                      suffix: '.example.com',
                    ),
                  ],
                ),
              ),
            ),
          ),
          scale: 2,
          direction: dir,
        );
        final first = find.text('Chisel (95-era PC)'),
            last = find.text('Platinum (classic Mac)');
        expect(
          tester.getTopLeft(last).dy,
          greaterThan(tester.getBottomLeft(first).dy),
        );
        for (final label in [
          'Chisel (95-era PC)',
          'Platinum (classic Mac)',
          'https://',
          '.example.com',
        ]) {
          final p = tester.renderObject<RenderParagraph>(find.text(label));
          expect(p.didExceedMaxLines, isFalse, reason: label);
          expect(p.textScaler.scale(14), 28);
        }
        await _press(tester, last);
        expect(chosen, 'Mac');
        final editor = find.byType(EditableText);
        expect(
          tester.getBottomLeft(find.text('https://')).dy,
          lessThanOrEqualTo(tester.getTopLeft(editor).dy),
        );
        expect(
          tester.getTopLeft(find.text('.example.com')).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(editor).dy),
        );
        await tester.enterText(editor, 'studio');
        expect(tester.widget<EditableText>(editor).controller.text, 'studio');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'the total stays inside the phone as invoice columns scroll at twice text size',
    (tester) async {
      await _show(
        tester,
        const KitPapers(front: KitPapersWindow.prints, alone: true),
        direction: TextDirection.rtl,
        scale: 2,
      );
      final total = find.text(r'$12.00').first;
      await tester.ensureVisible(total);
      final rect = tester.getRect(total);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
      final scroll = find.descendant(
        of: find.byType(RetroDesktopTable),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
      );
      expect(scroll, findsOneWidget);
      final x = rect.left;
      final scroller = tester.widget<SingleChildScrollView>(scroll).controller!;
      expect(scroller.position.maxScrollExtent, greaterThan(0));
      await Scrollable.ensureVisible(tester.element(scroll), alignment: .5);
      await tester.pumpAndSettle();
      final start = scroller.offset;
      await tester.dragFrom(
        tester
            .getRect(scroll)
            .intersect(const Rect.fromLTWH(0, 0, 390, 844))
            .center,
        const Offset(90, 0),
      );
      await tester.pumpAndSettle();
      expect(scroller.offset, greaterThan(start));
      expect(tester.getRect(total).left, x);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saved and discarded contact details survive reopening from the Papers menu',
    (tester) async {
      await _show(
        tester,
        const KitPapers(front: KitPapersWindow.details, alone: true),
        width: 1440,
      );
      final email = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is RetroDesktopTextField && w.labelText == 'Email address',
        ),
        matching: find.byType(EditableText),
      );
      Finder action(String label) => find.descendant(
        of: find.byType(KitDetailsForm),
        matching: find.widgetWithText(RetroDesktopButton, label),
      );
      Future<void> reopen() async {
        await _press(tester, find.text('Papers').first);
        await _press(tester, find.text('Your details…'));
      }

      await tester.enterText(email, 'new@example.net');
      await _press(tester, action('Save'));
      await reopen();
      expect(
        tester.widget<EditableText>(email).controller.text,
        'new@example.net',
      );
      await tester.enterText(email, 'discard@example.net');
      await _press(tester, action('Cancel'));
      await reopen();
      expect(
        tester.widget<EditableText>(email).controller.text,
        'new@example.net',
      );
      await tester.enterText(email, 'confirmed@example.net');
      await _press(tester, find.bySemanticsLabel('Close').first);
      final dialog = find.byType(RetroDesktopDialog);
      await _press(
        tester,
        find.descendant(of: dialog, matching: find.text('Save')),
      );
      await reopen();
      expect(
        tester.widget<EditableText>(email).controller.text,
        'confirmed@example.net',
      );
    },
  );

  testWidgets('the phone confirmation shows one set of actions', (
    tester,
  ) async {
    await _show(
      tester,
      const KitPapers(
        front: KitPapersWindow.details,
        moment: KitPapersMoment.unsaved,
        alone: true,
      ),
      scale: 2,
    );
    expect(find.byType(RetroDesktopDialog), findsOneWidget);
    final visibleActions = tester.widgetList<Visibility>(
      find.descendant(
        of: find.byType(KitDetailsForm, skipOffstage: false),
        matching: find.byType(Visibility, skipOffstage: false),
        skipOffstage: false,
      ),
    );
    expect(visibleActions.any((w) => !w.visible && w.maintainSize), isTrue);
    await _press(
      tester,
      find.descendant(
        of: find.byType(RetroDesktopDialog),
        matching: find.text('Cancel'),
      ),
    );
    final actions = tester.widgetList<Visibility>(
      find.descendant(
        of: find.byType(KitDetailsForm),
        matching: find.byType(Visibility),
      ),
    );
    expect(actions.every((widget) => widget.visible), isTrue);
  });

  testWidgets(
    'File and its shortcuts cannot open a document hidden by search',
    (tester) async {
      await _show(
        tester,
        const KitPapers(front: KitPapersWindow.documents, alone: true),
      );
      await tester.enterText(
        find.byType(EditableText).first,
        'zzzz-does-not-match',
      );
      await tester.pumpAndSettle();
      final file = tester
          .widget<RetroDesktopMenuBar>(find.byType(RetroDesktopMenuBar))
          .menus
          .firstWhere((entry) => entry.label == 'File');
      for (final text in ['Open', 'Order printed copies…']) {
        expect(
          file.children!.firstWhere((e) => e.label == text).onPressed,
          isNull,
        );
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(RetroDesktopDocument), findsNothing);
      expect(find.byType(RetroDesktopTable), findsNothing);
    },
  );

  testWidgets(
    'list rows keep their subtitles and explicit names, a sheet title is spoken once',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        Column(
          children: [
            RetroDesktopListTile(
              title: 'Invoice',
              subtitle: 'Due Friday',
              onPressed: () {},
            ),
            RetroDesktopListTile(
              title: 'Attachment',
              subtitle: 'Personal',
              semanticLabel: 'Open file',
              onPressed: () {},
            ),
            Builder(
              builder: (context) => RetroDesktopButton(
                'Details',
                onPressed: () => showRetroDesktopSheet<void>(
                  context,
                  title: 'File details',
                  builder: (_) => const Text('Body'),
                ),
              ),
            ),
          ],
        ),
      );
      expect(
        _nodes(tester).map((d) => d.label),
        containsAll(['Invoice, Due Friday', 'Open file']),
      );
      await _press(tester, find.text('Details'));
      final titles = _nodes(tester)
          .expand((d) => d.label.split('\n'))
          .where((s) => s == 'File details');
      expect(titles, hasLength(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('File details'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('RTL progress reads the completed count before the total', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      Column(
        children: [
          const RetroDesktopStepProgress(
            count: 3,
            currentStep: 0,
            name: 'Installation',
          ),
          kitSpecimenProgress(),
        ],
      ),
      direction: TextDirection.rtl,
      scale: 2,
    );
    final p = tester.renderObject<RenderParagraph>(find.text('1 / 3'));
    expect(p.textDirection, TextDirection.ltr);
    expect(
      _nodes(tester).where((n) => n.label == 'Installation').single.value,
      '1 / 3',
    );
    expect(find.text('הושלמו 2 מתוך 5'), findsOneWidget);
    semantics.dispose();
  });
}
