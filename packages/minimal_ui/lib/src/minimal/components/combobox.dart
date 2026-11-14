/// A field that suggests options as you type, and the same field choosing
/// several as tags, painted on ui_core's combobox and tag input.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../internal/text_entry.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'input.dart';
import 'pressable.dart';

String _text(Object option) => option.toString();

/// The open list's inset inside its card.
const EdgeInsets _cardInset = EdgeInsets.all(MinimalSpacing.s4);

/// The tag box's inset around its tags and its entry. Its height is the
/// text field's (the box centres one line of tags in it), so this inset is
/// the floor once the tags wrap onto more lines.
const EdgeInsetsDirectional _tagBoxInset = EdgeInsetsDirectional.symmetric(
  horizontal: MinimalSpacing.s4,
  vertical: MinimalSpacing.s2,
);

/// A tag's height at 100%: one line of tags stands inside a 28 px field,
/// 3 px clear of its rim, so the box stays its sibling fields' height.
const double _tagHeight = 20;

/// The air before a tag's words, inside its hairline.
const double _tagWords = MinimalSpacing.s8;

/// The open list under a combobox: Minimal's panel, 4 px off the field.
Widget _surface(BuildContext context, Widget list, MinimalStyle? style) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
      child: MinimalKitPanel(style: style, padding: _cardInset, child: list),
    );

/// The start side of [padding] in [direction].
double _startOf(EdgeInsetsGeometry padding, TextDirection direction) {
  final p = padding.resolve(direction);
  return direction == TextDirection.ltr ? p.left : p.right;
}

/// The card's leading inset before its rows, in [style] over the menu's.
double _cardStart(BuildContext context, MinimalStyle? style) {
  final t = context.minimalTheme;
  final card = MinimalStyleOf([style, t.components.menu], const {}).padding;
  return _startOf(card ?? _cardInset, Directionality.of(context));
}

/// The leading air of an option row whose words start where the field's
/// value does, [value] in from the edge the list's card stands on. The
/// card lies on the field's edges at its width, so the card's inset plus
/// the row's leading air is the field's text inset (shadcn's Select:
/// trigger 12, content 4 + item 8); the check stands at the trailing end.
double _rowStart(BuildContext context, double value, MinimalStyle? style) =>
    math.max(0, value - _cardStart(context, style));

/// A text field that suggests from [options] as you type: a city, an
/// assignee, a country. The field is a [MinimalTextField] with a chevron at
/// its end; the list opens under it in Minimal's panel of 32 px rows, the
/// highlighted row (the keyboard's, or the pointer's) in the selection
/// fill and the chosen value with a check. Words no option fits say so in
/// the panel ("No results").
///
/// Up and Down move the highlight, Enter takes it, Escape hides the list,
/// a tap takes an option; a screen reader hears the highlight and whether
/// the typing found anything. With [requireSelection] it is a searchable
/// select: leaving the field puts back [value]'s text, so it never holds
/// text that is not an option. The behaviour is ui_core's
/// ([DesignCombobox]); Minimal paints it.
///
/// [fieldStyle] dresses the box over `components.textField`; [listStyle]
/// the panel over `components.menu`.
///
/// ```dart
/// MinimalCombobox<String>(label: 'City', options: const ['Lisbon', 'London', 'Lyon'], value: city, onSelected: setCity)
/// ```
class MinimalCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const MinimalCombobox({
    super.key,
    required this.options,
    this.displayString = _text,
    this.value,
    this.onSelected,
    this.requireSelection = false,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.icon,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.fieldStyle,
    this.listStyle,
    this.autofocus = false,
  });

  /// The options typing filters (case-insensitively, by [displayString]).
  final Iterable<T> options;

  /// An option's words: what the filter matches and the field shows.
  final String Function(T option) displayString;

  /// The option taken: checked in the list, and the field's text while it
  /// is not being edited.
  final T? value;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// Whether the field only ever holds an option's text.
  final bool requireSelection;

  /// The field's name, over the box.
  final String? label;

  /// What the empty field shows.
  final String? hint;

  /// A quiet line under the box; the [error] replaces it.
  final String? helper;

  /// The message under the box.
  final String? error;

  /// A glyph at the box's start (a search glass).
  final IconData? icon;

  /// Whether it takes input.
  final bool enabled;

  /// The field's text, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus, when the caller holds it.
  final FocusNode? focusNode;

  /// The box's style, over `components.textField`.
  final MinimalStyle? fieldStyle;

  /// The list's panel style, over `components.menu`.
  final MinimalStyle? listStyle;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The options' words start on the field's value.
    final start = _rowStart(
      context,
      minimalFieldWordsStart(context, fieldStyle, icon: icon != null),
      listStyle,
    );
    return DesignCombobox<T>(
      options: options,
      displayStringForOption: displayString,
      value: value,
      onSelected: onSelected,
      requireSelection: requireSelection,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: label,
      fieldBuilder: (context, field) => MinimalTextField(
        label: label,
        hint: hint,
        helper: helper,
        error: error,
        icon: icon,
        enabled: enabled,
        controller: field.controller,
        focusNode: field.focusNode,
        autofocus: autofocus,
        onSubmitted: (_) => field.submit(),
        fieldStyle: fieldStyle,
        trailing: Padding(
          padding: const EdgeInsetsDirectional.only(end: MinimalSpacing.s8),
          child: MinimalIcon(
            LucideIcons.chevronsUpDown,
            size: MinimalIconSize.i16,
            color: t.textTertiary,
          ),
        ),
      ),
      optionBuilder: (context, option, states) => MinimalKitRow(
        states: states,
        label: displayString(option),
        checked: states.chosen,
        start: start,
        style: listStyle,
      ),
      surfaceBuilder: (context, list) => _surface(context, list, listStyle),
      // Words no option fits say so where the rows would stand, quiet.
      // (Its height is the row's: the overlay offers the whole room below.)
      emptyBuilder: (context) => Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: EdgeInsetsDirectional.only(
          start: start,
          end: MinimalSpacing.s8,
          top: MinimalSpacing.s4,
          bottom: MinimalSpacing.s4,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          child: Text(
            MinimalLocalizations.of(context).results(0),
            style: t.bodySmall.c(t.mutedForeground),
          ),
        ),
      ),
    );
  }
}

