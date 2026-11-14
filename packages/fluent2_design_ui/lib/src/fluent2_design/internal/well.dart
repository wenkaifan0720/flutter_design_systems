import 'package:flutter/widgets.dart';

import '../components/pressable/pressable.dart';
import '../theme.dart';

/// The fill of a neutral well: a segmented control's track, a filled tag or
/// a filled circular tab at rest, a neutral tile, in its [press] step (out
/// of use, [fluent2WellDisabled]).
///
/// Fluent draws these in `neutralBackground3` (#F5F5F5 by day), a step that
/// reads only on a white card: on the brand-tinted ground (`background`) it
/// all but disappears, and a chosen thumb is left as one pill among loose
/// words. So a well is laid over whatever stands under it, a step darker
/// than its ground everywhere: by day Fluent's `neutralBackground5` step
/// from white (8% ink), by night Fluent's `neutralBackground4` under a
/// card (#292929 to #0E0E0E, 65% ink: half, Fluent's `neutralBackground3`
/// step, stood only 1.14:1 on the warmer presets' tinted night page, where
/// grounds this dark crowd together). On a card it is Fluent's grey; on the
/// page, a card or the desktop layer it stands at least 1.15:1 from the
/// ground. Under the pointer and pressed it takes [fluent2WellWash] over it.
Color fluent2Well(
  Fluent2ThemeData t, [
  Fluent2Press press = Fluent2Press.rest,
]) {
  final rest = t.brightness == Brightness.dark
      ? const Color(0xA6000000)
      : const Color(0x14000000);
  return Color.alphaBlend(fluent2WellWash(t, press), rest);
}

/// What a part laid in a well paints over it in its [press] step (an
/// unchosen segment on the segmented control's track): none at rest, then
/// more ink, so the well steps darker under the pointer and darker again
/// pressed. By day it then stands Fluent's `neutralBackground1Pressed` and
/// `neutralBackground3Pressed` steps from white (12% and 16%); by night
/// the well steps darker too, toward black (Fluent lifts its dark hover
/// back to the card's own grey, where the well would vanish).
Color fluent2WellWash(Fluent2ThemeData t, Fluent2Press press) =>
    t.brightness == Brightness.dark
    ? press.pick(
        const Color(0x00000000),
        const Color(0x4D000000),
        const Color(0x80000000),
        const Color(0x00000000),
      )
    : press.pick(
        const Color(0x00000000),
        const Color(0x0B000000),
        const Color(0x17000000),
        const Color(0x00000000),
      );

/// A filled-darker field's fill: by day the well a step lighter (6% ink,
/// Fluent's `neutralBackground4` step from white), so the placeholder in
/// the third ink and the words hold 4.5:1 on it over every preset's tinted
/// page, and it still stands clear of that page (1.13:1 or more, beyond
/// Fluent's own #F5F5F5 on white); by night Fluent's `neutralBackground3`
/// step under a card (half ink), 1.1:1 or more from every ground.
Color fluent2FieldWell(Fluent2ThemeData t) => t.brightness == Brightness.dark
    ? const Color(0x82000000)
    : const Color(0x0F000000);

/// A well out of use, and any disabled face (a button's, a card's, a tab's):
/// by day Fluent's `neutralBackgroundDisabled` step from white (6% ink), by
/// night Fluent's disabled fill, its `neutralBackground3` step under a card
/// (half ink), where its own #141414 stood 1.08:1 on the warm night pages;
/// the part's disabled stroke and ink say the rest.
Color fluent2WellDisabled(Fluent2ThemeData t) => t.brightness == Brightness.dark
    ? const Color(0x82000000)
    : const Color(0x0F000000);

/// Fluent's grey [token] laid over whatever stands under it. By day Fluent
/// draws its greys as steps from white (a disabled fill #F0F0F0, a disabled
/// stroke or a divider #E0E0E0, a selected row #EBEBEB), steps the
/// brand-tinted page all but swallows; laid as the same step of ink (#E0E0E0
/// is 12% black), it is Fluent's grey on a card and the same step darker on
/// the page. By night, and for a colour that is not a grey, the token.
Color fluent2Step(Fluent2ThemeData t, Color token) {
  if (t.brightness == Brightness.dark || token.a < 1) return token;
  final r = (token.r * 255).round();
  final g = (token.g * 255).round();
  final b = (token.b * 255).round();
  if (r != g || g != b) return token;
  return Color.fromARGB(255 - r, 0, 0, 0);
}

/// The brand tint a part lays on the ground (a chosen day and the range
/// round it, a brand tile, a date block, a brand-chosen table row, the
/// empty state's disc, a banner), in its [press] step: Fluent's
/// `brandBackground2`, or its hover shade (and on) where the tint would
/// all but vanish on the brand-tinted page (#EBF3FC stood 1.02:1 on
/// lapis's page by day, and by night on every preset's but iris's), so it
/// stands at least 1.15:1 from the page, unless the brand's second ink
/// would fall under 4.5:1 on the shade (a designer's teal by night: 4.23),
/// where the words outrank the tint.
Color fluent2BrandWell(
  Fluent2ThemeData t, [
  Fluent2Press press = Fluent2Press.rest,
]) {
  final c = t.colors;
  final deep =
      Fluent2ThemeData.contrast(c.brandBackground2, t.background) < 1.15 &&
      Fluent2ThemeData.contrast(c.brandForeground2, c.brandBackground2Hover) >=
          4.5;
  return deep
      ? press.pick(
          c.brandBackground2Hover,
          c.brandBackground2Pressed,
          c.brandBackground2Pressed,
          c.brandBackground2Hover,
        )
      : press.pick(
          c.brandBackground2,
          c.brandBackground2Hover,
          c.brandBackground2Pressed,
          c.brandBackground2,
        );
}

/// The rail a measure runs in (a progress bar's track, a step bar's steps
/// to come, a rating's unfilled stars): Fluent's `neutralBackground6`. By
/// day it is laid over its ground as Fluent's step from white (#E6E6E6 on
/// a card, 10% ink), so the brand-tinted ground never swallows it; by night
/// the token, lighter than every ground.
Color fluent2Rail(Fluent2ThemeData t) => t.brightness == Brightness.dark
    ? t.colors.neutralBackground6
    : const Color(0x1A000000);
