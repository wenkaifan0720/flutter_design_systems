// A list tile's compact action (an icon key) stands at the row's end, beside its words, at every width: the row keeps
// the height it has without the key, the chosen band runs under the key, and the key stays a node of its own that a
// tap presses alone. An action with words still goes under the words in a narrow tile. At twice the text in a narrow
// tile the title wraps word by word and the key holds its place; only when the title's widest word can't fit beside
// the key does the key go under the words, so no word is broken.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _tile = Key('tile');
const _title = 'Proof the studio map';
const _subtitle = 'Open studio';
const _keyLabel = 'Task actions';

/// How far a chosen row's band runs past the row on each side, outside a grouped list.
const _bandOutset = 12.0;

enum _Kind { round40, iconButton }

int _opened = 0, _pressed = 0;

Widget _key(_Kind kind) => switch (kind) {
  _Kind.round40 => NeumorphicRoundButton(
    NeumorphicGlyphs.ellipsis,
    size: 40,
    label: _keyLabel,
    onPressed: () => _pressed++,
  ),
  _Kind.iconButton => NeumorphicIconButton(
    NeumorphicGlyphs.ellipsis,
    label: _keyLabel,
    onPressed: () => _pressed++,
  ),
};

Future<void> _show(
  WidgetTester tester, {
  required double width,
  double scale = 1,
  bool selected = false,
  TextDirection direction = TextDirection.ltr,
  String title = _title,
  Widget? trailing,
  Widget? action,
}) async {
  tester.view.physicalSize = Size(width + 40, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _opened = 0;
  _pressed = 0;
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: NeumorphicListTile(
            key: _tile,
            title: title,
            subtitle: _subtitle,
            leading: const NeumorphicMonogram('PS'),
            trailing: trailing,
            selected: selected,
            isFirst: true,
            onPressed: () => _opened++,
            action: action,
          ),
        ),
      ),
      textScale: scale,
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, Finder f) => tester.getRect(f);

/// The key's box: its whole target.
Finder get _keyBox => find.byType(NeumorphicRoundButton);

/// The paragraph of [text], to read whether a word of it is broken.
RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

/// The number of lines [p] is set on.
int _lines(RenderParagraph p) => p
    .getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
    )
    .map((box) => box.top)
    .toSet()
    .length;

