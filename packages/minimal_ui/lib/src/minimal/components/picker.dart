/// The picker row, its options and the single-choice list it opens as a
/// menu or a sheet.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/menu_keys.dart';
import '../localizations.dart';
import '../theme.dart';
import 'menu.dart';
import 'pressable.dart';
import 'selection.dart';
import 'sheet.dart';

/// One choice a picker offers: a stable [value], the [label] it prints, an
/// optional explanation and glyph. A disabled option shows but cannot be
/// chosen.
///
/// ```dart
/// MinimalSelectOption('evening', 'Evening', icon: LucideIcons.moon)
/// ```
@immutable
class MinimalSelectOption<T> {
  /// An option saying [label].
  const MinimalSelectOption(
    this.value,
    this.label, {
    this.subtitle,
    this.enabled = true,
    this.icon,
  });

  /// What choosing this option reports.
  final T value;

  /// What it says.
  final String label;

  /// A line under the label, in the sheet's list (a menu prints labels
  /// only).
  final String? subtitle;

  /// Whether it can be chosen.
  final bool enabled;

  /// A glyph before the label.
  final IconData? icon;
}

/// Where a [MinimalSelect] opens its choices: the anchored [MinimalMenu] for
/// a short set, a sheet holding a [MinimalSelectionList] for a longer one or
/// one whose options need their subtitles.
enum MinimalSelectPresentation {
  /// The anchored menu, for a short set.
  menu,

  /// A sheet of rows, for a longer set or one with subtitles.
  sheet,
}

