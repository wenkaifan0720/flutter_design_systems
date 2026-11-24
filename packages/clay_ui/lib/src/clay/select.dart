/// Clay's select: a white clay key showing the choice, a chevron at its end,
/// opening a floating list of the choices under it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/entry_parts.dart' show ClayFieldDecorator;
import 'internal/menu.dart';
import 'surface.dart';
import 'theme.dart';

/// One choice of a [ClaySelect].
@immutable
class ClaySelectItem<T> {
  /// The choice [value], reading [label].
  const ClaySelectItem({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
  });

  /// The value it stands for.
  final T value;

  /// Its words.
  final String label;

  /// A glyph before its words in the list.
  final Widget? leading;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A Clay select: a white clay key showing the choice with a chevron at its
/// end. A press sinks the key and floats the choices under it (above it
/// when the room is there), as wide as the key; the chosen one stands in
/// the accent's ink with a check, in view from the first frame.
///
/// One row is current at a time: the pointer's while it moves, the keys'
/// once a key is pressed; a list the pointer opened lights none. Up and
/// Down move, Enter chooses, Escape closes and gives focus back.
///
/// ```dart
/// ClaySelect<String>(labelText: 'Repeat', value: 'daily', items: const [ClaySelectItem(value: 'daily', label: 'Every day'), ClaySelectItem(value: 'weekdays', label: 'Weekdays')], onChanged: (value) {})
/// ```
class ClaySelect<T> extends StatelessWidget {
  /// A select over [items], [value] chosen.
  const ClaySelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.style,
  });

  /// The choices.
  final List<ClaySelectItem<T>> items;

  /// The chosen value; [hintText] shows when null.
  final T? value;

  /// Called with the value chosen; null turns it off.
  final ValueChanged<T>? onChanged;

  /// The label above the key.
  final String? labelText;

  /// What the key says while nothing is chosen.
  final String? hintText;

  /// Help under the key.
  final String? helperText;

  /// What is wrong, under the key in the danger ink.
  final String? errorText;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// This select's own style, over [ClayThemeData.selectStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final chosen = items.where((i) => i.value == value).firstOrNull;
    // Where the options have glyphs, the key keeps their place before its
    // words even with none chosen, so its words stand over the list's.
    final glyphs = items.any((i) => i.leading != null);
    final height = theme.controlHeight;
    Widget anchorKey(VoidCallback? toggle, bool open) => RawButton(
      onPressed: toggle,
      focusNode: focusNode,
      expanded: enabled ? open : null,
      semanticLabel: labelText,
      semanticValue: chosen?.label,
      builder: (context, states, _) {
        final layered = RawStyleOf(
          [style, theme.selectStyle],
          {...states, if (errorText != null) WidgetState.error},
        );
        final radius = clayRadiusOf(layered.shape, ClayRadius.control);
        final fill = layered.fill ?? c.clay;
        var face = enabled
            ? ClayFace.raised(c, color: fill, radius: radius)
            : ClayFace.flat(c, color: fill, radius: radius);
        face = face.copyWith(
          press: states.contains(WidgetState.pressed) || open ? 1 : 0,
          lift: states.contains(WidgetState.hovered) ? 0.6 : 0,
          focus: states.contains(WidgetState.focused) || errorText != null
              ? 1
              : 0,
          focusColor: errorText != null ? c.danger : null,
        );
        final ink = !enabled
            ? c.inkDisabled
            : chosen == null
            ? c.inkSecondary
            : (layered.foreground ?? c.ink);
        return SizedBox(
          height: height,
          child: AnimatedClaySurface(
            face: face,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ClaySpacing.regular,
                end: ClaySpacing.medium,
              ),
              child: Row(
                children: [
                  // Where its options carry glyphs, the value keeps the
                  // glyph's place its menu row gives it, so the list's words
                  // open on the field's; before a choice an empty cup holds
                  // the place, never a bare indent.
                  if (glyphs) ...[
                    SizedBox.square(
                      dimension: 20,
                      child: chosen == null
                          ? Center(
                              child: SizedBox.square(
                                dimension: 14,
                                child: ClaySurface(
                                  face: ClayFace.well(c, radius: 7),
                                ),
                              ),
                            )
                          : chosen.leading == null
                          ? null
                          : IconTheme.merge(
                              data: IconThemeData(size: 20, color: ink),
                              child: chosen.leading!,
                            ),
                    ),
                    const SizedBox(width: ClaySpacing.medium),
                  ],
                  Expanded(
                    child: RawCapCenter(
                      capHeightFactor: clayCapHeightFactor,
                      child: Text(
                        chosen?.label ?? hintText ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body
                            .merge(layered.textStyle)
                            .copyWith(color: ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: ClaySpacing.small),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: open ? 1 : 0),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => SizedBox.square(
                      dimension: 20,
                      child: CustomPaint(
                        painter: ClayChevronPainter(
                          enabled ? c.inkSecondary : c.inkDisabled,
                          t,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final box = !enabled
        ? anchorKey(null, false)
        : RawPopover(
            arrowKeyNavigation: true,
            semanticLabel: labelText,
            placement: const RawPopoverPlacement(
              gap: ClaySpacing.small,
              margin: ClaySpacing.small,
            ),
            dampingRatio: ClayMotion.panelDamping,
            stiffness: ClayMotion.panelStiffness,
            anchorBuilder: (context, anchor) =>
                anchorKey(anchor.toggle, anchor.isOpen),
            overlayBuilder: (context, info) => ClayMenuReveal(
              info: info,
              child: ClayMenuList<T>(
                entries: [
                  for (final i in items)
                    ClayMenuEntry(
                      value: i.value,
                      label: i.label,
                      leading: i.leading,
                      enabled: i.enabled,
                    ),
                ],
                chosen: value,
                hasChosen: true,
                rowHeight: height,
                maxHeight: info.maxSize.height,
                onChosen: (v) {
                  info.close();
                  onChanged?.call(v);
                },
              ),
            ),
          );
    return ClayFieldDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: enabled,
      focusNode: focusNode,
      child: box,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// How a floating list arrives: it grows from 96% of its size toward its
/// anchor's side, on the presence spring of [info]; no bounce. It is opaque
/// from its first frame, as clay is: the page under it never shows through
/// its rows while it moves.
///
/// ```dart
/// ClayMenuReveal(info: info, child: const SizedBox(width: 200, height: 120))
/// ```
class ClayMenuReveal extends StatelessWidget {
  /// [child] arriving on [info]'s presence.
  const ClayMenuReveal({super.key, required this.info, required this.child});

  /// The anchored surface's placement and presence.
  final RawPopoverInfo info;

  /// The list.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final above = info.side == RawPopoverSide.above;
    return AnimatedBuilder(
      animation: info.animation,
      child: child,
      builder: (context, child) {
        final t = info.animation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.96 + 0.04 * t,
          alignment: above
              ? AlignmentDirectional.bottomStart
              : AlignmentDirectional.topStart,
          child: child,
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<RawPopoverSide>('side', info.side));
  }
}
