// DesignWidthCheck: from 600 wide, a select, a button, a stepper and a
// segmented control keep to the width of what they show (or 320), as laid
// out and as drawn; and a list opened from a field is at least as wide as
// the field, starts on its leading edge, and sets its words on the field's.
import 'dart:io';
import 'dart:ui' show SemanticsInputType;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// The Flutter SDK's Roboto, so words are drawn in a typeface, not the test's
// boxes.
Future<void> _loadRoboto() async {
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
  for (final (family, file) in [
    ('Roboto', 'Roboto-Regular.ttf'),
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
  ]) {
    final font = File('$root/bin/cache/artifacts/material_fonts/$file');
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  }
}

// Material's chevron_right, from the SDK's icon font.
const _chevron = IconData(0xE15F, fontFamily: 'MaterialIcons');

const _page = Color(0xFFF7F7F5);
const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF16181D);
const _line = Color(0xFF8A8F99);
const _fill = Color(0xFF2F5BD3);
const _fieldKey = ValueKey('field');

Widget _words(String s, {Color colour = _ink}) => Text(
  s,
  maxLines: 1,
  softWrap: false,
  style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: colour),
);

// Words in a filled face 40 high, 16 a side.
Widget _button(String label) => Semantics(
  button: true,
  label: label,
  child: GestureDetector(
    onTap: () {},
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(widthFactor: 1, child: _words(label, colour: _white)),
        ),
      ),
    ),
  ),
);

// A select's closed face: its value, then a chevron, 12 a side.
Widget _selectFace(String value, VoidCallback onTap) => Semantics(
  button: true,
  label: value,
  child: GestureDetector(
    key: _fieldKey,
    onTap: onTap,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: _words(value)),
              const SizedBox(width: 8),
              const DecoratedBox(
                decoration: BoxDecoration(color: _line),
                child: SizedBox(width: 10, height: 6),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

// A surface a look paints with a render box of its own: a rounded white
// face, then what it holds.
class _OwnSurface extends SingleChildRenderObjectWidget {
  const _OwnSurface({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOwnSurface();
}

class _RenderOwnSurface extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(offset & size, const Radius.circular(8)),
      Paint()..color = _white,
    );
    super.paint(context, offset);
  }
}

// A select: its face, and a list of [options] (each [itemPad] a side) that
// it opens, on a decorated face or, with [ownSurface], on one its own
// render box paints.
Widget _select(
  String value, {
  List<String> options = const ['Apple', 'Banana', 'Cherry'],
  DesignOverlayPlacement placement = const DesignOverlayPlacement(),
  double itemPad = 12,
  bool ownSurface = false,
}) => DesignAnchoredOverlay(
  placement: placement,
  focusOnOpen: false,
  anchorBuilder: (context, anchor) => _selectFace(value, anchor.toggle),
  overlayBuilder: (context, info) => IntrinsicWidth(
    child: _listSurface(
      ownSurface: ownSurface,
      child: _options(options, info.close, itemPad: itemPad),
    ),
  ),
);

// [options] one over another, each [itemPad] a side; a note in their place
// when there are none.
Widget _options(
  List<String> options,
  VoidCallback onTap, {
  double itemPad = 12,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (options.isEmpty)
      Padding(
        padding: EdgeInsets.symmetric(horizontal: itemPad, vertical: 10),
        child: _words('No matches'),
      ),
    for (final o in options)
      Semantics(
        button: true,
        label: o,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: itemPad, vertical: 10),
            child: _words(o),
          ),
        ),
      ),
  ],
);

// A select whose list a look draws straight into the overlay (an
// OverlayPortal, no repaint boundary of its own) on a surface its own
// render box paints, [listWidth] wide, 4 under the field where _pump puts
// it.
class _PortalSelect extends StatefulWidget {
  const _PortalSelect({
    this.options = const ['Apple', 'Banana', 'Cherry'],
    this.listWidth = 240,
  });

  final List<String> options;
  final double listWidth;

  @override
  State<_PortalSelect> createState() => _PortalSelectState();
}

class _PortalSelectState extends State<_PortalSelect> {
  final _portal = OverlayPortalController();

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => Positioned(
      left: 24,
      top: 24 + 40 + 4,
      width: widget.listWidth,
      child: _OwnSurface(child: _options(widget.options, _portal.hide)),
    ),
    child: _selectFace('Apple', _portal.toggle),
  );
}

// A combobox: a text entry and, beside it, the toggle that opens its list,
// in one ringed face 40 high, the entry's words 12 in.
class _Combobox extends StatefulWidget {
  const _Combobox({this.itemPad = 12, this.chips = const []});

  final double itemPad;

