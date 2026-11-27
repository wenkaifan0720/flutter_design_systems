// A row a swipe slides aside stays inside its list's plate: the plate clips
// its rows to the corners it is drawn with (the theme's, or those a style
// gives it), so the row's words and glyph never draw on the housing past
// the plate's edge, in either reading direction.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _list(TextDirection direction, {ApplianceStyle? style}) => WidgetsApp(
  color: const Color(0xFFEE6A26),
  builder: (context, _) => Directionality(
    textDirection: direction,
    child: ApplianceHost(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ApplianceListGroup(
          style: style,
          children: [
            for (final title in ['Stoner', 'Pachinko'])
              ApplianceSwipeActions(
                endActions: [
                  RawSwipeAction(
                    label: 'Delete',
                    destructive: true,
                    onPressed: () {},
                  ),
                ],
                child: ApplianceListTile(
                  leading: const Icon(LucideIcons.heart),
                  title: title,
                  onTap: () {},
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);

/// The rounded clip over [finder]'s render object that stands on the plate
/// at [plate], in global coordinates; null when none does.
RRect? _plateClip(WidgetTester tester, Finder finder, Rect plate) {
  RenderObject? node = tester.renderObject(finder);
  while (node != null) {
    if (node is RenderClipRRect) {
      final clip = node.clipper!.getClip(node.size);
      final at = node.localToGlobal(Offset.zero);
      final placed = clip.shift(at);
      if ((placed.outerRect.left - plate.left).abs() < 0.5 &&
          (placed.outerRect.right - plate.right).abs() < 0.5) {
        return placed;
      }
    }
    node = node.parent;
  }
  return null;
}

Future<Rect> _swipeOpen(WidgetTester tester, TextDirection direction) async {
  tester.view.physicalSize = const Size(390, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_list(direction));
  final plate = tester.getRect(find.byType(AppliancePanel));
  final toStart = direction == TextDirection.ltr ? -1.0 : 1.0;
  await tester.drag(find.text('Pachinko'), Offset(160 * toStart, 0));
  await tester.pumpAndSettle();
  return plate;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a swiped row stays inside the plate (${direction.name})', (
      tester,
    ) async {
      final plate = await _swipeOpen(tester, direction);
      final glyph = tester.getRect(find.byIcon(LucideIcons.heart).last);
      final theme = ApplianceTheme.of(tester.element(find.text('Pachinko')));
      // The row slid: its glyph now stands past the plate's start edge.
      if (direction == TextDirection.ltr) {
        expect(glyph.left, lessThan(plate.left));
      } else {
        expect(glyph.right, greaterThan(plate.right));
      }
      final clip = _plateClip(tester, find.text('Pachinko'), plate);
      expect(clip, isNotNull, reason: 'the plate clips its rows');
      expect(clip!.outerRect.top, closeTo(plate.top, 0.5));
      expect(clip.outerRect.bottom, closeTo(plate.bottom, 0.5));
      expect(clip.tlRadiusX, theme.radiusPanel);
      expect(clip.brRadiusX, theme.radiusPanel);
      // The Delete key behind the row is clipped by the same corners.
      expect(_plateClip(tester, find.text('Delete'), plate), isNotNull);
    });
  }

  testWidgets('the clip follows the corners a style gives the plate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const cut = ApplianceStyle(
      corners: WidgetStatePropertyAll(
        RawCorners(topStart: RawCorner.extraSmall, bottomEnd: RawCorner.full),
      ),
    );
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(_list(direction, style: cut));
      final plate = tester.getRect(find.byType(AppliancePanel));
      final clip = _plateClip(tester, find.text('Stoner'), plate)!;
      final theme = ApplianceTheme.of(tester.element(find.text('Stoner')));
      final small = theme.shapeScheme.corners.extraSmall;
      final half = plate.shortestSide / 2;
      if (direction == TextDirection.ltr) {
        expect(clip.tlRadiusX, small);
        expect(clip.brRadiusX, half);
        expect(clip.trRadiusX, theme.radiusPanel);
      } else {
        expect(clip.trRadiusX, small);
        expect(clip.blRadiusX, half);
        expect(clip.tlRadiusX, theme.radiusPanel);
      }
    }
  });
}
