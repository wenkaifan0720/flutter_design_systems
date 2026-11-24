// Under a pointer a row's subtitle stands beside its title as a column:
// three fifths of the row in, or where the list says with titleCols, the
// same for every row so the column holds.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _message = 'wait for the token cache before the first call';

Widget _rows({int? titleCols}) => MaterialApp(
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Builder(
      builder: (context) => RawTapTargetScope(
        targets: RawTapTargets.of(context).copyWith(input: RawInput.pointer),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 720,
            child: Column(
              children: [
                for (final (title, message) in const [
                  ('#1481 atlas-api', _message),
                  ('#604 billing-worker', 'invoice rounding'),
                ])
                  TermListTile(
                    title: Text(title),
                    subtitle: Text(message),
                    trailing: const Text('3m 02s'),
                    titleCols: titleCols,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadFaces);

  testWidgets('titleCols moves where a list starts its subtitles', (
    tester,
  ) async {
    await tester.pumpWidget(_rows());
    final threeFifths = tester.getTopLeft(find.text(_message)).dx;

    await tester.pumpWidget(_rows(titleCols: 22));
    final message = find.text(_message);
    final at = tester.getTopLeft(message).dx;
    expect(at, lessThan(threeFifths));
    // One column for the list's subtitles.
    expect(tester.getTopLeft(find.text('invoice rounding')).dx, at);
    // The message has the room the short titles left it.
    final box = tester.renderObject<RenderBox>(message);
    expect(
      box.getMaxIntrinsicWidth(double.infinity),
      lessThanOrEqualTo(box.size.width + 0.5),
    );
    expect(tester.takeException(), isNull);
  });
}
