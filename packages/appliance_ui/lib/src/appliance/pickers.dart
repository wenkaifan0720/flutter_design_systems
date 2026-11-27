/// Appliance's pickers: [ApplianceCombobox] (a well that suggests as you
/// type), [ApplianceTagInput] (choices latched into a well as small keys),
/// [ApplianceChip] (a small key that latches, or one that removes),
/// [ApplianceDropZone] (a tray a file is dropped in) and
/// [ApplianceColorPicker] (a colour window over two faders).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'feedback.dart';
import 'internal/bare_field.dart';
import 'internal/glyphs.dart';
import 'internal/control_light.dart';
import 'material.dart';
import 'menus.dart';
import 'select.dart';
import 'theme.dart';
import 'internal/field_frame.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show RawColorController;
export 'package:ui_core/ui_core.dart' show RawOptionSearch;

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
            RawWidgetsLocalizations.of(context).loadingLabel,
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
Widget _failed(BuildContext context, RawSearchError error) {
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // ui_core's node already says the failure.
      ExcludeSemantics(child: _nothing(context, words.searchFailedMessage)),
      // The keys reach it from the field (Down), never by Tab.
      ExcludeFocus(
        child: RawButton(
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

/// A combobox: a well that suggests as you type, the select's up-and-down
/// legend at its end. The suggestions open on a plate under it, the one
/// chosen with its lamp lit; the pointer and the arrows light the same row;
/// Enter takes it and the field keeps the focus.
///
/// [options] are filtered by the words; [search] looks them up instead (it
/// may be async: [debounceDuration] lets the typing rest first; while it
/// looks the plate says so, and when it fails the plate says that with a
/// row to try again). [requireSelection] puts back the chosen option's words
/// when the field is left on something else.
///
/// ```dart
/// ApplianceCombobox<String>(labelText: 'Town', options: const ['Leith', 'Portobello'], onSelected: (town) {})
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
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
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
  final RawOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// The option chosen, its lamp lit in the list.
  final T? value;

  /// Called with the option chosen.
  final ValueChanged<T>? onSelected;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? labelText;

  /// What the well says while it is empty.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// The field's name for a screen reader, when [labelText] is not shown.
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
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
    final error = widget.errorText != null;
    return applianceFieldFrame(
      labelText: widget.labelText,
      semanticLabel: widget.semanticLabel,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.enabled,
      control: RawCombobox<T>(
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
        semanticLabel: widget.semanticLabel ?? widget.labelText,
        surfaceBuilder: _plate,
        emptyBuilder: (context) => _nothing(context, widget.emptyLabel),
        optionBuilder: (context, option, states) => ApplianceMenuRow(
          style: _onTheWords,
          label: _words(option),
          states: states,
          selected: option == widget.value,
        ),
        fieldBuilder: (context, field) {
          final states = <WidgetState>{
            if (!widget.enabled) WidgetState.disabled,
            if (field.focusNode.hasFocus) WidgetState.focused,
            if (error) WidgetState.error,
          };
          final layered = RawStyleOf([
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
                padding: const EdgeInsetsDirectional.only(
                  start: ApplianceSpacing.medium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RawCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: ApplianceBareField(
                          controller: field.controller,
                          focusNode: field.focusNode,
                          minHeight: theme.controlHeight,
                          hint: widget.hintText,
                          semanticLabel:
                              widget.semanticLabel ?? widget.labelText,
                          expanded: field.isOpen,
                          enabled: widget.enabled,
                          onEditingComplete: field.submit,
                        ),
                      ),
                    ),
                    _ListLegend(field: field, enabled: widget.enabled),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The select's up-and-down legend at the end of a combobox's well: it says
/// the well opens a list, and a press on it opens the list as a press on
/// the words does. The well's own node is the one a screen reader uses.
class _ListLegend extends StatelessWidget {
  const _ListLegend({required this.field, required this.enabled});

  final RawComboboxField field;
  final bool enabled;

  void _open(BuildContext context) {
    if (!field.focusNode.hasFocus) {
      field.focusNode.requestFocus();
      return;
    }
    // A closed list opens without moving its highlight.
    Actions.maybeInvoke<Intent>(context, const AutocompleteNextOptionIntent());
  }

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _open(context) : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: ApplianceSpacing.small,
            end: ApplianceSpacing.medium,
          ),
          child: CustomPaint(
            size: ApplianceUpDownPainter.size,
            painter: ApplianceUpDownPainter(
              enabled ? c.printMuted : c.printDisabled,
            ),
          ),
        ),
      ),
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
/// ApplianceTagInput<String>(labelText: 'Rooms', values: const ['Kitchen'], options: const ['Kitchen', 'Hall', 'Garden'], onChanged: (rooms) {})
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
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.semanticLabel,
    this.deleteLabel,
    this.maxTags,
    this.style,
  });

  /// The choices made.
  final List<T> values;

  /// Called with the choices after a change; null puts it out of use.
  final ValueChanged<List<T>>? onChanged;

  /// What can be chosen.
  final List<T> options;

  /// Looks the words up instead of filtering [options].
  final RawOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null runs it at once.
  final Duration? debounceDuration;

  /// Makes a choice of words typed that match no option; null: only options.
  final T? Function(String text)? onCreate;

  /// An option's words; `toString` otherwise.
  final String Function(T option)? displayStringForOption;

  /// The words over the well.
  final String? labelText;

  /// What the well says while it is empty.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// The field's name for a screen reader, when [labelText] is not shown.
  final String? semanticLabel;

  /// A remove key's name for a screen reader; "Remove" otherwise.
  final String? deleteLabel;

  /// The most choices.
  final int? maxTags;

  /// The well's style, over [ApplianceThemeData.textFieldStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceTagInput<T>> createState() => _ApplianceTagInputState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
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

  bool get _enabled => widget.onChanged != null;

  void _keep(List<T> values) {}

  String _words(T option) =>
      widget.displayStringForOption?.call(option) ?? option.toString();

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final error = widget.errorText != null;
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_within) WidgetState.focused,
      if (error) WidgetState.error,
    };
    final layered = RawStyleOf([widget.style, theme.textFieldStyle], states);
    return applianceFieldFrame(
      labelText: widget.labelText,
      semanticLabel: widget.semanticLabel,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: _enabled,
      control: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (inside) => setState(() => _within = inside),
        child: RawTagInput<T>(
          values: widget.values,
          onChanged: _enabled ? widget.onChanged! : _keep,
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
          semanticLabel: widget.semanticLabel ?? widget.labelText,
          deleteLabel: widget.deleteLabel,
          surfaceBuilder: _plate,
          optionBuilder: (context, option, states) => ApplianceMenuRow(
            style: _onTheWords,
            label: _words(option),
            states: states,
            selected: widget.values.contains(option),
          ),
          layoutBuilder: (context, tags, field) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The tags and the entry say what they are; the box's tap
            // only focuses the entry (as a button it took their names).
            excludeFromSemantics: true,
            onTap: _enabled ? _focus.requestFocus : null,
            child: MouseRegion(
              cursor: _enabled
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.basic,
              child: AnimatedApplianceSurface(
                face: layered.on(_wellFace(c, states, error: error)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: theme.controlHeight),
                  // A run of tags is the field's row high, never under the
                  // touch floor (the keys drawn smaller in it), so the
                  // well's inset is the rest.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ApplianceSpacing.small,
                      vertical: ApplianceSpacing.nudge,
                    ),
                    child: RawChipGroup(
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
            enabled: _enabled,
            removeLabel: '${widget.deleteLabel ?? 'Remove'} ${_words(value)}',
            onRemove: _enabled ? tag.onDeleted : null,
          ),
          fieldBuilder: (context, field) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ApplianceSpacing.tight,
            ),
            child: ApplianceBareField(
              controller: field.controller,
              focusNode: field.focusNode,
              minHeight: _tagRow(context, theme),
              hint: widget.values.isEmpty ? widget.hintText : null,
              semanticLabel: widget.semanticLabel ?? widget.labelText,
              expanded: field.isOpen,
              enabled: _enabled,
              onEditingComplete: field.submit,
            ),
          ),
        ),
      ),
    );
  }
}

