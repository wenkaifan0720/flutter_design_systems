// A chosen segment is told by its depth and its words (bold, the full ink) beside the others' (regular, the tertiary
// ink, still 4.5:1 on their face); a list tile's figure stands beside its words or under them by the width and the
// text size, alike in every row; an error is said in the danger ink, a red that reads at 4.5:1 on the wall and on
// every face and well in every palette, by day and by night, its mark once; a three-line row stands its mark and its
// figure level on the title's first line.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_parts.dart' show NeumorphicErrorMark;
import 'package:neumorphism_ui/neumorphism_ui.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _ratio(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double width = 390,
  double textScale = 1,
}) async {
  t.view.physicalSize = Size(width, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: NeumorphicHost(child: app!),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

const _titles = [
  'Middlemarch',
  'The Remains of the Day and a much longer subtitle',
  'Piranesi',
  'A Very Long Title That Wraps Onto Another Line Here',
];

Widget _list() => Column(
  children: [
    for (final (i, title) in _titles.indexed)
      NeumorphicListTile(
        title: title,
        subtitle: 'An author',
        trailing: NeumorphicTag(i.isEven ? 'To read' : 'Done'),
      ),
  ],
);

void main() {
  test('the danger ink reads at 4.5:1 on the wall and every face and well', () {
    for (final p in NeumorphicThemeData.palettes) {
      for (final b in Brightness.values) {
        final c = NeumorphicThemeData.preset(p.id, b).colors;
        for (final on in [
          c.ground,
          c.faceStart,
          c.faceEnd,
          c.wellStart,
          c.wellEnd,
        ]) {
          expect(
            _ratio(c.danger, on),
            greaterThanOrEqualTo(4.5),
            reason: '${p.id} ${b.name}',
          );
        }
        // A red, not the pigment: its hue stands in the reds.
        final hue = HSLColor.fromColor(c.danger).hue;
        expect(
          hue < 20 || hue > 340,
          isTrue,
          reason: '${p.id} ${b.name}: hue $hue',
        );
      }
    }
  });

  testWidgets(
    'a chosen segment: bold in the full ink; the others regular in the tertiary ink',
    (t) async {
      await _pump(
        t,
        NeumorphicSegmentedButton<String>(
          semanticLabel: 'Appearance',
          segments: const [
            NeumorphicButtonSegment('s', 'System'),
            NeumorphicButtonSegment('l', 'Light'),
            NeumorphicButtonSegment('d', 'Dark'),
          ],
          value: 'l',
          onChanged: (_) {},
        ),
      );
      final c = NeumorphicTheme.of(t.element(find.text('Light'))).colors;
      TextStyle style(String w) =>
          t.renderObject<RenderParagraph>(find.text(w)).text.style!;
      expect(style('Light').fontWeight, FontWeight.w700);
      expect(style('Light').color, c.ink);
      for (final w in ['System', 'Dark']) {
        expect(style(w).fontWeight, FontWeight.w500);
        expect(style(w).color, c.inkTertiary);
      }
    },
  );

  testWidgets(
    'a failure is said once, in the danger ink: its words and one mark',
    (t) async {
      await _pump(
        t,
        Column(
          children: [
            NeumorphicTextFormField(
              labelText: 'Title',
              forceErrorText: 'Enter the title',
            ),
            NeumorphicDateField(
              labelText: 'Started',
              value: null,
              onChanged: (_) {},
              errorText: 'Pick a day',
            ),
          ],
        ),
      );
      final c = NeumorphicTheme.of(t.element(find.text('Enter the title')))
          .colors;
      for (final (words, field) in [
        ('Enter the title', NeumorphicTextFormField),
        ('Pick a day', NeumorphicDateField),
      ]) {
        final style = t
            .renderObject<RenderParagraph>(find.text(words))
            .text
            .style!;
        expect(style.color, c.danger, reason: words);
        // At the field's end, so not again on the line under it.
        expect(
          find.descendant(
            of: find.byType(field),
            matching: find.byType(NeumorphicErrorMark),
          ),
          findsOneWidget,
          reason: words,
        );
      }
    },
  );

  for (final (scale, beside) in [(1.0, true), (2.0, false)]) {
    testWidgets('a list stands every row\'s tag alike at 390, text x$scale', (
      t,
    ) async {
      await _pump(t, _list(), textScale: scale);
      final tags = find.byType(NeumorphicTag).evaluate().toList();
      expect(tags, hasLength(_titles.length));
      for (final (i, e) in tags.indexed) {
        final tag = t.getRect(find.byWidget(e.widget));
        final title = t.getRect(find.text(_titles[i]));
        if (beside) {
          // At the row's end, beside the words, long titles too.
          expect(tag.left, greaterThan(title.right), reason: _titles[i]);
        } else {
          // Under the words, short titles too.
          expect(
            tag.top,
            greaterThanOrEqualTo(title.bottom),
            reason: _titles[i],
          );
        }
      }
      if (beside) {
        final ends = [
          for (final e in tags) t.getRect(find.byWidget(e.widget)).right,
        ];
        expect(ends.reduce(math.max) - ends.reduce(math.min), lessThan(.5));
      }
    });
  }

  for (final withAction in [false, true]) {
    testWidgets(
      'a three-line row stands its mark and its figure level, on the title\'s first line${withAction ? ', beside an action' : ''}',
      (t) async {
        const title = 'The Remains of the Day and a much longer subtitle';
        await _pump(
          t,
          NeumorphicListSection(
            children: [
              NeumorphicListTile(
                leading: const NeumorphicMonogram('TR'),
                title: title,
                subtitle: 'Kazuo Ishiguro',
                trailing: const NeumorphicTag('Reading'),
                action: withAction
                    ? NeumorphicIconButton(
                        NeumorphicGlyphs.ellipsis,
                        semanticLabel: 'More',
                        onPressed: () {},
                      )
                    : null,
                onPressed: () {},
              ),
            ],
          ),
        );
        final words = t.renderObject<RenderParagraph>(find.text(title));
        final first = words
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 1),
            )
            .first;
        final top = words.localToGlobal(Offset(0, first.top)).dy;
        final bottom = words.localToGlobal(Offset(0, first.bottom)).dy;
        // The title runs to two lines here: the row is three lines tall.
        expect(
          t.getSize(find.text(title)).height,
          greaterThan((bottom - top) * 1.5),
        );
        final line = (top + bottom) / 2;
        expect(
          t.getCenter(find.byType(NeumorphicMonogram)).dy,
          moreOrLessEquals(line, epsilon: .5),
        );
        final tag = t.getRect(find.byType(NeumorphicTag));
        if (withAction) {
          // Beside the words and a key the tag has no room at 390: it stands under the words.
          expect(
            tag.top,
            greaterThanOrEqualTo(t.getRect(find.text('Kazuo Ishiguro')).bottom),
          );
        } else {
          expect(tag.center.dy, moreOrLessEquals(line, epsilon: .5));
        }
      },
    );
  }
}
