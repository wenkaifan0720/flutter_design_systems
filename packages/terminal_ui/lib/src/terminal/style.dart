/// A part's style: ui_core's [DesignStyle], under Terminal's name, and the
/// reading of it that keeps the grid.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How one Terminal part looks in each of its states, as Material's
/// `ButtonStyle` is: ui_core's [DesignStyle] under Terminal's name.
///
/// Every part takes one as `style:`, over its slot in [TermThemeData] (as
/// Material's buttons sit over their `ButtonTheme`): the part's own wins,
/// state by state, then the theme's, then the look's.
///
/// Terminal reads four slots, the ones that cannot break it:
/// [DesignStyle.fill] (an inverse fill, a ground), [DesignStyle.foreground]
/// (the words), [DesignStyle.edge] (a box line, a bracket) and
/// [DesignStyle.textStyle], of which only the colour and the weight count:
/// a size, a line height, spacing or a face would take the words off the
/// cell grid. Shape, side, padding, minimum size and icon size are not
/// read: every part is whole cells, in brackets or box lines. Each part's
/// documentation says which slots it reads.
///
/// ```dart
/// final style = TermStyle(
///   foreground: WidgetStateProperty.resolveWith(
///     (states) => states.contains(WidgetState.disabled)
///         ? const Color(0xFF626A76)
///         : const Color(0xFFE3C46F),
///   ),
/// );
/// ```
typedef TermStyle = DesignStyle;

/// [layers] read at [states] the way Terminal reads them: the first layer
/// with a value wins, slot by slot, and a text style keeps only its colour
/// and weight.
///
/// ```dart
/// final own = TermStyleOf([style, theme.buttonStyle], states);
/// final ink = own.foreground ?? theme.foreground;
/// ```
@immutable
class TermStyleOf {
  /// [layers], first wins, at [states].
  TermStyleOf(List<TermStyle?> layers, Set<WidgetState> states)
    : _of = DesignStyleOf(layers, states);

  final DesignStyleOf _of;

  /// An inverse fill or a ground.
  Color? get fill => _of.fill;

  /// The words.
  Color? get foreground => _of.foreground;

  /// A box line or a bracket.
  Color? get edge => _of.edge;

  /// The words' colour and weight; nothing else is read.
  TextStyle? get textStyle {
    final t = _of.textStyle;
    if (t == null) return null;
    assert(
      t.fontSize == null &&
          t.height == null &&
          t.letterSpacing == null &&
          t.wordSpacing == null &&
          t.fontFamily == null,
      "A Terminal part's textStyle sets colour and weight only: a size, a "
      'line height, spacing or a face takes the words off the cell grid '
      '(set the face and the cell in TermThemeData instead).',
    );
    return TextStyle(color: t.color, fontWeight: t.fontWeight);
  }
}
