// The everyday parts survive a phone: the units that wrote their own rows crushed them at 390, so these parts must take
// what a unit hands them, and a row written by hand beside them must keep its words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('NeumorphicListTile', () {
    check(
      'long',
      () => NeumorphicListTile(
        title: long,
        subtitle: longLine,
        leading: const NeumorphicMonogram('AC'),
        trailing: const NeumorphicStatus(long),
        action: NeumorphicButton(long, onPressed: () {}),
      ),
    );
    check('plain', () => const NeumorphicListTile(title: 'A row'));
    check(
      'in a list',
      () => NeumorphicList(
        children: [
          for (var i = 0; i < 5; i++)
            NeumorphicListTile(
              isFirst: i == 0,
              title: 'Row $i',
              action: NeumorphicButton('Open', onPressed: () {}),
            ),
        ],
      ),
    );
    check(
      'picture and action',
      () => NeumorphicListTile(
        title: longLine,
        leading: const NeumorphicMedia(
          slotId: 'x',
          aspect: 1,
          width: 56,
          label: 'x',
        ),
        action: NeumorphicButton('Open', onPressed: () {}),
      ),
    );
  });

  group('NeumorphicSwitch, NeumorphicSwitchRow', () {
    check('on', () => NeumorphicSwitch(value: true, onChanged: (_) {}));
    check('off, no handler', () => const NeumorphicSwitch(value: false));
    check(
      'row, long',
      () => NeumorphicSwitchRow(
        label: long,
        note: longLine,
        value: true,
        onChanged: (_) {},
      ),
    );
  });

  group('NeumorphicPictureCard', () {
    check(
      'plain',
      () => const NeumorphicPictureCard(slotId: 'x', title: 'A piece'),
    );
    check(
      'long',
      () => NeumorphicPictureCard(
        slotId: 'x',
        title: long,
        subtitle: longLine,
        figure: '1,000,000',
        trailing: const NeumorphicTag(long),
        onPressed: () {},
      ),
    );
    check(
      'in a grid',
      () => NeumorphicGridOf(
        columns: 2,
        gap: 12,
        runGap: 12,
        children: [
          for (var i = 0; i < 3; i++)
            NeumorphicPictureCard(
              slotId: 'p$i',
              title: 'Piece $i',
              figure: '$i',
              trailing: const NeumorphicTag('New'),
            ),
        ],
      ),
    );
  });

  group('NeumorphicBeside', () {
    check(
      'an object and long words',
      () => NeumorphicBeside(
        object: const NeumorphicMonogram('X'),
        child: const NeumorphicKvRow(long, longLine, isFirst: true),
      ),
    );
    check(
      'a vault, wide',
      () => NeumorphicBeside(
        object: const NeumorphicMonogram('X'),
        child: const Text(longLine),
      ),
    );
    check(
      'at the end',
      () => NeumorphicBeside(
        objectAtEnd: true,
        object: const NeumorphicMonogram('X'),
        child: const Text('Short'),
      ),
    );
    check(
      'a hand-written row with a vault keeps its words',
      () => const Row(
        children: [
          NeumorphicMonogram('X'),
          SizedBox(width: 18),
          Expanded(child: Text(longLine)),
        ],
      ),
    );
  });

  group('NeumorphicChoices', () {
    check(
      'words',
      () => NeumorphicChoices(
        options: const [
          NeumorphicChoice('All'),
          NeumorphicChoice('Behaviour'),
          NeumorphicChoice('Feeding'),
          NeumorphicChoice('Near Mint'),
        ],
        value: 'All',
        onChanged: (_) {},
      ),
    );
    check(
      'with notes',
      () => NeumorphicChoices(
        options: const [
          NeumorphicChoice('Near Mint', note: 'Minimal sleeve lines'),
          NeumorphicChoice('Light Marks', note: 'Sharp corners'),
          NeumorphicChoice('Play Wear', note: 'Some'),
        ],
        value: 'Play Wear',
      ),
    );
    check(
      'long',
      () => const NeumorphicChoices(
        options: [NeumorphicChoice(long), NeumorphicChoice('B')],
      ),
    );
    check(
      'none, one',
      () => const NeumorphicColumn(
        children: [
          NeumorphicChoices(options: []),
          NeumorphicChoices(options: [NeumorphicChoice('Only')], value: 'Only'),
        ],
      ),
    );
  });

  group('words stay whole', () {
    check(
      'stats',
      () => const NeumorphicStats([
        NeumorphicStat('Average', '3,023', 'six periods'),
        NeumorphicStat('This period', '1,204,000', 'of 3,000,000'),
        NeumorphicStat('Left', '943', 'to the 30th'),
      ]),
    );
    check(
      'stepper',
      () => const NeumorphicNumberField(
        value: '1,204',
        unit: 'people',
        note: longLine,
      ),
    );
    check(
      'chips',
      () => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final w in const ['All', 'Kind A', long])
            NeumorphicChip(w, onPressed: () {}),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: SizedBox(width: width - 40, child: child),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('a chip is as wide as its word', (tester) async {
    await pump(tester, 390, const Wrap(children: [NeumorphicChip('Kind A')]));
    expect(tester.getSize(find.byType(NeumorphicChip)).width, lessThan(120));
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
          NeumorphicButton('A very long action label here', onPressed: () {}),
        ],
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('title'))).width,
      greaterThanOrEqualTo(150),
    );
  });

  testWidgets('a line button hugs, and takes the whole width when wide', (
    tester,
  ) async {
    await pump(
      tester,
      390,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicButton('Open', onPressed: () {}),
      ),
    );
    expect(tester.getSize(find.byType(NeumorphicButton)).width, lessThan(120));
    await pump(
      tester,
      390,
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicButton('Open', wide: true, onPressed: () {}),
      ),
    );
    expect(tester.getSize(find.byType(NeumorphicButton)).width, 350);
  });

  testWidgets(
    'a selected box tells you with no shadow: an LED, not only a press',
    (tester) async {
      await pump(
        tester,
        390,
        const NeumorphicFlatScope(
          child: NeumorphicColumn(
            children: [
              NeumorphicChoiceBox(selected: true, child: Text('selected')),
              NeumorphicChoiceBox(child: Text('not')),
            ],
          ),
        ),
      );
      expect(find.byType(NeumorphicLed), findsOneWidget);
    },
  );

  testWidgets('the icons a page passes keep their glyph set', (tester) async {
    await pump(
      tester,
      390,
      const NeumorphicTextField(
        hint: 'A name',
        trailing: Icon(NeumorphicGlyphs.search, size: 18),
      ),
    );
    expect(find.byIcon(NeumorphicGlyphs.search), findsOneWidget);
  });
}
