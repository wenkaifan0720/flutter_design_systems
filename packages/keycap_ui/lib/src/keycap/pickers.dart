/// Keycap's pickers: [KeycapCombobox] (a field that suggests as it is
/// typed in), [KeycapTagInput] (choices set in the well as small caps),
/// [KeycapChip] (a small key that latches, or carries a remove key),
/// [KeycapDropZone] (a well a file is dropped in) and [KeycapColorPicker].
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'feedback.dart';
import 'select.dart';
import 'text_field.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawColorController;
export 'package:ui_core/ui_core.dart' show DesignOptionSearch;

/// A field's well, as [KeycapTextField] draws it, for [states].
Widget _fieldWell(
  KeycapThemeData theme,
  Set<WidgetState> states,
  KeycapStyle? style, {
  required Widget child,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
}) {
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.textFieldStyle], states);
  final focused = states.contains(WidgetState.focused);
  final wrong = states.contains(WidgetState.error);
  final off = states.contains(WidgetState.disabled);
  return KeycapWell(
    radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
    floor: layered.fill ?? (off ? Color.lerp(c.well, c.ground, 0.6) : null),
    rim: focused
        ? (wrong ? c.dangerInk : c.focus)
        : wrong
        ? c.dangerInk.withValues(alpha: 0.55)
        : null,
    rimWidth: focused ? KeycapMetrics.focusWidth : 1,
    clip: false,
    padding: padding,
    child: child,
  );
}

/// An entry with no well of its own, for a part that draws one round it.
class _BareField extends StatelessWidget {
  const _BareField({
    required this.controller,
    required this.focusNode,
    required this.minHeight,
    required this.enabled,
    required this.onEditingComplete,
    this.hint,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double minHeight;
  final bool enabled;
  final VoidCallback onEditingComplete;
  final String? hint;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final words = theme.textTheme.body.copyWith(
      color: enabled ? c.ink : c.inkDisabled,
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DesignTextEntryBox(
        minHeight: minHeight,
        controller: controller,
        hint: hint == null
            ? null
            : Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: words.copyWith(color: c.inkMuted),
              ),
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: null,
            style: words,
            cursorColor: c.accent.top,
            cursorWidth: 2,
            enabled: enabled,
            onEditingComplete: onEditingComplete,
          ),
        ),
      ),
    );
  }
}

/// The panel an open list of suggestions stands on.
Widget _panel(BuildContext context, Widget list) =>
    KeycapMenuPanel(scroll: false, child: list);

/// A suggestion's row.
Widget _row(
  BuildContext context,
  String label,
  Set<WidgetState> states, {
  required bool chosen,
}) {
  final theme = KeycapTheme.of(context);
  final enabled = !states.contains(WidgetState.disabled);
  return KeycapMenuRow(
    label: label,
    height: theme.controlHeight - KeycapSpacing.tight,
    // On the well's words: the well's inset, less the panel's own.
    inset:
        KeycapSpacing.medium +
        theme.density.paddingDelta / 2 -
        KeycapSpacing.tight,
    chosen: chosen,
    enabled: enabled,
    lit:
        enabled &&
        (states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)),
  );
}

/// Says, in the list's panel, that nothing fits the words typed.
Widget _nothing(BuildContext context, String words) {
  final theme = KeycapTheme.of(context);
  return SizedBox(
    height: theme.controlHeight - KeycapSpacing.tight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          words,
          style: theme.textTheme.body.copyWith(color: theme.colors.inkMuted),
        ),
      ),
    ),
  );
}

/// Says, in the list's panel, that a search is looking.
Widget _looking(BuildContext context) {
  final theme = KeycapTheme.of(context);
  return SizedBox(
    height: theme.controlHeight - KeycapSpacing.tight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
      child: Row(
        children: [
          const ExcludeSemantics(child: KeycapSpinner(size: 16)),
          const SizedBox(width: KeycapSpacing.small),
          Text(
            RawWidgetsLocalizations.of(context).loadingLabel,
            style: theme.textTheme.body.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ),
    ),
  );
}

/// Says, in the list's panel, that a search failed, over a row to try
/// again, lit while the keys are on it.
Widget _failed(BuildContext context, RawSearchError error) {
  final theme = KeycapTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ui_core's node already says the failure.
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KeycapSpacing.medium,
            KeycapSpacing.small,
            KeycapSpacing.medium,
            KeycapSpacing.tight,
          ),
          child: Text(
            words.searchFailedMessage,
            style: theme.textTheme.secondary.copyWith(
              color: theme.colors.dangerInk,
            ),
          ),
        ),
      ),
      // The keys reach it from the field (Down), never by Tab.
      ExcludeFocus(
        child: RawButton(
          onPressed: error.retry,
          semanticLabel: words.retryButtonLabel,
          excludeSemantics: true,
          builder: (context, states, _) => KeycapMenuRow(
            label: words.retryButtonLabel,
            height: theme.controlHeight - KeycapSpacing.tight,
            leading: const Icon(LucideIcons.rotateCw),
            lit:
                error.focused ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed),
          ),
        ),
      ),
    ],
  );
}

