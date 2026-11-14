// Each signature part with odd data: empty, one, many, long words, RTL. No overflow, no exception, at 320 and 1440, light
// and dark. The real faces are loaded, so a long word is measured as it would be on a device.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

const _head = ComicPerson(initials: 'AB', size: 24);
List<ComicPerson> _heads(int n) => [
  for (var i = 0; i < n; i++)
    ComicPerson(initials: 'AB', size: 24, fillIndex: i % 3),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  group('ComicTier', () {
    const p = ComicPanel(child: Text('A few words in a panel'));
    final longPanel = ComicPanel(caption: long, child: const Text(longLine));
    for (final reflow in ComicTierLayout.values) {
      for (final n in const [1, 2, 3, 4, 5, 7]) {
        check(
          '${reflow.name} of $n',
          () => ComicTier(phone: reflow, children: List.filled(n, p)),
        );
      }
      check(
        '${reflow.name} with long words',
        () => ComicTier(
          phone: reflow,
          children: [longPanel, longPanel, longPanel],
        ),
      );
    }
    check('no children', () => const ComicTier(children: []));
    check('spans', () => const ComicTier(spans: [8, 4], children: [p, p]));
    check(
      'slanted',
      () => const ComicTier(
        slanted: true,
        spans: [7, 5],
        children: [
          ComicMarkPanel(
            title: 'Leaning one way',
            date: 'A date',
            leading: ComicMark(ComicMarks.tent),
            sfx: 'Snap!',
            words: 'A few words',
          ),
          ComicMarkPanel(
            title: 'And the other',
            date: 'A date',
            leading: ComicMark(ComicMarks.dice),
            ground: 2,
            sfx: 'Clack!',
            words: 'A few words',
          ),
        ],
      ),
    );
    check(
      'a stack beside a panel',
      () => const ComicTier(
        spans: [8, 4],
        children: [
          p,
          ComicPanelStack(children: [p, p]),
        ],
      ),
    );
  });

  group('ComicPanel', () {
    for (final g in ComicPanelFill.values) {
      check(
        g.name,
        () => ComicPanel(
          ground: g,
          caption: 'A caption',
          child: const Text('Words'),
        ),
      );
    }
    check('no child', () => const ComicPanel(caption: 'A caption'));
    check('empty', () => const ComicPanel());
    check(
      'long',
      () => ComicPanel(caption: longLine, child: const Text(longLine)),
    );
    check(
      'bleed, pressable',
      () =>
          ComicPanel(bleed: true, onPressed: () {}, child: const Text('Words')),
    );
  });

  group('ComicCaption', () {
    for (final tone in ComicSpeaker.values) {
      check(tone.name, () => ComicCaption('A caption', tone: tone));
    }
    check('long', () => const ComicCaption(longLine));
    check('free', () => const ComicCaption(longLine, free: true));
    check('tight', () => const ComicCaption(long, tight: true));
  });

  group('ComicBalloon', () {
    for (final tail in ComicTail.values) {
      check('$tail one word', () => ComicBalloon('Hm.', tail: tail));
      check('$tail long', () => ComicBalloon(longLine, tail: tail, by: long));
    }
    check('empty', () => const ComicBalloon(''));
    check('nothing', () => const ComicBalloon(null));
    check('tail at the far end', () => const ComicBalloon('Words', tailAt: 1));
    check('tail at the start', () => const ComicBalloon('Words', tailAt: 0));
    check('small', () => const ComicBalloon(longLine, small: true));
    check('fill', () => const ComicBalloon('Words', fill: true));
    check(
      'with its own child',
      () => const ComicBalloon(null, child: Text(longLine)),
    );
  });

  group('ComicThought', () {
    check('three dots', () => const ComicThought('...'));
    check('long', () => const ComicThought(longLine));
    check('empty', () => const ComicThought(''));
    check('no trail', () => const ComicThought('Hm', trail: false));
    check('trail at the end', () => const ComicThought('Hm', trailEnd: true));
  });

  group('ComicBurst', () {
    check('a number', () => const ComicBurst(number: '7'));
    check(
      'words',
      () => const ComicBurst(number: '23', over: 'In', under: 'days!'),
    );
    check('large', () => const ComicBurst(number: '23', large: true));
    check(
      'a huge number',
      () => const ComicBurst(number: '1,234,567,890', over: long, under: long),
    );
    check('empty', () => const ComicBurst(number: ''));
    check(
      'two lines',
      () => const ComicBurst(number: 'Quiz\nnight', over: 'Tomorrow!'),
    );
    check(
      'small',
      () => const ComicBurst(number: '1,234', width: 40, height: 40),
    );
  });

  group('ComicPop, ComicStamp', () {
    check('a pop', () => const ComicPop('5'));
    check('a long pop', () => const ComicPop('1,234,567'));
    check(
      'a plate',
      () => const ComicPop('4.7', width: 96, height: 80, size: 34, plate: true),
    );
    check('a stamp', () => const ComicStamp('Paid'));
    check('a long stamp', () => const ComicStamp(long));
  });

  group('ComicPerson, ComicPeople, ComicLineup', () {
    for (final b in ComicBust.values) {
      check(
        b.name,
        () => ComicPerson(portrait: ComicPortrait(b, cropped: true), size: 48),
      );
    }
    check('initials', () => const ComicPerson(initials: 'ABC'));
    check('nothing', () => const ComicPerson());
    check('a picture', () => const ComicPerson(slotId: 'nothing-here'));
    check('seeded', () => ComicPerson.seeded(long));
    check('none', () => const ComicPeople([]));
    check('forty', () => ComicPeople(_heads(40)));
    check('a lineup of none', () => const ComicLineup([]));
    check(
      'a lineup of one',
      () => const ComicLineup([
        ComicCast('Sam', portrait: ComicPortrait(ComicBust.bob)),
      ]),
    );
    check(
      'a lineup of twelve, long names',
      () => ComicLineup([for (var i = 0; i < 12; i++) ComicCast(long)]),
    );
  });

  group('ComicBar, ComicBarList', () {
    check('zero', () => const ComicBar(value: 0, of: 6));
    check('all', () => const ComicBar(value: 6, of: 6));
    check('past the whole', () => const ComicBar(value: 60, of: 6));
    check('of nothing', () => const ComicBar(value: 3, of: 0));
    for (final ink in ComicBarFill.values) {
      check(
        '${ink.name} with a stamp',
        () => ComicBar(value: 3, of: 6, ink: ink, height: 28, stamp: 'Leads'),
      );
      check(
        '${ink.name} full with a long stamp',
        () => ComicBar(value: 6, of: 6, ink: ink, height: 28, stamp: long),
      );
    }
    check('no rows', () => const ComicBarList(entries: []));
    check(
      'many, long',
      () => ComicBarList(
        entries: [
          for (var i = 0; i < 20; i++)
            ComicBarEntry(
              long,
              i,
              figure: '1,234,567',
              leading: _head,
              isLeading: i == 1,
              isCurrentUser: i == 2,
            ),
        ],
      ),
    );
    check(
      'all zero',
      () => const ComicBarList(entries: [ComicBarEntry('A', 0)]),
    );
  });

  group('ComicTally', () {
    check('none', () => const ComicTally(of: 0, options: []));
    check(
      'nobody voted',
      () => const ComicTally(
        of: 0,
        question: 'Which?',
        options: [ComicVote('A', count: 0), ComicVote('B', count: 0)],
      ),
    );
    check(
      'one',
      () => const ComicTally(
        of: 1,
        options: [ComicVote('Only', count: 1, isLeading: true)],
      ),
    );
    check(
      'many, long',
      () => ComicTally(
        of: 40,
        question: longLine,
        subtitle: longLine,
        options: [
          for (var i = 0; i < 12; i++)
            ComicVote(
              long,
              note: longLine,
              count: i * 10,
              isLeading: i == 11,
              stamp: long,
              people: _heads(i * 2),
            ),
        ],
        waitingPeople: _heads(20),
        waiting: long,
        yours: long,
      ),
    );
  });

  group('ComicFlow', () {
    check('none', () => const ComicFlow(into: 'Sam', from: []));
    check(
      'one',
      () => const ComicFlow(into: 'Sam', from: [ComicFlowFrom('You', 19)]),
    );
    check(
      'zeros',
      () => const ComicFlow(into: 'Sam', from: [ComicFlowFrom('You', 0)]),
    );
    check(
      'many, long',
      () => ComicFlow(
        into: long,
        intoFigure: '1,234,567,890',
        intoPerson: const ComicPerson(initials: 'SD', size: 64),
        from: [
          for (var i = 0; i < 12; i++)
            ComicFlowFrom(
              long,
              i * 100,
              figure: '1,234,567',
              isCurrentUser: i == 0,
              person: const ComicPerson(initials: 'AB', size: 34),
            ),
        ],
      ),
    );
    check(
      'exact',
      () => const ComicFlow(
        into: 'Sam',
        intoFigure: '+152',
        perUnit: .52,
        from: [
          ComicFlowFrom('You', 19, isCurrentUser: true),
          ComicFlowFrom('Alex', 133),
        ],
      ),
    );
  });

  group('ComicShares', () {
    check('none', () => const ComicShares(parts: []));
    check('all zero', () => const ComicShares(parts: [ComicShare('A', 0)]));
    check(
      'one',
      () => const ComicShares(stamp: 'Paid', parts: [ComicShare('A', 1)]),
    );
    check(
      'many, long',
      () => ComicShares(
        stamp: long,
        scaleStart: long,
        scaleEnd: long,
        parts: [
          for (var i = 0; i < 12; i++)
            ComicShare(
              longLine,
              i + 1,
              figure: '1,234,567',
              note: longLine,
              ink: ComicShareFill.values[i % ComicShareFill.values.length],
            ),
        ],
      ),
    );
  });

  group('ComicUnits', () {
    check('none', () => const ComicUnits([]));
    check('zero', () => const ComicUnits([ComicUnitColumn('Jan', 0)]));
    check(
      'many, tall',
      () => ComicUnits([
        for (var i = 0; i < 14; i++) ComicUnitColumn(long, i * 8, now: i == 13),
      ]),
    );
  });

  group('ComicPieChart', () {
    check('none', () => const ComicPieChart(slices: []));
    check('all zero', () => const ComicPieChart(slices: [ComicSlice('A', 0)]));
    check(
      'one',
      () => const ComicPieChart(centre: '1', slices: [ComicSlice('A', 1)]),
    );
    check(
      'many, long',
      () => ComicPieChart(
        centre: '1,234,567,890',
        unit: long,
        slices: [
          for (var i = 0; i < 12; i++)
            ComicSlice(long, i + 1, figure: '1,234,567', share: '100%'),
        ],
      ),
    );
  });

  group('ComicSegments, ComicProgressCells', () {
    check('none', () => const ComicSegments([]));
    check('all zero', () => const ComicSegments([0, 0]));
    check('steps', () => const ComicSegments([8, 5, 2, 5, 45, 5], long: 4));
    check(
      'many, long',
      () => ComicSegments(
        List.filled(40, 1),
        labels: List.filled(40, '1,234'),
        scaleStart: long,
        scaleEnd: long,
      ),
    );
    // The law: a number in a block keeps its size and air from the rules each side, or leaves the bar; no two words touch.
    for (final width in const [280.0, 320.0, 390.0, 700.0, 1440.0]) {
      for (final dir in TextDirection.values) {
        for (final (name, amounts, words) in const [
          ('steps', [8, 5, 2, 5, 45, 5], null),
          ('one long, many short', [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 40], null),
          ('words', [20, 2, 30, 3, 10], ['Prep', 'Rest', 'Cook', 'Dry', 'Eat']),
        ]) {
          testWidgets('a number fits its block or leaves it: $name @$width '
              '${dir.name}', (tester) async {
            tester.view.physicalSize = Size(width, 600);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              comicApp(
                Center(
                  child: SizedBox(
                    width: width - 40,
                    child: ComicSegments(amounts, labels: words, long: 2),
                  ),
                ),
                direction: dir,
              ),
            );
            expect(tester.takeException(), isNull);
            Rect rectOf(Element e) {
              final box = e.renderObject! as RenderBox;
              return MatrixUtils.transformRect(
                box.getTransformTo(null),
                Offset.zero & box.size,
              );
            }

            final blocks = find
                .byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_Segment',
                )
                .evaluate()
                .map(rectOf)
                .toList();
            expect(blocks, hasLength(amounts.length));
            final bar = blocks.reduce((a, b) => a.expandToInclude(b));
            final texts = find
                .descendant(
                  of: find.byType(ComicSegments),
                  matching: find.byType(RichText),
                )
                .evaluate()
                .toList();
            final rects = <Rect>[];
            for (final e in texts) {
              final r = rectOf(e);
              final own = (e.renderObject! as RenderBox).size;
              expect(
                (r.width - own.width).abs(),
                lessThan(.5),
                reason: 'a word squeezed to ${r.width} of ${own.width}',
              );
              if (r.overlaps(bar)) {
                final i = blocks.indexWhere((b) => b.overlaps(r));
                final b = blocks[i];
                // The rule stands on the block's start edge, inside it.
                final ruleLeft = dir == TextDirection.ltr && i > 0 ? 2.5 : 0;
                final ruleRight = dir == TextDirection.rtl && i > 0 ? 2.5 : 0;
                expect(
                  r.left - (b.left + ruleLeft),
                  greaterThanOrEqualTo(ComicSegments.air - .5),
                  reason:
                      'block $i: its number at ${r.left}, its rule at ${b.left + ruleLeft}',
                );
                expect(
                  b.right - ruleRight - r.right,
                  greaterThanOrEqualTo(ComicSegments.air - .5),
                  reason:
                      'block $i: its number ends at ${r.right}, its rule at ${b.right - ruleRight}',
                );
              }
              rects.add(r);
            }
            for (var a = 0; a < rects.length; a++) {
              for (var b = a + 1; b < rects.length; b++) {
                expect(
                  rects[a].intersect(rects[b]).width > 0 &&
                      rects[a].intersect(rects[b]).height > 0,
                  isFalse,
                  reason: 'two words overlap: ${rects[a]} and ${rects[b]}',
                );
              }
            }
          });
        }
      }
    }
    check('no cells', () => const ComicProgressCells(total: 0, completed: 0));
    check(
      'forty',
      () => const ComicProgressCells(total: 40, completed: 12, started: 8),
    );
    check(
      'past',
      () => const ComicProgressCells(total: 4, completed: 40, started: 8),
    );
  });

  group('ComicArtBand', () {
    for (var g = 1; g <= 4; g++) {
      check(
        'ground $g',
        () => SizedBox(
          height: 128,
          child: ComicArtBand(
            ground: g,
            leading: ComicMark(ComicMarks.peak),
            sfx: 'Crunch!',
            caption: 'A date',
          ),
        ),
      );
    }
    check(
      'long',
      () => const SizedBox(
        height: 128,
        child: ComicArtBand(sfx: long, caption: longLine),
      ),
    );
    check('nothing', () => const SizedBox(height: 128, child: ComicArtBand()));
  });

  group('ComicEventPanel', () {
    check('least', () => const ComicEventPanel(when: 'Sat', title: 'A thing'));
    check(
      'a drawing',
      () => const ComicEventPanel(
        when: 'Sat 14 Nov',
        title: 'A morning walk',
        where: 'From the station',
        leading: ComicMark(ComicMarks.peak),
        people: [_head],
        tally: '5 in',
      ),
    );
    check(
      'big',
      () => const ComicEventPanel(
        when: 'Fri 4 – Sun 6 Dec',
        title: 'The long weekend',
        big: true,
        count: '23',
        countWord: 'days to go',
        leading: ComicMark(ComicMarks.cabin, onNight: true),
        ground: 4,
        people: [_head],
        trailing: ComicTag('Open'),
      ),
    );
    check(
      'long',
      () => ComicEventPanel(
        when: longLine,
        title: longLine,
        where: longLine,
        leading: ComicMark(ComicMarks.peak),
        people: _heads(40),
        tally: longLine,
        big: true,
        count: '1,234,567,890',
        countWord: long,
      ),
    );
  });

  group('ComicMarkPanel', () {
    check('least', () => const ComicMarkPanel(title: 'A thing'));
    check(
      'long',
      () => const ComicMarkPanel(
        title: longLine,
        date: longLine,
        sfx: long,
        words: longLine,
        leading: ComicMark(ComicMarks.mug),
      ),
    );
    check(
      'in a strip',
      () => const ComicTier(
        phone: ComicTierLayout.strip,
        children: [
          ComicMarkPanel(
            title: 'One',
            leading: ComicMark(ComicMarks.mug),
            sfx: 'Munch!',
          ),
          ComicMarkPanel(
            title: long,
            leading: ComicMark(ComicMarks.pin),
            sfx: 'Krash!',
          ),
          ComicMarkPanel(
            title: 'Three',
            leading: ComicMark(ComicMarks.moon, onNight: true),
            ground: 4,
          ),
        ],
      ),
    );
  });

  group('ComicStepPanel', () {
    check('least', () => const ComicStepPanel(number: '1', words: 'A step'));
    check(
      'long',
      () => const ComicStepPanel(
        number: '123,456',
        words: longLine,
        sfx: long,
        leading: ComicMark(ComicMarks.pan),
        action: ComicButton(long, size: ComicButtonSize.small),
      ),
    );
    check(
      'the slow one',
      () => const ComicStepPanel(
        long: true,
        number: '5',
        words: longLine,
        sfx: 'Blub… blub…',
        leading: ComicMark(ComicMarks.simmer, onNight: true),
        ground: 4,
      ),
    );
  });

  group('ComicVoicePanel', () {
    check('least', () => const ComicVoicePanel(words: 'Hm.', name: 'Sam'));
    check(
      'long',
      () => const ComicVoicePanel(
        words: longLine,
        name: long,
        time: long,
        portrait: ComicPortrait(ComicBust.bob),
        warm: true,
      ),
    );
    check(
      'a strip',
      () => const ComicTier(
        children: [
          ComicVoicePanel(words: 'One line.', name: 'Sam'),
          ComicVoicePanel(words: longLine, name: 'Robin', warm: true),
          ComicVoicePanel(words: 'Two', name: 'Alex'),
          ComicVoicePanel(words: 'Three', name: 'Kim', warm: true),
        ],
      ),
    );
  });

  group('ComicChapterPanel', () {
    check(
      'no rows',
      () => const ComicChapterPanel(title: 'A chapter', children: []),
    );
    check(
      'long',
      () => ComicChapterPanel(
        title: longLine,
        caption: longLine,
        art: const ComicArtBand(leading: ComicMark(ComicMarks.cabin)),
        children: [
          for (var i = 0; i < 8; i++)
            ComicTimedRow(
              '09:00',
              title: longLine,
              subtitle: longLine,
              isFirst: i == 0,
              selected: i == 3,
              inset: 14,
              trailing: _head,
            ),
        ],
      ),
    );
  });

  group('ComicSpeech, ComicReply, ComicClaim', () {
    check('say', () => const ComicSpeech(person: _head, text: 'Hm.'));
    check(
      'say long',
      () => const ComicSpeech(person: _head, text: longLine, author: long),
    );
    check(
      'say fill',
      () => const ComicSpeech(person: _head, text: 'Hm', fill: true),
    );
    check('reply', () => const ComicReply(person: _head, hint: 'Say…'));
    check('reply long', () => const ComicReply(person: _head, hint: long));
    check('reply plain', () => const ComicReply(person: _head, plain: true));
    check('claim', () => const ComicClaim(figure: '19'));
    check(
      'claim long',
      () => const ComicClaim(
        before: longLine,
        figure: '1,234,567,890',
        after: long,
        note: longLine,
        person: _head,
      ),
    );
  });

  group('ComicFigures, ComicAmountRow, ComicLedgerRow', () {
    check('none', () => const ComicFigures([]));
    check('one', () => const ComicFigures([('1', 'One')], highlightLast: true));
    check(
      'long',
      () => const ComicFigures([
        ('1,234,567,890', long),
        ('1,234,567,890', long),
        ('1,234,567,890', long),
        ('1,234,567,890', long),
      ], highlightLast: true),
    );
    check('amount', () => const ComicAmountRow('2 tsp', 'smoked paprika'));
    check(
      'amount long',
      () => const ComicAmountRow('3 × 4000000000 g', longLine, note: longLine),
    );
    check(
      'ledger',
      () => const ComicLedgerRow(title: 'A line', value: '540', isFirst: true),
    );
    check(
      'ledger long',
      () => const ComicLedgerRow(
        title: longLine,
        value: '1,234,567,890',
        date: long,
        subtitle: longLine,
        isCurrentUser: true,
      ),
    );
  });

  group('ComicCover', () {
    check('least', () => const ComicCover(masthead: 'Huzzah!'));
    check(
      'whole',
      () => const ComicCover(
        masthead: 'Huzzah!',
        subtitle: 'The first',
        emphasis: 'issue!',
        issue: ComicCoverBox('No. 27', 'so far this year'),
        price: ComicCoverBox('12', 'to read'),
        date: ComicCoverBox('Wed 11 Nov', 'mild, 9°'),
        burst: ComicCoverBurst('23', over: 'Only', under: 'to go!'),
        say: 'A line from the cast, in a balloon.',
        sayer: 1,
        cast: [
          ComicCast('Sam', portrait: ComicPortrait(ComicBust.bob)),
          ComicCast(
            'You',
            portrait: ComicPortrait(ComicBust.puff),
            isCurrentUser: true,
          ),
        ],
      ),
    );
    check(
      'long',
      () => ComicCover(
        masthead: longLine,
        subtitle: longLine,
        emphasis: long,
        issue: const ComicCoverBox(long, long),
        price: const ComicCoverBox(long, long),
        date: const ComicCoverBox(long, long),
        burst: const ComicCoverBurst('1,234,567,890', over: long, under: long),
        say: longLine,
        sayer: 40,
        cast: [for (var i = 0; i < 12; i++) ComicCast(long)],
      ),
    );
    check(
      'compact',
      () => const ComicCover(
        compact: true,
        masthead: 'Huzzah!',
        issue: ComicCoverBox('No. 27', 'so far'),
        burst: ComicCoverBurst('23'),
      ),
    );
  });

  group('ComicSplash', () {
    for (final layout in ComicSplashLayout.values) {
      check(
        '${layout.name} least',
        () => ComicSplash(layout: layout, title: 'A title'),
      );
      check(
        '${layout.name} whole',
        () => ComicSplash(
          layout: layout,
          title: 'The long\nweekend',
          caption: 'Meanwhile…',
          note: 'A note',
          art: const ComicArtBand(
            ground: 2,
            leading: ComicMark(ComicMarks.cabin),
          ),
          figure: const ComicMark(ComicMarks.tins),
          sfx: 'Blub!',
          burst: const ComicCoverBurst('23', over: 'In', under: 'days!'),
          balloon: const ComicSpeech(person: _head, text: 'Words'),
          facts: const [('162', 'A'), ('Six', 'B'), ('Easy', 'C')],
        ),
      );
      check(
        '${layout.name} long',
        () => ComicSplash(
          layout: layout,
          title: longLine,
          caption: longLine,
          note: longLine,
          burst: const ComicCoverBurst('1,234,567,890', over: long),
          facts: const [(long, long), (long, long), (long, long), (long, long)],
        ),
      );
      check(
        '${layout.name} compact',
        () => ComicSplash(
          compact: true,
          layout: layout,
          title: 'A title',
          caption: 'A caption',
          burst: const ComicCoverBurst('23'),
          facts: const [('162', 'A')],
        ),
      );
    }
  });

  group('ComicEmptyState', () {
    check(
      'whole',
      () => const ComicEmptyState(
        title: 'Nothing here yet',
        body: 'It will show up here',
      ),
    );
    check('long', () => const ComicEmptyState(title: long, body: longLine));
  });
}
