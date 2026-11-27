// A destructive key stands apart from the key beside it and from the main
// key, by day and by night, in every palette: its cap is graphite warmed by
// the danger light, its legend reads at 4.5:1 down the whole cap, and its lamp
// is red. An ordinary destructive key's red legend reads at 4.5:1 too.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Future<StudioFace> _cap(
  WidgetTester tester,
  StudioThemeData theme,
  StudioButton key,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: StudioTheme(
        data: theme,
        child: Center(child: key),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester
      .widget<AnimatedStudioSurface>(
        find
            .descendant(
              of: find.byType(StudioButton),
              matching: find.byType(AnimatedStudioSurface),
            )
            .first,
      )
      .face;
}

void main() {
  for (final palette in StudioThemeData.palettes) {
    for (final brightness in Brightness.values) {
      final at =
          '${palette.label} by ${brightness == Brightness.dark ? 'night' : 'day'}';
      testWidgets('Delete stands apart from Keep and from Save: $at', (
        tester,
      ) async {
        final theme = StudioThemeData.preset(palette.id, brightness);
        final keep = await _cap(
          tester,
          theme,
          StudioButton('Keep', onPressed: () {}),
        );
        final save = await _cap(
          tester,
          theme,
          StudioButton.lit('Save', onPressed: () {}),
        );
        final delete = await _cap(
          tester,
          theme,
          StudioButton.lit(
            'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        );
        final plainDelete = await _cap(
          tester,
          theme,
          StudioButton('Delete', isDestructiveAction: true, onPressed: () {}),
        );
        expect(
          DesignToneCheck.distance(delete.fill, keep.fill),
          greaterThanOrEqualTo(24),
          reason: 'Delete ${delete.fill} beside Keep ${keep.fill}',
        );
        expect(
          DesignToneCheck.distance(delete.fill, save.fill),
          greaterThanOrEqualTo(24),
          reason: 'Delete ${delete.fill} beside Save ${save.fill}',
        );
        for (final (name, face) in [
          ('Delete', delete),
          ('plain Delete', plainDelete),
        ]) {
          for (final tone in [face.fill, face.fillLow]) {
            expect(
              RawPalette.contrastRatio(face.foreground!, tone),
              greaterThanOrEqualTo(4.5),
              reason: '$name legend ${face.foreground} on $tone',
            );
          }
        }
      });
    }
  }
}
