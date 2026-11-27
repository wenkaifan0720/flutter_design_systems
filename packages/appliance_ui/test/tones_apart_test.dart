// Appliance's tones stay apart in each of its six palettes, by day and by
// night: the signal lamp, the ready lamp and the danger lamp (a tag's lamp,
// a primary key and a destructive one), and the words each tag prints.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test(
    'the lamps and the words stay apart in every palette, day and night',
    () {
      const DesignToneCheck(look: 'Appliance').check([
        for (final palette in ApplianceThemeData.palettes)
          for (final brightness in Brightness.values) ...[
            () {
              final c = ApplianceColors.preset(palette.id, brightness);
              return DesignToneSet(
                palette: '${palette.label} lamps',
                brightness: brightness,
                tones: {
                  'signal': c.signal,
                  'ready': c.ready,
                  'danger': c.danger,
                },
              );
            }(),
            () {
              final c = ApplianceColors.preset(palette.id, brightness);
              return DesignToneSet(
                palette: '${palette.label} words',
                brightness: brightness,
                tones: {'signal': c.signalInk, 'danger': c.danger},
              );
            }(),
          ],
      ]).verify();
    },
  );
}
