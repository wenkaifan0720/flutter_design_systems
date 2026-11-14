/// Cards: elevated, filled and outlined (CONTRACT §4.1 `card`). Owner:
/// w3-cards.
///
/// A port of Compose's `Card.kt`: a card is a `Surface` (here
/// [ExpressiveSurface]) holding its content, in the variant's container
/// colour, shape (`corner.medium`), shadow elevation and — outlined — its
/// 1dp `outlineVariant` stroke, every value from the generated
/// `ElevatedCardTokens` / `FilledCardTokens` / `OutlinedCardTokens`. A card
/// with [ExpressiveCard.onPressed] is Compose's clickable card: the shared
/// [ExpressivePressable] draws its state layers and ripple in the content
/// colour and springs its elevation by interaction (`CardElevation`), and a
/// disabled one takes the variant's disabled colours.
///
/// CONTRACT §3 bans containment deeper than 2 and a card around one row, a
/// list section or one field. In debug a card asserts both where it can see
/// them: a third nested card, and a card whose child is itself one list row,
/// list section or field.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../color.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/elevated_card_tokens.g.dart';
import '../internal/tokens/filled_card_tokens.g.dart';
import '../internal/tokens/outlined_card_tokens.g.dart';
import '../motion.dart';
import '../states.dart';
import '../theme.dart';

/// A card's three styles (Compose's `ElevatedCard`, `Card`, `OutlinedCard`).
enum ExpressiveCardVariant {
  /// `surfaceContainerLow`, casting a level-1 shadow: separation from a busy
  /// or patterned background.
  elevated,

  /// `surfaceContainerHighest`, flat: the default card (Compose's `Card`).
  filled,

  /// `surface` with a 1dp `outlineVariant` stroke: the quietest card.
  outlined,
}

/// A card's colours (Compose's `CardColors`, plus the outlined card's
/// stroke from `CardDefaults.outlinedCardBorder`).
@immutable
class ExpressiveCardColors {
  /// A card's colours for its container, content and outline, enabled and disabled.
  const ExpressiveCardColors({
    required this.container,
    required this.content,
    required this.disabledContainer,
    required this.disabledContent,
    this.outline,
    this.disabledOutline,
  });

  /// The variant's colours in [colors] (`CardDefaults.*CardColors()` and
  /// `CardDefaults.outlinedCardBorder`).
  factory ExpressiveCardColors.of(
    ExpressiveCardVariant variant,
    ExpressiveColorScheme colors,
  ) {
    Color contentOn(Color container) =>
        colors.contentColorFor(container) ?? colors.onSurface;
    Color dim(Color content) =>
        content.withValues(alpha: CardBehavior.disabledContentAlpha);
    switch (variant) {
      case ExpressiveCardVariant.elevated:
        final container = colors.role(ElevatedCardTokens.containerColor);
        final disabled = colors.role(ElevatedCardTokens.disabledContainerColor);
        return ExpressiveCardColors(
          container: container,
          content: contentOn(container),
          disabledContainer: Color.alphaBlend(
            disabled.withValues(
              alpha: ElevatedCardTokens.disabledContainerOpacity,
            ),
            disabled,
          ),
          disabledContent: dim(contentOn(container)),
        );
      case ExpressiveCardVariant.filled:
        final container = colors.role(FilledCardTokens.containerColor);
        return ExpressiveCardColors(
          container: container,
          content: contentOn(container),
          disabledContainer: Color.alphaBlend(
            colors
                .role(FilledCardTokens.disabledContainerColor)
                .withValues(alpha: FilledCardTokens.disabledContainerOpacity),
            container,
          ),
          disabledContent: dim(contentOn(container)),
        );
      case ExpressiveCardVariant.outlined:
        final container = colors.role(OutlinedCardTokens.containerColor);
        return ExpressiveCardColors(
          container: container,
          content: contentOn(container),
          disabledContainer: container,
          disabledContent: dim(contentOn(container)),
          outline: colors.role(OutlinedCardTokens.outlineColor),
          disabledOutline: Color.alphaBlend(
            colors
                .role(OutlinedCardTokens.disabledOutlineColor)
                .withValues(alpha: OutlinedCardTokens.disabledOutlineOpacity),
            colors.role(ElevatedCardTokens.containerColor),
          ),
        );
    }
  }

