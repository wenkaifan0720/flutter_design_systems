import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalDataTable', () {
    testWidgets('a status badge stays whole while a name is cut', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          MinimalDataTable<List<String>>(
            rows: const [
              ['ORD-1041', 'Ben Okafor', 'Refunded'],
              ['ORD-1039', 'Dara Kelly', 'Pending'],
            ],
            columns: [
              MinimalDataColumn<List<String>>(
                'Order',
                value: (r) => r[0],
                mono: true,
              ),
              MinimalDataColumn<List<String>>(
                'Customer',
                value: (r) => r[1],
                flex: 2,
              ),
              MinimalDataColumn<List<String>>(
                'Status',
                value: (r) => r[2],
                cell: (context, r) => Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MinimalStatusBadge(r[2]),
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final status in ['Refunded', 'Pending']) {
        final badge = tester.renderObject<RenderParagraph>(find.text(status));
        expect(badge.didExceedMaxLines, isFalse, reason: status);
      }
    });
  });
}
