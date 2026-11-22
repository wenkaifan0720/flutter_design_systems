/// Single-choice rows and the hairline group that holds them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/press_feedback.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../theme.dart';
import 'pressable.dart';

/// One option of a single choice: a 44 px hairline row — an optional
/// leading glyph or mark, the title (and a quiet subtitle), and the accent
/// check at the end when it is the choice, its title then in the full ink at
/// medium weight (in a [MinimalSelectionGroup] with a choice, the other
/// titles stay muted). The row draws its own bottom
/// rule, like every Minimal row; stack them in a [MinimalSelectionGroup].
/// A null [onPressed] disables the option.
///
/// It announces itself as one of a mutually exclusive set, checked or not.
/// In a [MinimalSelectionGroup] it is a radio of the group's [RadioGroup].
/// It draws its own rule: stand it in a [MinimalSelectionGroup], never in a
/// `MinimalListSection`.
///
/// ```dart
/// MinimalChoiceRow(title: 'Every day', selected: repeat == 'daily', onPressed: () => setRepeat('daily'))
/// ```
class MinimalChoiceRow extends StatelessWidget {
  /// A row that can be chosen.
  const MinimalChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    this.subtitle,
    this.leading,
    this.content,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it is.
  final String title;

  /// A line under the title.
  final String? subtitle;

  /// Whether it is chosen.
  final bool selected;

  /// A glyph, a swatch or an avatar before the title.
  final Widget? leading;

  /// Replaces the title and subtitle with richer content; the row keeps its
  /// padding, its check and its hit target, and [title] stays what a
  /// screen reader hears.
  final Widget? content;

  /// Chooses it; null disables it.
  final VoidCallback? onPressed;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final subtitle = this.subtitle;
    final leading = this.leading;
    final content = this.content;
    final group = context.dependOnInheritedWidgetOfExactType<_ChoiceInset>();
    final inset = group?.padding ?? EdgeInsets.zero;
    // Minimal says a choice in ink and weight: the chosen row's words in the
    // full ink at medium weight, the rest of its group muted.
    final ink = (group?.choosing ?? false) && !selected
        ? t.mutedForeground
        : t.foreground;
    final face = Semantics(
      label: content == null ? null : title,
      child: Container(
        constraints: BoxConstraints(minHeight: t.rowHeight),
        padding: inset.add(
          const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const MinimalGap(MinimalFieldMetrics.rowIconGap),
            ],
            Expanded(
              child:
                  content ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      minimalCapLabel(
                        Text(
                          title,
                          style: (selected ? t.body.medium : t.body).c(ink),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle, style: t.caption, maxLines: 2),
                    ],
                  ),
            ),
            const MinimalGap(MinimalSpacing.s12),
            SizedBox(
              width: MinimalIconSize.i18,
              // The chosen row's check is in its words' ink, not the accent's.
              child: selected
                  ? MinimalIcon(LucideIcons.check, color: ink)
                  : null,
            ),
          ],
        ),
      ),
    );
    final slot = context.dependOnInheritedWidgetOfExactType<_ChoiceSlot>();
    final registry = slot == null ? null : RadioGroup.maybeOf<int>(context);
    // Painted over the row's foot, so the row's words and check are centred
    // on the whole row. Outside the press, so a disabled row dims its words
    // and keeps its rule as strong as its neighbours'.
    return Container(
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: slot == null || registry == null
          ? MinimalPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              enabled: onPressed != null,
              radius: 0,
              outset: MinimalFieldMetrics.rowReach,
              checked: selected,
              inMutuallyExclusiveGroup: true,
              child: face,
            )
          : _ChoiceRadio(
              index: slot.index,
              registry: registry,
              enabled: onPressed != null,
              focusNode: focusNode,
              autofocus: autofocus,
              child: face,
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('selected', selected))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
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

/// A single choice set out as hairline rows: a rule over the first
/// [MinimalChoiceRow], each row's own rule under it, no card and no inset of
/// its own (the page's gutter is the inset). Where the group runs edge to
/// edge (a phone page's lists do), [padding] insets the rows' words and
/// checks while the rules still span the screen. Once a row is chosen the
/// others' titles stay muted, so the choice reads at a glance. Keep the
/// chosen value in page state and wire every available option to update it.
///
/// The group is Flutter's [RadioGroup], each [MinimalChoiceRow] among its
/// [children] a `RawRadio`, with ui_core's [RadioGroupKeyboardFix] round
/// them: Tab lands on the chosen row (the first row Tab can reach while there
/// is none) and leaves the group next; the arrow keys choose the next or the
/// previous row, skipping disabled ones and wrapping at the ends, and Space
/// chooses the focused row. Choosing a row calls its `onPressed`, and so
/// does a tap, Enter or Space on the chosen row (a sheet that closes on a
/// choice closes on the chosen one too).
///
/// ```dart
/// MinimalSelectionGroup(children: [MinimalChoiceRow(title: 'Morning', selected: part == 'am', onPressed: () => setPart('am'))])
/// ```
class MinimalSelectionGroup extends StatelessWidget {
  /// A group of choice rows.
  const MinimalSelectionGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  /// The rows.
  final List<Widget> children;