  /// The container colour.
  final Color container;

  /// The content colour: text and icons inherit it.
  final Color content;

  /// The container colour of a disabled clickable card.
  final Color disabledContainer;

  /// The content colour of a disabled clickable card.
  final Color disabledContent;

  /// The outline stroke's colour (outlined only).
  final Color? outline;

  /// The outline stroke's colour when disabled (outlined only).
  final Color? disabledOutline;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCardColors &&
      other.container == container &&
      other.content == content &&
      other.disabledContainer == disabledContainer &&
      other.disabledContent == disabledContent &&
      other.outline == outline &&
      other.disabledOutline == disabledOutline;

  @override
  int get hashCode => Object.hash(
    container,
    content,
    disabledContainer,
    disabledContent,
    outline,
    disabledOutline,
  );
}

/// A variant's shadow elevation by interaction (Compose's
/// `CardDefaults.cardElevation`, `elevatedCardElevation`,
/// `outlinedCardElevation`: the outlined card keeps its rest level while
/// pressed, focused and hovered).
ExpressiveStateElevation expressiveCardElevation(
  ExpressiveCardVariant variant,
) => switch (variant) {
  ExpressiveCardVariant.elevated => const ExpressiveStateElevation(
    rest: ElevatedCardTokens.containerElevation,
    pressed: ElevatedCardTokens.pressedContainerElevation,
    focused: ElevatedCardTokens.focusContainerElevation,
    hovered: ElevatedCardTokens.hoverContainerElevation,
    dragged: ElevatedCardTokens.draggedContainerElevation,
    disabled: ElevatedCardTokens.disabledContainerElevation,
  ),
  ExpressiveCardVariant.filled => const ExpressiveStateElevation(
    rest: FilledCardTokens.containerElevation,
    pressed: FilledCardTokens.pressedContainerElevation,
    focused: FilledCardTokens.focusContainerElevation,
    hovered: FilledCardTokens.hoverContainerElevation,
    dragged: FilledCardTokens.draggedContainerElevation,
    disabled: FilledCardTokens.disabledContainerElevation,
  ),
  ExpressiveCardVariant.outlined => const ExpressiveStateElevation(
    rest: OutlinedCardTokens.containerElevation,
    pressed: OutlinedCardTokens.containerElevation,
    focused: OutlinedCardTokens.containerElevation,
    hovered: OutlinedCardTokens.containerElevation,
    dragged: OutlinedCardTokens.draggedContainerElevation,
    disabled: OutlinedCardTokens.disabledContainerElevation,
  ),
};

/// A card: related content and actions about one subject, on a contained
/// surface in one of three styles ([variant]; filled by default, as
/// Compose's `Card`). A card adds no padding of its own (Compose's card is
/// a bare `Column`): pass [padding], or lay the content out yourself —
/// media edge to edge, then text inset by the spacing scale's 16dp.
///
/// With [onPressed] (or [onLongPress]) the whole card is one button: state
/// layers, the ripple, focus and its elevation by interaction; without
/// them it is a plain surface. Keep actions inside a clickable card to a
/// minimum: it is already one tap target.
///
/// Never wrap one list row, one list section or one field in a card, and
/// never nest cards more than two deep (CONTRACT §3).
///
/// ```dart
/// ExpressiveCard.elevated(onPressed: open, padding: EdgeInsets.all(ExpressiveSpacing.s16), child: Text('Ridge trail'))
/// ```
class ExpressiveCard extends StatelessWidget {
  /// A card around [child] in the given [variant].
  const ExpressiveCard({
    required this.child,
    this.style,
    this.variant = ExpressiveCardVariant.filled,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.semanticLabel,
    this.dragged = false,
    this.focusNode,
    super.key,
  });

