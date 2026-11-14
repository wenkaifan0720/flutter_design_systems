/// Grouped form rows — a section, a label-and-control row, an inline input
/// row.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/trailing_glyph.dart';
import '../theme.dart';
import 'date_picker.dart';
import 'input.dart';
import 'picker.dart';
import 'pressable.dart';
import 'time_picker.dart';

/// Grouped form rows the Minimal way: no card — an uppercase group label
/// over a hairline, the rows (each drawing its own rule under it), and a
/// quiet footer line. It takes no inset of its own; the page's gutter is
/// the measure. Compose [MinimalInputRow], [MinimalFormRow], picker and date
/// rows inside it. A section holding a select or a date row keeps their
/// measure (320 from the compact width up), every other row, its label and
/// hairline with them, so the group's rows end on one edge.
///
/// ```dart
/// MinimalFormSection(title: 'Schedule', footer: 'Reminders follow your device time zone.', children: rows)
/// ```
class MinimalFormSection extends StatelessWidget {
  /// A band of form rows.
  const MinimalFormSection({
    super.key,
    this.title,
    this.footer,
    required this.children,
  });

  /// The group label, printed upper-cased in [MinimalThemeData.label].
  final String? title;

  /// An explanatory line under the rows.
  final String? footer;

  /// Its rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final title = this.title;
    final footer = this.footer;
    final section = DesignKeylineRegion(
      label: 'MinimalFormSection',
      child: _section(t, title, footer),
    );
    // One select, date or time row holds to a control's measure, so its
    // whole section does: every row of a group, and the rule over them, runs
    // to the same edge, never a picker stopping half way along its
    // neighbours or under its section's rule.
    final ofControls = children.any(
      (c) =>
          c is MinimalSelect ||
          c is MinimalDatePicker ||
          (c is MinimalTimePicker && !c.wheel),
    );
    return ofControls ? MinimalLayout.capControl(context, section) : section;
  }

  Widget _section(MinimalThemeData t, String? title, String? footer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              bottom: MinimalChromeMetrics.iconGap,
            ),
            child: Semantics(
              header: true,
              child: Text(title.toUpperCase(), style: t.label),
            ),
          ),
        Container(
          decoration: BoxDecoration(border: Border(top: t.rule)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: MinimalSpacing.s8),
            child: Text(footer, style: t.caption),
          ),
      ],
    );
  }
}

/// A 44 px hairline form row for a control or an action: an optional
/// glyph, the label in the ink, and the [trailing] control (a toggle, a
/// stepper, a button) at the end. With [onPressed] the whole row is the
/// control; with no [trailing] it then carries a forward chevron.
///
/// It names an act or a switch, so its label is the ink. A label that
/// names a VALUE (`Repeats · Every evening`, `Reminder · 21:30`) is a
/// property: print it as a [MinimalSelect] or a [MinimalDatePicker] row,
/// whose key is the quiet ink and whose value is the ink.
///
/// It draws its own bottom rule, so it stands in a [MinimalFormSection],
/// never in a `MinimalListSection` (which would rule it twice).
///
/// ```dart
/// MinimalFormRow(label: 'Remind me', icon: LucideIcons.bell, trailing: MinimalSwitch(value: on, onChanged: setOn))
/// ```
class MinimalFormRow extends StatelessWidget {
  /// A form row saying [label].
  const MinimalFormRow({
    super.key,
    required this.label,
    this.trailing,
    this.onPressed,
    this.icon,
    this.focusNode,
    this.autofocus = false,
  });

  /// What the row sets.
  final String label;

  /// What it shows at its end: a value, a switch, a chevron.
  final Widget? trailing;

  /// Opens the row; null leaves it still.
  final VoidCallback? onPressed;

  /// A glyph before the label, in the quiet ink.
  final IconData? icon;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final icon = this.icon;
    final trailing =
        this.trailing ??
        (onPressed == null
            ? null
            : MinimalTrailingChevron(color: t.textTertiary));
    final row = Container(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
      // Painted over the row's foot: what the row holds is centred on the
      // whole row, the rule's pixel with it.
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Row(
        children: [
          if (icon != null) ...[
            MinimalIcon(icon),
            const MinimalGap(MinimalFieldMetrics.rowIconGap),
          ],
          Expanded(child: minimalCapLabel(Text(label, style: t.body))),
          if (trailing != null) ...[
            const MinimalGap(MinimalSpacing.s12),
            trailing,
          ],
        ],
      ),
    );
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      radius: 0,
      outset: MinimalFieldMetrics.rowReach,
      child: row,
    );
  }
}

