import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

typedef _Part = Widget Function(String label, NeumorphicStyle? style);

void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <String, _Part>{
    // The buttons are pills at their small size; the medium and large ones are the control's rounded rectangle.
    'act': (label, style) => NeumorphicButton.filled(
      label,
      size: NeumorphicButtonSize.small,
      style: style,
      onPressed: () {},
    ),
    'line': (label, style) => NeumorphicButton(
      label,
      size: NeumorphicButtonSize.small,
      style: style,
      onPressed: () {},
    ),
    'chip': (label, style) =>
        NeumorphicChip(label, style: style, onPressed: () {}),
    'tag': (label, style) => NeumorphicTag(label, style: style),
    'segments': (label, style) => NeumorphicSegmentedButton<int>(
      label: 'Settings',
      segments: [NeumorphicButtonSegment(1, label)],
      value: 1,
      style: style,
      onChanged: (_) {},
    ),
    'latches': (label, style) => NeumorphicLatchGroup(
      options: [NeumorphicLatch(label)],
      value: label,
      style: style,
      onChanged: (_) {},
    ),
  };
  for (final entry in parts.entries) {
    for (final density in [
      NeumorphicDensity.compact,
      NeumorphicDensity.standard,
      NeumorphicDensity.comfortable,
    ]) {
      for (final scale in [1.0, 1.3]) {
        for (final long in [false, true]) {
          final label = long ? 'A much longer setting name' : 'One';
          testWidgets('${entry.key} wraps=$long $density $scale', (
            tester,
          ) async {
            await mount(
              tester,
              entry.value(label, null),
              NeumorphicThemeData.porcelain().copyWith(density: density),
              width: 120,
              scale: scale,
            );
            final role = entry.key == 'tag'
                ? tester
                      .widget<NeumorphicSurface>(find.byType(NeumorphicSurface))
                      .shape
                : tester
                      .widgetList<NeumorphicTap>(find.byType(NeumorphicTap))
                      .singleWhere((tap) => tap.label == label)
                      .shape;
            // A bank's cell takes its outline from the bank: the bank is the pill that holds or wraps the words.
            final shape = role is NeumorphicCellBorder ? role.bank : role;
            expect(
              shape,
              long
                  ? isA<NeumorphicRoundedBorder>()
                  : isA<NeumorphicStadiumBorder>(),
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
    testWidgets('${entry.key} keeps an explicitly supplied shape', (
      tester,
    ) async {
      const shape = NeumorphicRoundedBorder(radius: 3);
      await mount(
        tester,
        entry.value(
          'One',
          const NeumorphicStyle(shape: WidgetStatePropertyAll(shape)),
        ),
        NeumorphicThemeData.porcelain(),
        width: 120,
      );
      final local = entry.key == 'tag'
          ? tester
                .widget<NeumorphicSurface>(find.byType(NeumorphicSurface))
                .style
          : tester
                .widgetList<NeumorphicTap>(find.byType(NeumorphicTap))
                .singleWhere((tap) => tap.label == 'One')
                .style;
      expect(local?.shape?.resolve({}), shape);
    });
  }
  for (final enabled in [false, true]) {
    testWidgets('switch row forwards enabled=$enabled to its face', (
      tester,
    ) async {
      await mount(
        tester,
        NeumorphicSwitchRow(
          label: 'Setting',
          value: true,
          onChanged: enabled ? (_) {} : null,
          style: NeumorphicStyle(
            fill: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? Colors.red
                  : Colors.blue,
            ),
          ),
        ),
        NeumorphicThemeData.porcelain(),
      );
      final face = tester.widget<NeumorphicSwitch>(
        find.byType(NeumorphicSwitch),
      );
      expect(face.onChanged != null, enabled);
      if (enabled) {
        await tester.tap(find.text('Setting'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