/// Several choices as tags in one field: labels on an issue, recipients,
/// skills. The chosen values stand as small tags (the quiet fill, a remove
/// cross) in a box that grows a line as they wrap; typing suggests more
/// from [options] in Minimal's panel, and with [onCreate] free text becomes
/// a tag on Enter or a comma (a pasted "a, b, c" makes three).
///
/// Backspace on the empty field (or Left at its start) steps onto the tags;
/// Backspace or Delete on a tag removes it, and a screen reader offers the
/// same as an action. The behaviour is ui_core's ([DesignTagInput]);
/// Minimal paints it. [fieldStyle] dresses the box over
/// `components.textField`; [listStyle] the panel over `components.menu`.
///
/// ```dart
/// MinimalMultiSelect<String>(label: 'Labels', values: labels, options: const ['Bug', 'Design', 'Docs'], onChanged: setLabels)
/// ```
class MinimalMultiSelect<T extends Object> extends StatefulWidget {
  /// A multi-select over [values].
  const MinimalMultiSelect({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.displayString = _text,
    this.onCreate,
    this.maxTags,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.fieldStyle,
    this.listStyle,
    this.focusNode,
    this.autofocus = false,
  });

  /// The chosen values, in order.
  final List<T> values;

  /// Called with the new list as a tag is added or removed.
  final ValueChanged<List<T>> onChanged;

  /// What typing suggests (less what is chosen).
  final Iterable<T> options;

  /// A value's words.
  final String Function(T value) displayString;

  /// Makes a value of free text, or null to refuse it; null takes only
  /// suggestions.
  final T? Function(String text)? onCreate;

  /// The most tags it takes; null for no limit.
  final int? maxTags;

  /// The field's name, over the box.
  final String? label;

  /// What the empty field shows.
  final String? hint;

  /// A quiet line under the box; the [error] replaces it.
  final String? helper;

  /// The message under the box.
  final String? error;

  /// Whether it takes input.
  final bool enabled;

  /// The box's style, over `components.textField`.
  final MinimalStyle? fieldStyle;

  /// The list's panel style, over `components.menu`.
  final MinimalStyle? listStyle;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  State<MinimalMultiSelect<T>> createState() => _MinimalMultiSelectState<T>();
}

