/// Brutal's blocks: [BrutalBlock], a square panel in the rule (the card),
/// flat at rest and raised on its hard shadow when it can be pressed or
/// leads its screen; and [BrutalTag], a small square label.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/focus_ink.dart';
import 'surface.dart';
import 'theme.dart';

/// A square panel in the look's rule: the card.
///
/// It is flat (no shadow) unless it can be pressed ([onTap]) or [lead] is
/// set: one block per screen may lead, the screen's one colour block,
/// raised on the hard shadow. A pressed block slides into its shadow like a
/// button.
///
/// [color] fills it with one of the flat colours
/// ([BrutalColors.signal], [BrutalColors.lime], [BrutalColors.blue],
/// [BrutalColors.pink], [BrutalColors.violet]); the words on it are the
/// ones [BrutalColors.onColor] gives (black on the blocks whatever the mode,
/// black or white by contrast on a colour of the app's own). Use one per
/// screen and make it large.
///
/// Reads [style]'s `fill` (under [color]), `foreground`, `edge` and
/// `padding` (under [padding]), then [BrutalThemeData.blockStyle]'s.
///
/// The block marks itself a keyline region, so what it holds starts on one
/// line.
///
/// ```dart
/// BrutalBlock(lead: true, color: context.brutalTheme.colors.lime, onTap: () {}, child: const Text('Tonight: Low Tide, Hall 4'))
/// ```
class BrutalBlock extends StatelessWidget {
  /// A block holding [child].
  const BrutalBlock({
    super.key,
    required this.child,
    this.onTap,
    this.lead = false,
    this.color,
    this.padding,
    this.semanticLabel,
    this.label,
    this.style,
  });

  /// What it holds.
  final Widget child;

  /// Called when the block is pressed; null: it is not a button.
  final VoidCallback? onTap;

  /// Whether it is the screen's lead block, raised on the hard shadow.
  final bool lead;

  /// A flat colour to fill it; the surface when null.
  final Color? color;

  /// The room inside the rule; 16 all round when neither this nor a style
  /// says.
  final EdgeInsetsGeometry? padding;

  /// What a screen reader calls it when it is a button.
  final String? semanticLabel;

  /// What the keyline check calls it.
  final String? label;

  /// Its style, over [BrutalThemeData.blockStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final raised = lead || onTap != null;
    BrutalFace face(DesignStyleOf layered, Set<WidgetState> states) {
      final fill = color ?? layered.fill ?? c.surface;
      return BrutalFace(
        fill: fill,
        border: layered.side?.color ?? layered.edge ?? c.ink,
        foreground:
            layered.foreground ?? (fill == c.surface ? c.ink : c.onColor(fill)),
        shadow: raised ? c.ink : c.ink.withValues(alpha: 0),
        travel: states.contains(WidgetState.pressed) ? 1 : 0,
        focus: states.contains(WidgetState.focused)
            ? brutalFocusInk(c, c.ink)
            : c.ink.withValues(alpha: 0),
      );
    }

    Widget inside(DesignStyleOf layered) => DesignKeylineRegion(
      label: label ?? 'Block',
      child: Padding(
        padding:
            padding ??
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(BrutalSpacing.regular),
        child: child,
      ),
    );
    final layers = [style, theme.blockStyle];
    if (onTap == null) {
      final layered = DesignStyleOf(layers, const {});
      return BrutalSurface(
        face: face(layered, const {}),
        child: inside(layered),
      );
    }
    return DesignPressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      // Named, it is read by its name alone, not its name and then its words.
      excludeSemantics: semanticLabel != null,
      builder: (context, states, _) {
        final layered = DesignStyleOf(layers, states);
        return AnimatedBrutalSurface(
          face: face(layered, states),
          child: inside(layered),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('lead', value: lead, ifTrue: 'lead'))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(
        FlagProperty('pressable', value: onTap != null, ifTrue: 'pressable'),
      );
  }
}

/// How a [BrutalTag] reads.
enum BrutalTagTone {
  /// Ink on the surface, in the rule.
  plain,

  /// Paper on ink.
  strong,

  /// Black on the signal colour.
  signal,

  /// White on the danger colour (black in dark mode).
  danger,
}

/// A small square label: a status, a count, a kind. Caption type, in the
/// rule, never pressed.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding` and `textStyle`,
/// then [BrutalThemeData.tagStyle]'s.
///
/// ```dart
/// const BrutalTag('Sold out', tone: BrutalTagTone.strong)
/// ```
class BrutalTag extends StatelessWidget {
  /// A tag reading [text].
  const BrutalTag(
    this.text, {
    super.key,
    this.tone = BrutalTagTone.plain,
    this.style,
  });

  /// The words; shown in capitals.
  final String text;

  /// How it reads.
  final BrutalTagTone tone;

  /// Its style, over [BrutalThemeData.tagStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final (fill, words) = switch (tone) {
      BrutalTagTone.plain => (c.surface, c.ink),
      BrutalTagTone.strong => (c.ink, c.paper),
      BrutalTagTone.signal => (c.signal, c.onSignal),
      BrutalTagTone.danger => (c.danger, c.onDanger),
    };
    final layered = DesignStyleOf([style, theme.tagStyle], const {});
    final face = layered.on(
      BrutalFace(fill: fill, border: c.ink, foreground: words),
    );
    return BrutalSurface(
      face: face,
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.symmetric(
              horizontal: BrutalSpacing.small,
              vertical: BrutalSpacing.tight,
            ),
        child: DesignCapCenter(
          capHeightFactor: BrutalTheme.of(context).capHeightFactor,
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            style: layered.text(
              theme.textTheme.caption.copyWith(color: face.foreground),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(EnumProperty<BrutalTagTone>('tone', tone));
  }
}
