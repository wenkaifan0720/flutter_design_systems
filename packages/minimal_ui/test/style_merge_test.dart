// MinimalStyle.merge keeps a slot whole, as ButtonStyle.merge does: a style
// that sets a fill only for a press keeps no fill at rest, even over one that
// sets it. Falling through
// within a slot is MinimalStyle.layered's (ui_core's DesignStyle.layered).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);

void main() {
  final pressedOnly = MinimalStyle(
    fill: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.pressed) ? _red : null,
    ),
  );
  const everywhere = MinimalStyle(fill: WidgetStatePropertyAll(_blue));

  test('merge keeps the first style\'s slot whole', () {
    final merged = pressedOnly.merge(everywhere);
    expect(merged.fill!.resolve({WidgetState.pressed}), _red);
    expect(merged.fill!.resolve(const {}), isNull);
  });

  test('layered falls through within a slot', () {
    final layered = MinimalStyle.layered([pressedOnly, everywhere]);
    expect(layered.fill!.resolve({WidgetState.pressed}), _red);
    expect(layered.fill!.resolve(const {}), _blue);
  });

  test('first reads the layers in order, state by state', () {
    final layers = [pressedOnly, everywhere];
    expect(
      MinimalStyle.first(layers, (s) => s.fill, {WidgetState.pressed}),
      _red,
    );
    expect(MinimalStyle.first(layers, (s) => s.fill, const {}), _blue);
  });
}
