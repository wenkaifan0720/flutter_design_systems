// A description list sets a term and its description on one baseline, the
// smaller term level with the words it names.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a term and its description stand on one baseline', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ClayHost(
          child: Center(
            child: SizedBox(
              width: 640,
              child: ClayDescriptionList(
                entries: [
                  ClayDescription('Favourite', 'No'),
                  ClayDescription('Status', 'Reading'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    double baseline(String words) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(words));
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
        strutStyle: paragraph.strutStyle,
        textHeightBehavior: paragraph.textHeightBehavior,
      )..layout();
      final below = painter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      painter.dispose();
      return paragraph.localToGlobal(Offset.zero).dy + below;
    }

    expect(baseline('Favourite'), moreOrLessEquals(baseline('No')));
    expect(baseline('Status'), moreOrLessEquals(baseline('Reading')));
  });
}