/// A form row that shows the current choice and opens the rest: the label
/// in the quiet ink at the start, the chosen value (its glyph, its label)
/// in the ink at the end over an up-down chevron — or a forward chevron
/// when it opens a sheet. A 44 px hairline row, like every Minimal form
/// row; with no [onChanged] or no options it is disabled: it dims, and its
/// value takes the quiet ink, so it never reads stronger than an enabled
/// row's.
/// It rules itself: stand it in a `MinimalFormSection`, never in a
/// `MinimalListSection`.
///
/// ```dart
/// MinimalSelect(labelText: 'Repeats', value: repeat, options: repeats, onChanged: setRepeat)
/// ```
class MinimalSelect<T> extends StatefulWidget {
  /// A form row choosing one of [options].
  const MinimalSelect({
    super.key,
    required this.labelText,
    required this.value,
    required this.options,
    this.onChanged,
    this.presentation = MinimalSelectPresentation.menu,
    this.hintText,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it chooses.
  final String labelText;

  /// The chosen option's [MinimalSelectOption.value]; null prints
  /// [hintText].
  final T? value;

  /// The choices, in order.
  final List<MinimalSelectOption<T>> options;

  /// Called with the chosen option's value; null disables the row.
  final ValueChanged<T>? onChanged;

  /// Where the choices open: a menu or a sheet.
  final MinimalSelectPresentation presentation;

  /// What the row prints while nothing is chosen.
  final String? hintText;

  /// A glyph before the label, the property-row register.
  final IconData? icon;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  State<MinimalSelect<T>> createState() => _MinimalSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(IterableProperty<MinimalSelectOption<T>>('options', options))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        EnumProperty<MinimalSelectPresentation>(
          'presentation',
          presentation,
          defaultValue: MinimalSelectPresentation.menu,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
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

class _MinimalSelectState<T> extends State<MinimalSelect<T>> {
  // The menu opens from the whole field: as wide as it, on its leading
  // edge, as a list that opens from a field does.
  final GlobalKey _fieldKey = GlobalKey();

  bool get _enabled => widget.onChanged != null && widget.options.isNotEmpty;

  Future<void> _open() async {
    final onChanged = widget.onChanged;
    if (onChanged == null || widget.options.isEmpty) return;
    if (widget.presentation == MinimalSelectPresentation.menu) {
      final box =
          (_fieldKey.currentContext ?? context).findRenderObject()!
              as RenderBox;
      await showMinimalMenu(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        label: widget.labelText,
        items: [
          for (final option in widget.options)
            MinimalMenuItem(
              option.label,
              icon: option.icon,
              selected: option.value == widget.value,
              onPressed: option.enabled ? () => onChanged(option.value) : null,
            ),
        ],
      );
      return;
    }
    final result = await showMinimalBottomSheet<T>(
      context,
      title: widget.labelText,
      builder: (sheetContext) => MinimalSelectionList<T>(
        value: widget.value,
        options: widget.options,
        autofocus: true,
        onChanged: (v) => Navigator.of(sheetContext).pop(v),
      ),
    );
    if (result != null && mounted) widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final icon = widget.icon;
    final chosen = widget.options
        .where((option) => option.value == widget.value)
        .firstOrNull;
    final chosenIcon = chosen?.icon;
    // A form row spans its column at every width, as a text field and every
    // other form row do, so a form's rows end on one edge.
    return _row(t, icon, chosen, chosenIcon);
  }

  Widget _row(
    MinimalThemeData t,
    IconData? icon,
    MinimalSelectOption<T>? chosen,
    IconData? chosenIcon,
  ) {
    // Disabled, the value prints in the label's quiet ink: in the full ink
    // it would read stronger, once dimmed, than an enabled row's prompt.
    final valueInk = _enabled ? t.foreground : t.mutedForeground;
    // Painted over the row's foot: the label and value are centred on the
    // whole row, the rule's pixel with it. Outside the press, so a disabled
    // row dims its words and keeps its rule as strong as its neighbours'.
    // A menu button: Down opens the menu too.
    return minimalOpensOnDown(
      open: _enabled && widget.presentation == MinimalSelectPresentation.menu
          ? _open
          : null,
      child: Container(
        foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
        child: MinimalPressable(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onPressed: _enabled ? _open : null,
          enabled: _enabled,
          radius: 0,
          outset: MinimalFieldMetrics.rowReach,
          child: Container(
            key: _fieldKey,
            constraints: BoxConstraints(minHeight: t.rowHeight),
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              spacing: MinimalSpacing.s12,
              overflowSpacing: MinimalSpacing.s4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      MinimalIcon(icon),
                      const MinimalGap(MinimalFieldMetrics.rowIconGap),
                    ],
                    Flexible(
                      child: minimalCapLabel(
                        Text(
                          widget.labelText,
                          style: t.body.c(t.mutedForeground),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chosenIcon != null) ...[
                      MinimalIcon(
                        chosenIcon,
                        size: MinimalIconSize.i16,
                        color: valueInk,
                      ),
                      const MinimalGap(MinimalChromeMetrics.iconGap),
                    ],
                    Flexible(
                      child: minimalCapLabel(
                        Text(
                          chosen?.label ??
                              widget.hintText ??
                              MinimalLocalizations.of(context).choose,
                          style: t.body.c(
                            chosen == null ? t.mutedForeground : valueInk,
                          ),
                        ),
                      ),
                    ),
                    const MinimalGap(MinimalChromeMetrics.iconGap),
                    MinimalIcon(
                      widget.presentation == MinimalSelectPresentation.menu
                          ? LucideIcons.chevronsUpDown
                          : LucideIcons.chevronRightDir,
                      size: MinimalIconSize.i16,
                      color: t.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-choice list of [MinimalSelectOption]s: hairline rows with the
/// accent check on the chosen one and each option's subtitle under its
/// label — the body of a picker sheet, or a preference page of its own.
///
/// ```dart
/// MinimalSelectionList(value: part, options: parts, onChanged: setPart)
/// ```
class MinimalSelectionList<T> extends StatelessWidget {
  /// The rows of [options], one checked.
  const MinimalSelectionList({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.padding = EdgeInsets.zero,
    this.autofocus = false,
  });

  /// The chosen option's value; null checks none.
  final T? value;

  /// The choices, in order.
  final List<MinimalSelectOption<T>> options;

  /// Called with the chosen option's value; null disables the list.
  final ValueChanged<T>? onChanged;

  /// The side padding of every row's words and check, as
  /// [MinimalSelectionGroup.padding]: pass the screen's gutter when the list
  /// runs edge to edge.
  final EdgeInsetsGeometry padding;

  /// Whether the chosen option takes the focus as the list mounts, as it does
  /// in a select's sheet, so the keys go on from it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MinimalSelectionGroup(
      padding: padding,
      children: [
        for (final option in options)
          MinimalChoiceRow(
            title: option.label,
            subtitle: option.subtitle,
            selected: option.value == value,
            autofocus: autofocus && option.value == value,
            leading: option.icon == null ? null : MinimalIcon(option.icon!),
            onPressed: option.enabled && onChanged != null
                ? () => onChanged(option.value)
                : null,
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(IterableProperty<MinimalSelectOption<T>>('options', options))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: EdgeInsets.zero,
        ),
      );
  }
}
