import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:studio_ui_example/kit_gallery/roomtone/roomtone.dart';

void main() {
  setUpAll(studioLoadFonts);
  testWidgets(
    'the transport shows the complete Discard action at double text',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const RoomtoneApp(initialPlace: RoomtonePlace.record, textScale: 2),
      );
      await tester.pumpAndSettle();
      final action = find.text('Discard');
      await tester.ensureVisible(action);
      expect(
        tester.renderObject<RenderParagraph>(action).didExceedMaxLines,
        isFalse,
      );
      final discard = tester.getRect(
        find.ancestor(of: action, matching: find.byType(StudioButton)).first,
      );
      final record = tester.getRect(find.byType(StudioTransportKey).first);
      expect(discard.overlaps(record), isFalse);
    },
  );
}
