/// Appliance's pickers: [ApplianceCombobox] (a well that suggests as you
/// type), [ApplianceTagInput] (choices latched into a well as small keys),
/// [ApplianceChip] (a small key that latches, or one that removes),
/// [ApplianceDropZone] (a tray a file is dropped in) and
/// [ApplianceColorPicker] (a colour window over two faders).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'feedback.dart';
import 'internal/bare_field.dart';
import 'internal/glyphs.dart';
import 'material.dart';
import 'menus.dart';
import 'select.dart';
import 'text_field.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show DesignColorController;
export 'package:ui_core/ui_core.dart' show DesignOptionSearch;

/// A well's face in [states], as a text field draws it.
ApplianceFace _wellFace(
  ApplianceColors c,
  Set<WidgetState> states, {
  bool error = false,
}) {
  final disabled = states.contains(WidgetState.disabled);
  return ApplianceFace.well(c).copyWith(
    lift: disabled ? -0.5 : -1,
    edge: error ? c.danger : null,
    focus: states.contains(WidgetState.focused)
        ? (error ? c.danger : c.focus)
        : c.focus.withValues(alpha: 0),
  );
}

/// The plate an open list of suggestions stands on.
Widget _plate(BuildContext context, Widget list) =>
    ApplianceMenuPlate(scroll: false, child: list);

/// A suggestion's row with its words on the field's: the plate's inset and
/// the row's padding come to the well's ([ApplianceSpacing.medium]).
const ApplianceStyle _onTheWords = ApplianceStyle(
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(
      horizontal: ApplianceSpacing.medium - ApplianceSpacing.tight,
    ),
  ),
);

/// Says, in the list's own plate, that nothing fits the words typed.
Widget _nothing(BuildContext context, String words) {
  final theme = ApplianceTheme.of(context);
  return SizedBox(
    height: theme.controlHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: ApplianceSpacing.medium),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          words,
          style: theme.textTheme.body.copyWith(color: theme.colors.printMuted),
        ),
      ),
    ),
  );
}