  /// Compose's `ElevatedCard`.
  const ExpressiveCard.elevated({
    required this.child,
    this.style,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.semanticLabel,
    this.dragged = false,
    this.focusNode,
    super.key,
  }) : variant = ExpressiveCardVariant.elevated;

  /// Compose's `Card`.
  const ExpressiveCard.filled({
    required this.child,
    this.style,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.semanticLabel,
    this.dragged = false,
    this.focusNode,
    super.key,
  }) : variant = ExpressiveCardVariant.filled;

  /// Compose's `OutlinedCard`.
  const ExpressiveCard.outlined({
    required this.child,
    this.style,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.semanticLabel,
    this.dragged = false,
    this.focusNode,
    super.key,
  }) : variant = ExpressiveCardVariant.outlined;

  /// Stateful visual overrides before the card theme and global knobs.
  final ExpressiveComponentThemeData? style;

  /// The card's content.
  final Widget child;

  /// The card's style.
  final ExpressiveCardVariant variant;

  /// What a tap on the card does; the card is not clickable when this and
  /// [onLongPress] are null.
  final VoidCallback? onPressed;

  /// What a long press on the card does.
  final VoidCallback? onLongPress;

  /// Whether it takes input: false when onPressed is null, as in Flutter.
  bool get enabled => clickable;

  /// Padding around [child]; none when null (Compose's card).
  final EdgeInsetsGeometry? padding;

  /// What a screen reader says for the card, over its content's own text.
  final String? semanticLabel;

  /// Whether the card is being dragged (a reorderable grid): the dragged
  /// elevation and state layer.
  final bool dragged;

  /// A clickable card's focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether the card is clickable.
  bool get clickable => onPressed != null || onLongPress != null;

  @override
  Widget build(BuildContext context) {
    assert(_debugCheckContainment(context));
    final theme = context.expressiveTheme;
    final colors = ExpressiveCardColors.of(variant, theme.colors);
    final shape = theme.shapes.of(switch (variant) {
      ExpressiveCardVariant.elevated => ElevatedCardTokens.containerShape,
      ExpressiveCardVariant.filled => FilledCardTokens.containerShape,
      ExpressiveCardVariant.outlined => OutlinedCardTokens.containerShape,
    });
    final active = !clickable || enabled;
    final outline = active ? colors.outline : colors.disabledOutline;
    final side = outline == null
        ? BorderSide.none
        : BorderSide(color: outline, width: OutlinedCardTokens.outlineWidth);
    final elevation = expressiveCardElevation(variant);
    final resolved = theme.cardTheme.merge(style);
    final restingStates = expressiveComponentStates(enabled: active);
    final customShape = resolved.shape?.resolve(restingStates);
    final shownShape = customShape ?? shape;
    final styledOutline = resolved.outline?.resolve(restingStates);
    final shownSide =
        resolved.side?.resolve(restingStates) ??
        side.copyWith(
          color: styledOutline,
          style: styledOutline == null ? null : BorderStyle.solid,
        );
    final Widget content = _CardDepth(
      depth: _CardDepth.of(context) + 1,
      child: _StyledCardContent(
        fallback: resolved,
        states: restingStates,
        inherit: clickable,
        inset:
            customShape != null ||
                resolved.side?.resolve(restingStates) != null ||
                styledOutline != null
            ? shownShape.copyWith(side: shownSide).dimensions
            : EdgeInsets.zero,
        padding: padding,
        child: child,
      ),
    );

    // One keyline region per card: its title, rows and fields share its
    // keylines (ui_core's keyline check reads it; it paints nothing).
    if (!clickable) {
      // Compose's non-clickable card: its rest elevation, no interactions.
      return DesignKeylineRegion(
        label: semanticLabel ?? 'card',
        child: Semantics(
          container: true,
          label: semanticLabel,
          child: ExpressiveSurface(
            shape: shownShape,
            color: Color.alphaBlend(
              resolved.overlayColor?.resolve(restingStates) ??
                  expressiveTransparent,
              resolved.backgroundColor?.resolve(restingStates) ??
                  colors.container,
            ),
            contentColor:
                resolved.foregroundColor?.resolve(restingStates) ??
                colors.content,
            side: shownSide,
            shadowElevation: elevation.rest,
            child: content,
          ),
        ),
      );
    }
    return DesignKeylineRegion(
      label: semanticLabel ?? 'card',
      child: ExpressivePressable(
        style: style,
        componentStyle: theme.cardTheme,
        shapes: ExpressivePressShapes.all(shape),
        // A card never morphs its shape; the key only names the spring.
        motion: ExpressiveMotionKey.defaultSpatial,
        color: enabled ? colors.container : colors.disabledContainer,
        contentColor: enabled ? colors.content : colors.disabledContent,
        side: side,
        elevation: elevation,
        dragged: dragged,
        onPressed: enabled ? onPressed : null,
        onLongPress: enabled ? onLongPress : null,
        semanticLabel: semanticLabel,
        focusNode: focusNode,
        child: content,
      ),
    );
  }

