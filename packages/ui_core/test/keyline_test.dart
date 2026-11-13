import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

const _cardColor = Color(0xFFE6E6E6);
const _ink = Color(0xFF000000);
// The test font's glyphs fill their advance, so words start where their
// line box does.
const _words = TextStyle(inherit: false, fontSize: 14, height: 1, color: _ink);

// Material's chevron_right, drawn from the SDK's icon font: its ink ends
// 8 px before its 24 px box does.
const _chevronGlyph = IconData(0xE15F, fontFamily: 'MaterialIcons');

Future<void> _loadIconFont() async {
  // FLUTTER_ROOT, or up from bin/cache/artifacts/engine/<host>/flutter_tester.
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final font = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
      .load();
}

// A screen with one card 340 wide at its top centre: the card is the
// region, its content 16 in.
Widget _screen(Widget card, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
      home: Directionality(
        textDirection: direction,
        child: Material(
          color: const Color(0xFFFFFFFF),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: SizedBox(width: 340, child: card),
            ),
          ),
        ),
      ),
    );

Widget _card(
  List<Widget> rows, {
  String label = 'Settings',
  List<double> indents = const [],
  String? mixedHeights,
  bool startAligned = false,
}) => DesignKeylineRegion(
  label: label,
  indents: indents,
  mixedHeights: mixedHeights,
  startAligned: startAligned,
  child: ColoredBox(
    color: _cardColor,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rows)
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: r),
        ],
      ),
    ),
  ),
);

Text _text(String words, {double size = 14}) =>
    Text(words, style: _words.copyWith(fontSize: size));

// A row: [lead] at the start, [end] pushed to the end.
Widget _row(Widget lead, Widget end) =>
    Row(children: [lead, const Spacer(), end]);

// Moves [child] toward the end by [by] (left to right).
Widget _nudge(double by, Widget child) =>
    Transform.translate(offset: Offset(by, 0), child: child);

// A faced control: a box [width] by [height] that paints its face.
Widget _faced(
  String label, {
  double width = 120,
  double height = 40,
  Decoration decoration = const BoxDecoration(color: Color(0xFF3366CC)),
}) => Semantics(
  button: true,
  label: label,
  child: DecoratedBox(
    decoration: decoration,
    child: SizedBox(width: width, height: height),
  ),
);

// A row's chevron whose ink ends [inkEnd] px in from the card's trailing
// edge, its box hanging 8 px further out.
Widget _chevron({double inkEnd = 16}) =>
    _nudge(24 - inkEnd, const Icon(_chevronGlyph, size: 24, color: _ink));

// Moves [child] in from the start by [by].
Widget _start(double by, Widget child) => Padding(
  padding: EdgeInsetsDirectional.only(start: by),
  child: child,
);

// Draws a 1 px line along its bottom, 12 px in from each end: all a face
// the colour of the ground shows of itself (its shadow).
class _Underline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(12, size.height - 1, size.width - 24, 1),
    Paint()..color = const Color(0xFF808080),
  );

  @override
  bool shouldRepaint(_Underline oldDelegate) => false;
}

// Material's menu glyph: its ink starts 3 px into its box, the chevron's 8.
const _menuGlyph = IconData(0xE3DC, fontFamily: 'MaterialIcons');

