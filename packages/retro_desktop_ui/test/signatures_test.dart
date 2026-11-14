// Each signature part with odd data: empty, one, many, long words, RTL. No overflow, no exception, at 320 and 1440, light
// and dark. The real faces are loaded, so a long word is measured as it would be on a device.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

RetroDesktopHour _hour(int i, {String label = '10', String reading = '9°'}) =>
    RetroDesktopHour(
      label: label,
      icon: LucideIcons.cloud,
      value: 8.0 + i,
      reading: reading,
      kind: RetroDesktopSkyCondition
          .values[i % RetroDesktopSkyCondition.values.length],
      share: (i % 10) / 10,
    );

RetroDesktopDayRange _day(
  int i, {
  String weekday = 'Thu',
  String amount = '1.2',
}) => RetroDesktopDayRange(
  weekday: weekday,
  date: '${i + 1}',
  icon: LucideIcons.sun,
  low: i.toDouble(),
  high: i + 7.0,
  share: (i % 10) / 10,
  amount: amount,
);

/// The part where a page would put it: in a window on a desktop.
Widget _inWindow(Widget child) => RetroDesktopDesktop(
  tiles: [
    RetroDesktopWindowColumn(
      span: 12,
      windows: [RetroDesktopWindow(title: 'A window', child: child)],
    ),
  ],
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  group('RetroDesktopWindow', () {
    check(
      'nothing but a title',
      () => const RetroDesktopWindow(title: 'x', child: SizedBox.shrink()),
    );
    check(
      'a long title, info and status',
      () => const RetroDesktopWindow(
        title: long,
        icon: LucideIcons.mapPin,
        info: longLine,
        infoEnd: long,
        infoFlag: long,
        status: [longLine, long, longLine],
        child: Text(longLine),
      ),
    );
    check(
      'an empty status',
      () => const RetroDesktopWindow(
        title: 'x',
        status: [''],
        child: SizedBox.shrink(),
      ),
    );
    check(
      'a crowded toolbar',
      () => RetroDesktopWindow(
        title: 'x',
        toolbar: RetroDesktopToolbar(
          children: [
            for (var i = 0; i < 12; i++) const RetroDesktopChip(long),
            const RetroDesktopToolNote(longLine),
          ],
        ),
        child: const Text('Words'),
      ),
    );
    check(
      'an action in the foot',
      () => RetroDesktopWindow(
        title: 'x',
        status: const [longLine],
        statusAction: RetroDesktopButton(
          long,
          size: RetroDesktopButtonSize.small,
          onPressed: () {},
        ),
        child: const Text('Words'),
      ),
    );
    check(
      'a window in a window',
      () => const RetroDesktopWindow(
        title: 'x',
        child: RetroDesktopWindow(title: long, child: Text(longLine)),
      ),
    );
  });

  group('RetroDesktopDesktop', () {
    check('no tiles', () => const RetroDesktopDesktop(tiles: []));
    check(
      'a tile with no windows',
      () => const RetroDesktopDesktop(
        tiles: [RetroDesktopWindowColumn(span: 12, windows: [])],
      ),
    );
    check(
      'one window',
      () => const RetroDesktopDesktop(
        tiles: [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [RetroDesktopWindow(title: 'x', child: Text('Words'))],
          ),
        ],
      ),
    );
    check(
      'many narrow tiles',
      () => RetroDesktopDesktop(
        tiles: [
          for (var i = 0; i < 12; i++)
            RetroDesktopWindowColumn(
              span: 1,
              windows: [
                RetroDesktopWindow(title: 'Window $i', child: const Text(long)),
              ],
            ),
        ],
      ),
    );
    check(
      'spans that don\'t add up',
      () => const RetroDesktopDesktop(
        tiles: [
          RetroDesktopWindowColumn(
            span: 9,
            windows: [RetroDesktopWindow(title: 'A', child: Text('Words'))],
          ),
          RetroDesktopWindowColumn(
            span: 9,
            windows: [RetroDesktopWindow(title: 'B', child: Text('Words'))],
          ),
          RetroDesktopWindowColumn(
            span: 20,
            windows: [RetroDesktopWindow(title: 'C', child: Text('Words'))],
          ),
        ],
      ),
    );
    check(
      'marks and a strip, whole',
      () => const RetroDesktopDesktop(
        whole: true,
        marks: RetroDesktopDeskMarks(
          marks: [
            (RetroDesktopDeskMark.disk, long),
            (RetroDesktopDeskMark.bin, 'Bin'),
          ],
        ),
        strip: RetroDesktopDeskStrip(
          items: [
            RetroDesktopStripItem(
              long,
              icon: LucideIcons.wifi,
              highlighted: true,
            ),
            RetroDesktopStripItem(longLine),
          ],
        ),
        tiles: [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [RetroDesktopWindow(title: 'x', child: Text('Words'))],
          ),
        ],
      ),
    );
    check(
      'a shade and an alert, nothing else',
      () => const RetroDesktopDesktop(
        tiles: [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [
              RetroDesktopAlert(title: long, body: longLine, meta: long),
              RetroDesktopWindowShade(title: long),
            ],
          ),
        ],
      ),
    );
    check(
      'an order naming a window that isn\'t there',
      () => const RetroDesktopDesktop(
        phoneOrder: ['Nobody', 'B'],
        tiles: [
          RetroDesktopWindowColumn(
            span: 6,
            windows: [RetroDesktopWindow(title: 'A', child: Text('Words'))],
          ),
          RetroDesktopWindowColumn(
            span: 6,
            windows: [RetroDesktopWindow(title: 'B', child: Text('Words'))],
          ),
        ],
      ),
    );
  });

  group('RetroDesktopAlert', () {
    check('a title', () => const RetroDesktopAlert(title: 'x'));
    check(
      'long words, many actions',
      () => RetroDesktopAlert(
        title: long,
        body: longLine,
        meta: long,
        actions: [
          for (var i = 0; i < 6; i++)
            RetroDesktopButton(long, onPressed: () {}),
          RetroDesktopButton(long, isDefaultAction: true, onPressed: () {}),
        ],
      ),
    );
  });

  group('RetroDesktopWindowShade', () {
    check('a title', () => const RetroDesktopWindowShade(title: 'x'));
    check(
      'a long title, an icon',
      () => const RetroDesktopWindowShade(title: long, icon: LucideIcons.bell),
    );
  });

  group('RetroDesktopHeroHeader, RetroDesktopDayTile', () {
    const tile = RetroDesktopDayTile(
      month: 'MAR',
      year: '2026',
      day: '14',
      weekday: 'Saturday',
    );
    check('the tile alone', () => tile);
    check(
      'the tile with odd words',
      () => const RetroDesktopDayTile(
        month: long,
        year: long,
        day: '1,234,567',
        weekday: long,
      ),
    );
    check(
      'the tile empty',
      () =>
          const RetroDesktopDayTile(month: '', year: '', day: '', weekday: ''),
    );
    check(
      'a title',
      () => const RetroDesktopHeroHeader(object: tile, title: 'x'),
    );
    check(
      'everything, long',
      () => const RetroDesktopHeroHeader(
        object: tile,
        title: longLine,
        eyebrow: long,
        progress: 1.4,
        progressLabel: longLine,
        flag: long,
        flagNote: longLine,
        stats: [
          ('1,204,000', long, null),
          ('0', 'none', null),
          ('12', longLine, long),
          ('3', 'three', null),
          ('4', 'four', null),
        ],
      ),
    );
    check(
      'no progress, below zero',
      () =>
          const RetroDesktopHeroHeader(object: tile, title: 'x', progress: -1),
    );
    check(
      'in an active window on a phone and a desktop',
      () => _inWindow(
        const RetroDesktopHeroHeader(object: tile, title: longLine),
      ),
    );
  });

  group('RetroDesktopFigureHero, RetroDesktopBigFigure', () {
    check('one numeral', () => const RetroDesktopBigFigure('8'));
    check('nothing', () => const RetroDesktopBigFigure(''));
    check(
      'a long number',
      () => const RetroDesktopBigFigure('1,234,567,890.12', unit: long),
    );
    check(
      'in a zero width',
      () => const SizedBox(width: 0, child: RetroDesktopBigFigure('8')),
    );
    check(
      'a figure',
      () => const RetroDesktopFigureHero(value: '8', title: 'Showers'),
    );
    check(
      'everything, long',
      () => const RetroDesktopFigureHero(
        value: '1,234,567',
        unit: long,
        title: long,
        note: longLine,
        summary: longLine,
        reads: [
          (long, '1,234,567', long),
          ('High', '11°', null),
          ('Low', '', null),
          ('Rain', '6.4', 'mm'),
        ],
      ),
    );
    check(
      'in a window',
      () => _inWindow(
        const RetroDesktopFigureHero(
          value: '8',
          unit: '°',
          title: long,
          note: longLine,
          summary: longLine,
          reads: [('High', '11°', null)],
        ),
      ),
    );
    check(
      'a reading head',
      () => const RetroDesktopReadingHead(
        value: '1,234,567',
        title: long,
        note: longLine,
      ),
    );
  });

  group('RetroDesktopDocument, RetroDesktopChecklist', () {
    check('a title', () => const RetroDesktopDocument(title: 'x'));
    check(
      'everything, long',
      () => RetroDesktopDocument(
        title: longLine,
        path: const [long, long, long, long],
        meta: const [(long, longLine), ('Edited', 'today'), ('', '')],
        tags: const [long, 'Kept', long, ''],
        addTag: long,
        paragraphs: const [longLine, longLine, ''],
        children: const [
          RetroDesktopChecklist(
            title: long,
            items: [RetroDesktopCheckItem(longLine, value: true)],
          ),
        ],
      ),
    );
    check(
      'an empty checklist',
      () => const RetroDesktopChecklist(title: 'x', items: []),
    );
    check(
      'many items',
      () => RetroDesktopChecklist(
        title: 'A list',
        items: [
          for (var i = 0; i < 40; i++)
            RetroDesktopCheckItem(
              'Item $i',
              value: i.isEven,
              isCurrent: i == 3,
              chips: i % 5 == 0 ? const ['One', 'Two'] : const [],
              selectedChip: i % 5 == 0 ? 'Two' : null,
            ),
        ],
      ),
    );
    check(
      'long words and chips',
      () => const RetroDesktopChecklist(
        title: long,
        items: [
          RetroDesktopCheckItem(
            longLine,
            isCurrent: true,
            chips: [long, long, long],
            selectedChip: long,
          ),
        ],
      ),
    );
  });

  group('RetroDesktopTaskRow', () {
    check('a title', () => const RetroDesktopTaskRow(title: 'x'));
    check(
      'everything, long',
      () => RetroDesktopTaskRow(
        title: longLine,
        subtitle: longLine,
        overdue: long,
        time: '1,234,567',
        flexibleTime: long,
        bell: true,
        priority: 1,
        value: true,
        selected: true,
        onChanged: (_) {},
        onPressed: () {},
      ),
    );
    check(
      'a priority nothing has',
      () => const RetroDesktopTaskRow(title: 'x', priority: 9),
    );
    check(
      'many in a list, in a window',
      () => _inWindow(
        RetroDesktopList(
          share: true,
          children: [
            for (var i = 0; i < 30; i++)
              RetroDesktopTaskRow(title: 'Row $i', priority: i % 4),
          ],
        ),
      ),
    );
  });

  group('RetroDesktopListTable', () {
    const columns = [
      RetroDesktopListTableColumn('Name', sorted: true),
      RetroDesktopListTableColumn('Size', width: 60),
      RetroDesktopListTableColumn('Kind', width: 90),
    ];
    check(
      'no rows',
      () => const RetroDesktopListTable(columns: columns, rows: []),
    );
    check(
      'no columns',
      () => const RetroDesktopListTable(
        columns: [],
        rows: [RetroDesktopListTableRow(title: 'x')],
      ),
    );
    check(
      'one row',
      () => const RetroDesktopListTable(
        columns: columns,
        rows: [
          RetroDesktopListTableRow(
            title: 'x',
            cells: [('1 KB', null), ('Text', null)],
          ),
        ],
      ),
    );
    check(
      'many rows, long words',
      () => RetroDesktopListTable(
        columns: const [
          RetroDesktopListTableColumn(long, sorted: true),
          RetroDesktopListTableColumn(long, width: 60),
        ],
        total: 900,
        rows: [
          for (var i = 0; i < 80; i++)
            RetroDesktopListTableRow(
              title: longLine,
              note: long,
              selected: i == 2,
              cells: const [(long, long)],
            ),
        ],
      ),
    );
    check(
      'fewer cells than columns, more cells than columns',
      () => const RetroDesktopListTable(
        columns: columns,
        rows: [
          RetroDesktopListTableRow(title: 'x'),
          RetroDesktopListTableRow(
            title: 'y',
            cells: [('a', null), ('b', null), ('c', null), ('d', null)],
          ),
        ],
      ),
    );
  });

  group('RetroDesktopTable', () {
    const columns = [
      RetroDesktopTableColumn('Name', flex: 3),
      RetroDesktopTableColumn('Sum', figures: true, sorted: true),
      RetroDesktopTableColumn('Note', width: 90),
    ];
    check('no rows', () => const RetroDesktopTable(columns: columns, rows: []));
    check('no columns', () => const RetroDesktopTable(columns: [], rows: []));
    check(
      'one row',
      () => const RetroDesktopTable(
        columns: columns,
        rows: [
          ['x', '1', 'y'],
        ],
      ),
    );
    check(
      'many rows, long words, a total',
      () => RetroDesktopTable(
        columns: const [
          RetroDesktopTableColumn(long, flex: 3),
          RetroDesktopTableColumn(long, figures: true),
        ],
        total: const [long, '1,234,567,890.12'],
        rows: [
          for (var i = 0; i < 40; i++) const [longLine, '1,234,567,890.12'],
        ],
      ),
    );
    check(
      'a row shorter and longer than the columns',
      () => const RetroDesktopTable(
        columns: columns,
        rows: [
          ['x'],
          ['a', 'b', 'c', 'd', 'e'],
        ],
      ),
    );
  });

  group('RetroDesktopFolderGrid, RetroDesktopFileGrid', () {
    check('no folders', () => const RetroDesktopFolderGrid(items: []));
    check(
      'one folder',
      () => const RetroDesktopFolderGrid(
        items: [
          RetroDesktopFolder(
            'x',
            art: RetroDesktopFolderArt(selected: false, icon: null),
          ),
        ],
      ),
    );
    check(
      'many folders, long words',
      () => RetroDesktopFolderGrid(
        items: [
          for (var i = 0; i < 24; i++)
            RetroDesktopFolder(
              long,
              icon: LucideIcons.star,
              note: longLine,
              selected: i == 1,
              art: RetroDesktopFolderArt(
                selected: i == 1,
                icon: LucideIcons.star,
              ),
            ),
        ],
      ),
    );
    check('no files', () => const RetroDesktopFileGrid(items: []));
    check(
      'one file',
      () => const RetroDesktopFileGrid(
        items: [
          RetroDesktopFile(
            'x',
            kind: 'y',
            art: RetroDesktopFilePageArt(
              kind: RetroDesktopFileArt.text,
              selected: false,
            ),
          ),
        ],
      ),
    );
    check(
      'every art, long words',
      () => RetroDesktopFileGrid(
        items: [
          for (final art in RetroDesktopFileArt.values)
            RetroDesktopFile(
              'a-very-$long.txt',
              kind: long,
              note: longLine,
              art: RetroDesktopFilePageArt(kind: art, selected: false),
            ),
          for (var i = 0; i < 24; i++)
            RetroDesktopFile(
              long,
              kind: 'Text',
              selected: i == 1,
              art: RetroDesktopFilePageArt(
                kind: RetroDesktopFileArt.text,
                selected: i == 1,
              ),
            ),
        ],
      ),
    );
  });

  group('RetroDesktopTreeBars', () {
    check('no rows', () => const RetroDesktopTreeBars(rows: []));
    check(
      'one row',
      () => const RetroDesktopTreeBars(
        rows: [RetroDesktopTreeRow('x', '1', share: .5)],
      ),
    );
    check(
      'many rows, every depth, long words, past the ends',
      () => RetroDesktopTreeBars(
        totalName: long,
        total: '1,234,567,890.12',
        rows: [
          for (var i = 0; i < 30; i++)
            RetroDesktopTreeRow(
              long,
              '1,234,567,890.12',
              share: i * .1 - 1,
              level: i % 5,
              open: i % 3 == 0 ? i.isEven : null,
            ),
        ],
      ),
    );
  });

  group('RetroDesktopMonthGrid', () {
    check('no marks', () => const RetroDesktopMonthGrid(year: 2026, month: 3));
    check(
      'a month that starts on Sunday, today lit',
      () => const RetroDesktopMonthGrid(year: 2026, month: 2, today: 28),
    );
    check(
      'a leap February, six rows',
      () => const RetroDesktopMonthGrid(year: 2028, month: 2, today: 29),
    );
    check(
      'a long month, six rows',
      () => const RetroDesktopMonthGrid(year: 2026, month: 8),
    );
    check(
      'every day crowded',
      () => RetroDesktopMonthGrid(
        year: 2026,
        month: 3,
        today: 14,
        days: {
          for (var d = 1; d <= 31; d++)
            d: RetroDesktopDayMarks(
              remaining: 99,
              completed: 99,
              icon: LucideIcons.bell,
              overdue: d.isOdd,
            ),
        },
      ),
    );
    check(
      'a day that isn\'t in the month, a today that isn\'t',
      () => const RetroDesktopMonthGrid(
        year: 2026,
        month: 3,
        today: 99,
        days: {
          99: RetroDesktopDayMarks(remaining: 1),
          0: RetroDesktopDayMarks(completed: 1),
        },
      ),
    );
    check(
      'long weekday names',
      () => const RetroDesktopMonthGrid(
        year: 2026,
        month: 3,
        weekdays: [long, long, long, long, long, long, long],
      ),
    );
    check(
      'a head',
      () => RetroDesktopMonthHead(
        long,
        onPrevious: () {},
        onToday: () {},
        onNext: () {},
      ),
    );
    check(
      'a legend',
      () => const RetroDesktopLegend([
        (RetroDesktopLegendMark.solid, long),
        (RetroDesktopLegendMark.outline, longLine),
        (RetroDesktopLegendMark.tint, long),
        (RetroDesktopLegendMark.send, long),
      ]),
    );
    check('an empty legend', () => const RetroDesktopLegend([]));
  });

  group('RetroDesktopHourStrip, RetroDesktopPixelSky', () {
    check('no hours', () => const RetroDesktopHourStrip(hours: []));
    check('one hour', () => RetroDesktopHourStrip(hours: [_hour(0)]));
    check(
      'every sky',
      () =>
          RetroDesktopHourStrip(hours: [for (var i = 0; i < 8; i++) _hour(i)]),
    );
    check(
      'a whole day',
      () => RetroDesktopHourStrip(
        art: const RetroDesktopBeaconArt(),
        hours: [for (var i = 0; i < 24; i++) _hour(i)],
      ),
    );
    check(
      'long words',
      () => RetroDesktopHourStrip(
        hours: [
          for (var i = 0; i < 6; i++)
            _hour(i, label: long, reading: '1,234,567'),
        ],
      ),
    );
    check(
      'the same value all day',
      () => const RetroDesktopHourStrip(
        hours: [
          RetroDesktopHour(
            label: 'a',
            icon: LucideIcons.sun,
            value: 5,
            reading: '5',
          ),
          RetroDesktopHour(
            label: 'b',
            icon: LucideIcons.sun,
            value: 5,
            reading: '5',
          ),
        ],
      ),
    );
    check('no sky', () => const RetroDesktopPixelSky(kinds: []));
    check(
      'one sky, shares past the ends',
      () => const RetroDesktopPixelSky(
        kinds: [RetroDesktopSkyCondition.rain],
        shares: [9, -1, .5],
      ),
    );
    check(
      'a tall sky in a beacon',
      () => const RetroDesktopPixelSky(
        kinds: RetroDesktopSkyCondition.values,
        height: 200,
        art: RetroDesktopBeaconArt(),
      ),
    );
  });

  group('RetroDesktopRangeShape', () {
    check('no days', () => const RetroDesktopRangeShape(days: []));
    check('one day', () => RetroDesktopRangeShape(days: [_day(0)]));
    check(
      'many days',
      () =>
          RetroDesktopRangeShape(days: [for (var i = 0; i < 30; i++) _day(i)]),
    );
    check(
      'long words, a warning',
      () => RetroDesktopRangeShape(
        unit: long,
        keyLabel: longLine,
        dry: long,
        wet: long,
        days: [
          for (var i = 0; i < 5; i++)
            RetroDesktopDayRange(
              weekday: long,
              date: long,
              icon: LucideIcons.sun,
              low: -40,
              high: 60,
              share: 2,
              shareLabel: long,
              amount: '1,234,567',
              warn: true,
              lowLabel: long,
              highLabel: long,
            ),
        ],
      ),
    );
    check(
      'one value: no range to draw',
      () => const RetroDesktopRangeShape(
        days: [
          RetroDesktopDayRange(
            weekday: 'a',
            date: '1',
            icon: LucideIcons.sun,
            low: 5,
            high: 5,
          ),
          RetroDesktopDayRange(
            weekday: 'b',
            date: '2',
            icon: LucideIcons.sun,
            low: 5,
            high: 5,
          ),
        ],
      ),
    );
  });

  group('RetroDesktopHatchBars, RetroDesktopDayBars', () {
    check('no bars', () => const RetroDesktopHatchBars(values: []));
    check('one bar', () => const RetroDesktopHatchBars(values: [1]));
    check('all zero', () => const RetroDesktopHatchBars(values: [0, 0, 0]));
    check(
      'a bar past the top, one below zero',
      () => const RetroDesktopHatchBars(values: [9, -3, 1], max: 2),
    );
    check(
      'many bars, labels and notes',
      () => RetroDesktopHatchBars(
        values: [for (var i = 0; i < 120; i++) i % 7.0],
        axis: const [long, long],
        labels: const [long, long, long],
        notes: const [
          RetroDesktopBarNote(0, longLine),
          RetroDesktopBarNote(5, long),
          RetroDesktopBarNote(999, 'Past the end'),
        ],
        spanFrom: 1,
        spanTo: 50,
        spanWords: longLine,
        divider: 3,
        nowAt: 2,
      ),
    );
    check(
      'a span past the end, a divider past the end',
      () => const RetroDesktopHatchBars(
        values: [1, 2, 3],
        spanFrom: 2,
        spanTo: 99,
        divider: 50,
        nowAt: 50,
      ),
    );
    check(
      'no day bars',
      () => const RetroDesktopDayBars(values: [], labels: []),
    );
    check(
      'one day bar',
      () => const RetroDesktopDayBars(values: [1], labels: ['x']),
    );
    check(
      'many day bars, long labels, past the limit',
      () => RetroDesktopDayBars(
        values: [for (var i = 0; i < 30; i++) i * 9.0],
        labels: [for (var i = 0; i < 30; i++) long],
        limit: 50,
      ),
    );
    check(
      'fewer labels than bars, all zero',
      () => const RetroDesktopDayBars(values: [0, 0, 0], labels: ['x']),
    );
  });

  group('RetroDesktopGaugeBlock, RetroDesktopThumbGauge', () {
    for (final share in const [0.0, .004, .5, 1.0, 9.0, -1.0]) {
      check('a share of $share', () => RetroDesktopThumbGauge(share: share));
    }
    check('a block', () => const RetroDesktopGaugeBlock(value: '8', share: .5));
    check(
      'a block, long words',
      () => const RetroDesktopGaugeBlock(
        value: '1,234,567,890.12',
        share: .5,
        of: long,
        endLabel: longLine,
        footStart: longLine,
        footEnd: longLine,
      ),
    );
  });

  group('RetroDesktopScaleBar, RetroDesktopSpanBar', () {
    check('no bands', () => const RetroDesktopScaleBar(at: .5, bands: []));
    check('one band', () => const RetroDesktopScaleBar(at: .5, bands: ['x']));
    check(
      'past the ends',
      () => const RetroDesktopScaleBar(at: 9, bands: ['a\nb', 'c\nd']),
    );
    check(
      'below the ends',
      () => const RetroDesktopScaleBar(
        at: -9,
        bands: ['a\nb', 'c\nd'],
        fine: long,
      ),
    );
    check(
      'many long bands',
      () => const RetroDesktopScaleBar(
        at: .5,
        bands: [long, longLine, long, long, long, long, long, long, long],
        fine: longLine,
      ),
    );
    check('a span', () => const RetroDesktopSpanBar(from: .2, to: .8));
    check(
      'a span, long words, a marker',
      () => const RetroDesktopSpanBar(
        from: .2,
        to: .8,
        at: .5,
        fromLabel: long,
        toLabel: long,
        startLabel: longLine,
        endLabel: longLine,
      ),
    );
    check(
      'a span backward, past the ends',
      () => const RetroDesktopSpanBar(from: 9, to: -3, at: 40),
    );
  });

  group('RetroDesktopDescriptionList, RetroDesktopStats, RetroDesktopReadings, RetroDesktopMeasures', () {
    check('no facts', () => const RetroDesktopDescriptionList([]));
    check(
      'long facts, with leaders',
      () => const RetroDesktopDescriptionList([
        RetroDesktopFact(long, longLine, icon: LucideIcons.wind),
        RetroDesktopFact('Wind', long, figures: true),
      ], leaders: true),
    );
    check('no stats', () => const RetroDesktopStats([]));
    check(
      'many long stats',
      () => const RetroDesktopStats([
        ('1,234,567,890.12', long, null),
        ('2', longLine, long),
        ('3', long, null),
        ('4', long, null),
        ('5', long, null),
        ('6', long, null),
      ]),
    );
    check('no readings', () => const RetroDesktopReadings([]));
    check(
      'many long readings',
      () => const RetroDesktopReadings([
        (long, '1,234,567,890.12', long),
        ('High', '11', null),
        ('Low', '4', 'x'),
        ('Rain', '6', null),
        ('Sun', '2', long),
        ('Wind', '9', null),
      ]),
    );
  });
}