  /// The side padding of every row's words and check; the rules run the
  /// group's whole width. None by default: pass the screen's gutter when the
  /// group runs edge to edge.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final chosen = children.indexWhere(
      (c) => c is MinimalChoiceRow && c.selected,
    );
    return RadioGroup<int>(
      groupValue: chosen < 0 ? null : chosen,
      // Each row's radio toggles, so pressing the chosen row reaches the group
      // as null: that row is pressed again, as its pressable was.
      onChanged: (index) {
        final at = index ?? chosen;
        final row = at < 0 ? null : children[at];
        if (row is MinimalChoiceRow) row.onPressed?.call();
      },
      child: RadioGroupKeyboardFix<int>(
        child: Container(
          decoration: BoxDecoration(border: Border(top: t.rule)),
          child: _ChoiceInset(
            padding: padding,
            choosing: chosen >= 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, child) in children.indexed)
                  _ChoiceSlot(index: index, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>(
        'padding',
        padding,
        defaultValue: EdgeInsets.zero,
      ),
    );
  }
}

/// The side padding a [MinimalSelectionGroup] hands its rows.
class _ChoiceInset extends InheritedWidget {
  const _ChoiceInset({
    required this.padding,
    required this.choosing,
    required super.child,
  });

  final EdgeInsetsGeometry padding;

  /// Whether one of the group's rows is chosen: the others' words then stay
  /// in the muted ink.
  final bool choosing;

  @override
  bool updateShouldNotify(_ChoiceInset old) =>
      padding != old.padding || choosing != old.choosing;
}

/// A row's place among its group's children: its value in the group.
class _ChoiceSlot extends InheritedWidget {
  const _ChoiceSlot({required this.index, required super.child});

  final int index;

  @override
  bool updateShouldNotify(_ChoiceSlot old) => index != old.index;
}

/// A [MinimalChoiceRow] in a [MinimalSelectionGroup]: a radio of the group,
/// drawn as a row press draws, its wash and ring over the row's reach.
class _ChoiceRadio extends StatefulWidget {
  const _ChoiceRadio({
    required this.index,
    required this.registry,
    required this.enabled,
    required this.focusNode,
    required this.autofocus,
    required this.child,
  });

  final int index;
  final RadioGroupRegistry<int> registry;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget child;

  @override
  State<_ChoiceRadio> createState() => _ChoiceRadioState();
}

class _ChoiceRadioState extends State<_ChoiceRadio> {
  FocusNode? _own;
  // A pointer can hover even when touch was the last input, as over a
  // pressable.
  bool _hover = false;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    // The target is the outermost layer, as a pressable's: the area a tap
    // reaches is the box a screen reader outlines.
    return minimalInlineNode(
      context,
      TapTargetPadding(
        alignment:
            MinimalTapAlignment.maybeOf(context) ?? AlignmentDirectional.center,
        child: Semantics(
          enabled: enabled,
          child: MergeSemantics(
            child: RawRadio<int>(
              value: widget.index,
              mouseCursor: WidgetStateMouseCursor.clickable,
              toggleable: true,
              focusNode: _node,
              autofocus: widget.autofocus,
              groupRegistry: widget.registry,
              enabled: enabled,
              builder: (context, radio) {
                final pressed = enabled && radio.downPosition != null;
                final focused =
                    enabled && radio.states.contains(WidgetState.focused);
                return MouseRegion(
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  // The whole row takes the press, its gaps too.
                  child: MetaData(
                    behavior: HitTestBehavior.opaque,
                    child: MinimalPressFeedback(
                      states: minimalStates(
                        enabled: enabled,
                        pressed: pressed,
                        hovered: enabled && _hover,
                        focused: focused,
                        selected: radio.value ?? false,
                      ),
                      enabled: enabled,
                      pressed: pressed,
                      focused: focused,
                      radius: 0,
                      outset: MinimalFieldMetrics.rowReach,
                      child: widget.child,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
