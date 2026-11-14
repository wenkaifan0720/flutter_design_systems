// The everyday parts survive a phone: the units that wrote their own rows crushed them at 390, so these parts must take
// what a unit hands them, and a row written by hand beside them must keep its words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  group('ComicListTile', () {
    check(
      'long',
      () => ComicListTile(
        title: long,
        subtitle: longLine,
        leading: const ComicPerson(initials: 'AC'),
        trailing: const ComicTag(long),
        action: ComicButton(long, onPressed: () {}),
      ),
    );
    check('plain', () => const ComicListTile(title: 'A row'));
    check(
      'in a list',
      () => ComicList(
        children: [
          for (var i = 0; i < 5; i++)
            ComicListTile(
              isFirst: i == 0,
              title: 'Row $i',
              action: ComicButton('Open', onPressed: () {}),
            ),
        ],
      ),
    );
    check(
      'picture and action',
      () => ComicListTile(
        title: longLine,
        leading: const ComicMedia(
          slotId: 'x',
          aspect: 1,
          width: 56,
          label: 'x',
        ),
        action: ComicButton('Open', onPressed: () {}),
      ),
    );
  });

  group('ComicSwitch, ComicSwitchRow', () {
    check('on', () => ComicSwitch(value: true, onChanged: (_) {}));
    check('off, no handler', () => const ComicSwitch(value: false));
    check(
      'row, long',
      () => ComicSwitchRow(
        label: long,
        note: longLine,
        value: true,
        onChanged: (_) {},
      ),
    );
  });

  group('ComicMedia with no picture', () {
    check('on a page', () => const ComicMedia(slotId: 'x', aspect: 16 / 9));
    check(
      'in a panel',
      () => const ComicPanel(child: ComicMedia(slotId: 'x', aspect: 1)),
    );
    check(
      'bare in a band',
      () => const SizedBox(
        height: 120,
        child: ComicArtBand(child: ComicMedia(slotId: 'x', bare: true)),
      ),
    );
    check(
      'on dots',
      () => const ComicPanel(
        ground: ComicPanelFill.dots,
        child: ComicMedia(slotId: 'x', aspect: 1),
      ),
    );
  });

  group('ComicPictureCard', () {
    check('plain', () => const ComicPictureCard(slotId: 'x', title: 'A piece'));
    check(
      'long',
      () => ComicPictureCard(
        slotId: 'x',
        title: long,
        subtitle: longLine,
        figure: '1,000,000',
        trailing: const ComicTag(long),
        onPressed: () {},
      ),
    );
    check(
      'in a grid',
      () => ComicGridOf(
        columns: 2,
        gap: 12,
        runGap: 12,
        children: [
          for (var i = 0; i < 3; i++)
            ComicPictureCard(
              slotId: 'p$i',
              title: 'Piece $i',
              figure: '$i',
              trailing: const ComicTag('New'),
            ),
        ],
      ),
    );
  });

  group('ComicBeside', () {
    check(
      'an object and long words',
      () => ComicBeside(
        object: const ComicPerson(initials: 'X'),
        child: const ComicKvRow(long, longLine, isFirst: true),
      ),
    );
    check(
      'a vault, wide',
      () => ComicBeside(
        object: const ComicPerson(initials: 'X'),
        child: const Text(longLine),
      ),
    );
    check(
      'at the end',
      () => ComicBeside(
        objectAtEnd: true,
        object: const ComicPerson(initials: 'X'),
        child: const Text('Short'),
      ),
    );
    check(
      'a hand-written row with a vault keeps its words',
      () => const Row(
        children: [
          ComicPerson(initials: 'X'),
          SizedBox(width: 18),
          Expanded(child: Text(longLine)),
        ],
      ),
    );
  });

  group('ComicChoices', () {
    check(
      'words',
      () => ComicChoices(
        options: const [
          ComicChoice('All'),
          ComicChoice('Behaviour'),
          ComicChoice('Feeding'),
          ComicChoice('Near Mint'),
        ],
        value: 'All',
        onChanged: (_) {},
      ),
    );
    check(
      'with notes',
      () => ComicChoices(
        options: const [
          ComicChoice('Near Mint', note: 'Minimal sleeve lines'),
          ComicChoice('Light Marks', note: 'Sharp corners'),
          ComicChoice('Play Wear', note: 'Some'),
        ],
        value: 'Play Wear',
      ),
    );
    check(
      'long',
      () => const ComicChoices(options: [ComicChoice(long), ComicChoice('B')]),
    );
    check(
      'none, one',
      () => const ComicColumn(
        children: [
          ComicChoices(options: []),
          ComicChoices(options: [ComicChoice('Only')], value: 'Only'),
        ],
      ),
    );
  });

  group('words stay whole', () {
    check(
      'facts',
      () => const ComicFacts([
        ('3,023', 'six periods'),
        ('1,204,000', 'of 3,000,000'),
        ('943', 'to the 30th'),
      ]),
    );
    check(
      'figures',
      () => const ComicFigures([('20:00', 'Now'), ('1,204', 'Opposition')]),
    );
    check(
      'stepper',
      () => ComicNumberField(
        value: 1204,
        unit: 'people',
        note: longLine,
        format: (count) => '1,204',
      ),
    );
    check(
      'chips',
      () => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final w in const ['All', 'Kind A', long])
            ComicChip(w, onPressed: () {}),
        ],
      ),
    );
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      comicApp(
        Center(
          child: SizedBox(width: width - 40, child: child),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('a chip is as wide as its word', (tester) async {
    await pump(tester, 390, const Wrap(children: [ComicChip('Kind A')]));
    expect(tester.getSize(find.byType(ComicChip)).width, lessThan(120));
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
          ComicButton('A very long action label here', onPressed: () {}),
        ],
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('title'))).width,
      greaterThanOrEqualTo(150),
    );
  });

  testWidgets('a line button given the whole width takes it', (tester) async {
    await pump(tester, 390, ComicButton('Open', onPressed: () {}));
    expect(
      tester
          .getSize(
            find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Outlined'),
          )
          .width,
      350,
    );
  });

  testWidgets('a selected box re-scopes its words onto the lamp', (
    tester,
  ) async {
    final t = ComicTheme.preset('offset', Brightness.light);
    await pump(
      tester,
      390,
      const ComicChoiceBox(
        selected: true,
        child: Text('x', key: ValueKey('x')),
      ),
    );
    expect(
      DefaultTextStyle.of(tester.element(find.byKey(const ValueKey('x'))))
          .style
          .color,
      t.colors.onCaption,
    );
  });

  testWidgets('the icons a page passes keep their glyph set', (tester) async {
    await pump(
      tester,
      390,
      const ComicTextField(
        hint: 'A name',
        trailing: Icon(LucideIcons.search, size: 18),
      ),
    );
    expect(find.byIcon(LucideIcons.search), findsOneWidget);
  });
}
