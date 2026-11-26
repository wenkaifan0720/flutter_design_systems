/// Grouped form rows — a section, a label-and-control row, an inline input
/// row.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/tap_band.dart';
import '../internal/trailing_glyph.dart';
import '../theme.dart';
import 'date_picker.dart';
import 'input.dart';
import 'picker.dart';
import 'pressable.dart';

/// Grouped form rows the Minimal way: no card — an uppercase group label
/// over a hairline, the rows (each drawing its own rule under it), and a
/// quiet footer line. It takes no inset of its own; the page's gutter is
/// the measure. Compose [MinimalInputRow], [MinimalFormRow], picker and date
/// rows inside it. Every row spans the column, so the group's rows end on one
/// edge with the text fields beside them.
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
    return RawKeylineRegion(
      label: 'MinimalFormSection',
      child: _section(t, title, footer),
    );
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('footer', footer, defaultValue: null));
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

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
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
    final head = Row(
      children: [
        if (icon != null) ...[
          MinimalIcon(icon),
          const MinimalGap(MinimalFieldMetrics.rowIconGap),
        ],
        Expanded(child: minimalCapLabel(Text(label, style: t.body))),
      ],
    );
    // From 160% text a control of the caller's stands under the label, at
    // its start, as a list row's trailing part does, rather than squeeze
    // the label or its own words; the chevron of a row that opens stays.
    final stacked =
        this.trailing != null &&
        MediaQuery.textScalerOf(context).scale(10) / 10 >=
            MinimalChromeMetrics.rowStackScale;
    final row = Container(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
      // Painted over the row's foot: what the row holds is centred on the
      // whole row, the rule's pixel with it.
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: stacked && trailing != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                head,
                const MinimalGap(MinimalSpacing.s4),
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: icon == null
                        ? 0
                        : MinimalIconSize.i18 + MinimalFieldMetrics.rowIconGap,
                  ),
                  // Its face on the label's keyline, its target reaching
                  // past it.
                  child: MinimalTapAlignment(
                    alignment: AlignmentDirectional.centerStart,
                    child: trailing,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: head),
                if (trailing != null) ...[
                  const MinimalGap(MinimalSpacing.s12),
                  // Its face on the end keyline, its target reaching in.
                  MinimalTapAlignment(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing,
                  ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
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

/// A labeled text field inline in a form: the label in the quiet ink in a
/// column at the start, the boxless field in the ink beside it, and the
/// row's own hairline under both — the accent while the field has focus,
/// the danger with an [errorText], whose message prints under the row. Narrow
/// rows (under 280 px) stack the label over the field. `mono: true` sets the value in
/// Geist Mono, for a number, an id or a time.
///
/// The whole row is the field's tap target: a tap on the label or in the
/// row's padding focuses the field. It draws its own rule, so it stands in
/// a [MinimalFormSection], never in a `MinimalListSection`.
///
/// ```dart
/// MinimalInputRow(labelText: 'Name', controller: name, hintText: 'Stretch before bed')
/// ```
class MinimalInputRow extends StatefulWidget {
  /// A form row that edits text.
  const MinimalInputRow({
    super.key,
    required this.labelText,
    this.controller,
    this.hintText,
    this.errorText,
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
  final String labelText;

  /// The text; null keeps its own.
  final TextEditingController? controller;

  /// What an empty field says.
  final String? hintText;

  /// What is wrong with it; null when nothing is.
  final String? errorText;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  /// Reports the text when the keyboard's action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// {@template minimal.textInputAction}
  /// The keyboard's action key.
  /// {@endtemplate}
  final TextInputAction? textInputAction;

  /// Whether it takes input.
  final bool enabled;

  /// {@template minimal.readOnly}
  /// Whether its text is shown but not edited.
  /// {@endtemplate}
  final bool readOnly;

  /// Whether it hides what is typed.
  final bool obscureText;

  /// The most lines it grows to.
  final int maxLines;

  /// Set the value in Geist Mono with tabular figures.
  final bool mono;

  /// A glyph before the label, the property-row register.
  final IconData? icon;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  State<MinimalInputRow> createState() => _MinimalInputRowState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(FlagProperty('mono', value: mono, ifTrue: 'mono'))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
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
    final error = widget.errorText;
    final icon = widget.icon;
    final ruleColor = error != null
        ? t.destructive
        : _focused
        ? t.ring
        : t.border;
    final field = Semantics(
      label: widget.labelText,
      child: MinimalTextField(
        bare: true,
        style: widget.mono ? t.monoValue : t.body,
        controller: widget.controller,
        hintText: widget.hintText,
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
        onFocusChange: (focused) => setState(() => _focused = focused),
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
            child: Text(widget.labelText, style: t.body.c(t.mutedForeground)),
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
    // The whole row is the field's target, well past the tap floor: a tap
    // on the label or in the row's padding focuses the field. The field's
    // own tap (placing the caret) wins the arena where it lands. The pointer
    // shows the text cursor over all of it, as over the field.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focus.requestFocus : null,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.text : MouseCursor.defer,
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
      ),
    );
  }
}