/// A labeled text field inline in a form: the label in the quiet ink in a
/// column at the start, the boxless field in the ink beside it, and the
/// row's own hairline under both — the accent while the field has focus,
/// the danger with an [error], whose message prints under the row. Narrow
/// rows (under 280 px) stack the label over the field. `mono: true` sets the value in
/// Geist Mono, for a number, an id or a time.
///
/// The whole row is the field's tap target: a tap on the label or in the
/// row's padding focuses the field. It draws its own rule, so it stands in
/// a [MinimalFormSection], never in a `MinimalListSection`.
///
/// ```dart
/// MinimalInputRow(label: 'Name', controller: name, hint: 'Stretch before bed')
/// ```
class MinimalInputRow extends StatefulWidget {
  /// A form row that edits text.
  const MinimalInputRow({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.mono = false,
    this.icon,
    this.autofocus = false,
  });

  /// What it edits.
  final String label;

  /// The text; null keeps its own.
  final TextEditingController? controller;

  /// What an empty field says.
  final String? hint;

  /// What is wrong with it; null when nothing is.
  final String? error;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  /// Reports the text when the keyboard's action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its text is shown but not edited.
  final bool readOnly;

  /// Whether it hides what is typed.
  final bool obscureText;

  /// The most lines it grows to.
  final int maxLines;

  /// Set the value in Geist Mono with tabular figures.
  final bool mono;

  /// A glyph before the label, the property-row register.
  final IconData? icon;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  State<MinimalInputRow> createState() => _MinimalInputRowState();
}

/// The input row's measure: the label column's width bounds beside the
/// field (a share of the row between them), and the width under which the
/// label stacks over the field.
abstract final class _RowMetrics {
  static const double labelMin = 88;
  static const double labelMax = 120;
  static const double labelShare = 0.3;
  static const double stackBelow = 280;
}

class _MinimalInputRowState extends State<MinimalInputRow> {
  bool _focused = false;

  /// The field's focus node: the caller's, or one the row owns, so a tap
  /// anywhere on the row — its label, its padding — focuses the field.
  FocusNode? _ownedFocus;
  FocusNode get _focus =>
      widget.focusNode ??
      (_ownedFocus ??= FocusNode(debugLabel: 'MinimalInputRow'));

  @override
  void dispose() {
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final error = widget.error;
    final icon = widget.icon;
    final ruleColor = error != null
        ? t.destructive
        : _focused
        ? t.ring
        : t.border;
    final field = Semantics(
      label: widget.label,
      child: MinimalTextField(
        bare: true,
        style: widget.mono ? t.monoValue : t.body,
        controller: widget.controller,
        hint: widget.hint,
        focusNode: _focus,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        onFocusChanged: (focused) => setState(() => _focused = focused),
      ),
    );
    final label = ExcludeSemantics(
      child: Row(
        children: [
          if (icon != null) ...[
            MinimalIcon(icon),
            const MinimalGap(MinimalFieldMetrics.rowIconGap),
          ],
          Flexible(
            child: Text(widget.label, style: t.body.c(t.mutedForeground)),
          ),
        ],
      ),
    );
    final message = error == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Text(error, style: t.caption.c(t.destructiveInk)),
          );
    // The whole row is the field's target, well past the 44 px floor: a tap
    // on the label or in the row's padding focuses the field. The field's
    // own tap (placing the caret) wins the arena where it lands.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focus.requestFocus : null,
      // Disabled, the words dim; the rule keeps its neighbours' strength.
      child: Container(
        constraints: BoxConstraints(minHeight: t.rowHeight),
        padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s12),
        // Painted over the row's foot, as every ruled row's: the label
        // and the field are centred on the whole row.
        foregroundDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ruleColor, width: t.hairline),
          ),
        ),
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < _RowMetrics.stackBelow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    label,
                    const MinimalGap(MinimalSpacing.s4),
                    field,
                    if (message != null) ...[
                      const MinimalGap(MinimalSpacing.s4),
                      message,
                    ],
                  ],
                );
              }
              final labelWidth = (c.maxWidth * _RowMetrics.labelShare).clamp(
                _RowMetrics.labelMin,
                _RowMetrics.labelMax,
              );
              // The message starts under the field it describes, not under
              // the label.
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: widget.maxLines > 1
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: labelWidth, child: label),
                      const MinimalGap(MinimalSpacing.s8),
                      Expanded(child: field),
                    ],
                  ),
                  if (message != null)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        top: MinimalSpacing.s4,
                        start: labelWidth + MinimalSpacing.s8,
                      ),
                      child: message,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
