import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

void main() {
  testWidgets('MinimalIconTile is the size it is given', (tester) async {
    await tester.pumpWidget(
      columnHost(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalIconTile(Icons.settings, key: Key('a')),
            MinimalIconTile(Icons.settings, size: 40, key: Key('b')),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('a'))), const Size(28, 28));
    expect(tester.getSize(find.byKey(const Key('b'))), const Size(40, 40));
  });
}
