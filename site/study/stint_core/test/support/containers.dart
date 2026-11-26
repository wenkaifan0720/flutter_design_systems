import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

/// Checks every page of an edition, at 390 and 1440, day and night, for a
/// look container set inside another of the look's containers, the double
/// frame a reader sees as a box in a box, and for a container that insets
/// its children on some sides but not on others, so that its edges run
/// flush with theirs where they don't inset: a misregistered double outline.
///
/// [kind] names a widget's container kind, or null where it is none.
/// [allowed] says which kind may sit in which, such as glass set into a
/// panel as an instrument's window is. [padding] gives a container's own
/// inset, where the look's API sets one.
void checkContainers({
  required String look,
  required Widget Function(StintLaunch launch, StintRepository repository) app,
  required String? Function(Widget widget) kind,
  bool Function(String inner, String outer)? allowed,
  EdgeInsetsGeometry? Function(Widget widget)? padding,
}) {
  const pages = [
    (Place.today, false, ''),
    (Place.tasks, false, ''),
    (Place.tasks, true, ''),
    (Place.tasks, false, 'empty'),
    (Place.time, false, ''),
    (Place.time, false, 'empty'),
    (Place.settings, false, ''),
  ];
  for (final size in const [Size(390, 844), Size(1440, 960)]) {
    for (final appearance in const [Appearance.day, Appearance.night]) {
      testWidgets(
        'no $look container sits in another at ${size.width.round()}, '
        '${appearance.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final faults = <String>[];
          for (final (place, detail, scenario) in pages) {
            final page =
                '${place.name}${detail ? ' detail' : ''}'
                '${scenario.isEmpty ? '' : ' $scenario'}';
            await tester.pumpWidget(
              KeyedSubtree(
                key: UniqueKey(),
                child: app(
                  StintLaunch(
                    place: place,
                    detail: detail,
                    appearance: appearance,
                    scenario: scenario,
                  ),
                  StintRepository(
                    clock: () => studyMorning,
                    empty: scenario == 'empty',
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (final element
                in find.byWidgetPredicate((w) => kind(w) != null).evaluate()) {
              final widget = element.widget, name = kind(widget)!;
              final box = element.renderObject! as RenderBox;
              final at = box.localToGlobal(Offset.zero) & box.size;
              final where = '$page: $name at ${at.topLeft} ${at.size}';
              element.visitAncestorElements((ancestor) {
                final outer = kind(ancestor.widget);
                if (outer == null) return true;
                // A part that draws its surface through another of its own
                // box (an animated face over a still one) is one surface.
                final round = ancestor.renderObject;
                if (round is RenderBox && round.hasSize) {
                  final own = round.localToGlobal(Offset.zero) & round.size;
                  if ((own.topLeft - at.topLeft).distance < 0.5 &&
                      (own.bottomRight - at.bottomRight).distance < 0.5) {
                    return false;
                  }
                }
                if (!(allowed?.call(name, outer) ?? false)) {
                  faults.add('$where sits in $outer');
                }
                return false;
              });
              final inset = padding?.call(widget)?.resolve(TextDirection.ltr);
              if (inset != null) {
                final sides = [
                  inset.left,
                  inset.top,
                  inset.right,
                  inset.bottom,
                ];
                if (sides.any((s) => s == 0) && sides.any((s) => s > 0)) {
                  faults.add('$where insets only some sides: $inset');
                }
              }
            }
          }
          expect(faults, isEmpty, reason: faults.join('\n'));
        },
      );
    }
  }
}
