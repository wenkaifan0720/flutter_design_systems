/// Values chosen as tags on a Ledger field, over ui_core's [RawTagInput].
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/field_frame.dart';
import '../../internal/option_paper.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../text-field/text_field.dart';

/// Several values (the categories a rule files under, the people a bill is
/// split with) chosen as tags on one Ledger field: each tag a ringed pill of
/// the mono capitals with its cross, the words typed after the last on the
/// same rule, and the matching [options] on the select's raised paper as
/// they are typed. Enter, a comma or a tab takes the highlighted line (or,
/// with [onCreate], makes a tag of the words); Backspace in the empty field
/// walks onto the last tag and takes it off, the arrows walk the tags. Each
/// cross is laid out at the tap floor, and a tag the keyboard is on is
/// ringed in the ink. [maxTags] stops it taking more.
///
/// ```dart
/// LedgerMultiSelect<String>(labelText: 'Split with', values: const ['Maren'], options: const ['Maren', 'Theo', 'Ana'], onChanged: (v) {})
/// ```
class LedgerMultiSelect<T extends Object> extends StatefulWidget {
  /// A tag field named [labelText] holding [values].
  const LedgerMultiSelect({
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.displayStringForOption,
    this.onCreate,
    this.maxTags,
    this.enabled = true,
    this.focusNode,
    super.key,
  }) : assert(maxTags == null || maxTags >= 1);

  /// The tags.
  final List<T> values;

  /// Called with the tags as they change.
  final ValueChanged<List<T>> onChanged;

  /// What it suggests from.
  final Iterable<T> options;

  /// The small capitals over the line.
  final String? labelText;

  /// Words in the third ink while it is empty.
  final String? hintText;

  /// The note under the rule.
  final String? helperText;

  /// What is wrong, in the vermilion; it replaces [helperText].
  final String? errorText;

  /// Each value's words; null: its `toString`.
  final String Function(T value)? displayStringForOption;

  /// Makes a value of typed words; null: only options are taken.
  final T? Function(String text)? onCreate;

  /// The most tags it takes; null: no limit.
  final int? maxTags;

  /// Whether it takes tags.
  final bool enabled;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<Object?>.has(
        'displayStringForOption',
        displayStringForOption,
      ),
    );
    properties.add(ObjectFlagProperty<Object?>.has('onCreate', onCreate));
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(IterableProperty<T>('options', options))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }

  @override
  State<LedgerMultiSelect<T>> createState() => _LedgerMultiSelectState<T>();
}

class _LedgerMultiSelectState<T extends Object>
    extends State<LedgerMultiSelect<T>> {
  FocusNode? _ownFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  String _words(T value) =>
      widget.displayStringForOption?.call(value) ?? value.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final enabled = widget.enabled;
    final words = LedgerTextField.wordsOf(t);
    final input = RawTagInput<T>(
      values: widget.values,
      // The pointer's mark (an underline) and the keyboard's (the double
      // rule) differ on purpose, and only the chosen option stands on the
      // menu's paper, ticked: a pointer leaves the keyboard's place alone.
      highlightFollowsPointer: false,
      onChanged: enabled ? widget.onChanged : (_) {},
      options: widget.options,
      displayStringForOption: _words,
      onCreate: widget.onCreate,
      maxTags: widget.maxTags,
      focusNode: _focus,
      semanticLabel: widget.labelText,
      optionsMaxHeight: _paper,
      fieldBuilder: (context, field) => Semantics(
        label: widget.labelText,
        // Whether its list of suggestions stands open.
        expanded: field.isOpen,
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: field.controller,
            focusNode: field.focusNode,
            decoration: null,
            enabled: enabled,
            style: words.colored(t.textPrimary),
            cursorColor: t.textPrimary,
            cursorWidth: 1.5,
            maxLines: 1,
            // Enter adds the lit tag and the field keeps the focus for the
            // next: in onEditingComplete, never onSubmitted, whose submit
            // restarts the text input of a field that keeps the focus (a
            // browser's then takes no typing).
            onEditingComplete: field.submit,
          ),
        ),
      ),
      optionBuilder: (context, option, states) =>
          LedgerOptionRow(label: _words(option), states: states),
      surfaceBuilder: ledgerOptionPaper,
      tagBuilder: (context, value, tag) => _Tag(
        words: _words(value),
        focused: tag.focused,
        enabled: enabled,
        onDeleted: enabled ? tag.onDeleted : null,
      ),
      // The line's ground: a press between the tags, or past the last, writes in
      // the field, so a tap reaches the whole line a screen reader outlines.
      // It spans the field's rule, so the suggestions open at the field's
      // width, not the tags' and the entry's.
      layoutBuilder: (context, tags, field) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? _focus.requestFocus : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: LedgerTextField.heightOf(t),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: LedgerSpacing.s6,
            children: [
              ...tags,
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: _fieldMin),
                child: IntrinsicWidth(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      if (widget.values.isEmpty && widget.hintText != null)
                        ExcludeSemantics(
                          child: Text(
                            widget.hintText!,
                            maxLines: 1,
                            style: words
                                .copyWith(fontWeight: FontWeight.w400)
                                .colored(t.textTertiary),
                          ),
                        ),
                      field,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return RawInputDecorator(
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        displayLabel: widget.labelText,
        focusNode: _focus,
        labelCursor: SystemMouseCursors.text,
        line: parts.control,
      ),
      child: input,
    );
  }

  static const double _paper = 5 * 48 + 8;
  static const double _fieldMin = 96;
}

/// One tag: a 28 pill ringed in the rule, the mono capitals and a cross
/// laid out at the tap floor; ringed in the ink while the keyboard is on it.
class _Tag extends StatelessWidget {
  const _Tag({
    required this.words,
    required this.focused,
    required this.enabled,
    required this.onDeleted,
  });

  final String words;
  final bool focused;
  final bool enabled;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final floor = DesignTapTargets.of(context).floorOn();
    final ink = enabled ? t.textPrimary : t.textTertiary;
    final remove = RawWidgetsLocalizations.of(context).deleteButtonTooltip;
    return SizedBox(
      height: floor.height < _pill ? _pill : floor.height,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          // The pill, drawn behind the words and the cross's target.
          Positioned.fill(
            child: Center(
              child: AnimatedContainer(
                duration: LedgerMotion.of(context, LedgerMotion.fast),
                height: _pill,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(_pill / 2),
                  border: Border.all(color: focused ? t.textPrimary : t.border),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: _pad),
              Text(
                words.toUpperCase(),
                maxLines: 1,
                style: t.meta.medium.colored(ink),
              ),
              TapTargetPadding(
                minSize: Size(floor.height, floor.height),
                child: LedgerPressable(
                  onTap: onDeleted,
                  label: '$remove $words',
                  radius: _cross / 2,
                  child: SizedBox(
                    width: _cross,
                    height: _cross,
                    child: Icon(
                      LucideIcons.x,
                      size: _glyph,
                      color: enabled ? t.textSecondary : t.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const double _pill = 28;
  static const double _pad = LedgerSpacing.s12;
  static const double _cross = 20;
  static const double _glyph = 14;
}
