// Comic's first law, flat opaque inks, checked where a part reads its style: a fill or an overlay part way see-through
// asserts in debug builds (a guard, not a clamp: a caller's colour is drawn as given in a release build).
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Whether [color] is a flat ink: opaque, or wholly clear (which stands for none).
bool comicFlatInk(Color? color) =>
    color == null || color.a == 0 || color.a == 1;

/// Resolves [layers] for [states] and checks that fills and overlays are opaque in debug mode.
DesignStyleOf comicStyleOf(List<DesignStyle?> layers, Set<WidgetState> states) {
  final look = DesignStyleOf(layers, states);
  assert(
    comicFlatInk(look.fill),
    "Comic's first law is flat opaque inks, nothing see-through: a part's fill resolved to ${look.fill}. Give an "
    'opaque ink; a lighter tone is a screen of Ben-Day dots (ComicBenDay).',
  );
  assert(() {
    for (final more in const [
      <WidgetState>{},
      {WidgetState.hovered},
      {WidgetState.pressed},
      {WidgetState.focused},
    ]) {
      final overlay = look.overlay?.resolve({...states, ...more});
      if (!comicFlatInk(overlay)) {
        throw FlutterError(
          "Comic's first law is flat opaque inks, nothing see-through: a part's overlay resolved to $overlay at "
          '${{...states, ...more}}. Give an opaque ink, or none.',
        );
      }
    }
    return true;
  }());
  return look;
}
