// Behind another window a list table's selection stays in sight: the machine's
// grey a step off the paper, darker by day and lighter by night. By night the
// pressed grey it took is the paper's own, and the row read as unselected.
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

const _shot = ValueKey('shot');

/// The commonest colour in [r]: a row's fill under its words.
Color _fill(ByteData bytes, int width, Rect r) {
  final counts = <int, int>{};
  for (var y = r.top.ceil(); y < r.bottom.floor(); y++) {
    for (var x = r.left.ceil(); x < r.right.floor(); x++) {
      final v = bytes.getUint32((y * width + x) * 4);
      counts[v] = (counts[v] ?? 0) + 1;
    }
  }
  final rgba = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  return Color.fromARGB(
    0xff,
    rgba >> 24 & 0xff,
    rgba >> 16 & 0xff,
    rgba >> 8 & 0xff,
  );
}

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final brightness in Brightness.values) {
    testWidgets('behind another window the selected row stands off the '
        'others (${brightness.name})', (tester) async {
      tester.view.physicalSize = const Size(390, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) =>
              RetroDesktopHost(brightness: brightness, child: app!),
          home: RepaintBoundary(
            key: _shot,
            child: RetroDesktopWindowScope(
              active: false,
              compact: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RetroDesktopListTable(
                  columns: const [
                    RetroDesktopListTableColumn('Name'),
                    RetroDesktopListTableColumn('Size', width: 80),
                  ],
                  rows: const [
                    RetroDesktopListTableRow(
                      title: 'Meeting summary',
                      cells: [('18 KB', null)],
                    ),
                    RetroDesktopListTableRow(
                      title: 'Project notes',
                      cells: [('24 KB', null)],
                    ),
                    RetroDesktopListTableRow(
                      title: 'Quarterly plan',
                      cells: [('112 KB', null)],
                    ),
                  ],
                  selected: 1,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      late ByteData bytes;
      late int width;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_shot),
        );
        final image = await boundary.toImage();
        width = image.width;
        bytes = (await image.toByteData())!;
        image.dispose();
      });
      final origin = tester.getTopLeft(find.byKey(_shot));
      final table = tester.getRect(find.byType(RetroDesktopListTable));
      Color row(String title) {
        final words = tester.getRect(find.text(title));
        return _fill(
          bytes,
          width,
          Rect.fromLTRB(
            table.left + 4,
            words.top,
            table.right - 4,
            words.bottom,
          ).shift(-origin),
        );
      }

      final selected = row('Project notes');
      for (final other in ['Meeting summary', 'Quarterly plan']) {
        expect(
          _ratio(selected, row(other)),
          greaterThanOrEqualTo(1.3),
          reason: 'the selected row $selected against "$other"',
        );
      }
    });
  }
}
