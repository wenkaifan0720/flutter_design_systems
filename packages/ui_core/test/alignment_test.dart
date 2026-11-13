import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _ink = TextStyle(fontSize: 16, color: Color(0xFF000000));

// The test font's capitals: its glyphs stand 0.75 em above the baseline.
const _testCaps = 0.75;

// [child] with its capitals on its box's middle, as a look draws its labels
// and entries.
Widget _caps(Widget child) =>
    DesignCapCenter(capHeightFactor: _testCaps, child: child);

// The bare reference painter: a grey box [height] high, as wide as its
// label and its padding, the label centred in it by its capitals (by its
// line box when not [capCentred]), then drawn [nudge] lower.
Widget _box(
  String label, {
  double height = 40,
  double nudge = 0,
  TextStyle style = _ink,
  bool capCentred = true,
}) => SizedBox(
  height: height,
  child: ColoredBox(
    color: const Color(0xFFDDDDDD),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        widthFactor: 1,
        child: Transform.translate(
          offset: Offset(0, nudge),
          child: capCentred
              ? _caps(Text(label, style: style))
              : Text(label, style: style),
        ),
      ),
    ),
  ),
);

DesignAlignmentEntry _entry(
  DesignInlineControl kind, {
  double height = 40,
  double nudge = 0,
  TextStyle style = _ink,
  bool capCentred = true,
  String? inkUnmeasured,
}) => DesignAlignmentEntry(
  kind,
  (context, label) => _box(
    label,
    height: height,
    nudge: nudge,
    style: style,
    capCentred: capCentred,
  ),
  inkUnmeasured: inkUnmeasured,
);

// One row of [entries]; every other kind absent.
DesignAlignmentMatrix _matrix(
  List<DesignAlignmentEntry> entries, {
  Map<DesignInlineControl, String> heightExceptions = const {},
  DesignAlignmentTheme? theme,
  double pixelRatio = 3,
}) {
  final used = {for (final e in entries) e.kind};
  return DesignAlignmentMatrix(
    look: 'Bare',
    pixelRatio: pixelRatio,
    themes: {'standard': theme ?? (context, child) => child},
    rows: [
      DesignAlignmentRow(
        size: 'medium',
        entries: entries,
        heightExceptions: heightExceptions,
      ),
    ],
    absent: {
      for (final kind in DesignInlineControl.values)
        if (!used.contains(kind)) kind: 'Out of this test\'s look',
    },
  );
}