/// A field that suggests as it is typed in: the [options] that fit the
/// words (or what [search] finds) open in a panel under it, the lit row a
/// plate inset in the panel, the chosen one ticked. The arrows move the lit
/// row; Enter takes it. Built on ui_core's `RawCombobox`.
///
/// ```dart
/// KeycapCombobox<String>(label: 'Folder', options: const ['Ideas', 'Work', 'Home'], onSelected: move)
/// ```
class KeycapCombobox<T extends Object> extends StatefulWidget {
  /// A combobox over [options] or [search].
  const KeycapCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.onSelected,
    this.value,
    this.displayStringForOption,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.semanticLabel,
    this.emptyLabel,
    this.requireSelection = false,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.style,
  });

  /// What can be chosen.
  final List<T> options;

  /// Looks the words up instead of filtering [options].
  final DesignOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// The option chosen, ticked in the list.
  final T? value;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? label;

  /// What the well says while empty.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// The field's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// What the list says when nothing fits; the kit's "No results" when
  /// null.
  final String? emptyLabel;

  /// Whether leaving the field puts back the chosen option's words.
  final bool requireSelection;

  /// Whether the field takes words.
  final bool enabled;

  /// The words' controller; one you give is yours to dispose.
  final TextEditingController? controller;

  /// The field's focus node.
  final FocusNode? focusNode;

  /// Overrides for the well, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  State<KeycapCombobox<T>> createState() => _KeycapComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _KeycapComboboxState<T extends Object> extends State<KeycapCombobox<T>> {
  FocusNode? _own;

  FocusNode get _focus =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'KeycapCombobox'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(KeycapCombobox<T> old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  String _words(T option) =>
      widget.displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final pad = KeycapSpacing.medium + theme.density.paddingDelta / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: KeycapFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        RawCombobox<T>(
          options: widget.options,
          search: widget.search,
          debounceDuration: widget.debounceDuration,
          loadingBuilder: _looking,
          errorBuilder: _failed,
          value: widget.value,
          onSelected: widget.onSelected,
          displayStringForOption: _words,
          requireSelection: widget.requireSelection,
          highlightFollowsPointer: true,
          controller: widget.controller,
          focusNode: _focus,
          semanticLabel: widget.semanticLabel ?? widget.label,
          surfaceBuilder: _panel,
          emptyBuilder: (context) => _nothing(
            context,
            widget.emptyLabel ??
                RawWidgetsLocalizations.of(context).noResultsLabel,
          ),
          optionBuilder: (context, option, states) => _row(
            context,
            _words(option),
            states,
            chosen: option == widget.value,
          ),
          fieldBuilder: (context, field) => MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            child: _fieldWell(
              theme,
              {
                if (!widget.enabled) WidgetState.disabled,
                if (field.focusNode.hasFocus) WidgetState.focused,
                if (widget.error != null) WidgetState.error,
              },
              widget.style,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: pad),
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: _BareField(
                          controller: field.controller,
                          focusNode: field.focusNode,
                          minHeight: theme.controlHeight,
                          hint: widget.hint,
                          semanticLabel: widget.semanticLabel ?? widget.label,
                          enabled: widget.enabled,
                          onEditingComplete: field.submit,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Icon(
                      LucideIcons.chevronsUpDown,
                      size: 18,
                      color: widget.enabled ? c.inkMuted : c.inkDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        KeycapFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// Choices set in a well as small caps, each with its own remove key, the
/// words typed after them. Suggestions open in a panel under it; Enter (or
/// a comma) takes the lit one, or makes one of the words when [onCreate]
/// does, and the field keeps the focus for the next. Backspace in an empty
/// field removes the last. Built on ui_core's `RawTagInput`.
///
/// ```dart
/// KeycapTagInput<String>(label: 'Tags', values: tags, options: const ['draft', 'work', 'recipe'], onChanged: setTags)
/// ```
class KeycapTagInput<T extends Object> extends StatefulWidget {
  /// A tag input holding [values].
  const KeycapTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.onCreate,
    this.displayStringForOption,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.semanticLabel,
    this.deleteLabel,
    this.maxTags,
    this.enabled = true,
    this.style,
  });

  /// The choices made.
  final List<T> values;

  /// Called with the choices after a change.
  final ValueChanged<List<T>> onChanged;

  /// What can be chosen.
  final List<T> options;

  /// Looks the words up instead of filtering [options].
  final DesignOptionSearch<T>? search;

  /// How long the typing rests before [search] runs.
  final Duration? debounceDuration;

  /// Makes a choice of words that match no option; null: options only.
  final T? Function(String text)? onCreate;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? label;

  /// What the well says while empty.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// The field's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// A remove key's name for a screen reader; the kit's "Delete" when null.
  final String? deleteLabel;

  /// The most choices.
  final int? maxTags;

  /// Whether it takes choices.
  final bool enabled;

  /// Overrides for the well, over [KeycapThemeData.textFieldStyle].
  final KeycapStyle? style;

  @override
  State<KeycapTagInput<T>> createState() => _KeycapTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _KeycapTagInputState<T extends Object> extends State<KeycapTagInput<T>> {
  final FocusNode _focus = FocusNode(debugLabel: 'KeycapTagInput');
  bool _within = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _words(T option) =>
      widget.displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final remove =
        widget.deleteLabel ??
        RawWidgetsLocalizations.of(context).deleteButtonTooltip;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_within) WidgetState.focused,
      if (widget.error != null) WidgetState.error,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: KeycapFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (inside) => setState(() => _within = inside),
          child: RawTagInput<T>(
            values: widget.values,
            onChanged: widget.onChanged,
            options: widget.options,
            search: widget.search,
            debounceDuration: widget.debounceDuration,
            loadingBuilder: _looking,
            errorBuilder: _failed,
            onCreate: widget.onCreate,
            displayStringForOption: _words,
            highlightFollowsPointer: true,
            maxTags: widget.maxTags,
            focusNode: _focus,
            semanticLabel: widget.semanticLabel ?? widget.label,
            deleteLabel: remove,
            surfaceBuilder: _panel,
            optionBuilder: (context, option, states) => _row(
              context,
              _words(option),
              states,
              chosen: widget.values.contains(option),
            ),
            layoutBuilder: (context, tags, field) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.enabled ? _focus.requestFocus : null,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.basic,
                child: _fieldWell(
                  theme,
                  states,
                  widget.style,
                  // A hair above and below: the entry's own box stays a
                  // finger's 44 high inside a 48 field.
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeycapSpacing.small,
                    vertical: KeycapSpacing.hairline,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          theme.controlHeight - 2 * KeycapSpacing.hairline,
                    ),
                    child: Wrap(
                      spacing: KeycapMetrics.keyGap,
                      runSpacing: KeycapMetrics.keyGap,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...tags,
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 96,
                            maxWidth: 240,
                          ),
                          child: IntrinsicWidth(child: field),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            tagBuilder: (context, value, tag) => _TagCap(
              label: _words(value),
              focused: tag.focused,
              enabled: widget.enabled,
              removeLabel: '$remove ${_words(value)}',
              onRemove: widget.enabled ? tag.onDeleted : null,
            ),
            fieldBuilder: (context, field) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KeycapSpacing.tight,
              ),
              child: _BareField(
                controller: field.controller,
                focusNode: field.focusNode,
                minHeight: theme.controlHeight - 2 * KeycapSpacing.hairline,
                hint: widget.values.isEmpty ? widget.hint : null,
                semanticLabel: widget.semanticLabel ?? widget.label,
                enabled: widget.enabled,
                onEditingComplete: field.submit,
              ),
            ),
          ),
        ),
        KeycapFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A choice made, standing in a tag input's well: a small alpha cap with
