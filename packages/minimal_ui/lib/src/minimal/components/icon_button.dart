import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/bar_actions.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'button.dart';
import 'pressable.dart';

/// A [MinimalIconButton]'s register: `outline` the bar's bordered square,
/// `ghost` the bare glyph a row or a sheet header carries, `secondary` a
/// quiet filled square, and `primary` the accent square the one primary act
/// wears, as a primary [MinimalButton] does — the bar's `+`.
enum MinimalIconButtonVariant {
  /// The bar's bordered square.
  outline,

  /// The bare glyph.
  ghost,

  /// A square button with a neutral fill.
  secondary,

  /// The accent square of the one primary act, as a primary button's face.
  primary,
}

/// Minimal's square icon control: a 32 px square (28 or 40 by [size])
/// holding an 18 px Lucide glyph — the top bar's actions, a row's overflow,
/// a sheet's close. The hit area pads out to 44.
///
/// The default [variant] is ghost, or outline in a [MinimalAppBar].
/// Supply a [label] so screen readers announce the button's action.
///
/// [selected] makes it an on/off control (a favourite star, a pin): on is
/// said in ink, as every Minimal choice is (the glyph goes from the muted
/// ink to the full one in every register, and a square's hairline turns to
/// the ink), and a screen reader hears a button, selected when on, as
/// Flutter's `IconButton(isSelected:)` says it; null is a plain action, its
/// glyph in the ink.
///
/// [style] dresses one, `components.iconButton` every one: fill,
/// foreground, edge or side, overlay, shape (else `shapes.small`),
/// minimumSize (the square's side) and iconSize, resolved with
/// [WidgetState.selected] when on. `density` moves the square's side;
/// `t.rim` is the outline's rim.
///
/// ```dart
/// MinimalAppBar(title: 'Today', actions: [MinimalIconButton(LucideIcons.search, label: 'Search', onPressed: search)])
/// ```
class MinimalIconButton extends StatelessWidget {
  /// A button showing [icon], called [label].
  const MinimalIconButton(
    this.icon, {
    super.key,
    this.onPressed,
    this.variant,
    this.label,
    this.size = MinimalButtonSize.medium,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Its glyph.
  final IconData icon;

  /// What the control does, in words: announced, never printed.
  final String? label;

  /// Its press; null disables it.
  final VoidCallback? onPressed;

  /// The register; null derives it: `outline` in a top bar's actions,
  /// `ghost` anywhere else.
  final MinimalIconButtonVariant? variant;

  /// Its square, as a [MinimalButton]'s height: 28 ([MinimalButtonSize.small],
  /// for a dense row or a pill), 32 (the default) or 40.
  final MinimalButtonSize size;

  /// Whether an on/off control is on; null for a plain action.
  final bool? selected;

  /// This control's style, over `components.iconButton`.
  final MinimalStyle? style;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final variant =
        this.variant ??
        (MinimalBarActions.contains(context)
            ? MinimalIconButtonVariant.outline
            : MinimalIconButtonVariant.ghost);
    final on = selected ?? false;
    // Off, a toggle's glyph is muted in any register (the rest stay muted);
    // a plain action's glyph is the ink.
    final glyphInk = selected == false ? t.mutedForeground : t.foreground;
    final (tone, toneInk, border) = switch (variant) {
      // On is said in ink: the glyph goes from the muted ink to the full
      // one, and a bordered square's hairline turns to the ink. No tint.
      MinimalIconButtonVariant.outline => (
        t.background,
        glyphInk,
        on ? t.foreground : t.border,
      ),
      MinimalIconButtonVariant.ghost => (
        null,
        on ? t.foreground : t.mutedForeground,
        null,
      ),
      MinimalIconButtonVariant.secondary => (
        t.muted,
        glyphInk,
        on ? t.foreground : null,
      ),
      // The act to take wears the accent, as a primary button does; on,
      // it keeps it (it is already the loudest register).
      MinimalIconButtonVariant.primary => (
        t.primary,
        t.primaryForeground,
        null,
      ),
    };
    // Out of use, a filled square takes the muted fill and the ink, as a
    // button out of use does, and fades as one.
    final out = onPressed == null;
    final bg = out && tone != null ? t.muted : tone;
    final fg = out ? t.foreground : toneInk;
    final square = t.density.height(switch (size) {
      MinimalButtonSize.small => MinimalChromeMetrics.controlSm,
      MinimalButtonSize.medium => MinimalChromeMetrics.barControl,
      MinimalButtonSize.large => MinimalChromeMetrics.controlLg,
    });
    final layers = <MinimalStyle?>[style, t.components.iconButton];
    final rest = MinimalStyleOf(layers, const {});
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      // A control with no action is disabled.
      enabled: onPressed != null,
      semanticLabel: label,
      selected: selected,
      style: rest.press,
      shape: t.shapes.small,
      face: rest.fill ?? bg,
      ink: rest.foreground ?? fg,
      builder: (context, states) {
        final so = MinimalStyleOf(layers, states);
        final least = so.minimumSize;
        // The face lerps to each state: on, off, a style's own states.
        return MinimalFace(
          width: least?.width ?? square,
          height: least?.height ?? square,
          decoration: minimalFrame(
            so.shape ?? t.shapes.small,
            fill: so.fill ?? bg ?? const Color(0x00000000),
            side: so.rim(border, t.rim),
          ),
          ink: so.foreground ?? fg,
          builder: (context, ink) => MinimalIcon(
            icon,
            size:
                so.iconSize ??
                switch (size) {
                  MinimalButtonSize.small => MinimalIconSize.i16,
                  MinimalButtonSize.medium => MinimalIconSize.i18,
                  MinimalButtonSize.large => MinimalIconSize.i20,
                },
            color: ink ?? fg,
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IconDataProperty('icon', icon))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        EnumProperty<MinimalIconButtonVariant>(
          'variant',
          variant,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<MinimalButtonSize>(
          'size',
          size,
          defaultValue: MinimalButtonSize.medium,
        ),
      )
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}
