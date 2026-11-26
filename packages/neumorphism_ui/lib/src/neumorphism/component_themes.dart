// A part's style: ui_core's RawStyle under the look's name.
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart' show RawStyle, RawStyleOf;

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves for the part's states
/// ([WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `NeumorphicThemeData`, then
/// from the look's own default. A slot that is null, or resolves to null for the states at hand, falls through to the
/// next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the look's width: off the look's rule (relief is the only edge), as the fine outline is what high contrast draws, so keep it for a high-contrast rim of your own |
/// | [overlay] | a wash over the face for the states you name; the look draws none (hover changes nothing, a press sinks) |
/// | [side] | the whole rim, colour and width; it wins over [edge], and is off the look's rule as [edge] is |
/// | [shape] | the outline, one of Neumorphism's own: a rounded border at least `NeumorphicRadii.least` round, a stadium or a circle (a debug build asserts it: a moulded surface has no sharp corner) |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays at the touch floor on every platform |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads. Its shape animates when a state changes it, as a Material 3 button's
/// does. It is ui_core's [RawStyle] under the look's name, so every look's parts take the same style, read the
/// same way; [RawStyle.layered] forwards a part's style and its theme to a part inside it.
///
/// ```dart
/// NeumorphicChip(
///   'Jazz',
///   onPressed: () {},
///   style: NeumorphicStyle(
///     shape: WidgetStateProperty.resolveWith(
///       (states) => states.contains(WidgetState.pressed)
///           ? const NeumorphicStadiumBorder()
///           : const NeumorphicRoundedBorder(radius: 12),
///     ),
///     padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
///   ),
/// )
/// ```
typedef NeumorphicStyle = RawStyle;