/// Whether [p] keeps every word whole: no line is narrower than its widest word.
bool _wordsWhole(RenderParagraph p) =>
    p.getMinIntrinsicWidth(double.infinity) <= p.size.width + .5;

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in const [380.0, 320.0]) {
    for (final scale in const [1.0, 2.0]) {
      for (final selected in const [false, true]) {
        for (final kind in _Kind.values) {
          for (final direction in TextDirection.values) {
            final name =
                '${kind.name} @$width text x$scale'
                '${selected ? ' selected' : ''} ${direction.name}';
            testWidgets(
              '$name: the key stands at the row\'s end beside the words',
              (tester) async {
                final semantics = tester.ensureSemantics();
                await _show(
                  tester,
                  width: width,
                  scale: scale,
                  selected: selected,
                  direction: direction,
                );
                final bare = _rect(tester, find.byKey(_tile));
                final bareTitle = _rect(tester, find.text(_title));
                final bareSubtitle = _rect(tester, find.text(_subtitle));

                await _show(
                  tester,
                  width: width,
                  scale: scale,
                  selected: selected,
                  direction: direction,
                  action: _key(kind),
                );
                final tile = _rect(tester, find.byKey(_tile));
                final key = _rect(tester, _keyBox);
                final title = _rect(tester, find.text(_title));
                final subtitle = _rect(tester, find.text(_subtitle));
                final rtl = direction == TextDirection.rtl;

                // At the row's end: the band's end, less the band's outset.
                if (rtl) {
                  expect(key.left, moreOrLessEquals(tile.left, epsilon: .5));
                } else {
                  expect(key.right, moreOrLessEquals(tile.right, epsilon: .5));
                }
                // A whole target: ui_core's touch floor.
                expect(key.width, greaterThanOrEqualTo(40));
                expect(key.height, greaterThanOrEqualTo(40));
                // Beside the words: across the title's lines, not under the subtitle.
                expect(key.top, lessThan(title.bottom), reason: '$key, $title');
                expect(key.bottom, greaterThan(title.top), reason: '$key');
                expect(key.top, lessThan(subtitle.top), reason: '$key');
                // The words never reach under the key.
                if (rtl) {
                  expect(title.left, greaterThanOrEqualTo(key.right - .5));
                } else {
                  expect(title.right, lessThanOrEqualTo(key.left + .5));
                }
                expect(_wordsWhole(_paragraph(tester, _title)), isTrue);

                // The row keeps its height without the key; where the words take more lines beside the key, it
                // grows by those lines alone.
                final grew =
                    (title.height + subtitle.height) -
                    (bareTitle.height + bareSubtitle.height);
                if (scale == 1) expect(grew, 0, reason: 'the words fit at x1');
                expect(
                  tile.height,
                  moreOrLessEquals(bare.height + grew, epsilon: 1),
                  reason: 'with the key $tile, without $bare',
                );

                // The chosen band runs to the row's end, under the key.
                if (selected) {
                  final paint = find
                      .descendant(
                        of: find.byKey(_tile),
                        matching: find.byType(CustomPaint),
                      )
                      .first;
                  expect(
                    tester.renderObject<RenderCustomPaint>(paint).painter,
                    isNotNull,
                  );
                  final band = const EdgeInsets.symmetric(
                    horizontal: _bandOutset,
                  ).inflateRect(_rect(tester, paint));
                  expect(
                    band.left,
                    lessThanOrEqualTo(key.left - _bandOutset + .5),
                  );
                  expect(
                    band.right,
                    greaterThanOrEqualTo(key.right + _bandOutset - .5),
                  );
                  expect(band.top, lessThanOrEqualTo(key.top + .5));
                  expect(band.bottom, greaterThanOrEqualTo(key.bottom - .5));
                }

                // The key is a node of its own, apart from the row's.
                final keyNode = tester.getSemantics(
                  find.bySemanticsLabel(_keyLabel),
                );
                final rowNode = tester.getSemantics(
                  find.bySemanticsLabel('$_title, $_subtitle'),
                );
                expect(keyNode, isSemantics(label: _keyLabel, isButton: true));
                expect(keyNode.id, isNot(rowNode.id));
                semantics.dispose();

                // A tap on the key presses it alone; a tap on the words opens the row.
                await tester.tapAt(key.center);
                await tester.pumpAndSettle();
                expect((_opened, _pressed), (0, 1));
                await tester.tap(find.text(_subtitle));
                await tester.pumpAndSettle();
                expect((_opened, _pressed), (1, 1));
              },
            );
          }
        }
      }
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'an action with words goes under the words at 380 (${direction.name})',
      (tester) async {
        await _show(
          tester,
          width: 380,
          direction: direction,
          action: NeumorphicButton('Open', onPressed: () {}),
        );
        final button = _rect(tester, find.byType(NeumorphicButton));
        final title = _rect(tester, find.text(_title));
        final subtitle = _rect(tester, find.text(_subtitle));
        expect(button.top, greaterThanOrEqualTo(subtitle.bottom));
        if (direction == TextDirection.rtl) {
          expect(button.right, moreOrLessEquals(title.right, epsilon: .5));
        } else {
          expect(button.left, moreOrLessEquals(title.left, epsilon: .5));
        }
      },
    );
  }

  group('at twice the text in a narrow tile', () {
    testWidgets('the title wraps word by word and a figure goes under, while '
        'the key holds its place', (tester) async {
      await _show(
        tester,
        width: 320,
        scale: 2,
        trailing: const NeumorphicStatus('Due today'),
        action: _key(_Kind.iconButton),
      );
      final tile = _rect(tester, find.byKey(_tile));
      final key = _rect(tester, _keyBox);
      final title = _rect(tester, find.text(_title));
      final status = _rect(tester, find.text('Due today'));
      expect(_lines(_paragraph(tester, _title)), greaterThan(1));
      expect(_wordsWhole(_paragraph(tester, _title)), isTrue);
      expect(status.top, greaterThanOrEqualTo(title.bottom));
      expect(key.right, moreOrLessEquals(tile.right, epsilon: .5));
      expect(key.top, lessThan(title.bottom));
      expect(key.size, const Size(48, 48));
    });

    for (final direction in TextDirection.values) {
      testWidgets(
        'when its widest word can\'t fit beside the key, the key goes '
        'under the words and no word breaks (${direction.name})',
        (tester) async {
          const title = 'Countersign drawings';
          // The tile's widest word and where the words start, read from the row without the key.
          await _show(tester, width: 320, scale: 2, title: title);
          final paragraph = _paragraph(tester, title);
          final widest = paragraph.getMinIntrinsicWidth(double.infinity);
          final bare = _rect(tester, find.byKey(_tile));
          final start = _rect(tester, find.text(title)).left - bare.left;
          // A tile where the widest word fits the words' whole width but not beside a 48 key and its 14 gap.
          final width = (start + widest + 31).ceilToDouble();
          expect(width, lessThanOrEqualTo(320));
          expect(width - start - 48 - 14, lessThan(widest));

          await _show(
            tester,
            width: width,
            scale: 2,
            title: title,
            direction: direction,
            action: _key(_Kind.iconButton),
          );
          final key = _rect(tester, _keyBox);
          final words = _rect(tester, find.text(title));
          final subtitle = _rect(tester, find.text(_subtitle));
          expect(_wordsWhole(_paragraph(tester, title)), isTrue);
          expect(key.top, greaterThanOrEqualTo(subtitle.bottom));
          if (direction == TextDirection.rtl) {
            expect(key.right, moreOrLessEquals(words.right, epsilon: .5));
          } else {
            expect(key.left, moreOrLessEquals(words.left, epsilon: .5));
          }
          expect(key.size, const Size(48, 48));
        },
      );
    }
  });
}
