/// A field that suggests options as you type, and the same field choosing
/// several as tags, painted on ui_core's combobox and tag input.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'feedback.dart';
import 'input.dart';
import 'pressable.dart';

String _text(Object option) => option.toString();

/// The open list's inset inside its card.
const EdgeInsets _cardInset = EdgeInsets.all(MinimalSpacing.s4);

/// Space between the field's hairline and its chips, including wrapped rows.
const EdgeInsets _tagBoxInset = EdgeInsets.all(MinimalSpacing.s4);

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
  final card = MinimalStyleOf([
    style,
    t.components.menu,
  ], const {}).paddingIn(context);
  return _startOf(card ?? _cardInset, Directionality.of(context));
}

/// The leading padding that aligns an option's label with the field value.
double _rowStart(BuildContext context, double value, MinimalStyle? style) =>
    math.max(0, value - _cardStart(context, style));

/// A text field that suggests from [options] as you type: a city, an
/// assignee, a country. The field is a [MinimalTextField] with a chevron at
/// its end; the list opens under it in Minimal's panel of 32 px rows, the
/// chosen value in the full ink at medium weight with a check (the other
/// options muted), and the highlighted row (the keyboard's, or the
/// pointer's) on the muted fill. Words no option fits say so in the panel
/// ("No results").
///
/// Up and Down move the highlight, Enter takes it, Escape hides the list,
/// a tap takes an option; a screen reader hears the highlight and whether
/// the typing found anything. With [requireSelection] it is a searchable
/// select: leaving the field puts back [value]'s text, so it never holds
/// text that is not an option.
///
/// With [search] the options come from a search that may take time and
/// fail (a server's): it runs once typing rests for [debounceDuration],
/// the panel says it is loading (a small spinner and "Loading") while it
/// runs, and a failed one says so with a "Try again" row that Down reaches
/// and Enter or a tap runs, the focus staying in the field; only the
/// latest words' result shows. The behaviour is ui_core's
/// ([RawCombobox]); Minimal paints it.
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
    this.options = const [],
    this.search,
    this.debounceDuration,
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

  /// The options typing filters (case-insensitively, by [displayString]),
  /// when there is no [search].
  final Iterable<T> options;

  /// Finds the options for the words typed, in place of filtering
  /// [options]: a future for a search that takes time, which may fail.
  final DesignOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null runs it at every
  /// letter.
  final Duration? debounceDuration;

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

  /// {@macro minimal.autofocus}
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
    // A loading or failed search's line, where the rows would stand.
    Widget line(Widget lead, String words) => Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: EdgeInsetsDirectional.only(
        start: start,
        end: MinimalSpacing.s8,
        top: MinimalSpacing.s4,
        bottom: MinimalSpacing.s4,
      ),
      child: Row(
        children: [
          lead,
          const MinimalGap(MinimalSpacing.s8),
          Expanded(child: Text(words, style: t.bodySmall.c(t.mutedForeground))),
        ],
      ),
    );
    return RawCombobox<T>(
      options: options,
      search: search,
      debounceDuration: debounceDuration,
      displayStringForOption: displayString,
      value: value,
      onSelected: onSelected,
      // The pointer's row and the keys' are painted alike (the muted fill):
      // one place, which the pointer moves, as in a native menu.
      highlightFollowsPointer: true,
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
        // Enter in onEditingComplete, with no onSubmitted: the field keeps the
        // focus, and Flutter restarts the text input of a field told of a submit
        // that still holds it, which in a browser then takes no typing.
        onEditingComplete: field.submit,
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
        choosing: value != null,
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
      loadingBuilder: (context) => line(
        const MinimalCircularProgressIndicator(size: 14),
        MinimalLocalizations.of(context).loading,
      ),
      // The failure, then "Try again" as a row: lit while the keys are on
      // it (ui_core moves them there on Down), run by Enter or a tap.
      errorBuilder: (context, failed) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(
            MinimalIcon(
              LucideIcons.circleAlert,
              size: MinimalIconSize.i14,
              color: t.mutedForeground,
            ),
            RawWidgetsLocalizations.of(context).searchFailedMessage,
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: failed.retry,
              child: MinimalKitRow(
                states: {if (failed.focused) WidgetState.focused},
                label: MinimalLocalizations.of(context).tryAgain,
                icon: LucideIcons.rotateCw,
                start: start,
                style: listStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(ObjectFlagProperty<DesignOptionSearch<T>>.has('search', search))
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(T option)>.has(
          'displayString',
          displayString,
        ),
      )
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        FlagProperty(
          'requireSelection',
          value: requireSelection,
          ifTrue: 'requireSelection',
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalStyle>(
          'fieldStyle',
          fieldStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalStyle>(
          'listStyle',
          listStyle,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
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
/// same as an action. The behaviour is ui_core's ([RawTagInput]);
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

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  State<MinimalMultiSelect<T>> createState() => _MinimalMultiSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(IterableProperty<T>('options', options))
      ..add(
        ObjectFlagProperty<String Function(T value)>.has(
          'displayString',
          displayString,
        ),
      )
      ..add(
        ObjectFlagProperty<T? Function(String text)>.has('onCreate', onCreate),
      )
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<MinimalStyle>(
          'fieldStyle',
          fieldStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalStyle>(
          'listStyle',
          listStyle,
          defaultValue: null,
        ),
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

class _MinimalMultiSelectState<T extends Object>
    extends State<MinimalMultiSelect<T>> {
  FocusNode? _owned;

  /// The caller's focus node, or one of its own (disposed with it; one
  /// handed in never is).
  FocusNode get _focus =>
      widget.focusNode ??
      (_owned ??= FocusNode(debugLabel: 'MinimalMultiSelect'));

  // A disabled field still lists each tag's Remove action (ui_core's tag
  // input has no disabled state); running it changes nothing.
  void _changed(List<T> values) {
    if (widget.enabled) widget.onChanged(values);
  }

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
    final inset =
        tagBox.rim(t.border, t.rim).width +
        (tagBox.paddingIn(context) ?? _tagBoxInset)
            .resolve(Directionality.of(context))
            .top;
    final height =
        tagBox.minimumSize?.height ??
        minimalGrownHeight(
          context,
          t.density.height(MinimalChromeMetrics.control),
        );
    // A run can grow to the editable line before the nominal control height,
    // especially at 200% text or compact density. Its chips fill that line.
    final entryLine = minimalLineHeight(context, t.body);
    final tagHeight = math.max(
      math.max(entryLine, MinimalIconSize.i14 + 2 * t.hairline),
      height - 2 * inset,
    );
    final start = _rowStart(
      context,
      tagBox.rim(t.border, t.rim).width +
          _startOf(
            tagBox.paddingIn(context) ?? _tagBoxInset,
            Directionality.of(context),
          ) +
          t.hairline +
          _tagWords,
      widget.listStyle,
    );
    final error = widget.error;
    final message = error ?? widget.helper;

    Widget tag(T value, RawTagDetails tag) {
      final name = widget.displayString(value);
      final shape = MinimalShapes.inset(tagBox.shape ?? t.shapes.small, inset);
      return Container(
        height: tagHeight,
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
        // A tap on the tag's rim lands inside, on the part under it: the
        // rim is the remove key's too, not a pixel no tap reaches.
        child: MinimalTapReach(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: t.caption.medium.c(t.foreground)),
              const MinimalGap(MinimalSpacing.s2),
              // The remove key stands the tag's whole height, so the box's
              // air above and below the tag reaches it.
              if (widget.enabled)
                SizedBox(
                  height: tagHeight - 2 * t.hairline,
                  child: MinimalPressable(
                    onPressed: tag.onDeleted,
                    focusable: false,
                    semanticLabel: words.removeItem(name),
                    shape: MinimalShapes.inset(shape, MinimalSpacing.s2),
                    child: SizedBox.square(
                      dimension: MinimalIconSize.i16,
                      child: MinimalIcon(
                        LucideIcons.x,
                        size: MinimalIconSize.i14,
                        color: t.mutedForeground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
        return Container(
          constraints: BoxConstraints(
            minHeight:
                so.minimumSize?.height ??
                minimalGrownHeight(
                  context,
                  t.density.height(MinimalChromeMetrics.control),
                ),
          ),
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
          foregroundDecoration: minimalFocusEdge(
            t,
            shown: within,
            shape: shape,
          ),
          child: MinimalTapReach(
            child: Padding(
              padding: so.paddingIn(context) ?? _tagBoxInset,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: child,
              ),
            ),
          ),
        );
      },
    );

    final input = RawTagInput<T>(
      values: widget.values,
      onChanged: _changed,
      // One place, as the combobox's.
      highlightFollowsPointer: true,
      options: widget.options,
      displayStringForOption: widget.displayString,
      onCreate: widget.onCreate,
      maxTags: widget.maxTags,
      focusNode: _focus,
      semanticLabel: label,
      deleteLabel: words.remove,
      fieldBuilder: (context, field) {
        Widget text = MinimalBareTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          // Enter in onEditingComplete, with no onSubmitted: the field keeps the
          // focus, and Flutter restarts the text input of a field told of a submit
          // that still holds it, which in a browser then takes no typing.
          onEditingComplete: field.submit,
          style: t.body.c(t.foreground),
          hint: widget.values.isEmpty ? widget.hint : null,
          hintStyle: t.body.c(t.mutedForeground),
        );
        // The line by its capitals, level with the tags' words beside it.
        text = minimalCapLabel(text);
        // Alone, the entry's words stand where the first tag's will. The
        // padding stays, at none, once a tag stands before it: a wrapper that
        // came and went would build the field again as the first tag came or
        // the last went, dropping its text input mid-typing.
        text = Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.values.isEmpty ? t.hairline + _tagWords : 0,
          ),
          child: text,
        );
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
      // A tap in the box's air above or below the tags reaches the one
      // under it.
      layoutBuilder: (context, tags, field) => group(
        MinimalTapReach(
          child: Wrap(
            spacing: MinimalSpacing.s4,
            runSpacing: MinimalSpacing.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...tags,
              // The entry's node reaches as far as its outline: a tap past
              // its line lands on it.
              MinimalFieldTarget(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 96,
                    maxWidth: 240,
                  ),
                  child: IntrinsicWidth(child: field),
                ),
              ),
            ],
          ),
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
        // At a finger the field stands in a band as tall as the floor.
        minimalTapStrip(context, input),
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
