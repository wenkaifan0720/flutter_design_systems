import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/choice_face.dart';
import '../../theme.dart';

/// A small face that filters or chooses (Zone B, Open now, Under review):
/// the action's tint with its words in the action colour, and, once on,
/// solid in the action colour with a tick before its words, so the state
/// reads without colour. Smaller than a button and with no solid edge, so
/// it never reads as the page's action. Stand several in a `Wrap`.
///
/// [CivicChip.removable] is a filter already applied, said as what a press
/// does ("Remove filter: Zone B"), with a cross after its words: the whole
/// face is the one target.
///
/// Reads [CivicStyle]'s fill, foreground and edge by state (selected among
/// them), padding and textStyle: its `style:`, then
/// [CivicThemeData.chipStyle].
///
/// ```dart
/// CivicChip(
///   label: 'Open now',
///   selected: openNow,
///   onSelected: (on) => setState(() => openNow = on),
/// )
/// ```
class CivicChip extends StatelessWidget {
  /// A chip that turns on and off.
  const CivicChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : onDeleted = null,
       deleteLabel = null;

  /// A filter already applied: a press removes it. A screen reader hears
  /// [label] and the reader's word for removing it (ui_core's "Remove"), or
  /// [deleteLabel] in place of both.
  const CivicChip.removable({
    super.key,
    required this.label,
    required this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : selected = false,
       onSelected = null;

  /// Its words.
  final String label;

  /// Whether it is on.
  final bool selected;

  /// Called with the new state on a press; null disables it.
  final ValueChanged<bool>? onSelected;

  /// Called when a removable chip is pressed.
  final VoidCallback? onDeleted;

  /// What a screen reader hears for a removable chip, in place of its
  /// [label] and the word for removing it.
  final String? deleteLabel;

  /// A glyph before the words.
  final IconData? icon;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the face's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final removable = onDeleted != null;
    final change = onSelected;
    final press = removable
        ? onDeleted
        : change == null
        ? null
        : () => change(!selected);
    final icon = this.icon;
    return TapTargetPadding(
      child: RawButton(
        onPressed: press,
        focusNode: focusNode,
        autofocus: autofocus,
        selected: !removable && selected,
        // A filter chip is a toggle button: a button that is selected.
        semanticSelected: removable ? null : selected,
        semanticLabel: removable ? (deleteLabel ?? label) : label,
        semanticHint: removable && deleteLabel == null
            ? RawWidgetsLocalizations.of(context).tagInputDeleteLabel
            : null,
        excludeSemantics: true,
        mouseCursor: press == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) => CivicChoiceFace(
          states: states,
          styles: [style, t.chipStyle],
          edge: false,
          minHeight: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: CivicSpacing.s12,
            vertical: CivicSpacing.s4,
          ),
          textStyle: text.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          // Its glyphs grow with the reader's text, as its words do.
          leading: icon == null ? null : Icon(icon, applyTextScaling: true),
          child: removable
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: CivicSpacing.s8,
                  children: [
                    Flexible(child: Text(label)),
                    const Icon(LucideIcons.x, size: 18, applyTextScaling: true),
                  ],
                )
              : Text(label),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has('onSelected', onSelected),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onDeleted', onDeleted))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