void main() {
  Future<List<String>> problems(
    WidgetTester tester,
    DesignAlignmentMatrix matrix,
  ) async => (await matrix.check(
    pump: tester.pumpWidget,
    runAsync: tester.runAsync,
  )).problems;

  testWidgets('a centred label passes; one drawn 1 px low fails', (
    tester,
  ) async {
    expect(
      await problems(
        tester,
        _matrix([
          _entry(DesignInlineControl.button),
          _entry(DesignInlineControl.chip),
        ]),
      ),
      isEmpty,
    );
    expect(debugDefaultTargetPlatformOverride, isNull, reason: 'put back');

    expect(
      await problems(
        tester,
        _matrix([
          _entry(DesignInlineControl.button),
          _entry(DesignInlineControl.chip, nudge: 1),
        ]),
      ),
      [
        for (final platform in ['android', 'iOS', 'macOS']) ...[
          "medium · standard · $platform · Chip: its label's baseline is "
              "1 px below that of the row's other labels of its size and "
              'style',
          "medium · standard · $platform · Chip: its label's capitals are 1 "
              "px below the row's centre line as laid out, 3 device px below "
              'as drawn',
        ],
      ],
    );
  });

  testWidgets('a label centred by its line box, not its capitals, fails; one '
      'in a DesignCapCenter passes', (tester) async {
    // The test font's glyphs stand 12 above the baseline and 4 below it: a
    // 16 px line box centred in the face puts the capitals' middle 2 px
    // above the face's, and the baseline 2 px above the cap-centred one's.
    final found = await problems(
      tester,
      _matrix([
        _entry(DesignInlineControl.button),
        _entry(DesignInlineControl.chip, capCentred: false),
      ]),
    );
    expect(found, [
      for (final platform in ['android', 'iOS', 'macOS']) ...[
        "medium · standard · $platform · Chip: its label's baseline is 2 px "
            "above that of the row's other labels of its size and style",
        "medium · standard · $platform · Chip: its label's capitals are 2 px "
            "above the row's centre line as laid out, 6 device px above as "
            'drawn',
      ],
    ]);
    // Leading shared in the font's proportion (a line 1.5 high) keeps the
    // capitals on the line box's middle; a 13 px label beside a 16 px one,
    // each cap-centred, shares their line though not their baseline.
    const tall = TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF000000));
    const small = TextStyle(fontSize: 13, color: Color(0xFF000000));
    expect(
      await problems(
        tester,
        _matrix([
          _entry(DesignInlineControl.button),
          _entry(DesignInlineControl.chip, style: tall),
          _entry(DesignInlineControl.select, style: small),
        ]),
      ),
      isEmpty,
    );
  });

  group("the engine's whole-pixel baseline", () {
    // The engine draws a line's baseline on a whole pixel from its top. The
    // test font's ascent is 0.75 em: at 14 px a baseline laid out 10.5
    // below the label's top is drawn at 11, half a pixel lower; at 13.96 one
    // laid out at 10.47 is drawn at 10, 0.47 px higher. Drawn at 2x, where
    // these labels' ink edges fall on whole device pixels, so that no
    // rasterizer's anti-aliasing decides an edge row (at 3x Linux read the
    // 14 px label 0.2 px higher than macOS).
    const lower = TextStyle(fontSize: 14, color: Color(0xFF000000));
    const higher = TextStyle(fontSize: 13.96, color: Color(0xFF000000));
    DesignAlignmentMatrix both(TextStyle style, double nudge) => _matrix([
      _entry(DesignInlineControl.button, style: style, nudge: nudge),
      _entry(DesignInlineControl.chip, style: style, nudge: nudge),
    ], pixelRatio: 2);
    List<String> each(String problem) => [
      for (final platform in ['android', 'iOS', 'macOS'])
        for (final kind in ['Button', 'Chip'])
          'medium · standard · $platform · $kind: $problem',
    ];

    testWidgets('is paid in advance by DesignCapCenter', (tester) async {
      expect(await problems(tester, both(lower, 0)), isEmpty);
      expect(await problems(tester, both(higher, 0)), isEmpty);
    });

    testWidgets('does not excuse a label drawn 1 px low, whichever way it '
        'rounds', (tester) async {
      // Its cap center paid the engine's rounding in advance, so as laid
      // out it reads that much less; drawn, it is 1 px (2 device px) low,
      // and the device pixel the baseline lands on adds up to half of one.
      expect(
        await problems(tester, both(lower, 1)),
        each(
          "its label's capitals are 0.5 px below the row's centre line as "
          'laid out, 2.5 device px below as drawn',
        ),
      );
      expect(
        await problems(tester, both(higher, 1)),
        each(
          "its label's capitals are 1.5 px below the row's centre line as "
          'laid out, 1.5 device px below as drawn',
        ),
      );
    });
  });

  testWidgets('a short control in a row fails; its exception, with a reason, '
      'excuses it', (tester) async {
    final row = [
      _entry(DesignInlineControl.button),
      _entry(DesignInlineControl.select, height: 36),
      _entry(DesignInlineControl.chip),
    ];
    expect(await problems(tester, _matrix(row)), [
      for (final platform in ['android', 'iOS', 'macOS'])
        'medium · standard · $platform · Select: 36 high, the row 40',
    ], reason: 'centred in a centred row, its label is on the line');
    expect(
      await problems(
        tester,
        _matrix(
          row,
          heightExceptions: {
            DesignInlineControl.select: 'The look draws its select compact',
          },
        ),
      ),
      isEmpty,
    );
  });

  testWidgets('a control that changes size between Android and macOS fails', (
    tester,
  ) async {
    expect(
      await problems(
        tester,
        _matrix([
          DesignAlignmentEntry(
            DesignInlineControl.button,
            (context, label) => _box(
              label,
              height: defaultTargetPlatform == TargetPlatform.macOS ? 32 : 40,
            ),
          ),
        ]),
      ),
      [
        'medium · standard · Button: 88 × 40 as android, 88 × 32 as macOS',
        'medium · standard · Button: its label sits 4 px higher in it as '
            'macOS than as android',
        allOf(contains('visualDensity'), contains('materialTapTargetSize')),
      ],
    );
  });

  testWidgets('Material\'s outlined field is shorter on macOS unless the '
      'theme pins its density', (tester) async {
    DesignAlignmentMatrix field(ThemeData Function() theme) => _matrix(
      [
        DesignAlignmentEntry(
          DesignInlineControl.textField,
          (context, label) => SizedBox(
            width: 200,
            child: TextField(
              decoration: InputDecoration(
                hintText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          inkUnmeasured: 'Material places the hint by its baseline',
        ),
      ],
      theme: (context, child) => MaterialApp(
        theme: theme(),
        home: Material(child: child),
      ),
    );
    expect(
      await problems(tester, field(ThemeData.new)),
      contains(
        'medium · standard · Text field: 200 × 56 as android, 200 × 48 as '
        'macOS',
      ),
    );
    expect(
      await problems(
        tester,
        field(() => ThemeData(visualDensity: VisualDensity.standard)),
      ),
      isEmpty,
    );
  });

  testWidgets('a face declared unmeasurable has its box and baseline '
      'checked, not its ink', (tester) async {
    final found = await problems(
      tester,
      _matrix([
        _entry(DesignInlineControl.button),
        _entry(
          DesignInlineControl.chip,
          nudge: 3,
          inkUnmeasured: 'A gradient face',
        ),
      ]),
    );
    expect(found, isNot(anyElement(contains('ink'))));
    expect(found, anyElement(contains("Chip: its label's baseline is 3 px")));
  });

  test('the matrix answers every kind once, each reason a reason', () {
    final matrix = DesignAlignmentMatrix(
      look: 'Broken',
      themes: const {},
      rows: [
        DesignAlignmentRow(
          size: 'small',
          entries: [
            _entry(DesignInlineControl.button),
            _entry(DesignInlineControl.button),
            _entry(DesignInlineControl.chip, inkUnmeasured: 'TODO'),
          ],
          heightExceptions: const {
            DesignInlineControl.select: 'A compact select',
            DesignInlineControl.button: 'tbd',
          },
        ),
        const DesignAlignmentRow(size: 'large', entries: []),
      ],
      absent: {
        for (final kind in DesignInlineControl.values)
          if (kind != DesignInlineControl.textField &&
              kind != DesignInlineControl.button)
            kind: kind == DesignInlineControl.listTile
                ? 'Not built yet'
                : 'Out of this look\'s vocabulary',
      },
    );
    expect(matrix.problems, [
      'no theme to check under',
      'small: Button more than once',
      'small · Chip: "TODO" is a to-do, not a reason its ink cannot be '
          'measured',
      'small: a height exception for Select, which is not in the row',
      'small · Button: "tbd" is a to-do, not a reason for its height',
      'large: no controls',
      'Text field: in no row and not absent',
      'Chip: both in a row and absent',
      'List tile: "Not built yet" is a to-do, not a reason',
    ]);
  });

  test('verify throws the problems, and passes none', () {
    expect(
      const DesignAlignmentReport('Bare', ['one']).verify,
      throwsA(
        isA<DesignAlignmentError>().having(
          (e) => e.toString(),
          'message',
          'Bare alignment: 1 problem(s)\none',
        ),
      ),
    );
    const clean = DesignAlignmentReport('Bare', []);
    expect(clean.isAligned, isTrue);
    clean.verify();
  });

  testWidgets('the sheet draws each row four times its size, marked', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        DesignAlignmentSheet(
          matrix: _matrix([
            _entry(DesignInlineControl.button),
            _entry(DesignInlineControl.chip),
          ]),
        ),
      ),
    );
    expect(find.text('medium · standard'), findsOneWidget);
    expect(tester.getRect(find.text('TEXT').first).height, 64);
    expect(tester.takeException(), isNull);
  });

  group('text entry', () {
    // A line exactly as tall as the type, so the numbers are the box's.
    const field = TextStyle(fontSize: 16, height: 1, color: Color(0xFF000000));

    Future<List<String>> entries(
      WidgetTester tester,
      Map<String, DesignTextEntryBuilder> entries, {
      Map<String, DesignAlignmentTheme>? themes,
      List<TargetPlatform> platforms = const [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ],
    }) async => (await DesignTextEntryCheck(
      look: 'Bare',
      themes:
          themes ??
          {
            'material': (context, child) => MaterialApp(
              theme: ThemeData(),
              home: Material(child: child),
            ),
          },
      entries: entries,
    ).check(pump: tester.pumpWidget, platforms: platforms)).problems;

    // Today's fault: a padded dense decoration in a row aligned to the
    // bottom, beside a 36 px button.
    Widget composer(
      BuildContext context,
      TextEditingController controller,
      String hint,
    ) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 200,
          child: _caps(
            TextField(
              controller: controller,
              style: field,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _box('SEND', height: 36),
      ],
    );

    // I3: the look's box (min height, border, padding), the bare editable
    // centred in it, the look's own hint on its baseline.
    Widget structured(
      BuildContext context,
      TextEditingController controller,
      String hint,
    ) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF888888)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 200,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) => _caps(
                  Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      if (value.text.isEmpty) Text(hint, style: field),
                      TextField(
                        controller: controller,
                        style: field,
                        decoration: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('a padded dense decoration aligned to the bottom passes as '
        'Android and fails as macOS', (tester) async {
      expect(
        await entries(
          tester,
          {'Composer': composer},
          platforms: [TargetPlatform.android],
        ),
        isEmpty,
      );
      final found = await entries(tester, {'Composer': composer});
      expect(
        found,
        containsAll([
          'Composer · material · macOS: its capitals are 4 px below the '
              'middle of its box as drawn, 4 px below as laid out',
          'Composer · material: its text sits 4 px lower in its box as '
              'macOS than as android',
        ]),
      );
      expect(found, isNot(anyElement(contains('iOS'))));
      expect(found.last, contains('materialTapTargetSize'));
    });

    // Every density, Material 2 and 3, text scale 1 and 1.5, each under a
    // host decoration theme that sets what a decoration leaves unset (its
    // padding uneven, so a line that takes it is pushed down): with the
    // three platforms, 36 configurations.
    const host = InputDecorationTheme(
      contentPadding: EdgeInsets.fromLTRB(20, 24, 20, 8),
      isDense: true,
      constraints: BoxConstraints(minHeight: 56),
    );
    final everywhere = <String, DesignAlignmentTheme>{
      for (final (name, density) in [
        ('compact', VisualDensity.compact),
        ('standard', VisualDensity.standard),
        ('comfortable', VisualDensity.comfortable),
      ])
        for (final m3 in [true, false])
          for (final scale in [1.0, 1.5])
            '$name M${m3 ? 3 : 2} ×$scale': (context, child) => MaterialApp(
              theme: ThemeData(
                useMaterial3: m3,
                visualDensity: density,
                inputDecorationTheme: host,
              ),
              home: Material(
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child,
                  ),
                ),
              ),
            ),
    };

    // The look's box without a border: a minimum height, side air, the
    // editable placed by alignment.
    Widget inBox(Widget editable) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 200,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _caps(editable),
          ),
        ),
      ),
    );

    // The second form, Minimal's (23b1b39b6a): a collapsed decoration with
    // every field a host theme could fill set, the hint its own. [unset]
    // leaves those fields to the theme.
    DesignTextEntryBuilder pinned({Set<String> unset = const {}}) =>
        (context, controller, hint) => inBox(
          TextField(
            controller: controller,
            style: field,
            decoration: InputDecoration(
              isCollapsed: true,
              isDense: unset.contains('isDense') ? null : false,
              contentPadding: unset.contains('contentPadding')
                  ? null
                  : EdgeInsets.zero,
              hintText: hint,
              hintStyle: field,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              visualDensity: unset.contains('visualDensity')
                  ? null
                  : VisualDensity.standard,
              constraints: unset.contains('constraints')
                  ? null
                  : const BoxConstraints(),
            ),
          ),
        );

    testWidgets('the one structure passes on every platform, density, '
        'Material 2 and 3, text size, and under a host decoration theme', (
      tester,
    ) async {
      expect(everywhere, hasLength(12));
      expect(
        await entries(tester, {'Field': structured}, themes: everywhere),
        isEmpty,
      );
    });

    testWidgets('so does a collapsed decoration with every sizing field set; '
        'one that leaves its padding or constraints to the theme fails', (
      tester,
    ) async {
      expect(
        await entries(tester, {'Pinned': pinned()}, themes: everywhere),
        isEmpty,
      );
      final found = await entries(
        tester,
        {
          'No padding': pinned(unset: {'contentPadding'}),
          'No constraints': pinned(unset: {'constraints'}),
          'No density': pinned(unset: {'visualDensity', 'isDense'}),
        },
        themes: {'compact M3 ×1.0': everywhere['compact M3 ×1.0']!},
      );
      expect(found, [
        for (final platform in ['android', 'iOS', 'macOS']) ...[
          'No padding · compact M3 ×1.0 · $platform: its decoration leaves '
              '16 px more room above its line than below it: padding or a '
              'minimum height the theme fills in',
          'No constraints · compact M3 ×1.0 · $platform: its decoration '
              'leaves 40 px more room below its line than above it: padding '
              'or a minimum height the theme fills in',
        ],
      ], reason: 'with no padding, a collapsed decorator nets density to 0');
    });

    testWidgets('a TextFormField is named, even given no decoration', (
      tester,
    ) async {
      final found = await entries(tester, {
        'Form field': (context, controller, hint) => inBox(
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                if (value.text.isEmpty) Text(hint, style: field),
                TextFormField(
                  controller: controller,
                  style: field,
                  decoration: null,
                ),
              ],
            ),
          ),
        ),
      });
      expect(found.where((p) => p.contains('TextFormField')), [
        'Form field: it is a TextFormField, which builds a decoration from the '
            'theme even given none and writes a failed validation\'s error '
            'into it; validate in the look\'s own FormField around a '
            'TextField whose decoration is null',
      ]);
    });

    testWidgets('a collapsed decoration takes a host theme\'s constraints, '
        'and is pushed off the middle; a bare editable is not', (tester) async {
      final found = await entries(
        tester,
        {
          'Collapsed': (context, controller, hint) => inBox(
            TextField(
              controller: controller,
              style: field,
              decoration: InputDecoration.collapsed(hintText: hint),
            ),
          ),
          'Bare': structured,
        },
        themes: {
          'host': (context, child) => MaterialApp(
            theme: ThemeData(
              inputDecorationTheme: const InputDecorationTheme(
                constraints: BoxConstraints(minHeight: 56),
              ),
            ),
            home: Material(child: child),
          ),
        },
        platforms: [TargetPlatform.android],
      );
      expect(found, [
        'Collapsed · host · android: its decoration leaves 40 px more room '
            'below its line than above it: padding or a minimum height the '
            'theme fills in',
      ]);
    });

    testWidgets('a decoration that carries a counter or an icon is named', (
      tester,
    ) async {
      final found = await entries(
        tester,
        {
          'Search': (context, controller, hint) => SizedBox(
            width: 200,
            child: TextField(
              controller: controller,
              style: field,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(IconData(0xE8B6)),
              ),
            ),
          ),
        },
        platforms: [TargetPlatform.android],
      );
      expect(
        found,
        anyElement(
          allOf(
            contains('Search · material · android: its decoration carries'),
            contains('an icon'),
            contains('"0/10"'),
          ),
        ),
      );
    });

    testWidgets('what the look lays beside a bare editable is its own; an '
        'icon in a decoration beside it is still named', (tester) async {
      const reveal = Icon(IconData(0xE8F4));
      // The look's hint over its own row: the editable, then [decoration]
      // and a reveal button, each the row's.
      DesignTextEntryBuilder row(InputDecoration? decoration) =>
          (context, controller, hint) => inBox(
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (value.text.isEmpty) Text(hint, style: field),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: field,
                          decoration: decoration,
                        ),
                      ),
                      reveal,
                    ],
                  ),
                ],
              ),
            ),
          );
      final found = await entries(
        tester,
        {
          'Own row': row(null),
          'Decorated row': row(
            const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              suffixIcon: reveal,
            ),
          ),
        },
        platforms: [TargetPlatform.android],
      );
      expect(found.where((p) => p.startsWith('Own row')), isEmpty);
      expect(found.where((p) => p.contains('carries')), [
        'Decorated row · material · android: its decoration carries an icon; '
            'icons, a counter, help and error are the look\'s own widgets, '
            'outside it',
      ]);
    });
  });
}