Future<List<String>> _problems(
  WidgetTester tester,
  Widget screen, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(_screen(screen, direction: direction));
  await tester.pump();
  final report = await const DesignKeylineCheck(look: 'Bare')
      .check(tester.binding.rootElement!, runAsync: tester.runAsync);
  return report.problems;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadIconFont();
  });

  testWidgets('one leading keyline: a title at 16 beside rows at 26 and a '
      'checkbox at 22 fail; an indent declared for the rows leaves the '
      'checkbox', (tester) async {
    // The checkbox's 18 px box sits 15 px into its 48 px tap box.
    final checkbox = Row(
      children: [
        _nudge(-9, Checkbox(value: true, onChanged: (_) {})),
        _text('Remember me'),
      ],
    );
    final rows = [
      _text('Notifications'),
      Padding(padding: const EdgeInsets.only(left: 10), child: _text('Email')),
      Padding(padding: const EdgeInsets.only(left: 10), child: _text('Push')),
      checkbox,
    ];
    expect(await _problems(tester, _card(rows)), [
      'Settings: "Notifications" starts 16 px in; the leading keyline is '
          '26 px in',
      'Settings: a checkbox starts 22 px in; the leading keyline is 26 px in',
    ]);
    expect(await _problems(tester, _card(rows, indents: const [10])), [
      'Settings: a checkbox starts 22 px in; the leading keyline is 16 px or '
          '26 px in',
    ]);
  });

  testWidgets('one trailing keyline, an icon read by its ink: a switch and a '
      'chevron on it pass; a chevron 6 px short and a select 10 px past '
      'fail', (tester) async {
    expect(
      await _problems(
        tester,
        _card([
          _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
          _row(_text('Account'), _chevron(inkEnd: 22)),
          _row(_text('Theme'), _nudge(10, _faced('Theme', height: 32))),
          _row(_text('About'), _chevron()),
        ]),
      ),
      [
        'Settings: an icon ends 22 px in; the trailing keyline is 16 px in',
        'Settings: a button "Theme" ends 6 px in; the trailing keyline is '
            '16 px in',
      ],
    );
  });

  testWidgets('a face is the box that paints it: raised on the ground '
      'colour, glass over a gradient, a hard offset shadow, a checkbox in '
      'its tap box, a text button by its words', (tester) async {
    final faces = <String, Widget>{
      'raised': _faced(
        'Raised',
        decoration: const BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFFFFF),
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Color(0xFFA0A0A0),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
          ],
        ),
      ),
      'glass': Semantics(
        button: true,
        label: 'Glass',
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x33FFFFFF),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x66FFFFFF)),
                ),
              ),
              child: SizedBox(width: 120, height: 40),
            ),
          ),
        ),
      ),
      'comic': _faced(
        'Comic',
        decoration: const BoxDecoration(
          color: Color(0xFFFFD600),
          border: Border.fromBorderSide(BorderSide(width: 2)),
          boxShadow: [BoxShadow(offset: Offset(-5, 5))],
        ),
      ),
      'comic, its shadow a box': Semantics(
        button: true,
        label: 'Stacked',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(-5, 5),
              child: const ColoredBox(
                color: _ink,
                child: SizedBox(width: 120, height: 40),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFD600),
                border: Border.fromBorderSide(BorderSide(width: 2)),
              ),
              child: SizedBox(width: 120, height: 40),
            ),
          ],
        ),
      ),
      'checkbox': Row(
        children: [_nudge(-15, Checkbox(value: false, onChanged: (_) {}))],
      ),
      'text button': Row(
        children: [
          _nudge(
            -12,
            TextButton(
              onPressed: () {},
              child: const Text('Unavailable', style: _words),
            ),
          ),
        ],
      ),
    };
    final gradient = DesignKeylineRegion(
      label: 'Faces',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6E6E6), Color(0xFFC8D8F0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _text('Faces'),
              for (final f in faces.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: f,
                ),
            ],
          ),
        ),
      ),
    );
    expect(await _problems(tester, gradient), isEmpty);
    // Each face 4 px off the title's keyline is named.
    for (final MapEntry(key: name, value: face) in faces.entries) {
      final card = _card([
        _text('Faces'),
        Padding(padding: const EdgeInsets.only(left: 4), child: face),
      ]);
      expect(await _problems(tester, card), [
        matches(RegExp(r'starts 20 px in; the leading keyline is 16 px in$')),
      ], reason: name);
    }
  });

  testWidgets("a gallery's section starts every example on its column's "
      'edge: one centred is named; a card may centre one', (tester) async {
    List<Widget> examples() => [
      _text('Steppers'),
      Center(child: _faced('2 people')),
      Center(child: _text('Total 42')),
    ];
    expect(
      await _problems(
        tester,
        _card(examples(), label: 'Section', startAligned: true),
      ),
      [
        'Section: a button "2 people" starts 110 px in; the leading keyline '
            'is 16 px in',
        'Section: "Total 42" starts 114 px in; the leading keyline is 16 px '
            'in',
      ],
    );
    expect(await _problems(tester, _card(examples())), isEmpty);
  });

  testWidgets("a wrap's runs and a group of choices end ragged; a row of "
      'buttons across the card does not', (tester) async {
    // Chips 70 wide, 8 apart: four take 304 of the card's 308, ending 4
    // short of the trailing keyline the Edit button stands on.
    Widget chip(String label, {bool choice = false}) => Semantics(
      button: true,
      selected: choice ? label == 'A' : null,
      label: label,
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFF3366CC)),
        child: SizedBox(width: 70, height: 32),
      ),
    );
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    final edit = _row(_text('Pay with'), _faced('Edit', width: 52));
    // Two runs: A to D, then E and F.
    expect(
      await _problems(
        tester,
        _card([
          edit,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final l in labels) chip(l, choice: true)],
          ),
        ]),
      ),
      isEmpty,
    );
    expect(
      await _problems(
        tester,
        _card([
          edit,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final l in labels) chip(l)],
          ),
        ]),
      ),
      isEmpty,
    );
    // One run of choices in a row, and of buttons.
    Widget row({required bool choice}) => Row(
      spacing: 8,
      children: [for (final l in labels.take(4)) chip(l, choice: choice)],
    );
    expect(await _problems(tester, _card([edit, row(choice: true)])), isEmpty);
    expect(await _problems(tester, _card([edit, row(choice: false)])), [
      'Settings: a button "D" ends 20 px in; the trailing keyline is 16 px in',
    ]);
  });

  testWidgets('an edge is judged only on the side its item is anchored to', (
    tester,
  ) async {
    Widget chip(String words) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFCCCCCC)),
        child: Padding(padding: const EdgeInsets.all(6), child: _text(words)),
      ),
    );
    expect(
      await _problems(
        tester,
        _card([
          _text('A label alone'),
          Row(children: [chip('One'), chip('Two'), chip('Three')]),
          Row(
            children: [_text('Plan'), const SizedBox(width: 8), _text('Pro')],
          ),
          _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _nudge(-30, _faced('Save', width: 80)),
          ),
          Center(child: _text('No messages')),
          // A divider across the whole card, its content's padding and all.
          const SizedBox(
            height: 1,
            child: OverflowBox(
              maxWidth: 340,
              child: ColoredBox(
                color: Color(0xFF999999),
                child: SizedBox(width: 340, height: 1),
              ),
            ),
          ),
        ]),
      ),
      [
        'Settings: a button "Save" ends 46 px in; the trailing keyline is '
            '16 px in',
      ],
      reason:
          'a lone end button is judged at its end; a label, chips, a value '
          'after its label, a centred line and a full divider are not judged '
          'at theirs',
    );
    // An inset divider starts on the keyline, or is named; one drawn as a
    // Container's colour as well.
    Widget divider(double inset, {bool decorated = true}) => Padding(
      padding: EdgeInsetsDirectional.only(start: inset),
      child: decorated
          ? const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF999999)),
              child: SizedBox(height: 1, width: double.infinity),
            )
          : Container(height: 1, color: const Color(0xFF999999)),
    );
    expect(
      await _problems(tester, _card([_text('Title'), divider(0)])),
      isEmpty,
    );
    for (final decorated in [true, false]) {
      expect(
        await _problems(
          tester,
          _card([_text('Title'), divider(4, decorated: decorated)]),
        ),
        [
          'Settings: a divider starts 20 px in; the leading keyline is 16 px '
              'in',
        ],
        reason: decorated ? 'a decorated box' : 'a Container',
      );
    }
    // A box the colour of the card around it draws nothing, and is not
    // an item: what it holds is.
    expect(
      await _problems(
        tester,
        _card([
          _text('Title'),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(color: _cardColor, child: _text('Inside')),
          ),
        ]),
      ),
      ['Settings: "Inside" starts 20 px in; the leading keyline is 16 px in'],
    );
  });

  testWidgets('controls in one row share a height and a centre line, unless '
      'the region says why not', (tester) async {
    Widget row(CrossAxisAlignment align) => Row(
      crossAxisAlignment: align,
      children: [
        _faced('Country', width: 200, height: 50),
        const SizedBox(width: 8),
        _faced('Search', width: 40, height: 40),
      ],
    );
    const heights =
        'Settings: in one row, a button "Country" is 50 px high and a button '
        '"Search" 40 px';
    expect(await _problems(tester, _card([row(CrossAxisAlignment.center)])), [
      heights,
    ]);
    expect(await _problems(tester, _card([row(CrossAxisAlignment.end)])), [
      heights,
      'Settings: in one row, a button "Search"\'s centre is 5 px below a '
          'button "Country"\'s',
    ]);
    expect(
      await _problems(
        tester,
        _card([
          row(CrossAxisAlignment.end),
        ], mixedHeights: "The search button sits on the field's baseline"),
      ),
      isEmpty,
    );
    expect(
      await _problems(
        tester,
        _card([row(CrossAxisAlignment.center)], mixedHeights: 'TODO'),
      ),
      ['Settings: "TODO" is a to-do, not a reason its controls differ'],
    );
  });

  testWidgets('right to left, the leading side is the right', (tester) async {
    expect(
      await _problems(
        tester,
        _card([
          _text('Notifications'),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 10),
            child: _text('Email'),
          ),
          _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
          _row(
            _text('Theme'),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: _faced('Theme', height: 32),
            ),
          ),
        ]),
        direction: TextDirection.rtl,
      ),
      [
        'Settings: "Email" starts 26 px in; the leading keyline is 16 px in',
        'Settings: a button "Theme" ends 20 px in; the trailing keyline is '
            '16 px in',
      ],
    );
  });

  group('a settings screen', () {
    // Each padding the screen is built from, by name; each puts one edge
    // 4 px off its keyline.
    const paddings = [
      'heading',
      'margin',
      'title',
      'row',
      'switch',
      'chevron',
      'select',
      'value',
      'footer',
    ];
    Widget screen([String? off]) {
      double pad(String name) => name == off ? 4 : 0;
      Widget start(String name, Widget w) => Padding(
        padding: EdgeInsetsDirectional.only(start: pad(name)),
        child: w,
      );
      Widget end(String name, Widget w) => Padding(
        padding: EdgeInsetsDirectional.only(end: pad(name)),
        child: w,
      );
      Widget section(String title, List<Widget> rows) => DesignKeylineRegion(
        label: title,
        child: ColoredBox(
          color: _cardColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The first section's title is the one moved.
                start(
                  title == 'Account' ? 'title' : '',
                  _text(title, size: 18),
                ),
                const SizedBox(height: 8),
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: r,
                  ),
              ],
            ),
          ),
        ),
      );
      return DesignKeylineRegion(
        label: 'Screen',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              start('heading', _text('Settings', size: 22)),
              const SizedBox(height: 16),
              start(
                'margin',
                section('Account', [
                  start(
                    'row',
                    _row(
                      _text('Notifications'),
                      end('switch', _faced('Switch', width: 52, height: 32)),
                    ),
                  ),
                  _row(_text('Privacy'), end('chevron', _chevron())),
                ]),
              ),
              const SizedBox(height: 16),
              section('Preferences', [
                _row(
                  _text('Language'),
                  end('select', _faced('English', height: 32)),
                ),
                _row(_text('Version'), end('value', _text('4.2.1'))),
              ]),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: start('footer', _faced('Sign out')),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('passes as drawn', (tester) async {
      expect(await _problems(tester, screen()), isEmpty);
    });

    for (final name in paddings) {
      testWidgets('names the one edge its $name padding moves', (tester) async {
        expect(await _problems(tester, screen(name)), [
          matches(
            RegExp(r' 20 px in; the (leading|trailing) keyline is 16 px in$'),
          ),
        ]);
      });
    }
  });

  group('what looks met on real screens', () {
    for (final direction in TextDirection.values) {
      final d = direction.name;
      Future<List<String>> problems(WidgetTester t, Widget w) =>
          _problems(t, w, direction: direction);

      testWidgets('1 ($d): what lies inside a face or a well is not an item: '
          "a field's well, a segmented control's track and a table's well "
          'are each read at their face', (tester) async {
        Widget field({double start = 0}) => _start(
          start,
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF888888)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Semantics(
                textField: true,
                label: 'Name',
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFFF4F4F4)),
                  child: SizedBox(
                    height: 20,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _text('Ada'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        Widget cell(String words, {bool chosen = false}) => Semantics(
          button: true,
          label: words,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: chosen ? const Color(0xFFFFFFFF) : const Color(0x00000000),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _text(words),
            ),
          ),
        );
        final segmented = Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFCCCCCC)),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [cell('Day', chosen: true), cell('Week')],
              ),
            ),
          ),
        );
        Widget head(String words) => Semantics(
          button: true,
          label: words,
          child: Padding(padding: const EdgeInsets.all(6), child: _text(words)),
        );
        final table = DecoratedBox(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: Color(0xFF888888))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: head('Name')),
                  head('Size'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(child: _text('Notes')),
                    _text('4 KB'),
                  ],
                ),
              ),
            ],
          ),
        );
        expect(
          await problems(
            tester,
            _card([_text('Details'), field(), segmented, table]),
          ),
          isEmpty,
        );
        expect(
          await problems(
            tester,
            _card([_text('Details'), field(start: 4), segmented, table]),
          ),
          [
            'Settings: a text field "Name" starts 20 px in; the leading '
                'keyline is 16 px in',
          ],
        );
      });

      testWidgets('2 ($d): a face the colour of the ground is read where a '
          'look marks it, and a marked well can be a region of its own', (
        tester,
      ) async {
        Widget raised({required bool marked, double start = 0}) {
          Widget face = ColoredBox(
            color: _cardColor,
            child: SizedBox(
              width: 120,
              height: 40,
              child: Center(child: _text('Go')),
            ),
          );
          if (marked) face = DesignKeylineFace(child: face);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: _start(
              start,
              Semantics(button: true, label: 'Raised', child: face),
            ),
          );
        }

        expect(
          await problems(
            tester,
            _card([_text('Title'), raised(marked: false)]),
          ),
          ['Settings: "Go" starts 62 px in; the leading keyline is 16 px in'],
          reason: 'unmarked, its pixels show only its words',
        );
        expect(
          await problems(tester, _card([_text('Title'), raised(marked: true)])),
          isEmpty,
        );
        expect(
          await problems(
            tester,
            _card([_text('Title'), raised(marked: true, start: 4)]),
          ),
          [
            'Settings: a button "Raised" starts 20 px in; the leading '
                'keyline is 16 px in',
          ],
        );
        final well = DesignKeylineFace(
          child: ColoredBox(
            color: _cardColor,
            child: DesignKeylineRegion(
              label: 'Well',
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_text('Inside'), _start(4, _text('Off'))],
                ),
              ),
            ),
          ),
        );
        expect(await problems(tester, _card([_text('Title'), well])), [
          'Well: "Off" starts 16 px in; the leading keyline is 12 px in',
        ]);
      });

      testWidgets('3 ($d): a leading icon is read by its box, though the '
          "control's face is read from a paint that shows only its shadow", (
        tester,
      ) async {
        Widget row(IconData icon, String words) => Semantics(
          button: true,
          label: words,
          child: CustomPaint(
            painter: _Underline(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: _ink),
                  const SizedBox(width: 12),
                  _text(words),
                ],
              ),
            ),
          ),
        );
        expect(
          await problems(
            tester,
            _card([
              _text('Devices'),
              row(_chevronGlyph, 'Ceiling fan'),
              row(_menuGlyph, 'Hall light'),
            ]),
          ),
          isEmpty,
        );
        expect(
          await problems(
            tester,
            _card([
              _text('Devices'),
              row(_chevronGlyph, 'Ceiling fan'),
              _start(4, row(_menuGlyph, 'Hall light')),
            ]),
          ),
          [
            'Settings: a button "Hall light" starts 20 px in; the leading '
                'keyline is 16 px in',
          ],
        );
      });

      testWidgets('4 ($d): a wrapped or a short text is judged only at the '
          'side it is aligned to, not at its ragged end', (tester) async {
        final saved = Text('Saved', style: _words, textAlign: TextAlign.end);
        Widget card({double end = 0}) => _card([
          _text('Lights'),
          _text('Lights dimmed slowly before the house sleeps'),
          _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
          Padding(
            padding: EdgeInsetsDirectional.only(end: end),
            child: saved,
          ),
        ]);
        expect(await problems(tester, card()), isEmpty);
        expect(await problems(tester, card(end: 4)), [
          'Settings: "Saved" ends 20 px in; the trailing keyline is 16 px in',
        ]);
      });

      testWidgets('5 ($d): a picture with things placed on it is one item '
          'where a look marks it', (tester) async {
        Widget plan({required bool marked}) {
          Widget key(String words, double height) => Semantics(
            button: true,
            label: words,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
              child: SizedBox(
                width: 70,
                height: height,
                child: Center(child: _text(words, size: 10)),
              ),
            ),
          );
          final Widget picture = SizedBox(
            height: 120,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFB0C4DE)),
                  ),
                ),
                PositionedDirectional(
                  start: 30,
                  top: 20,
                  child: key('Hall', 24),
                ),
                PositionedDirectional(
                  start: 150,
                  top: 16,
                  child: key('Kitchen', 32),
                ),
              ],
            ),
          );
          return marked ? DesignKeylineFace(child: picture) : picture;
        }

        expect(
          await problems(tester, _card([_text('Plan'), plan(marked: false)])),
          contains(
            'Settings: in one row, a button "Kitchen" is 32 px high and a '
            'button "Hall" 24 px',
          ),
        );
        expect(
          await problems(tester, _card([_text('Plan'), plan(marked: true)])),
          isEmpty,
        );
      });

      testWidgets('($d) a checkbox read to the end of its words is not judged '
          'at that ragged end, though it reaches across the region', (
        tester,
      ) async {
        final remember = Semantics(
          checked: true,
          label: 'Save as I type',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: _ink)),
                ),
                child: SizedBox(width: 18, height: 18),
              ),
              const SizedBox(width: 8),
              _text('Save it as I type it'),
            ],
          ),
        );
        expect(
          await problems(
            tester,
            _card([
              _text('Editing'),
              _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
              remember,
            ]),
          ),
          isEmpty,
        );
      });

      testWidgets('($d) a quiet button before the default at the end of a row '
          "is not the leading side's", (tester) async {
        Widget bar({double start = 0}) => Row(
          children: [
            const Spacer(),
            Semantics(
              button: true,
              label: 'Order copies',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _text('Order'),
              ),
            ),
            const SizedBox(width: 24),
            _faced('Open', width: 80),
          ],
        );
        expect(
          await problems(tester, _card([_text('Documents'), bar()])),
          isEmpty,
        );
      });
    }
  });

  testWidgets('a card laid out but not shown is not read: an IndexedStack\'s '
      'other screens, an Offstage, a Visibility that keeps its state', (
    tester,
  ) async {
    Widget off(String label) =>
        _card([_text('Title'), _start(10, _text('Off by ten'))], label: label);
    expect(
      await _problems(
        tester,
        Column(
          children: [
            IndexedStack(
              index: 0,
              children: [
                _card([_text('Shown')]),
                off('Hidden screen'),
              ],
            ),
            Offstage(child: off('Off stage')),
            Visibility(
              visible: false,
              maintainState: true,
              child: off('Invisible'),
            ),
          ],
        ),
      ),
      isEmpty,
    );
    expect(await _problems(tester, off('Shown')), [
      'Shown: "Off by ten" starts 26 px in; the leading keyline is 16 px in',
    ]);
  });

  testWidgets("the sheet draws a screen's keylines over it", (tester) async {
    await tester.pumpWidget(
      _screen(
        DesignKeylineSheet(
          child: _card([
            _text('Notifications'),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _text('Email'),
            ),
            _row(_text('Wi-Fi'), _faced('Wi-Fi', width: 52, height: 32)),
          ]),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Notifications'), findsOneWidget);
  });
}
