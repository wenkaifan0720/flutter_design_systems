// A record's long value wraps whole beside its key at a phone's width, never
// cut mid-letter, its first line on the key's line so the dot leader runs
// from the key to it; a mask that cannot stand whole ends in an ellipsis.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _long =
    'The Remarkable Adventures of a Bookkeeper and Other Extraordinary Tales';
// Longer than the line beside its key, each word short enough to stand there.
const _author = 'Mary Ann Evans, later Mary Ann Cross';
const _mask = '··4821 ··9930 ··1177 ··6402 ··5518';

Future<void> _pump(
  WidgetTester t,
  List<Widget> rows, {
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.physicalSize = const Size(390, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: LedgerHost(
          brightness: Brightness.light,
          theme: LedgerThemeData.light(density: LedgerDensity.standard),
          child: Align(
            alignment: Alignment.topCenter,
            // A record's slip on a phone: the page less its gutters.
            child: SizedBox(
              width: 342,
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The height [words] need, wrapped whole at [paragraph]'s width.
double _needed(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.size.width);
  final height = painter.height;
  painter.dispose();
  return height;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a long value wraps whole beside its key (${direction.name})', (
      t,
    ) async {
      await _pump(t, const [
        LedgerKeyValue('Title', _long),
        LedgerKeyValue('Author', _author),
      ], direction: direction);
      final ltr = direction == TextDirection.ltr;
      for (final (key, value) in [('Title', _long), ('Author', _author)]) {
        final paragraph = t.renderObject<RenderParagraph>(find.text(value));
        // Every letter shows: the value stands as tall as its words need.
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(_needed(paragraph) - 0.5),
          reason: '$value is cut',
        );
        final k = t.getRect(find.text(key));
        final v = t.getRect(find.text(value));
        // Its first line stands on the key's line, past the key and the
        // leader's least, so the leader runs from the key to it.
        expect((v.top - k.top).abs(), lessThan(1.5), reason: value);
        expect(
          ltr ? v.left - k.right : k.left - v.right,
          greaterThanOrEqualTo(16 + 2 * 8 - 0.5),
          reason: value,
        );
      }
      // Both take more than one line beside their keys.
      expect(t.getSize(find.text(_long)).height, greaterThan(30));
      expect(t.getSize(find.text(_author)).height, greaterThan(30));
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      'a key measured a hair narrow stands whole (${direction.name})',
      (t) async {
        // A font fallback on the web (a Hebrew key) can measure its words a hair
        // under the width they take: the key keeps every letter all the same.
        await _pump(t, const [
          LedgerLeaderLine(
            wrapsEnd: true,
            start: _HairNarrow(
              child: Text(
                'Status',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            end: Text('Pending'),
          ),
        ], direction: direction);
        final key = t.renderObject<RenderParagraph>(find.text('Status'));
        expect(key.didExceedMaxLines, isFalse, reason: 'the key is cut');
        final k = t.getRect(find.text('Status'));
        final v = t.getRect(find.text('Pending'));
        expect((v.top - k.top).abs(), lessThan(1.5));
      },
    );
  }

  testWidgets('a mask that cannot stand whole ends in an ellipsis', (t) async {
    await _pump(t, const [
      LedgerKeyValue('Accounts', _mask + _mask, monospace: true),
    ]);
    final text = t.widget<Text>(find.text(_mask + _mask));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}

/// Reports its words' width a twentieth of a pixel under what they take.
class _HairNarrow extends SingleChildRenderObjectWidget {
  const _HairNarrow({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHairNarrow();
}

class _RenderHairNarrow extends RenderProxyBox {
  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) - 0.05;
}