  /// CONTRACT §3 in debug: a third nested card, or a card around one row,
  /// section or field, is a defect.
  bool _debugCheckContainment(BuildContext context) {
    final depth = _CardDepth.of(context) + 1;
    if (depth > _CardDepth.maxDepth) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('ExpressiveCard is nested $depth deep.'),
        ErrorDescription(
          'Containment deeper than 2 is banned (CONTRACT §3): a card may '
          'hold a card, never a card holding a card.',
        ),
        ErrorHint('Flatten the inner cards into rows, sections or media.'),
      ]);
    }
    final name = child.runtimeType.toString();
    if (_CardDepth.bannedChildren.any(name.startsWith)) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('ExpressiveCard holds a single $name.'),
        ErrorDescription(
          'A card around one row, a list section or one field is banned '
          '(CONTRACT §3): the row, section or field is already a container.',
        ),
        ErrorHint(
          'Drop the card, or give it a subject: media, text and actions.',
        ),
      ]);
    }
    return true;
  }
}

/// How many cards enclose a subtree.
class _CardDepth extends InheritedWidget {
  const _CardDepth({required this.depth, required super.child});

  /// The deepest nesting CONTRACT §3 allows.
  static const int maxDepth = 2;

  /// The components a card must never wrap alone, by class name (the
  /// families that build them are not this family's dependencies).
  static const List<String> bannedChildren = <String>[
    'ExpressiveListRow',
    'ExpressiveListTile',
    'ExpressiveListSection',
    'ExpressiveTextField',
    'ExpressiveTextArea',
    'ExpressiveInputOtp',
    'ExpressiveSelect',
    'ExpressiveCombobox',
  ];

  final int depth;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CardDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_CardDepth oldWidget) => depth != oldWidget.depth;
}

class _StyledCardContent extends StatelessWidget {
  const _StyledCardContent({
    required this.fallback,
    required this.states,
    required this.inherit,
    required this.inset,
    required this.padding,
    required this.child,
  });
  final ExpressiveComponentThemeData fallback;
  final bool inherit;
  final Set<WidgetState> states;
  final EdgeInsetsGeometry inset;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = inherit ? ExpressiveStyleScope.maybeOf(context) : null;
    final style = scope?.style ?? fallback;
    final active = scope?.states ?? states;
    final minimum = style.minimumSize?.resolve(active);
    final contentPadding =
        (style.padding?.resolve(active) ?? padding ?? EdgeInsets.zero).add(
          scope?.inset ?? inset,
        );
    Widget content = Padding(padding: contentPadding, child: child);
    final textStyle = style.textStyle?.resolve(active);
    if (textStyle != null) {
      content = DefaultTextStyle.merge(style: textStyle, child: content);
    }
    final iconSize = style.iconSize?.resolve(active);
    if (iconSize != null) {
      content = IconTheme.merge(
        data: IconThemeData(size: iconSize),
        child: content,
      );
    }
    if (minimum != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimum.width,
          minHeight: minimum.height,
        ),
        child: content,
      );
    }
    return content;
  }
}
