import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

// A look names the shared style as its own, as the looks do from 0.2.0.
typedef _LookStyle = RawStyle;
typedef _LookStyleOf = RawStyleOf;

const _red = Color(0xFFFF0000);
const _blue = Color(0xFF0000FF);
const _green = Color(0xFF00FF00);
const _pressed = {WidgetState.pressed};
const _rest = <WidgetState>{};

// Red under a press, nothing otherwise: falls through at rest.
final _pressRed = WidgetStateProperty.resolveWith<Color?>(
  (states) => states.contains(WidgetState.pressed) ? _red : null,
);

void main() {
  test('a look alias is the shared type: const, factory, statics and '
      'tear-offs all work through it', () {
    const style = _LookStyle(fill: WidgetStatePropertyAll(_red));
    expect(style, isA<RawStyle>());
    expect(style.runtimeType, RawStyle);
    expect(_LookStyle.layered([style]).fill?.resolve(_rest), _red);
    expect(_LookStyle.first([style], (s) => s.fill, _rest), _red);
    expect(_LookStyle.lerp(style, style, .5), same(style));
    const make = _LookStyle.new;
    expect(make(fill: style.fill), style);
    expect(const _LookStyleOf([style], _rest).fill, _red);
  });

  test('layered falls through inside a slot, state by state; merge keeps '
      'a slot whole', () {
    const theme = RawStyle(fill: WidgetStatePropertyAll(_blue));
    final own = RawStyle(fill: _pressRed);
    final layered = RawStyle.layered([own, null, theme]);
    expect(layered.fill!.resolve(_pressed), _red);
    expect(layered.fill!.resolve(_rest), _blue, reason: 'falls to the theme');
    final merged = own.merge(theme);
    expect(merged.fill!.resolve(_pressed), _red);
    expect(merged.fill!.resolve(_rest), isNull, reason: 'the slot is kept');
    expect(RawStyle.layered([null]).isEmpty, isTrue);
    expect(RawStyle.layered([theme]).fill, same(theme.fill));
  });

  test('first reads the layers in order; resolve falls back', () {
    final own = RawStyle(fill: _pressRed);
    const theme = RawStyle(fill: WidgetStatePropertyAll(_blue));
    expect(RawStyle.first([own, theme], (s) => s.fill, _pressed), _red);
    expect(RawStyle.first([own, theme], (s) => s.fill, _rest), _blue);
    expect(RawStyle.first([own], (s) => s.fill, _rest), isNull);
    expect(RawStyle.resolve(own.fill, _rest, _green), _green);
    expect(RawStyle.resolve(own.fill, _pressed, _green), _red);
  });

  test('copyWith changes the named slots and keeps the rest', () {
    const style = RawStyle(
      fill: WidgetStatePropertyAll(_red),
      iconSize: WidgetStatePropertyAll(20),
    );
    final changed = style.copyWith(fill: const WidgetStatePropertyAll(_blue));
    expect(changed.fill!.resolve(_rest), _blue);
    expect(changed.iconSize, same(style.iconSize));
    expect(style.merge(null), same(style));
  });

  test('lerp blends what both sides have and snaps what one side lacks', () {
    const a = RawStyle(
      fill: WidgetStatePropertyAll(Color(0xFF000000)),
      padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
      iconSize: WidgetStatePropertyAll(16),
      foreground: WidgetStatePropertyAll(_red),
    );
    const b = RawStyle(
      fill: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
      padding: WidgetStatePropertyAll(EdgeInsets.all(16)),
      iconSize: WidgetStatePropertyAll(24),
    );
    final mid = RawStyle.lerp(a, b, .5)!;
    expect(
      mid.fill!.resolve(_rest),
      Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), .5),
    );
    expect(mid.padding!.resolve(_rest), const EdgeInsets.all(12));
    expect(mid.iconSize!.resolve(_rest), 20);
    expect(RawStyle.lerp(a, b, .4)!.foreground!.resolve(_rest), _red);
    expect(RawStyle.lerp(a, b, .6)!.foreground!.resolve(_rest), isNull);
    expect(RawStyle.lerp(a, b, 0), same(a));
    expect(RawStyle.lerp(a, b, 1), same(b));
    // Round corners morph into each other.
    final shapes = RawStyle.lerp(
      const RawStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder())),
      const RawStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      .5,
    )!;
    expect(
      shapes.shape!.resolve(_rest),
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  });

  test('equal styles share a hash; isEmpty; diagnostics name set slots '
      'only', () {
    const fill = WidgetStatePropertyAll(_red);
    expect(const RawStyle(fill: fill), const RawStyle(fill: fill));
    expect(
      const RawStyle(fill: fill).hashCode,
      const RawStyle(fill: fill).hashCode,
    );
    expect(const RawStyle(fill: fill), isNot(const RawStyle()));
    expect(const RawStyle().isEmpty, isTrue);
    expect(const RawStyle(fill: fill).isEmpty, isFalse);
    final builder = DiagnosticPropertiesBuilder();
    const RawStyle(fill: fill).debugFillProperties(builder);
    final shown = builder.properties
        .where((p) => !p.isFiltered(DiagnosticLevel.info))
        .map((p) => p.name);
    expect(shown, ['fill']);
  });

  group('RawStyleOf', () {
    final own = RawStyle(
      fill: _pressRed,
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.only(start: 4, end: 12),
      ),
    );
    const theme = RawStyle(
      fill: WidgetStatePropertyAll(_blue),
      shape: WidgetStatePropertyAll(StadiumBorder()),
      iconSize: WidgetStatePropertyAll(18),
    );

    test('reads each slot from the first layer that has it at its states', () {
      final look = RawStyleOf([own, theme], _pressed);
      expect(look.fill, _red);
      expect(look.at(_rest).fill, _blue);
      expect(look.iconSize, 18);
      expect(look.shape, const StadiumBorder());
      expect(look.foreground, isNull);
      expect(
        look.padding(TextDirection.rtl),
        const EdgeInsets.only(left: 12, right: 4),
      );
    });

    test('shapes and overlay read any states; overlay is null with none', () {
      final look = RawStyleOf([own, theme], _rest);
      const square = RoundedRectangleBorder();
      expect(look.shapes(square).resolve(_pressed), const StadiumBorder());
      expect(
        const RawStyleOf([RawStyle()], _rest).shapes(square).resolve({}),
        square,
      );
      expect(look.overlay, isNull);
      final washed = RawStyleOf([
        RawStyle(overlay: _pressRed),
        const RawStyle(overlay: WidgetStatePropertyAll(_green)),
      ], _rest);
      expect(washed.overlay!.resolve(_pressed), _red);
      expect(washed.overlay!.resolve(_rest), _green);
    });

    test('freeze holds the values at its states, whatever states read it', () {
      final frozen = RawStyleOf([own, theme], _pressed).freeze();
      expect(frozen.fill!.resolve(_rest), _red);
      expect(frozen.iconSize!.resolve(_rest), 18);
      expect(frozen.foreground, isNull);
      expect(
        frozen.padding!.resolve(_rest),
        const EdgeInsetsDirectional.only(start: 4, end: 12),
      );
    });
  });
}