/// its words and a remove glyph that takes it out.
class _TagCap extends StatelessWidget {
  const _TagCap({
    required this.label,
    required this.focused,
    required this.enabled,
    required this.removeLabel,
    required this.onRemove,
  });

  final String label;
  final bool focused;
  final bool enabled;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final h = KeycapMetrics.grown(context, 32, theme.textTheme.secondary);
    return RawButton(
      onPressed: onRemove,
      semanticLabel: removeLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final face = keycapKeyFace(theme, KeycapKind.alpha, {
          ...states,
          if (focused) WidgetState.focused,
          if (!enabled) WidgetState.disabled,
        }, radius: KeycapMetrics.smallKeyRadius);
        return TapTargetPadding(
          child: SizedBox(
            height: h,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(h),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: KeycapSpacing.small + 2,
                  end: KeycapSpacing.small,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.secondary.copyWith(
                            color: face.legend,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: KeycapSpacing.tight + 2),
                    Icon(LucideIcons.x, size: 14, color: face.legend),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A chip: a small key. With [onSelected] it latches (a filter, a
/// choice): part way down, in the modifier plastic, until pressed again.
/// With [onDeleted] it carries a remove key. A chip with neither is shown
/// only, and is printed rather than moulded (it is not pressed): see
/// [KeycapTag].
///
/// ```dart
/// KeycapChip('Pinned', selected: pinnedOnly, onSelected: (on) => setState(() => pinnedOnly = on))
/// ```
class KeycapChip extends StatelessWidget {
  /// A chip reading [label].
  const KeycapChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.enabled = true,
    this.style,
  });

  /// Its words.
  final String label;

  /// Whether it is latched.
  final bool selected;

  /// Called with its new state when pressed; null: it does not latch.
  final ValueChanged<bool>? onSelected;

  /// Called by its remove key; no remove key when null.
  final VoidCallback? onDeleted;

  /// The remove key's name for a screen reader.
  final String? deleteLabel;

  /// A glyph before the words.
  final IconData? icon;

  /// Whether it takes presses.
  final bool enabled;

  /// Overrides, over [KeycapThemeData.tagStyle].
  final KeycapStyle? style;

  /// A chip's height.
  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final words = RawWidgetsLocalizations.of(context);
    Widget cap(Set<WidgetState> states, {required bool latched}) {
      final layered = DesignStyleOf([style, theme.tagStyle], states);
      var face = keycapKeyFace(
        theme,
        KeycapKind.alpha,
        states,
        latched: latched,
        radius: KeycapMetrics.smallKeyRadius,
      );
      face = layered.on(face);
      final h = KeycapMetrics.grown(
        context,
        layered.minimumSize?.height ?? height,
        theme.textTheme.secondary,
      );
      return SizedBox(
        height: h,
        child: AnimatedKeycapCap(
          face: face,
          walls: KeycapMetrics.walls(h),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: KeycapSpacing.medium,
              end: onDeleted != null
                  ? KeycapSpacing.small
                  : KeycapSpacing.medium,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (latched || icon != null) ...[
                  Icon(
                    latched && icon == null ? LucideIcons.check : icon,
                    size: 16,
                    color: face.legend,
                  ),
                  const SizedBox(width: KeycapSpacing.tight + 2),
                ],
                Flexible(
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.secondary
                          .merge(layered.textStyle)
                          .copyWith(
                            color: face.legend,
                            fontWeight: latched
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: KeycapSpacing.tight),
                  ExcludeSemantics(
                    child: Icon(LucideIcons.x, size: 14, color: face.legend),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (onSelected == null && onDeleted == null) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: cap({if (!enabled) WidgetState.disabled}, latched: selected),
      );
    }
    if (onSelected == null) {
      return RawButton(
        onPressed: enabled ? onDeleted : null,
        semanticLabel: '${deleteLabel ?? words.deleteButtonTooltip} $label',
        excludeSemantics: true,
        builder: (context, states, _) =>
            TapTargetPadding(child: cap(states, latched: selected)),
      );
    }
    final chip = RawButton(
      onPressed: enabled ? () => onSelected!(!selected) : null,
      semanticLabel: label,
      // A button, selected while latched, as a selectable chip is.
      semanticSelected: selected,
      selected: selected,
      excludeSemantics: true,
      builder: (context, states, _) =>
          TapTargetPadding(child: cap(states, latched: selected)),
    );
    if (onDeleted == null) return chip;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        const SizedBox(width: KeycapMetrics.keyGap),
        KeycapIconButton(
          icon: const Icon(LucideIcons.x),
          semanticLabel: '${deleteLabel ?? words.deleteButtonTooltip} $label',
          onPressed: enabled ? onDeleted : null,
          style: const KeycapStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(height)),
            iconSize: WidgetStatePropertyAll(14),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'));
  }
}

/// A well a file is dropped in: cut deeper than a field, a glyph and the
/// words saying what goes in it, and a key to choose one instead. While a
/// file is dragged over it ([active]) its rim lights in the focus band.
/// It draws the well; the app picks or receives the file (a picker on
/// [onPressed], a drop target round it).
///
/// ```dart
/// KeycapDropZone(label: 'Drop an image to attach it', onPressed: pickImage)
/// ```
class KeycapDropZone extends StatelessWidget {
  /// A drop zone.
  const KeycapDropZone({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonLabel = 'Choose a file',
    this.hint,
    this.icon,
    this.active = false,
  });

  /// What goes in it.
  final String label;

  /// Opens a file picker; null turns it off.
  final VoidCallback? onPressed;

  /// The key's words.
  final String buttonLabel;

  /// Smaller words under [label] (the kinds and size it takes).
  final String? hint;

  /// The glyph; an upload arrow when null.
  final IconData? icon;

  /// Whether a file is being dragged over it.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final enabled = onPressed != null;
    return KeycapWell(
      floor: active ? c.wellPressed : null,
      rim: active ? c.focus : null,
      padding: const EdgeInsets.symmetric(
        horizontal: KeycapSpacing.large,
        vertical: KeycapSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon ?? LucideIcons.upload,
              size: 28,
              color: enabled ? c.inkMuted : c.inkDisabled,
            ),
          ),
          const SizedBox(height: KeycapSpacing.medium),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.body.copyWith(
              color: enabled ? c.ink : c.inkDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: KeycapSpacing.tight),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.secondary,
              ),
            ),
          const SizedBox(height: KeycapSpacing.regular),
          KeycapButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('active', value: active, ifTrue: 'active'));
  }
}

/// A colour picked by hand: a square of saturation and brightness in a
/// well, a slot for the hue (and the alpha) under it, each with a small cap
/// riding it. The arrows move each. Built on ui_core's `RawColorPicker`.
///
/// ```dart
/// KeycapColorPicker(controller: RawColorController(const Color(0xFF2F59CF)))
/// ```
class KeycapColorPicker extends StatelessWidget {
  /// A colour picker over [controller].
  const KeycapColorPicker({
    super.key,
    required this.controller,
    this.showAlpha = false,
    this.areaHeight = 160,
  });