/// A run of tags' height: the field's row (its height less a hairline pair
/// above and below), never under the touch floor, so a tag's remove key
/// reaches a finger's whole run.
double _tagRow(BuildContext context, ApplianceThemeData theme) => math.max(
  theme.controlHeight - 2 * ApplianceSpacing.nudge,
  RawTapTargets.of(context).touch.height,
);

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
    final key = ApplianceFace.key(
      c,
      radius: ApplianceMetrics.wellRadius - ApplianceSpacing.small,
    );
    final face = (enabled ? key.copyWith(lift: 0.8) : key.asDisabled(c))
        .copyWith(
          foreground: enabled ? c.print : c.printDisabled,
          focus: focused ? c.focus : c.focus.withValues(alpha: 0),
        );
    // The key is drawn in the run's middle, as far in from the well's top as
    // from its start, and the remove key reaches the run's whole height.
    final row = _tagRow(context, theme);
    const inset = ApplianceSpacing.small - ApplianceSpacing.nudge;
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
                RawCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    style: theme.textTheme.secondary.copyWith(
                      color: face.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.tight),
                RawButton(
                  onPressed: onRemove,
                  semanticLabel: removeLabel,
                  excludeSemantics: true,
                  builder: (context, states, _) => TapTargetPadding(
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

/// A chip: a small key. Given [selected] or [onSelected] it latches (a
/// filter, a choice), as a `FilterChip` does: down, its lamp lit, until
/// pressed again; with [selected] given and a null [onSelected] it is out of
/// use and keeps its state. With [onDeleted] it carries a remove key (a
/// choice made, a recipient). A chip with no [selected] and no [onSelected]
/// is shown only, as a `Chip` is.
///
/// ```dart
/// ApplianceChip('In stock', selected: true, onSelected: (on) {})
/// ```
class ApplianceChip extends StatelessWidget {
  /// A chip reading [label].
  const ApplianceChip(
    this.label, {
    super.key,
    this.selected,
    this.onSelected,
    this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.style,
  });

  /// Its words.
  final String label;

  /// Whether it is latched down, whether or not it takes presses; null: a
  /// chip that does not latch, unless [onSelected] is given (then up).
  final bool? selected;

  /// Called with its new state when pressed; null: it takes no presses (a
  /// chip given [selected] is out of use, keeping its state; any other is
  /// shown only).
  final ValueChanged<bool>? onSelected;

  /// Removes it; null: no remove key.
  final VoidCallback? onDeleted;

  /// The remove key's name for a screen reader; "Remove [label]" otherwise.
  final String? deleteLabel;

  /// A glyph before the words.
  final Widget? icon;

  /// Its style, over [ApplianceThemeData.chipStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    // A chip's face holds its words whole as the text grows.
    final words = TextPainter(
      text: TextSpan(
        text: label,
        style: RawStyleOf([
          style,
          theme.chipStyle,
        ], const {}).text(theme.textTheme.secondary),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = math.max(
      theme.controlHeight - ApplianceSpacing.regular,
      words.height + 2 * ApplianceSpacing.tight,
    );
    words.dispose();
    // A chip given its state keeps its latched key even when it takes no
    // presses.
    final latches = onSelected != null || this.selected != null;
    final selected = this.selected ?? false;
    Widget body(Set<WidgetState> states) {
      final layered = RawStyleOf([style, theme.chipStyle], states);
      final down =
          (latches && selected) || states.contains(WidgetState.pressed);
      final disabled = states.contains(WidgetState.disabled);
      final base = down
          ? ApplianceFace.keyDown(c, radius: height / 2)
          : ApplianceFace.key(c, radius: height / 2);
      final face = layered.on(
        (disabled && !down ? base.asDisabled(c) : base).copyWith(
          foreground: disabled ? c.printDisabled : c.print,
          // Focus lights a latching chip's bezel, selected or not: the
          // lamp means selected, and a half-lit lamp would read as half
          // selected.
          focus: applianceLitFocus(c, states, lit: latches && !disabled),
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
              // Out of use, a selected chip's lamp stays lit in the disabled
              // print, as a radio's does.
              ApplianceControlLamp(
                lit: selected,
                states: states.difference(const {WidgetState.focused}),
                size: ApplianceMetrics.lampSize - 2,
                color: disabled ? c.printDisabled : null,
              ),
              const SizedBox(width: ApplianceSpacing.small),
            ],
            if (icon != null) ...[
              // The glyph grows with the words beside it.
              IconTheme.merge(
                data: IconThemeData(
                  size: MediaQuery.textScalerOf(context).scale(16),
                  color: face.foreground,
                ),
                child: icon!,
              ),
              const SizedBox(width: ApplianceSpacing.small),
            ],
            RawCapCenter(
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
              RawButton(
                onPressed: onDeleted,
                semanticLabel: deleteLabel ?? 'Remove $label',
                excludeSemantics: true,
                builder: (context, s, _) => TapTargetPadding(
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
      final row = math.max(
        theme.controlHeight - 2 * ApplianceSpacing.nudge,
        height,
      );
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
    return RawButton(
      onPressed: onSelected == null ? null : () => onSelected!(!selected),
      selected: selected,
      // A button that is selected, as a Material filter chip reads.
      semanticSelected: selected,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => TapTargetPadding(child: body(states)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty(
          'selected',
          value: selected,
          ifTrue: 'selected',
          ifFalse: 'not selected',
        ),
      );
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
    final look = RawStyleOf([
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
            RawButton(
              onPressed: onPressed,
              semanticLabel: buttonLabel,
              excludeSemantics: true,
              builder: (context, states, _) {
                final pressed = states.contains(WidgetState.pressed);
                final key = ApplianceFace.key(
                  c,
                ).copyWith(lift: pressed ? -0.7 : 1, travel: pressed ? 1 : 0);
                final face = (enabled ? key : key.asDisabled(c)).copyWith(
                  foreground: enabled ? c.print : c.printDisabled,
                  focus: states.contains(WidgetState.focused)
                      ? c.focus
                      : c.focus.withValues(alpha: 0),
                );
                return TapTargetPadding(
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
                          child: RawCapCenter(
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

/// A colour picker: the colour's window (saturation across, brightness
/// down) behind smoked glass, a ring marking the colour, and faders for its
/// hue (and, with [showAlpha], how solid it is) under it.
///
/// With no [controller] it holds its own colour, black to start;
/// [onChanged] says each new one.
///
/// ```dart
/// ApplianceColorPicker(onChanged: (colour) {})
/// ```
class ApplianceColorPicker extends StatefulWidget {
  /// A picker for [controller]'s colour.
  const ApplianceColorPicker({
    super.key,
    this.controller,
    this.onChanged,
    this.showAlpha = false,
    this.areaHeight = 160,
    this.style,
  });

  /// The colour; yours to dispose. Null: the picker makes its own (black
  /// to start) and disposes it.
  final RawColorController? controller;

  /// Called with the colour each time it changes, by the picker or through
  /// [controller].
  final ValueChanged<Color>? onChanged;

  /// Whether a fader sets how solid it is.
  final bool showAlpha;

  /// The window's height.
  final double areaHeight;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window).
  final ApplianceStyle? style;

  @override
  State<ApplianceColorPicker> createState() => _ApplianceColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('showAlpha', value: showAlpha, ifTrue: 'alpha'),
    );
  }
}

class _ApplianceColorPickerState extends State<ApplianceColorPicker> {
  // The picker's own controller, while none is handed in.
  RawColorController? _own;

  RawColorController get _controller => widget.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _own = RawColorController();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(ApplianceColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.controller == old.controller) return;
    (old.controller ?? _own)?.removeListener(_changed);
    if (widget.controller == null) {
      _own = RawColorController();
    } else {
      _own?.dispose();
      _own = null;
    }
    _controller.addListener(_changed);
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged?.call(_controller.color);

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      widget.style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RawColorPicker(
      controller: _controller,
      showAlpha: widget.showAlpha,
      areaHeight: widget.areaHeight,
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
}