class _MinimalMultiSelectState<T extends Object>
    extends State<MinimalMultiSelect<T>> {
  FocusNode? _owned;

  /// The caller's focus node, or one of its own (disposed with it; one
  /// handed in never is).
  FocusNode get _focus =>
      widget.focusNode ??
      (_owned ??= FocusNode(debugLabel: 'MinimalMultiSelect'));

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final label = widget.label;
    // The suggestions open on the box's edges (ui_core opens them from the
    // layout, which draws the box); their words start on the tags' words:
    // the box's rim and inset, a tag's hairline and its leading air.
    final tagBox = MinimalStyleOf([
      widget.fieldStyle,
      t.components.textField,
    ], const {});
    final start = _rowStart(
      context,
      tagBox.rim(t.border, t.rim).width +
          _startOf(tagBox.padding ?? _tagBoxInset, Directionality.of(context)) +
          t.hairline +
          _tagWords,
      widget.listStyle,
    );
    final error = widget.error;
    final message = error ?? widget.helper;

    Widget tag(T value, DesignTagDetails tag) {
      final name = widget.displayString(value);
      final shape = t.shapes.mark;
      return Container(
        height: minimalGrownHeight(context, _tagHeight),
        padding: const EdgeInsetsDirectional.only(
          start: _tagWords,
          end: MinimalSpacing.s2,
        ),
        decoration: minimalFrame(
          shape,
          fill: t.muted,
          side: BorderSide(color: t.border, width: t.hairline),
        ),
        foregroundDecoration: minimalStateLayer(t, shape, {
          if (tag.focused) WidgetState.focused,
        }, ground: minimalGround(context)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: t.caption.medium.c(t.foreground)),
            const MinimalGap(MinimalSpacing.s2),
            if (widget.enabled)
              MinimalPressable(
                onPressed: tag.onDeleted,
                focusable: false,
                semanticLabel: words.removeItem(name),
                shape: MinimalShapes.inset(shape, MinimalSpacing.s2),
                child: SizedBox.square(
                  dimension: _tagHeight - 2 * MinimalSpacing.s2,
                  child: MinimalIcon(
                    LucideIcons.x,
                    size: MinimalIconSize.i14,
                    color: t.mutedForeground,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget group(Widget child) => DesignInputGroup(
      focusNode: _focus,
      enabled: widget.enabled,
      isError: error != null,
      child: child,
      builder: (context, states, child) {
        final so = MinimalStyleOf([
          widget.fieldStyle,
          t.components.textField,
        ], states);
        final shape = so.shape ?? t.shapes.small;
        final within = states.contains(WidgetState.focused);
        final keyboard =
            within &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional;
        return Container(
          constraints: BoxConstraints(
            minHeight:
                so.minimumSize?.height ??
                minimalGrownHeight(
                  context,
                  t.density.height(MinimalChromeMetrics.control),
                ),
          ),
          alignment: AlignmentDirectional.centerStart,
          padding: so.padding ?? _tagBoxInset,
          decoration: minimalFrame(
            shape,
            fill: so.fill ?? (states.off ? t.sunken : t.card),
            side: so.rim(
              states.wrong
                  ? t.destructive
                  : within
                  ? t.ring
                  : t.border,
              t.rim,
            ),
          ),
          foregroundDecoration: minimalFieldRing(
            t,
            shown: keyboard,
            error: states.wrong,
            shape: shape,
          ),
          child: child,
        );
      },
    );

    final input = DesignTagInput<T>(
      values: widget.values,
      onChanged: widget.onChanged,
      options: widget.options,
      displayStringForOption: widget.displayString,
      onCreate: widget.onCreate,
      maxTags: widget.maxTags,
      focusNode: _focus,
      semanticLabel: label,
      deleteLabel: words.remove,
      fieldBuilder: (context, field) {
        Widget text = TextField(
          controller: field.controller,
          focusNode: field.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          onSubmitted: (_) => field.submit(),
          cursorColor: t.primary,
          cursorWidth: MinimalFieldMetrics.cursor,
          style: t.body.c(t.foreground),
          decoration: minimalBareDecoration(
            hint: widget.values.isEmpty ? widget.hint : null,
            hintStyle: t.body.c(t.textTertiary),
          ),
        );
        // The line by its capitals, level with the tags' words beside it.
        text = minimalCapLabel(text);
        // Alone, the entry's words stand where the first tag's will.
        if (widget.values.isEmpty) {
          text = Padding(
            padding: EdgeInsetsDirectional.only(start: t.hairline + _tagWords),
            child: text,
          );
        }
        if (label != null) text = Semantics(label: label, child: text);
        if (Material.maybeOf(context) == null) {
          text = Material(type: MaterialType.transparency, child: text);
        }
        return text;
      },
      optionBuilder: (context, option, states) => MinimalKitRow(
        states: states,
        label: widget.displayString(option),
        start: start,
        style: widget.listStyle,
      ),
      tagBuilder: (context, value, d) => tag(value, d),
      surfaceBuilder: (context, list) =>
          _surface(context, list, widget.listStyle),
      // The box round the tags and the entry: the suggestions open from it.
      layoutBuilder: (context, tags, field) => group(
        Wrap(
          spacing: MinimalSpacing.s4,
          runSpacing: MinimalSpacing.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...tags,
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96, maxWidth: 240),
              child: IntrinsicWidth(child: field),
            ),
          ],
        ),
      ),
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(label, style: t.caption.medium.c(t.foreground)),
          ),
          const MinimalGap(MinimalChromeMetrics.iconGap),
        ],
        MinimalHitTarget(child: input),
        if (message != null) ...[
          const MinimalGap(MinimalChromeMetrics.iconGap),
          Semantics(
            liveRegion: error != null,
            child: Text(
              message,
              style: t.caption.c(
                error != null ? t.destructiveInk : t.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
    return widget.enabled ? column : Opacity(opacity: 0.45, child: column);
  }
}