  /// The colour.
  final RawColorController controller;

  /// Whether it has an alpha slot.
  final bool showAlpha;

  /// The square's height.
  final double areaHeight;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const inset = KeycapSpacing.tight;
    return RawColorPicker(
      controller: controller,
      showAlpha: showAlpha,
      areaHeight: areaHeight,
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: KeycapSpacing.medium),
            part,
          ],
        ],
      ),
      areaBuilder: (context, area) => KeycapWell(
        rim: area.states.contains(WidgetState.focused) ? c.focus : null,
        padding: const EdgeInsets.all(inset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KeycapMetrics.wellRadius - inset),
          child: CustomPaint(
            painter: _AreaPainter(area.color.hue),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      areaThumbBuilder: (context, area) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: area.color.toColor(),
          border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.45),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      trackBuilder: (context, channel, color) => SizedBox(
        height: 16,
        child: KeycapWell(
          radius: BorderRadius.circular(8),
          padding: const EdgeInsets.all(KeycapSpacing.hairline),
          child: CustomPaint(
            painter: _ChannelPainter(channel, color, rtl: rtl),
            child: const SizedBox.expand(),
          ),
        ),
      ),
      thumbBuilder: (context, states) {
        final face = keycapKeyFace(theme, KeycapKind.alpha, states, radius: 5);
        return SizedBox(
          width: 20,
          height: 30,
          child: AnimatedKeycapCap(
            face: face,
            walls: KeycapMetrics.walls(30),
            child: Center(
              child: SizedBox(
                width: 2,
                height: 10,
                child: ColoredBox(color: face.legend),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('showAlpha', value: showAlpha, ifTrue: 'alpha'),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFFFFF),
              HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
            ],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.hue != hue;
}

class _ChannelPainter extends CustomPainter {
  _ChannelPainter(this.channel, this.color, {required this.rtl});

  final RawColorChannel channel;
  final HSVColor color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colours = switch (channel) {
      RawColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      RawColorChannel.saturation => [
        color.withSaturation(0).toColor(),
        color.withSaturation(1).toColor(),
      ],
      RawColorChannel.brightness => [
        color.withValue(0).toColor(),
        color.withValue(1).toColor(),
      ],
      RawColorChannel.alpha => [
        color.withAlpha(0).toColor(),
        color.withAlpha(1).toColor(),
      ],
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      Paint()
        ..shader = LinearGradient(
          colors: rtl ? colours.reversed.toList() : colours,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ChannelPainter old) =>
      old.channel != channel || old.color != color || old.rtl != rtl;
}