  // Chosen values, each a chip with a way to remove it, before the entry
  // (a multi-select).
  final List<String> chips;

  @override
  State<_Combobox> createState() => _ComboboxState();
}

class _ComboboxState extends State<_Combobox> {
  final _text = TextEditingController(text: 'Lisbon');
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    focusOnOpen: false,
    anchorBuilder: (context, anchor) => DecoratedBox(
      key: _fieldKey,
      decoration: BoxDecoration(
        color: _white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            for (final c in widget.chips)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Semantics(
                  button: true,
                  label: 'Remove $c',
                  child: GestureDetector(
                    onTap: () {},
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE4F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SizedBox(
                        height: 28,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(widthFactor: 1, child: _words(c)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                // As a field's entry announces itself.
                child: Semantics(
                  textField: true,
                  child: EditableText(
                    controller: _text,
                    focusNode: _focus,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: _ink,
                    ),
                    cursorColor: _ink,
                    backgroundCursorColor: _line,
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              expanded: anchor.isOpen,
              label: anchor.isOpen ? 'Hide suggestions' : 'Show suggestions',
              child: GestureDetector(
                onTap: anchor.toggle,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(child: Icon(_chevron, size: 20, color: _ink)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    overlayBuilder: (context, info) => IntrinsicWidth(
      child: _listSurface(
        ownSurface: false,
        child: _options(
          const ['Lisbon', 'Porto'],
          info.close,
          itemPad: widget.itemPad,
        ),
      ),
    ),
  );
}

Widget _listSurface({required bool ownSurface, required Widget child}) =>
    ownSurface
    ? _OwnSurface(child: child)
    : DecoratedBox(
        decoration: BoxDecoration(
          color: _white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );

// A list row 48 high: [label] at its start, a chevron at its end, pressed
// as a whole; [expanded] when it discloses what is under it.
Widget _row(String label, {bool? expanded}) => Semantics(
  button: true,
  label: label,
  expanded: expanded,
  child: GestureDetector(
    onTap: () {},
    child: DecoratedBox(
      decoration: const BoxDecoration(color: _white),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _words(label),
              const Spacer(),
              const Icon(_chevron, size: 24, color: _ink),
            ],
          ),
        ),
      ),
    ),
  ),
);

// [children] one over another, as wide as their column, [gap] apart.
Widget _stack(List<Widget> children, {double gap = 0}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    for (final (i, c) in children.indexed) ...[
      if (i > 0) SizedBox(height: gap),
      c,
    ],
  ],
);

// Choices side by side in one ringed face; [tabs] marks them as tabs, on
// each pressable, or [tabsAround] it (as Material's tab bar says it), and
// [merged] merges what is said round each into one node.
Widget _segments(
  List<String> labels, {
  bool tabs = false,
  bool tabsAround = false,
  bool merged = false,
  bool fill = false,
}) => DecoratedBox(
  decoration: BoxDecoration(
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(8),
  ),
  child: SizedBox(
    height: 40,
    child: Padding(
      // The choices inside the ring, so it shows.
      padding: const EdgeInsets.all(1),
      child: Row(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            _share(
              fill,
              _merge(
                merged,
                _around(
                  tabsAround,
                  Semantics(
                    button: true,
                    selected: i == 0,
                    inMutuallyExclusiveGroup: true,
                    role: tabs ? SemanticsRole.tab : null,
                    label: labels[i],
                    child: GestureDetector(
                      onTap: () {},
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: i == 0 ? const Color(0xFFDDE4F5) : _white,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            widthFactor: 1,
                            child: _words(labels[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);

// [child], said to be a tab round it when [tab].
Widget _around(bool tab, Widget child) =>
    tab ? Semantics(role: SemanticsRole.tab, child: child) : child;

// [child], what is said in it merged into one node when [merge].
Widget _merge(bool merge, Widget child) =>
    merge ? MergeSemantics(child: child) : child;

// [child], taking an equal share of its row when [share].
Widget _share(bool share, Widget child) =>
    share ? Expanded(child: child) : child;

Widget _step(String label) => Semantics(
  button: true,
  label: label,
  child: GestureDetector(
    onTap: () {},
    child: const SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(color: _ink),
          child: SizedBox(width: 12, height: 2),
        ),
      ),
    ),
  ),
);

// A value between a step down and a step up, in one ringed face; with
// [unit], the unit beside the value.
Widget _stepper({String? unit}) => DecoratedBox(
  decoration: BoxDecoration(
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(8),
  ),
  child: SizedBox(
    height: 40,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _step('Decrease'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: unit == null
              ? _words('3')
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [_words('2'), _words(unit)],
                ),
        ),
        _step('Increase'),
      ],
    ),
  ),
);

// [body] on a page [width] wide, 24 in from its sides.
Future<void> _pump(
  WidgetTester tester,
  Widget body, {
  double width = 1200,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: width - 48, child: body),
          ),
        ),
      ),
      textDirection: direction,
    ),
  );
}

Widget _stretched(Widget child) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [child]);

Widget _hugging(Widget child) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [child]);

Future<List<String>> _widths(
  WidgetTester tester, [
  DesignWidthCheck check = const DesignWidthCheck(look: 'Fixture'),
]) async => (await check.check(
  tester.element(find.byType(WidgetsApp)),
  runAsync: tester.runAsync,
)).problems;

Future<List<String>> _list(
  WidgetTester tester, [
  DesignWidthCheck check = const DesignWidthCheck(look: 'Fixture'),
]) async => (await check.checkList(
  tester.element(find.byKey(_fieldKey)),
  runAsync: tester.runAsync,
)).problems;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_fieldKey));
  await tester.pumpAndSettle();
}

