// On the web a script's face arrives after the first frame: the platform
// fetches it once a word needs it. TermGrid.widthOf measures the words as
// they are drawn now, and TermTheme builds what reads it again when the
// platform's fonts change, so a part sized on widthOf (a window list) is
// sized again on the face that arrived.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _arabic = '\u{627}\u{644}\u{64A}\u{648}\u{645}';

// [family] arrives: JetBrains Mono's file under that name. The test engine
// draws a letter it lacks as its box, 0.6 of an em, where a family it can't
// find drew the test font's em.
Future<void> _arrives(WidgetTester tester, String family) async {
  await tester.runAsync(() async {
    final bytes = File('assets/fonts/JetBrainsMonoNL-Regular.ttf')
        .readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });
  // The platform's word that its fonts changed, as the web engine sends it
  // when a fetched face is ready.
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.system.name,
    SystemChannels.system.codec.encodeMessage(<String, Object?>{
      'type': 'fontsChange',
    }),
    (_) {},
  );
  await tester.pump();
}

void main() {
  setUpAll(loadFaces);

  testWidgets('widthOf measures the face that arrived', (tester) async {
    const face = TermFace(family: 'ArrivesLater', advance: 0.6);
    final grid = TermThemeData.dark(face: face).grid;
    final before = grid.widthOf(_arabic);
    await _arrives(tester, 'ArrivesLater');
    expect(grid.widthOf(_arabic), lessThan(before));
  });

  testWidgets('what reads the grid builds again when a face arrives', (
    tester,
  ) async {
    const face = TermFace(family: 'ArrivesLaterToo', advance: 0.6);
    final widths = <double>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: TermTheme(
          data: TermThemeData.dark(face: face),
          child: Builder(
            builder: (context) {
              widths.add(context.termGrid.widthOf(_arabic));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await _arrives(tester, 'ArrivesLaterToo');
    expect(widths.length, greaterThan(1));
    expect(widths.last, lessThan(widths.first));
  });
}
