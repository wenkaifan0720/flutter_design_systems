// The everyday parts survive a phone: the units that wrote their own rows crushed them at 390, so these parts must take
// what a unit hands them, and a row written by hand beside them must keep its words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  group('RetroDesktopListTile', () {
    check(
      'long',
      () => RetroDesktopListTile(
        title: long,
        subtitle: longLine,
        leading: const RetroDesktopMonogram('AC'),
        trailing: const RetroDesktopFlag(long),
        action: RetroDesktopButton(long, onPressed: () {}),
      ),
    );
    check('plain', () => const RetroDesktopListTile(title: 'A row'));
    check(
      'in a list',
      () => RetroDesktopList(
        children: [
          for (var i = 0; i < 5; i++)
            RetroDesktopListTile(
              isFirst: i == 0,
              title: 'Row $i',
              action: RetroDesktopButton('Open', onPressed: () {}),
            ),
        ],
      ),
    );
    check(
      'picture and action',
      () => RetroDesktopListTile(
        title: longLine,
        leading: const RetroDesktopMedia(
          slotId: 'x',
          aspect: 1,
          width: 56,
          label: 'x',
        ),
        action: RetroDesktopButton('Open', onPressed: () {}),
      ),
    );
  });

  // This sample uses a checkbox for its on/off setting.
  group('RetroDesktopCheckbox, RetroDesktopCheckRow', () {
    check(
      'on',
      () =>
          RetroDesktopCheckbox(value: true, onChanged: (_) {}, label: 'Option'),
    );
    check(
      'off, no handler',
      () => const RetroDesktopCheckbox(value: false, label: 'Option'),
    );
    check(
      'row, long',
      () => RetroDesktopCheckRow(
        label: long,
        note: longLine,
        value: true,
        onChanged: (_) {},
      ),
    );
  });

  group('RetroDesktopMedia, with no picture', () {
    check('whole', () => const RetroDesktopMedia(slotId: 'nothing-here'));
    check(
      'a thumbnail',
      () =>
          const RetroDesktopMedia(slotId: 'nothing-here', width: 56, aspect: 1),
    );
    check(
      'in a window',
      () => const RetroDesktopWindow(
        title: 'A window',
        child: RetroDesktopMedia(slotId: 'nothing-here'),
      ),
    );
    testWidgets('stays dark at night', (tester) async {
      await tester.pumpWidget(
        retroDesktopApp(
          const SizedBox(
            width: 200,
            child: RetroDesktopMedia(slotId: 'nothing-here'),
          ),
          dark: true,
        ),
      );
      await tester.pump();
      final c = RetroDesktopThemeData.preset('classic', Brightness.dark).colors;
      final ground = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((b) => b.color)
          .contains(c.platinumDark);
      expect(ground, isTrue);
      expect(c.platinumDark.computeLuminance(), lessThan(.2));
    });
  });

  group('RetroDesktopPictureCard', () {
    check(
      'plain',
      () => const RetroDesktopPictureCard(slotId: 'x', title: 'A piece'),
    );
    check(
      'long',
      () => RetroDesktopPictureCard(
        slotId: 'x',
        title: long,
        subtitle: longLine,
        figure: '1,000,000',
        trailing: const RetroDesktopFlag(long),
        onPressed: () {},
      ),
    );
    check(
      'in a grid',
      () => RetroDesktopGridOf(
        columns: 2,
        gap: 12,
        runGap: 12,
        children: [
          for (var i = 0; i < 3; i++)
            RetroDesktopPictureCard(
              slotId: 'p$i',
              title: 'Piece $i',
              figure: '$i',
              trailing: const RetroDesktopFlag('New'),
            ),
        ],
      ),
    );
  });

  group('RetroDesktopBeside', () {
    check(
      'an object and long words',
      () => RetroDesktopBeside(
        object: const RetroDesktopMonogram('X'),
        child: const RetroDesktopDescriptionList([
          RetroDesktopFact(long, longLine),
        ]),
      ),
    );
    check(
      'a vault, wide',
      () => RetroDesktopBeside(
        object: const RetroDesktopMonogram('X'),
        child: const Text(longLine),
      ),
    );
    check(
      'at the end',
      () => RetroDesktopBeside(
        objectAtEnd: true,
        object: const RetroDesktopMonogram('X'),
        child: const Text('Short'),
      ),
    );
    check(
      'a hand-written row with a vault keeps its words',
      () => const Row(
        children: [
          RetroDesktopMonogram('X'),
          SizedBox(width: 18),
          Expanded(child: Text(longLine)),
        ],
      ),
    );
  });

  group('RetroDesktopChoices', () {
    check(
      'words',
      () => RetroDesktopChoices(
        options: const [
          RetroDesktopChoice('All'),
          RetroDesktopChoice('Behaviour'),
          RetroDesktopChoice('Feeding'),
          RetroDesktopChoice('Near Mint'),
        ],
        onChanged: (_) {},
        value: 'All',
      ),
    );
    check(
      'with notes',
      () => RetroDesktopChoices(
        options: const [
          RetroDesktopChoice('Near Mint', note: 'Minimal sleeve lines'),
          RetroDesktopChoice('Light Marks', note: 'Sharp corners'),
          RetroDesktopChoice('Play Wear', note: 'Some'),
        ],
        value: 'Play Wear',
      ),
    );
    check(
      'long',
      () => const RetroDesktopChoices(
        options: [RetroDesktopChoice(long), RetroDesktopChoice('B')],
      ),
    );
    check(
      'none, one',
      () => const RetroDesktopColumn(
        children: [
          RetroDesktopChoices(options: []),
          RetroDesktopChoices(
            options: [RetroDesktopChoice('Only')],
            value: 'Only',
          ),
        ],
      ),
    );
  });

  group('words stay whole', () {
    check(
      'stats',
      () => RetroDesktopStats(const [
        ('Average', '3,023', 'six periods'),
        ('This period', '1,204,000', 'of 3,000,000'),
        ('Left', '943', 'to the 30th'),
      ]),
    );
    check(
      'readings',
      () => const RetroDesktopReadings([
        ('Average', '3,023', 'six periods'),
        ('This period', '1,204,000', 'of 3,000,000'),
      ]),
    );
    check(
      'big figure',
      () => const RetroDesktopBigFigure('1,204,000', unit: '°'),
    );
    check(
      'stepper',
      () => const RetroDesktopNumberField(
        value: 1204,
        unit: 'people',
        note: longLine,
        max: 1204,
      ),
    );
    check(
      'chips',
      () => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final w in const ['All', 'Kind A', long])
            RetroDesktopChip(w, onPressed: () {}),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      retroDesktopApp(
        Center(
          child: SizedBox(width: width - 40, child: child),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('a chip is as wide as its word', (tester) async {
    await pump(tester, 390, const Wrap(children: [RetroDesktopChip('Kind A')]));
    expect(tester.getSize(find.byType(RetroDesktopChip)).width, lessThan(120));
  });

  testWidgets('a hand-written row keeps its title beside a line button', (
    tester,
  ) async {
    await pump(
      tester,
      390,
      Row(
        children: [
          const Expanded(
            child: Text('A title worth reading', key: ValueKey('title')),
          ),
          RetroDesktopButton('A very long action label here', onPressed: () {}),
        ],
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('title'))).width,
      greaterThanOrEqualTo(150),
    );
  });

  testWidgets('a line button given the whole width takes it', (tester) async {
    await pump(tester, 390, RetroDesktopButton('Open', onPressed: () {}));
    expect(tester.getSize(find.byType(RetroDesktopButton)).width, 350);
  });

  testWidgets('a chosen box re-scopes its words onto the highlight', (
    tester,
  ) async {
    final t = RetroDesktopThemeData.preset('classic', Brightness.light);
    await pump(
      tester,
      390,
      const RetroDesktopChoiceBox(
        selected: true,
        child: Text('x', key: ValueKey('x')),
      ),
    );
    expect(
      DefaultTextStyle.of(tester.element(find.byKey(const ValueKey('x'))))
          .style
          .color,
      t.colors.onHighlight,
    );
  });

  testWidgets('the icons a page passes keep their glyph set', (tester) async {
    await pump(
      tester,
      390,
      const RetroDesktopTextField(
        hint: 'A name',
        trailing: Icon(LucideIcons.search, size: 18),
      ),
    );
    expect(find.byIcon(LucideIcons.search), findsOneWidget);
  });
}