Matcher _one(String pattern) => equals([matches(RegExp('^$pattern\$'))]);

void main() {
  setUpAll(_loadRoboto);

  group('from 600 wide', () {
    testWidgets('a select stretched across its column is named, as laid out '
        'and as drawn', (tester) async {
      await _pump(tester, _stretched(_select('Apple')));
      expect(
        await _widths(tester),
        _one(
          r'a select "Apple": 1152 px wide as laid out, 1152 as drawn; its '
          r'content and padding take [0-9.]+ \(at most 320 from 600 wide\)',
        ),
      );
    });

    testWidgets('a select that keeps to its content passes', (tester) async {
      await _pump(tester, _hugging(_select('Apple')));
      expect(await _widths(tester), isEmpty);
    });

    testWidgets("a select in a form grid's cell passes up to 320", (
      tester,
    ) async {
      Widget grid() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _stretched(_select('Apple'))),
          const SizedBox(width: 24),
          const Expanded(child: SizedBox(height: 40)),
        ],
      );
      // Cells of 288 at 648 wide; of 564 at 1200.
      await _pump(tester, grid(), width: 648);
      expect(await _widths(tester), isEmpty);
      await _pump(tester, grid());
      expect(
        await _widths(tester),
        _one(r'a select "Apple": 564 px wide as laid out, 564 as drawn; .*'),
      );
    });

    testWidgets('below 600 wide a control may span its column', (tester) async {
      await _pump(tester, _stretched(_select('Apple')), width: 500);
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a button stretched is named; one whose words need the room '
        'passes', (tester) async {
      await _pump(tester, _stretched(_button('Save')));
      expect(
        await _widths(tester),
        _one(
          r'a button "Save": 1152 px wide as laid out, 1152 as drawn; its '
          r'content and padding take [0-9.]+ \(at most 320 from 600 wide\)',
        ),
      );
      const long = 'Save every change to this ledger, then close the book';
      await _pump(tester, _hugging(_button(long)));
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a button whose words wrap, though on one line they would '
        'fit, is named from 600 wide', (tester) async {
      // A face [width] wide, 16 a side, its words free to wrap.
      Widget wrapping(double width) => Semantics(
        button: true,
        label: 'Open the command palette',
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _fill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: width,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Open the command palette',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: _white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _pump(tester, _hugging(wrapping(152)));
      expect(
        await _widths(tester),
        _one(
          r'a button "Open the command palette": its words wrap onto 2 lines '
          r'in 120 px; on one line they take [0-9.]+ \(from 600 wide buttons '
          r'keep their words on one line\)',
        ),
      );
      await _pump(tester, _hugging(wrapping(260)));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _hugging(wrapping(152)), width: 500);
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a group face is what holds every one of its choices, not a '
        'layer painted over them that holds none; its content is theirs', (
      tester,
    ) async {
      // An hour bank: twelve radio cells 40 wide on a ringed face, and its
      // seams painted over the whole of it by a layer of their own. Each
      // cell's width is set on it, so its content is its words.
      Widget cell(int i) => Semantics(
        button: true,
        inMutuallyExclusiveGroup: true,
        selected: i == 0,
        label: (i + 1).toString().padLeft(2, '0'),
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(child: _words((i + 1).toString().padLeft(2, '0'))),
          ),
        ),
      );
      final bank = DecoratedBox(
        decoration: BoxDecoration(
          color: _white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: 480,
          height: 40,
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _Seams())),
              for (var i = 0; i < 12; i++)
                Positioned(left: i * 40.0, top: 0, child: cell(i)),
            ],
          ),
        ),
      );
      await _pump(
        tester,
        _hugging(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [bank, _button('Save')],
          ),
        ),
      );
      expect(
        await _widths(tester),
        _one(
          r'a segmented control "01": 480 px wide as laid out, 480 as drawn; '
          r'its content and padding take 1[0-9]{2}\.[0-9] \(at most 320 from '
          r'600 wide\)',
        ),
      );
    });

    testWidgets('a segmented control is held whole; tabs keeping to their '
        'words are not held', (tester) async {
      final labels = ['Day', 'Week', 'Month'];
      await _pump(tester, _stretched(_segments(labels)));
      expect(
        await _widths(tester),
        _one(
          r'a segmented control "Day": 1152 px wide as laid out, 1152 as '
          r'drawn; its content and padding take [0-9.]+ \(at most 320 from '
          r'600 wide\)',
        ),
      );
      await _pump(tester, _hugging(_segments(labels)));
      expect(await _widths(tester), isEmpty);
      // Tabs (said on or round each choice) in a ring stretched round them,
      // each keeping to its words: a tab bar that passes.
      await _pump(tester, _stretched(_segments(labels, tabs: true)));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _stretched(_segments(labels, tabsAround: true)));
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a tab bar whose tabs stand past their words is held; folder '
        'tabs of a minimum width pass', (tester) async {
      final labels = ['Day', 'Week', 'Month'];
      const bar =
          r'a tab bar "Day": 1150 px wide as laid out, 1150 as drawn; its 3 '
          "tabs' content and padding take "
          r'[0-9.]+, [0-9.]+ with 40 a tab and the gaps \(at most 320 from 600 '
          r'wide\)';
      await _pump(
        tester,
        _stretched(_segments(labels, tabs: true, fill: true)),
      );
      expect(await _widths(tester), _one(bar));
      await _pump(
        tester,
        _stretched(_segments(labels, tabsAround: true, fill: true)),
      );
      expect(await _widths(tester), _one(bar));
      // The tab said on a MergeSemantics round the control.
      await _pump(
        tester,
        _stretched(
          _segments(labels, tabsAround: true, merged: true, fill: true),
        ),
      );
      expect(await _widths(tester), _one(bar));
      // Six folder tabs, each at least 96 wide: past 320 together, but each
      // within 40 of its words and padding.
      Widget folder(String label) => Semantics(
        role: SemanticsRole.tab,
        selected: label == 'Inbox',
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 96),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: SizedBox(
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(widthFactor: 1, child: _words(label)),
                ),
              ),
            ),
          ),
        ),
      );
      await _pump(
        tester,
        _hugging(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final l in [
                'Inbox',
                'Sent',
                'Drafts',
                'Spam',
                'Trash',
                'Archive',
              ])
                folder(l),
            ],
          ),
        ),
      );
      expect(await _widths(tester), isEmpty);
      // Below 600 fixed tabs may fill.
      await _pump(
        tester,
        _stretched(_segments(labels, tabs: true, fill: true)),
        width: 500,
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a segmented control on a well, its chosen pill sliding under '
        'its choices, is held whole', (tester) async {
      // A well 3 in round its segments, 2 apart, and the chosen one's pill
      // drawn under them by the well, not by the segment.
      Widget segment(String label) => Semantics(
        button: true,
        selected: label == 'Today',
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: _words(label)),
            ),
          ),
        ),
      );
      final well = DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE6E8EE),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: LayoutBuilder(
            builder: (context, box) {
              final share = (box.maxWidth - 4) / 3;
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: share,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Row(
                    spacing: 2,
                    children: [
                      for (final l in ['Today', 'Tomorrow', 'Choose a date'])
                        Expanded(child: segment(l)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
      await _pump(tester, _stretched(well));
      expect(await _widths(tester), _one(r'a segmented control "Today": .*'));
    });

    testWidgets('chosen chips apart, or a navigation bar, are not a '
        'segmented control', (tester) async {
      Widget chip(String label, {bool on = false}) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: on ? const Color(0xFFDDE4F5) : _white,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 32,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(widthFactor: 1, child: _words(label)),
              ),
            ),
          ),
        ),
      );
      await _pump(
        tester,
        _stretched(
          Row(
            spacing: 8,
            children: [chip('All', on: true), chip('Food'), chip('Travel')],
          ),
        ),
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a stepper is held whole', (tester) async {
      await _pump(tester, _stretched(_stepper()));
      expect(
        await _widths(tester),
        _one(
          r'a stepper "Decrease": 1152 px wide as laid out, 1152 as drawn; '
          r'its content and padding take [0-9.]+ \(at most 320 from 600 '
          r'wide\)',
        ),
      );
      await _pump(tester, _hugging(_stepper()));
      expect(await _widths(tester), isEmpty);
      // A count and its unit between the steps.
      await _pump(tester, _stretched(_stepper(unit: 'people')));
      expect(await _widths(tester), _one(r'a stepper "Decrease": .*'));
      await _pump(tester, _hugging(_stepper(unit: 'people')));
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('choices apart, each a face of its own, sharing their column '
        'are a group of choices held to what they show', (tester) async {
      // Each choice: a ringed face, filled when chosen, holding [child].
      Widget choice(String label, Widget child, {bool on = false}) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: on ? const Color(0xFFDDE4F5) : _white,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      );
      Widget shared(List<Widget> choices) => Row(
        spacing: 6,
        children: [for (final c in choices) Expanded(child: c)],
      );
      Widget kept(List<Widget> choices) =>
          Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: choices);
      // Words alone (Comic's choices).
      List<Widget> boxes() => [
        choice('All', _words('All'), on: true),
        choice('New', _words('New')),
        choice('In stock', _words('In stock')),
      ];
      // A figure over its caption (choice cards).
      List<Widget> cards() => [
        for (final (figure, caption) in const [
          (r'$50', 'A week'),
          (r'$100', 'Two weeks'),
          (r'$250', 'A month'),
        ])
          choice(
            figure,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [_words(figure), _words(caption)],
            ),
            on: figure == r'$100',
          ),
      ];
      // One glyph each (icon tiles).
      List<Widget> tiles() => [
        for (final name in ['Plane', 'House', 'Bike', 'Gift'])
          choice(name, const Icon(_chevron, size: 18), on: name == 'Plane'),
      ];
      // A face painted behind the glyph in a stack, holding none of it.
      List<Widget> behind() => [
        for (final name in ['Plane', 'House', 'Bike', 'Gift'])
          Semantics(
            button: true,
            selected: name == 'Plane',
            label: name,
            child: GestureDetector(
              onTap: () {},
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _white,
                        border: Border.all(color: _line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      widthFactor: 1,
                      child: Icon(_chevron, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ];
      const group =
          r'a group of choices "(All|\$50|Plane)": [0-9.]+ px wide as laid '
          r'out, [0-9.]+ as drawn; its [34] '
          "choices' content and padding take "
          r'[0-9.]+, [0-9.]+ with 40 a choice and the gaps \(at most 320 from '
          r'600 wide\)';
      for (final make in [boxes, cards, tiles, behind]) {
        await _pump(tester, shared(make()));
        expect(await _widths(tester), _one(group));
        await _pump(tester, _hugging(kept(make())));
        expect(await _widths(tester), isEmpty);
      }
    });

    testWidgets("a navigation bar's destinations, faces of their own on "
        'none but the chosen, are read one by one', (tester) async {
      Widget destination(String label, {bool on = false}) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFFDDE4F5) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox(
                    width: 56,
                    height: 28,
                    child: Icon(_chevron, size: 18),
                  ),
                ),
                _words(label),
              ],
            ),
          ),
        ),
      );
      await _pump(
        tester,
        Row(
          children: [
            Expanded(child: destination('Home', on: true)),
            Expanded(child: destination('Search')),
            Expanded(child: destination('Profile')),
          ],
        ),
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets("a chart's bars, choices side by side on a surface that "
        'shows more than them, are not a segmented control', (tester) async {
      // A bar per day, the chosen one picked; each a choice the width of its
      // share of the chart.
      Widget bar(String day, double tall) => Semantics(
        button: true,
        selected: day == 'Wed',
        label: day,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 24,
                  height: tall,
                  child: const ColoredBox(color: _fill),
                ),
                const SizedBox(height: 4),
                _words(day),
              ],
            ),
          ),
        ),
      );
      Widget chart({required bool titled}) => DecoratedBox(
        decoration: BoxDecoration(
          color: _white,
          border: Border.all(color: _line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (titled) _words('Meeting hours this week'),
              Row(
                children: [
                  for (final (day, tall) in const [
                    ('Mon', 40.0),
                    ('Tue', 80.0),
                    ('Wed', 120.0),
                    ('Thu', 60.0),
                  ])
                    Expanded(child: bar(day, tall)),
                ],
              ),
            ],
          ),
        ),
      );
      await _pump(tester, chart(titled: true));
      expect(await _widths(tester), isEmpty);
      // The same choices alone in their own ring are a segmented control.
      await _pump(tester, chart(titled: false));
      expect(await _widths(tester), _one(r'a segmented control "Mon": .*'));
    });

    testWidgets('two buttons round a heading are a header, not a stepper: '
        'the heading marked, or the header round them', (tester) async {
      // A calendar's month header and a pushed page's top bar.
      Widget bar({bool heading = false, bool header = false}) {
        Widget title = _words('November 2026');
        if (heading) title = Semantics(header: true, child: title);
        Widget row = Row(
          children: [
            _step('Previous month'),
            Expanded(child: Center(child: title)),
            _step('Next month'),
          ],
        );
        if (header) row = Semantics(header: true, child: row);
        return row;
      }

      await _pump(tester, bar());
      expect(await _widths(tester), _one(r'a stepper "Previous month": .*'));
      await _pump(tester, bar(heading: true));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, bar(header: true));
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a text entry and a list row of two lines may span', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Notes');
      addTearDown(controller.dispose);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await _pump(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: _line)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: EditableText(
                  controller: controller,
                  focusNode: focus,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
                  cursorColor: _ink,
                  backgroundCursorColor: _line,
                ),
              ),
            ),
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: () {},
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: _white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_words('Account'), _words('Signed in')],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a ring drawn inside its box is held where it is drawn', (
      tester,
    ) async {
      // A face the colour of the page, stretched, with a ring drawn [ring]
      // wide at its start.
      Widget ghost(double ring) => Semantics(
        button: true,
        label: 'Ghost',
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _page,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: 40,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: ring,
                    height: 40,
                    child: Center(child: _words('Ghost')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await _pump(tester, _stretched(ghost(200)));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _stretched(ghost(600)));
      expect(
        await _widths(tester),
        _one(
          r'a button "Ghost": 1152 px wide as laid out, 600 as drawn; its '
          r'content and padding take [0-9.]+ \(at most 320 from 600 wide\)',
        ),
      );
    });

    testWidgets("a list's rows span it; the same rows 16 apart are held", (
      tester,
    ) async {
      final rows = [_row('Wi-Fi'), _row('Bluetooth'), _row('Battery')];
      // Touching, and with a 1 px rule between.
      await _pump(tester, _stack(rows));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _stack(rows, gap: 1));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _stack(rows, gap: 16));
      expect(await _widths(tester), hasLength(3));
    });

    testWidgets("a palette's rows span it, a heading apart, each in a "
        'repaint boundary of its own or not; the same rows apart round plain '
        'words are held', (tester) async {
      // A command: its words leading, nothing trailing.
      Widget command(String label) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: DecoratedBox(
            decoration: const BoxDecoration(color: _white),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _words(label),
                ),
              ),
            ),
          ),
        ),
      );
      Widget group(String title, {required bool heading}) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: heading
            ? Semantics(header: true, child: _words(title))
            : _words(title),
      );
      Widget palette({required bool heading, bool boundaries = false}) =>
          _stack([
            for (final item in [
              group('Recent', heading: heading),
              command('Open file'),
              command('New file'),
              group('Account', heading: heading),
              command('Sign out'),
            ])
              // A list's rows are each drawn in a boundary of their own.
              boundaries ? RepaintBoundary(child: item) : item,
          ]);
      await _pump(tester, palette(heading: true));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, palette(heading: true, boundaries: true));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, palette(heading: false));
      expect(await _widths(tester), _one(r'a button "Sign out": .*'));
    });

    testWidgets("an open disclosure and its rows span", (tester) async {
      await _pump(
        tester,
        _stack([_row('Advanced', expanded: true), _row('Proxy'), _row('Port')]),
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets("a section's one row spans it edge to edge; a select in its "
        'padding is held', (tester) async {
      Widget section(Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          color: _white,
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _words('Account'),
            ),
            child,
          ],
        ),
      );
      await _pump(tester, section(_row('Sign out')));
      expect(await _widths(tester), isEmpty);
      await _pump(
        tester,
        section(
          Padding(padding: const EdgeInsets.all(16), child: _select('Apple')),
        ),
      );
      expect(
        await _widths(tester),
        _one(
          r'a select "Apple": 1120 px wide as laid out, [0-9.]+ as drawn; its '
          r'content and padding take [0-9.]+ \(at most 320 from 600 wide\)',
        ),
      );
    });

    testWidgets('a row alone on the page, between paragraphs, spans; a '
        'select there is held', (tester) async {
      Widget page(Widget Function(String) control) => _stack([
        _words('A short sheet rests at its own height.'),
        control('Open the trail log'),
        _words('Raised from code rather than a route.'),
        control('Share this note'),
      ], gap: 8);
      await _pump(tester, page(_row));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, page((label) => _select(label)));
      expect(await _widths(tester), hasLength(2));
    });

    testWidgets("rows a look declares with Flutter's list roles span, whatever "
        'their gaps', (tester) async {
      await _pump(
        tester,
        Semantics(
          role: SemanticsRole.list,
          explicitChildNodes: true,
          child: _stack([
            for (final label in ['Inbox', 'Sent'])
              Semantics(role: SemanticsRole.listItem, child: _row(label)),
          ], gap: 12),
        ),
      );
      expect(await _widths(tester), isEmpty);
    });

    testWidgets('a search bar, by its semantics, spans', (tester) async {
      Widget bar({required bool search}) => Semantics(
        inputType: search ? SemanticsInputType.search : null,
        child: _button('Search'),
      );
      await _pump(tester, _stretched(bar(search: true)));
      expect(await _widths(tester), isEmpty);
      await _pump(tester, _stretched(bar(search: false)));
      expect(await _widths(tester), hasLength(1));
    });

    testWidgets('what is never painted is not read: rows laid out past a '
        "list's end, with or without a boundary of their own; the rest of the "
        'page still is', (tester) async {
      Widget page({required bool boundaries}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _button('Sign in'),
          SizedBox(
            height: 120,
            child: ListView(
              addRepaintBoundaries: boundaries,
              children: [
                for (var i = 0; i < 12; i++)
                  // The fourth row, past the list's end, spans it.
                  i == 3
                      ? _button('Row $i')
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _button('Row $i'),
                        ),
              ],
            ),
          ),
          // What the rows past the list's end would lie over.
          const SizedBox(height: 400, child: ColoredBox(color: _fill)),
        ],
      );
      for (final boundaries in [true, false]) {
        await _pump(tester, page(boundaries: boundaries));
        expect(
          await _widths(tester),
          _one('a button "Sign in": 1152 px wide .*'),
          reason: 'boundaries: $boundaries',
        );
      }
    });

    testWidgets("a look's own limit takes a reason, never a to-do", (
      tester,
    ) async {
      await _pump(tester, _stretched(_button('Sign in')));
      expect(
        await _widths(
          tester,
          const DesignWidthCheck(
            look: 'Fixture',
            limits: {
              DesignWidthKind.button: DesignWidthLimit(
                1200,
                "the sign-in card's one act spans it",
              ),
            },
          ),
        ),
        isEmpty,
      );
      expect(
        await _widths(
          tester,
          const DesignWidthCheck(
            look: 'Fixture',
            limits: {DesignWidthKind.button: DesignWidthLimit(1200, 'TODO')},
          ),
        ),
        ['a limit for buttons: "TODO" is a to-do, not a reason'],
      );
    });
  });

  group('a list opened from a field', () {
    Widget field({
      DesignOverlayPlacement placement = const DesignOverlayPlacement(),
      List<String> options = const ['Apple', 'Banana', 'Cherry'],
      double itemPad = 12,
      bool ownSurface = false,
    }) => _hugging(
      SizedBox(
        width: 240,
        child: _select(
          'Apple',
          placement: placement,
          options: options,
          itemPad: itemPad,
          ownSurface: ownSurface,
        ),
      ),
    );

    for (final width in [390.0, 1440.0]) {
      testWidgets('by default: as wide as the field, on its leading edge, '
          'its words on the field\'s (${width.round()})', (tester) async {
        await _pump(tester, field(), width: width);
        await _open(tester);
        expect(await _list(tester), isEmpty);
      });
    }

    testWidgets('right to left, on its leading edge', (tester) async {
      await _pump(tester, field(), direction: TextDirection.rtl);
      await _open(tester);
      expect(await _list(tester), isEmpty);
    });

    testWidgets('narrower than the field is named', (tester) async {
      await _pump(
        tester,
        field(
          placement: const DesignOverlayPlacement(matchAnchorWidth: false),
          options: const ['Fig', 'Kiwi'],
        ),
      );
      await _open(tester);
      expect(
        await _list(tester),
        _one(
          r'a list opened from a select "Apple": [0-9.]+ px wide as laid '
          r'out, [0-9.]+ as drawn, narrower than the field \(240, 240 as '
          r'drawn\)',
        ),
      );
    });

    testWidgets('off its leading edge is named, and its words with it', (
      tester,
    ) async {
      await _pump(
        tester,
        field(
          placement: const DesignOverlayPlacement(
            align: DesignOverlayAlign.end,
            matchAnchorWidth: false,
          ),
          options: const [
            'A long choice that runs on past the field',
            'Another',
          ],
        ),
      );
      await _open(tester);
      final problems = await _list(tester);
      expect(problems, [
        matches(
          RegExp(
            r'^a list opened from a select "Apple": its leading edge is '
            r"[0-9.]+ px out past the field's as laid out, [0-9.]+ px out "
            r'past as drawn$',
          ),
        ),
        matches(
          RegExp(
            r'^a list opened from a select "Apple": its words are [0-9.]+ px '
            r"out past the field's words$",
          ),
        ),
      ]);
    });

    testWidgets('words set in from the field\'s are named, unless the look '
        'states the indent', (tester) async {
      await _pump(tester, field(itemPad: 24));
      await _open(tester);
      expect(await _list(tester), [
        'a list opened from a select "Apple": its words are 12 px in from '
            "the field's words",
      ]);
      expect(
        await _list(
          tester,
          const DesignWidthCheck(look: 'Fixture', listWordsIndent: 12),
        ),
        isEmpty,
      );
    });

    testWidgets('a list on a surface the look paints with its own render '
        'box is found', (tester) async {
      await _pump(tester, field(ownSurface: true));
      await _open(tester);
      expect(await _list(tester), isEmpty);
    });

    testWidgets('a list on a surface the look paints with its own render '
        'box is held as any other', (tester) async {
      await _pump(
        tester,
        field(
          ownSurface: true,
          placement: const DesignOverlayPlacement(matchAnchorWidth: false),
          options: const ['Fig', 'Kiwi'],
        ),
      );
      await _open(tester);
      expect(
        await _list(tester),
        _one(
          r'a list opened from a select "Apple": [0-9.]+ px wide as laid '
          r'out, [0-9.]+ as drawn, narrower than the field \(240, 240 as '
          r'drawn\)',
        ),
      );
    });

    testWidgets('a field whose list is not open is named', (tester) async {
      await _pump(tester, field());
      expect(await _list(tester), ['no list open from a select "Apple"']);
    });

    Widget portal({
      List<String> options = const ['Apple', 'Banana', 'Cherry'],
      double listWidth = 240,
    }) => _hugging(
      SizedBox(
        width: 240,
        child: _PortalSelect(options: options, listWidth: listWidth),
      ),
    );

    testWidgets('a list drawn straight into the overlay, on a surface the '
        'look paints, is found and read as laid out', (tester) async {
      await _pump(tester, portal());
      await _open(tester);
      expect(await _list(tester), isEmpty);

      // A new field, not the open one.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, portal(listWidth: 200));
      await _open(tester);
      expect(await _list(tester), [
        // Nothing says it is a select (no anchor, no expanded state).
        'a list opened from a button "Apple": 200 px wide as laid out, '
            'narrower than the field (240, 240 as drawn)',
      ]);
    });

    testWidgets('an open list holding no choices, only a note, is still the '
        'list', (tester) async {
      await _pump(tester, portal(options: const []));
      await _open(tester);
      expect(await _list(tester), isEmpty);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, portal(options: const [], listWidth: 200));
      await _open(tester);
      expect(await _list(tester), [
        // Nothing says it is a select (no anchor, no expanded state).
        'a list opened from a button "Apple": 200 px wide as laid out, '
            'narrower than the field (240, 240 as drawn)',
      ]);
    });

    testWidgets("a combobox's field is the face around its entry and "
        'toggle, its words the entry\'s', (tester) async {
      await _pump(
        tester,
        _hugging(const SizedBox(width: 240, child: _Combobox())),
      );
      await tester.tap(find.byIcon(_chevron));
      await tester.pumpAndSettle();
      expect(await _list(tester), isEmpty);

      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        _hugging(const SizedBox(width: 240, child: _Combobox(itemPad: 24))),
      );
      await tester.tap(find.byIcon(_chevron));
      await tester.pumpAndSettle();
      expect(await _list(tester), [
        "a list opened from a select: its words are 12 px in from the field's "
            'words',
      ]);
    });

    testWidgets("a multi-select's groove holding its chosen chips before its "
        'entry is its field', (tester) async {
      await _pump(
        tester,
        _hugging(
          const SizedBox(width: 280, child: _Combobox(chips: ['Porto'])),
        ),
      );
      await tester.tap(find.byIcon(_chevron));
      await tester.pumpAndSettle();
      expect(await _list(tester), isEmpty);
    });

    testWidgets('a disabled field opens nothing and has nothing to check', (
      tester,
    ) async {
      Widget face({required bool enabled}) => _hugging(
        Semantics(
          key: _fieldKey,
          enabled: enabled,
          child: SizedBox(
            width: 240,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _words('Apple'),
                ),
              ),
            ),
          ),
        ),
      );
      await _pump(tester, face(enabled: false));
      await _open(tester);
      expect(await _list(tester), isEmpty);

      await _pump(tester, face(enabled: true));
      await _open(tester);
      expect(await _list(tester), _one('no list open from .*'));
    });
  });
}

// Seams between twelve cells 40 wide, painted over the whole bank.
class _Seams extends CustomPainter {
  const _Seams();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _line;
    for (var x = 40.0; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_Seams oldDelegate) => false;
}
