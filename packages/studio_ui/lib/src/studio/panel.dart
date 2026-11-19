/// Studio's two containers: [StudioPanel], a module of brushed metal set in
/// the chassis (chrome), and [StudioDisplay], a recessed pane of glass that
/// content is read on.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

/// A panel: a module of brushed anodised metal, flush with the chassis, its
/// top edge catching the light. Controls and legends stand on it; what
/// people read goes on a [StudioDisplay] set into it.
///
/// Reads [style]'s `fill`, `foreground` and `padding`, then
/// [StudioThemeData.panelStyle].
///
/// ```dart
/// StudioPanel(child: Row(children: [StudioButton('Mark', onPressed: mark)]))
/// ```
class StudioPanel extends StatelessWidget {
  /// A panel round [child].
  const StudioPanel({super.key, required this.child, this.padding, this.style});

  /// What stands on it.
  final Widget child;

  /// Round [child]; 16 on every side when null.
  final EdgeInsetsGeometry? padding;

  /// Its style, over [StudioThemeData.panelStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final layered = DesignStyleOf([style, theme.panelStyle], const {});
    return StudioSurface(
      face: layered.on(theme.colors.panelFace),
      child: Padding(
        padding:
            padding ??
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(StudioSpacing.regular),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: layered.foreground ?? theme.colors.legend),
          child: child,
        ),
      ),
    );
  }
}

/// A display: a pane of glass set into the metal, shadow falling inside it
/// from its top edge. Content is read on it: an episode, a list, notes. Pale
/// by day and dark by night; [readout] makes it a readout window's glass,
/// lit amber from behind by day and dark by night.
///
/// With [onTap] it is pressable as a whole (a card): a press lights its rim,
/// the keyboard focuses it with a ring outside it.
///
/// Reads [style]'s `fill`, `foreground`, `edge` (the rim) and `padding`,
/// then [StudioThemeData.displayStyle].
///
/// ```dart
/// StudioDisplay(child: Text(episode.notes))
/// ```
class StudioDisplay extends StatelessWidget {
  /// A pane round [child].
  const StudioDisplay({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.readout = false,
    this.semanticLabel,
    this.style,
  });

  /// What is read on it.
  final Widget child;

  /// Round [child]; 16 all round when null. A pane of rows passes its own
  /// (the rows bring their padding).
  final EdgeInsetsGeometry? padding;

  /// What a press does, when it is a card.
  final VoidCallback? onTap;

  /// Whether it is a readout window's glass: lit from behind by day, dark by
  /// night.
  final bool readout;

  /// What a screen reader calls it when it is pressable.
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.displayStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    StudioFace faceIn(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.displayStyle], states);
      final base = readout
          ? c.readoutFace.copyWith(
              radius: StudioRadii.display,
              foreground: c.onReadout,
            )
          : c.displayFace;
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);
      return layered
          .on(base)
          .copyWith(
            rim: c.indicator.withValues(
              alpha: pressed
                  ? 0.85
                  : hovered
                  ? 0.35
                  : 0,
            ),
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          );
    }

    Widget content(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.displayStyle], states);
      final face = faceIn(states);
      final body = Padding(
        padding:
            padding ??
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(StudioSpacing.regular),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: face.foreground),
          child: child,
        ),
      );
      return onTap == null
          ? StudioSurface(face: face, child: body)
          : AnimatedStudioSurface(
              face: face,
              stiffness: StudioMotion.lampStiffness,
              child: body,
            );
    }

    if (onTap == null) return content(const {});
    return DesignPressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      // Named, it is read by its name alone, not its name and then its words.
      excludeSemantics: semanticLabel != null,
      builder: (context, states, _) => content(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('readout', value: readout, ifTrue: 'readout'))
      ..add(
        FlagProperty('pressable', value: onTap != null, ifTrue: 'pressable'),
      );
  }
}
