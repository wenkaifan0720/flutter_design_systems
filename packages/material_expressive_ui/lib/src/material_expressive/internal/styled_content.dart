/// Content layout shared by controls with optional visual overrides.
library;

import 'package:flutter/widgets.dart';

import '../states.dart';
import '../theme.dart';

/// Applies a pressable's stateful content slots and reserves its outline inset.
class ExpressiveStyledContent extends StatelessWidget {
  /// Lays out a control's content inside its resolved visual outline.
  const ExpressiveStyledContent({
    required this.child,
    this.minimumSize = Size.zero,
    this.padding = EdgeInsets.zero,
    this.iconSize,
    this.textStyle,
    this.center = true,
    this.keylineSides = false,
    super.key,
  });

  /// The control's label, icon or custom content.
  final Widget child;

  /// The default visual minimum before density.
  final Size minimumSize;

  /// The default padding before density and outline insets.
  final EdgeInsetsGeometry padding;

  /// The default icon size.
  final double? iconSize;

  /// The default content typography.
  final TextStyle? textStyle;

  /// Whether the padded content is centred.
  final bool center;

  /// Whether the side padding is a row's keyline (a labelled control's, a
  /// choice tile's), which density leaves where it is so the row's words
  /// stay in line with its list, section header and page; density then
  /// moves the top and bottom only. A control's own room shrinks with it.
  final bool keylineSides;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final scope = ExpressiveStyleScope.maybeOf(context)!;
    final style = scope.style;
    final states = scope.states;
    final direction = Directionality.of(context);
    final inset = scope.inset.resolve(direction);
    final ownPadding = (style.padding?.resolve(states) ?? padding).resolve(
      direction,
    );
    final space =
        (style.padding?.resolve(states) == null
            ? (keylineSides
                  ? theme.density
                        .padding(ownPadding)
                        .copyWith(
                          left: ownPadding.left,
                          right: ownPadding.right,
                        )
                  : theme.density.padding(ownPadding))
            : ownPadding) +
        inset;
    final minimum = style.minimumSize?.resolve(states);
    final content = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle())
          .merge(style.textStyle?.resolve(states))
          .copyWith(color: style.foregroundColor?.resolve(states)),
      child: IconTheme.merge(
        data: IconThemeData(
          size: style.iconSize?.resolve(states) ?? iconSize,
          color: style.foregroundColor?.resolve(states),
        ),
        child: child,
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth:
            minimum?.width ?? theme.density.width(minimumSize.width, floor: 0),
        minHeight:
            minimum?.height ??
            theme.density.height(minimumSize.height, floor: 0),
      ),
      child: Padding(
        padding: space,
        child: center
            ? Center(widthFactor: 1, heightFactor: 1, child: content)
            : content,
      ),
    );
  }
}
