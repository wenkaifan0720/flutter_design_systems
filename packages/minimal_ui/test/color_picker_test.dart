import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/padded_host.dart';

void main() {
  group('MinimalColorPicker', () {
    testWidgets('one gap stands between every part', (tester) async {
      await tester.pumpWidget(
        paddedHost(
          SizedBox(
            width: 320,
            child: MinimalColorPicker(
              value: const Color(0xFF2563EB),
              onChanged: (_) {},
              showAlpha: true,
              swatches: const [Color(0xFF2563EB), Color(0xFF16A34A)],
            ),
          ),
        ),
      );
      final picker = find.byType(MinimalColorPicker);
      final tracks = find.descendant(
        of: picker,
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_ChannelTrack',
        ),
      );
      expect(tracks, findsNWidgets(2));
      final area = tester.getRect(find.byType(RawColorArea));
      final hue = tester.getRect(tracks.first);
      final alpha = tester.getRect(tracks.last);
      final hex = tester.getRect(
        find
            .ancestor(
              of: find.byType(MinimalTextField),
              matching: find.byType(Row),
            )
            .first,
      );
      final swatches = tester.getRect(
        find.descendant(of: picker, matching: find.byType(Wrap)).last,
      );
      expect(hue.top - area.bottom, moreOrLessEquals(16));
      expect(alpha.top - hue.bottom, moreOrLessEquals(16));
      expect(hex.top - alpha.bottom, moreOrLessEquals(16));
      expect(swatches.top - hex.bottom, moreOrLessEquals(16));
    });
  });
}