/// Says, in the list's plate, that a search is looking: a small ring
/// turning beside the words. ui_core reads it as the loading word.
Widget _looking(BuildContext context) {
  final theme = ApplianceTheme.of(context);
  return SizedBox(
    height: theme.controlHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: ApplianceSpacing.medium),
      child: Row(
        children: [
          const ApplianceProgressRing(
            size: ApplianceSpacing.regular,
            stroke: ApplianceSpacing.nudge,
          ),
          const SizedBox(width: ApplianceSpacing.small),
          Text(
            DesignLocalizations.of(context).loadingLabel,
            style: theme.textTheme.body.copyWith(
              color: theme.colors.printMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Says, in the list's plate, that a search failed, over a row to try
/// again: the list's one row, lit while the keys are on it.
Widget _failed(BuildContext context, DesignSearchError error) {
  final words = DesignLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ui_core's node already says the failure.
      ExcludeSemantics(child: _nothing(context, words.searchFailedMessage)),
      // The keys reach it from the field (Down), never by Tab.
      ExcludeFocus(
        child: DesignPressable(
          onPressed: error.retry,
          semanticLabel: words.retryButtonLabel,
          excludeSemantics: true,
          builder: (context, states, _) => ApplianceMenuRow(
            style: _onTheWords,
            label: words.retryButtonLabel,
            states: {...states, if (error.focused) WidgetState.focused},
          ),
        ),
      ),
    ],
  );
}

/// A combobox: a well that suggests as you type. The suggestions open on a
/// plate under it, the one chosen with its lamp lit; the pointer and the
/// arrows light the same row; Enter takes it and the field keeps the focus.
///
/// [options] are filtered by the words; [search] looks them up instead (it
/// may be async: [debounceDuration] lets the typing rest first; while it
/// looks the plate says so, and when it fails the plate says that with a
/// row to try again). [requireSelection] puts back the chosen option's words
/// when the field is left on something else.
///
/// ```dart
/// ApplianceCombobox<String>(label: 'Town', options: const ['Leith', 'Portobello'], onSelected: (town) {})
/// ```
class ApplianceCombobox<T extends Object> extends StatefulWidget {
  /// A combobox over [options].
  const ApplianceCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.value,
    this.onSelected,
    this.displayStringForOption,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.semanticLabel,
    this.emptyLabel = 'Nothing matches',
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

  /// The option chosen, its lamp lit in the list.
  final T? value;

  /// Called with the option chosen.
  final ValueChanged<T>? onSelected;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? label;

  /// What the well says while it is empty.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// The field's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// What the list says when nothing fits the words.
  final String emptyLabel;

  /// Whether leaving the field puts back the chosen option's words.
  final bool requireSelection;

  /// Whether the field takes words.
  final bool enabled;

  /// The words' controller; one you give is yours to dispose.
  final TextEditingController? controller;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceCombobox<T>> createState() => _ApplianceComboboxState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _ApplianceComboboxState<T extends Object>
    extends State<ApplianceCombobox<T>> {
  FocusNode? _own;

  FocusNode get _focus =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'ApplianceCombobox'));

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(ApplianceCombobox<T> old) {
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final error = widget.error != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: ApplianceFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        DesignCombobox<T>(
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
          surfaceBuilder: _plate,
          emptyBuilder: (context) => _nothing(context, widget.emptyLabel),
          optionBuilder: (context, option, states) => ApplianceMenuRow(
            style: _onTheWords,
            label: _words(option),
            states: states,
            chosen: option == widget.value,
          ),
          fieldBuilder: (context, field) {
            final states = <WidgetState>{
              if (!widget.enabled) WidgetState.disabled,
              if (field.focusNode.hasFocus) WidgetState.focused,
              if (error) WidgetState.error,
            };
            final layered = DesignStyleOf([
              widget.style,
              theme.textFieldStyle,
            ], states);
            return MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.basic,
              child: AnimatedApplianceSurface(
                face: layered.on(_wellFace(c, states, error: error)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.medium,
                  ),
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: ApplianceBareField(
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
            );
          },
        ),
        ApplianceFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A tag input: the choices made stand in the well as small keys, each with
/// its own remove key, the words typed after them. Suggestions open on a
/// plate under it; Enter (or a comma) takes the lit one, or what was typed
/// when [onCreate] makes one of it, and the field keeps the focus for the
/// next. Backspace in an empty field removes the last.
///
/// ```dart
/// ApplianceTagInput<String>(label: 'Rooms', values: const ['Kitchen'], options: const ['Kitchen', 'Hall', 'Garden'], onChanged: (rooms) {})
/// ```
class ApplianceTagInput<T extends Object> extends StatefulWidget {
  /// A tag input holding [values].
  const ApplianceTagInput({
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

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// Makes a choice of words typed that match no option; null: only options.
  final T? Function(String text)? onCreate;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? label;

  /// What the well says while it is empty.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// The field's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// A remove key's name for a screen reader; "Remove" otherwise.
  final String? deleteLabel;

  /// The most choices.
  final int? maxTags;

  /// Whether it takes choices.
  final bool enabled;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceTagInput<T>> createState() => _ApplianceTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _ApplianceTagInputState<T extends Object>
    extends State<ApplianceTagInput<T>> {
  final FocusNode _focus = FocusNode(debugLabel: 'ApplianceTagInput');
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final error = widget.error != null;
    final states = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (_within) WidgetState.focused,
      if (error) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.textFieldStyle], states);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: ApplianceFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (inside) => setState(() => _within = inside),
          child: DesignTagInput<T>(
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
            deleteLabel: widget.deleteLabel,
            surfaceBuilder: _plate,
            optionBuilder: (context, option, states) => ApplianceMenuRow(
              style: _onTheWords,
              label: _words(option),
              states: states,
              chosen: widget.values.contains(option),
            ),
            layoutBuilder: (context, tags, field) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              // The tags and the entry say what they are; the box's tap
              // only focuses the entry (as a button it took their names).
              excludeFromSemantics: true,
              onTap: widget.enabled ? _focus.requestFocus : null,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.text
                    : SystemMouseCursors.basic,
                child: AnimatedApplianceSurface(
                  face: layered.on(_wellFace(c, states, error: error)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: theme.controlHeight),
                    // A row of tags is a finger's reach high (the keys
                    // drawn smaller in it), so the well's inset is the rest.
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ApplianceSpacing.small,
                        vertical: ApplianceSpacing.nudge,
                      ),
                      child: Wrap(
                        spacing: ApplianceSpacing.small,
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
            ),
            tagBuilder: (context, value, tag) => _TagKey(
              label: _words(value),
              focused: tag.focused,
              enabled: widget.enabled,
              removeLabel: '${widget.deleteLabel ?? 'Remove'} ${_words(value)}',
              onRemove: widget.enabled ? tag.onDeleted : null,
            ),
            fieldBuilder: (context, field) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ApplianceSpacing.tight,
              ),
              child: ApplianceBareField(
                controller: field.controller,
                focusNode: field.focusNode,
                minHeight: theme.controlHeight - 2 * ApplianceSpacing.nudge,
                hint: widget.values.isEmpty ? widget.hint : null,
                semanticLabel: widget.semanticLabel ?? widget.label,
                enabled: widget.enabled,
                onEditingComplete: field.submit,
              ),
            ),
          ),
        ),
        ApplianceFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A choice latched into a tag input's well: a small key with its words and
/// a remove key.
class _TagKey extends StatelessWidget {
  const _TagKey({
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
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final face = ApplianceFace.key(c, radius: ApplianceMetrics.smallKeyRadius)
        .copyWith(
          lift: enabled ? 0.8 : 0.35,
          foreground: enabled ? c.print : c.printDisabled,
          focus: focused ? c.focus : c.focus.withValues(alpha: 0),
        );
    // The row is a finger's reach high, the key drawn in its middle, so the
    // remove key reaches the row's whole height.
    final row = theme.controlHeight - 2 * ApplianceSpacing.nudge;
    final inset = ApplianceSpacing.small - ApplianceSpacing.nudge;
    return SizedBox(
      height: row,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Positioned.fill(
            top: inset,
            bottom: inset,
            child: AnimatedApplianceSurface(
              face: face,
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: ApplianceSpacing.medium,
              end: ApplianceSpacing.tight,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    style: theme.textTheme.secondary.copyWith(
                      color: face.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.tight),
                DesignPressable(
                  onPressed: onRemove,
                  semanticLabel: removeLabel,
                  excludeSemantics: true,
                  builder: (context, states, _) => DesignTapTarget(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CustomPaint(
                        painter: ApplianceCrossPainter(
                          states.contains(WidgetState.pressed)
                              ? c.print
                              : enabled
                              ? c.printMuted
                              : c.printDisabled,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip: a small key. With [onSelected] it latches (a filter, a choice):
/// down, its lamp lit, until pressed again. With [onDeleted] it carries a
/// remove key (a choice made, a recipient). A chip with neither is shown
/// only.
///
/// ```dart
/// ApplianceChip('In stock', selected: true, onSelected: (on) {})
/// ```
class ApplianceChip extends StatelessWidget {
  /// A chip reading [label].
  const ApplianceChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.enabled = true,
    this.deleteLabel,
    this.icon,
    this.style,
  });

  /// Its words.
  final String label;

  /// Whether it is latched down.
  final bool selected;

  /// Called with its new state when pressed; null: it does not latch.
  final ValueChanged<bool>? onSelected;

  /// Removes it; null: no remove key.
  final VoidCallback? onDeleted;

  /// The remove key's name for a screen reader; "Remove [label]" otherwise.
  final String? deleteLabel;

  /// A glyph before the words.
  final Widget? icon;

  /// Its style, over [ApplianceThemeData.chipStyle].
  final ApplianceStyle? style;

  /// Whether a chip that latches takes presses; off, it shows disabled at
  /// the same size.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight - ApplianceSpacing.regular;
    final latches = onSelected != null;
    Widget body(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.chipStyle], states);
      final down =
          (latches && selected) || states.contains(WidgetState.pressed);
      final disabled = states.contains(WidgetState.disabled);
      final face = layered.on(
        (down
                ? ApplianceFace.keyDown(c, radius: height / 2)
                : ApplianceFace.key(c, radius: height / 2))
            .copyWith(
              lift: disabled && !down ? 0.35 : null,
              foreground: disabled ? c.printDisabled : c.print,
              focus: states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
            ),
      );
      final content = Padding(
        padding: EdgeInsetsDirectional.only(
          start: ApplianceSpacing.medium,
          end: onDeleted != null
              ? ApplianceSpacing.tight
              : ApplianceSpacing.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (latches) ...[
              ApplianceLamp(
                lit: selected && !disabled,
                size: ApplianceMetrics.lampSize - 2,
              ),
              const SizedBox(width: ApplianceSpacing.small),
            ],
            if (icon != null) ...[
              IconTheme.merge(
                data: IconThemeData(size: 16, color: face.foreground),
                child: icon!,
              ),
              const SizedBox(width: ApplianceSpacing.small),
            ],
            DesignCapCenter(
              capHeightFactor: theme.capHeightFactor,
              child: Text(
                label,
                maxLines: 1,
                style: layered.text(
                  theme.textTheme.secondary.copyWith(color: face.foreground),
                ),
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: ApplianceSpacing.tight),
              DesignPressable(
                onPressed: onDeleted,
                semanticLabel: deleteLabel ?? 'Remove $label',
                excludeSemantics: true,
                builder: (context, s, _) => DesignTapTarget(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CustomPaint(
                      painter: ApplianceCrossPainter(
                        s.contains(WidgetState.pressed)
                            ? c.print
                            : c.printMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      if (onDeleted == null) {
        return SizedBox(
          height: height,
          child: AnimatedApplianceSurface(face: face, child: content),
        );
      }
      // A remove key reaches a finger's height: the chip stands in a row that
      // tall, its face drawn in the middle (as a tag in a tag input's well).
      final row = theme.controlHeight - 2 * ApplianceSpacing.nudge;
      final inset = (row - height) / 2;
      return SizedBox(
        height: row,
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Positioned.fill(
              top: inset,
              bottom: inset,
              child: AnimatedApplianceSurface(
                face: face,
                child: const SizedBox.expand(),
              ),
            ),
            content,
          ],
        ),
      );
    }

    if (!latches) {
      return Semantics(
        container: true,
        label: label,
        child: ExcludeSemantics(
          excluding: onDeleted == null,
          child: body(const {}),
        ),
      );
    }
    return DesignPressable(
      onPressed: enabled ? () => onSelected!(!selected) : null,
      selected: selected,
      toggled: selected,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => DesignTapTarget(child: body(states)),
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

/// A tray a file is dropped in: sunk deep into the panel, a glyph and the
/// words saying what goes in it, and a key to choose one instead. While a
/// file is dragged over it ([active]) its lamp lights and its rim glows in
/// the signal colour.
///
/// It draws the tray; the app picks or receives the file (a file picker on
/// [onPressed], a drop target round it).
///
/// ```dart
/// ApplianceDropZone(label: 'Drop a photo of the receipt', buttonLabel: 'Choose a file', onPressed: () {})
/// ```
class ApplianceDropZone extends StatelessWidget {
  /// A tray asking for [label].
  const ApplianceDropZone({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonLabel = 'Choose a file',
    this.hint,
    this.icon,
    this.active = false,
    this.style,
  });

  /// What goes in it.
  final String label;

  /// Chooses a file; null disables the tray.
  final VoidCallback? onPressed;

  /// The key's legend.
  final String buttonLabel;

  /// What it takes ("PNG or JPG, up to 10 MB").
  final String? hint;

  /// A glyph over the words.
  final Widget? icon;

  /// Whether a file is being dragged over it.
  final bool active;

  /// Its style, over [ApplianceThemeData.panelStyle]: fill (the tray).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).panelStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final enabled = onPressed != null;
    return ApplianceSurface(
      face:
          ApplianceFace.well(
            c,
            radius: ApplianceMetrics.panelRadius,
            fill: look.fill ?? c.trough,
          ).copyWith(
            lift: -1.4,
            edge: active ? c.signal : null,
            focus: active ? c.signal : c.signal.withValues(alpha: 0),
          ),
      child: Padding(
        padding: const EdgeInsets.all(ApplianceSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApplianceLamp(lit: active),
                if (icon != null) ...[
                  const SizedBox(width: ApplianceSpacing.small),
                  IconTheme.merge(
                    data: IconThemeData(
                      size: 24,
                      color: enabled ? c.printMuted : c.printDisabled,
                    ),
                    child: icon!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: ApplianceSpacing.small),
            Text(
              label,
              textAlign: TextAlign.center,
              style: t.body.copyWith(
                color: enabled ? c.print : c.printDisabled,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: ApplianceSpacing.tight),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: t.secondary.copyWith(
                  color: enabled ? c.printMuted : c.printDisabled,
                ),
              ),
            ],
            const SizedBox(height: ApplianceSpacing.regular),
            DesignPressable(
              onPressed: onPressed,
              semanticLabel: buttonLabel,
              excludeSemantics: true,
              builder: (context, states, _) {
                final face = ApplianceFace.key(c).copyWith(
                  lift: !enabled
                      ? 0.35
                      : states.contains(WidgetState.pressed)
                      ? -0.7
                      : 1,
                  travel: states.contains(WidgetState.pressed) ? 1 : 0,
                  foreground: enabled ? c.print : c.printDisabled,
                  focus: states.contains(WidgetState.focused)
                      ? c.focus
                      : c.focus.withValues(alpha: 0),
                );
                return DesignTapTarget(
                  child: SizedBox(
                    height: theme.controlHeight,
                    child: AnimatedApplianceSurface(
                      face: face,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ApplianceSpacing.large,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: DesignCapCenter(
                            capHeightFactor: theme.capHeightFactor,
                            child: Text(
                              buttonLabel,
                              style: t.label.copyWith(color: face.foreground),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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

/// The saturation and brightness of a hue, painted.
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

/// A channel's run of colour, painted.
class _ChannelPainter extends CustomPainter {
  _ChannelPainter(this.channel, this.color, {required this.rtl});

  final DesignColorChannel channel;
  final HSVColor color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colours = switch (channel) {
      DesignColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      DesignColorChannel.saturation => [
        color.withSaturation(0).toColor(),
        color.withSaturation(1).toColor(),
      ],
      DesignColorChannel.brightness => [
        color.withValue(0).toColor(),
        color.withValue(1).toColor(),
      ],
      DesignColorChannel.alpha => [
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

/// A colour picker: the colour's window (saturation across, brightness
/// down) behind smoked glass, a ring marking the colour, and faders for its
/// hue (and, with [showAlpha], how solid it is) under it.
///
/// ```dart
/// ApplianceColorPicker(controller: DesignColorController(const Color(0xFFEE6A26)))
/// ```
class ApplianceColorPicker extends StatelessWidget {
  /// A picker for [controller]'s colour.
  const ApplianceColorPicker({
    super.key,
    required this.controller,
    this.showAlpha = false,
    this.areaHeight = 160,
    this.style,
  });

  /// The colour; yours to dispose.
  final DesignColorController controller;

  /// Whether a fader sets how solid it is.
  final bool showAlpha;

  /// The window's height.
  final double areaHeight;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DesignColorPicker(
      controller: controller,
      showAlpha: showAlpha,
      areaHeight: areaHeight,
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: ApplianceSpacing.medium),
            part,
          ],
        ],
      ),
      areaBuilder: (context, area) => ApplianceSurface(
        face:
            ApplianceFace.well(
              c,
              radius: ApplianceMetrics.wellRadius,
              fill: look.fill ?? c.display,
            ).copyWith(
              focus: area.states.contains(WidgetState.focused)
                  ? c.focus
                  : c.focus.withValues(alpha: 0),
            ),
        child: Padding(
          padding: const EdgeInsets.all(ApplianceMetrics.capInset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ApplianceMetrics.wellRadius - ApplianceMetrics.capInset,
            ),
            child: CustomPaint(
              painter: _AreaPainter(area.color.hue),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      areaThumbBuilder: (context, area) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: area.color.toColor(),
          border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
          boxShadow: [
            BoxShadow(
              color: c.shade.withValues(alpha: 0.4),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      trackBuilder: (context, channel, color) => SizedBox(
        height: 14,
        child: CustomPaint(painter: _ChannelPainter(channel, color, rtl: rtl)),
      ),
      thumbBuilder: (context, states) {
        final focused = states.contains(WidgetState.focused);
        return SizedBox(
          width: 20,
          height: 28,
          child: ApplianceSurface(
            face: ApplianceFace.key(c, radius: ApplianceSpacing.tight).copyWith(
              lift: states.contains(WidgetState.pressed) ? 0.6 : 1,
              focus: focused ? c.focus : c.focus.withValues(alpha: 0),
            ),
            child: Center(
              child: Container(width: 2, height: 12, color: c.print),
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
