// Faults the 0.1.0 self-review (round 2) showed at twice the text size on a phone, each held here:
// - parts measured their words at 1x and drew them at 2x: a thought's words spilled over its cloud, choice tiles broke
//   "In stoc / k" and "Standar / d", balanced paragraphs set in a box too narrow;
// - a key-value row broke "Member since" mid-word; a tier of picture cards kept its pairs and broke their titles;
// - a toggle group's longest label was lettered smaller than the rest; the time picker broke "Minut / e";
// - a field couldn't hold its own direction, so a member number's groups swapped in a right-to-left app.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// [child] at twice the text size, in a phone-wide page.
Future<void> _large(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
}

/// Every word under [within] fits the width its paragraph was given, so none breaks in two.
void _wordsWhole(WidgetTester tester, Finder within) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(of: within, matching: find.byType(RichText)),
  );
  expect(paragraphs, isNotEmpty);
  for (final p in paragraphs) {
    final plain = p.text.toPlainText();
    for (final word in plain.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: word, style: p.text.style),
        textDirection: TextDirection.ltr,
        textScaler: p.textScaler,
        maxLines: 1,
      )..layout();
      expect(
        p.size.width + .5,
        greaterThanOrEqualTo(tp.width),
        reason: '"$word" in "$plain" breaks mid-word',
      );
      tp.dispose();
    }
  }
}

void main() {
  setUpAll(loadComicFonts);

  testWidgets('a thought grows its cloud from its words at 2x', (tester) async {
    await _large(tester, const ComicThought('Still thinking it over'));
    final p = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(ComicThought),
        matching: find.byType(RichText),
      ),
    );
    // The words' whole height at their width stands inside the box the cloud gave them.
    expect(
      p.getMinIntrinsicHeight(p.size.width),
      lessThanOrEqualTo(p.size.height + .5),
    );
    _wordsWhole(tester, find.byType(ComicThought));
  });

  testWidgets('choice tiles hold their words at 2x', (tester) async {
    await _large(
      tester,
      Column(
        children: [
          ComicChoices(
            options: const [
              ComicChoice('Standard', note: '3 to 5 days, €3'),
              ComicChoice('Express', note: 'Next day, €6'),
              ComicChoice('Collect', note: 'In store, free'),
            ],
            value: 'Standard',
            onChanged: (_) {},
          ),
          ComicChoices(
            options: const [
              ComicChoice('Card', note: 'Visa, Mastercard'),
              ComicChoice('Phone wallet', note: 'On this device'),
              ComicChoice('In stock'),
            ],
            value: 'Card',
            onChanged: (_) {},
          ),
        ],
      ),
    );
    _wordsWhole(tester, find.byType(ComicChoices));
  });

  testWidgets('a key-value row keeps its label whole at 2x', (tester) async {
    await _large(
      tester,
      const ComicKvRow('Member since', 'March 2024', isFirst: true),
    );
    _wordsWhole(tester, find.byType(ComicKvRow));
  });

  testWidgets('a tier of pairs stacks at 2x before its titles break', (
    tester,
  ) async {
    await _large(
      tester,
      const ComicTier(
        phone: ComicTierLayout.pairs,
        children: [
          ComicPanel(child: Text('A small adventure')),
          ComicPanel(child: Text('The everyday issue')),
        ],
      ),
    );
    _wordsWhole(tester, find.byType(ComicTier));
    final a = tester.getRect(find.byType(ComicPanel).first);
    final b = tester.getRect(find.byType(ComicPanel).last);
    expect(b.top, greaterThanOrEqualTo(a.bottom), reason: 'stacked');
  });

  testWidgets('a toggle group letters every label alike at 2x', (tester) async {
    await _large(
      tester,
      ComicToggleGroup<String>(
        label: 'Style',
        values: const ['Bold', 'Italic', 'Underline'],
        selected: const {'Bold'},
        multiple: true,
        allowEmpty: true,
        labelOf: (v) => v,
        onChanged: (_) {},
      ),
    );
    final heights = [
      for (final p in tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(ComicToggleGroup<String>),
          matching: find.byType(RichText),
        ),
      ))
        if (const {
          'BOLD',
          'ITALIC',
          'UNDERLINE',
        }.contains(p.text.toPlainText().toUpperCase()))
          MatrixUtils.transformRect(
            p.getTransformTo(null),
            Offset.zero & p.size,
          ).height,
    ];
    expect(heights, hasLength(3));
    for (final h in heights) {
      expect(h, moreOrLessEquals(heights.first, epsilon: .5));
    }
    _wordsWhole(tester, find.byType(ComicToggleGroup<String>));
  });

  testWidgets('the time picker stacks its selects before a label breaks', (
    tester,
  ) async {
    await _large(
      tester,
      ComicTimePicker(
        value: const ComicTime(19, 30),
        minuteStep: 15,
        onChanged: (_) {},
      ),
    );
    final labels = find.descendant(
      of: find.byType(ComicTimePicker),
      matching: find.byType(RichText),
    );
    // Only the selects' labels: a value may ellipsise in a narrow select, a label may not break.
    final words = {'Hour', 'Minute', 'AM or PM'};
    for (final p in tester.renderObjectList<RenderParagraph>(labels)) {
      if (!words.contains(p.text.toPlainText())) continue;
      for (final word in p.text.toPlainText().split(' ')) {
        final tp = TextPainter(
          text: TextSpan(text: word, style: p.text.style),
          textDirection: TextDirection.ltr,
          textScaler: p.textScaler,
        )..layout();
        expect(p.size.width + .5, greaterThanOrEqualTo(tp.width));
        tp.dispose();
      }
    }
  });

  testWidgets('a field holds its own direction in a right-to-left app', (
    tester,
  ) async {
    await _large(
      tester,
      const ComicTextField(
        label: 'Member number',
        initialValue: '0042 1187',
        textDirection: TextDirection.ltr,
      ),
      direction: TextDirection.rtl,
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).textDirection,
      TextDirection.ltr,
    );
  });
}
