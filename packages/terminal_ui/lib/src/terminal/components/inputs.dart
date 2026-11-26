/// Fields beyond the text field: a password with its `[show]`, a one-time
/// code in bracketed cells, a number with its `[-]` and `[+]`, a field that
/// suggests as you type, and one that gathers tags.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/words.dart';
import '../grid.dart';
import '../internal/frame_edge.dart';
import '../internal/list_open.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../primitives/menu.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'button.dart';
import 'chips.dart';
import 'feedback.dart';
import 'pane.dart';
import 'text_field.dart';

/// A password field: the words typed written `*`, a `[show]` at the end of
/// the line that writes them out until pressed again, the field keeping
/// its caret as it flips.
///
/// ```dart
/// TermPasswordField(labelText: 'token', controller: token)
/// ```
class TermPasswordField extends StatelessWidget {
  /// A password field.
  const TermPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.style,
  });

  /// Overrides for the field, over the theme's
  /// [TermThemeData.textFieldStyle], as a [TermTextField] reads them.
  final TermStyle? style;

  /// The text; one given is the caller's to dispose.
  final TextEditingController? controller;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// What the field is.
  final String? labelText;

  /// The dim words while it is empty.
  final String? hintText;

  /// Help, under the words.
  final String? helperText;

  /// What is wrong, in place of the help.
  final String? errorText;

  /// Called on Return.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  /// {@macro term.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) => RawPasswordReveal(
    focusNode: focusNode,
    builder: (context, password) => TermTextField(
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      autocorrect: false,
      obscureText: password.obscured,
      keyboardType: TextInputType.visiblePassword,
      style: style,
      autofillHints: const [AutofillHints.password],
      // The reveal is a toggle button: a button, selected while the
      // password shows, as IconButton(isSelected:) is.
      suffix: Semantics(
        label: password.toggleLabel,
        button: true,
        selected: !password.obscured,
        excludeSemantics: true,
        child: TermButton(
          label: password.obscured
              ? TermLocalizations.of(context).showLabel
              : TermLocalizations.of(context).hideLabel,
          onPressed: enabled ? password.toggle : null,
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null));
  }
}

/// A one-time code: [length] cells, each in its own brackets, `[4][8][ ]`,
/// the next one's caret a block in the accent; a dim `-` halves an even
/// code. Paste fills it; a phone offers the code from its messages.
///
/// ```dart
/// TermOtpField(onCompleted: (code) => verify(code))
/// ```
class TermOtpField extends StatelessWidget {
  /// A code of [length] characters.
  const TermOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
    this.enabled = true,
    this.isError = false,
    this.obscureText = false,
    this.semanticLabel = 'one-time code',
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.otpFieldStyle]:
  /// `foreground` (the characters) and `edge` (the brackets).
  final TermStyle? style;

  /// How many characters.
  final int length;

  /// The code; one given is the caller's to dispose.
  final RawOtpController? controller;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when the last cell fills.
  final ValueChanged<String>? onCompleted;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the code is wrong: every bracket in the danger ink.
  final bool isError;

  /// Whether each character is written `*`.
  final bool obscureText;

  /// What a screen reader calls it.
  ///
  /// Left as `'one-time code'`, it is the reader's words for it
  /// (`TermLocalizations.oneTimeCodeLabel`): Arabic or German in an app in either.
  final String semanticLabel;

  // The code grows with the reader's text to twice its size, and never
  // past the width it is given: past that a six-character code runs off a
  // phone.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cells = length * 3 + (length.isEven ? 3 : 0);
      final whole = TermTheme.of(context).grid.cols(cells);
      final fits = box.hasBoundedWidth ? box.maxWidth / whole : 2.0;
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: math.max(1, math.min(2, fits)),
        child: Builder(builder: _code),
      );
    },
  );

  Widget _code(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStrokeWidth(theme, grid);
    // The code is one line; what a tap reaches is the floor's height (two
    // lines under a finger), the cells in its middle.
    return TermTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: RawOtpField(
        length: length,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onCompleted: onCompleted,
        autofocus: autofocus,
        enabled: enabled,
        isError: isError,
        obscureText: obscureText,
        semanticLabel: termWords(
          context,
          semanticLabel,
          'one-time code',
          (w) => w.oneTimeCodeLabel,
        ),
        slotBuilder: (context, slot) {
          final focus = slot.active && slot.focused ? 1.0 : 0.0;
          final own = TermStyleOf(
            [style, theme.otpFieldStyle],
            {
              if (slot.active && slot.focused) WidgetState.focused,
              if (!slot.enabled) WidgetState.disabled,
              if (slot.isError) WidgetState.error,
            },
          );
          final edge = !slot.enabled
              ? theme.rule.withValues(alpha: 0.6)
              : slot.isError
              ? theme.danger
              : Color.lerp(own.edge ?? theme.rule, theme.accent, focus)!;
          final shown = slot.filled
              ? (slot.obscured ? '*' : slot.character)
              : '';
          return CustomPaint(
            // The cell the keys are in: its brackets heavy in the accent,
            // its caret the block; one line round it, as round the rest.
            painter: TermBracketPainter(
              grid: grid,
              color: edge,
              stroke: stroke * (1 + focus),
            ),
            child: SizedBox(
              width: grid.cols(3),
              height: grid.lineHeight,
              child: Center(
                child: slot.active && slot.focused && !slot.filled
                    ? ColoredBox(
                        color: theme.accent,
                        child: SizedBox(
                          width: grid.cellWidth,
                          height: grid.fontSize * 1.25,
                        ),
                      )
                    : Text(
                        shown,
                        style: theme.boldStyle.copyWith(
                          color: slot.enabled
                              ? own.foreground ?? theme.foreground
                              : theme.rule,
                        ),
                      ),
              ),
            ),
          );
        },
        layoutBuilder: (context, slots) {
          final half = length.isEven && length >= 6 ? length ~/ 2 : -1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, slot) in slots.indexed) ...[
                if (i == half)
                  SizedBox(
                    width: grid.cols(3),
                    height: grid.lineHeight,
                    child: Center(
                      child: ExcludeSemantics(
                        child: Text('-', style: theme.dimStyle),
                      ),
                    ),
                  ),
                slot,
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('length', length))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'));
  }
}

/// A number and the two keys that step it: `[-]  3  [+]`, the number as
/// wide as its widest value so nothing shifts as it counts, in the
/// reader's digits. The number is the one stop for the keyboard: Up and
/// Down step it, Home and End take it to [min] and [max]; the keys are the
/// pointer's. A screen reader hears it as a value it can raise and lower.
///
/// ```dart
/// TermNumberField(
///   semanticLabel: 'replicas',
///   value: replicas,
///   min: 1,
///   max: 9,
///   onChanged: (v) => setState(() => replicas = v),
/// )
/// ```
class TermNumberField extends StatelessWidget {
  /// A number stepped by [step] between [min] and [max].
  const TermNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.min = 0,
    this.max = 99,
    this.step = 1,
    this.unit,
    this.style,
  });

  /// Overrides for the two steppers, over the theme's
  /// [TermThemeData.iconButtonStyle], as a [TermIconButton] reads them.
  final TermStyle? style;

  /// The number.
  final int value;

  /// Called with the stepped number; null disables it.
  final ValueChanged<int>? onChanged;

  /// What the number is.
  final String semanticLabel;

  /// The least it goes to.
  final int min;

  /// The most it goes to.
  final int max;

  /// How far a press steps it.
  final int step;

  /// Dim words after the number: `GB`, `min`.
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final l = RawWidgetsLocalizations.of(context);
    final change = onChanged;
    final down = change != null && value > min
        ? () => change(math.max(min, value - step))
        : null;
    final up = change != null && value < max
        ? () => change(math.min(max, value + step))
        : null;
    String figure(int v) => l.formatDecimal(v);
    final shown = figure(value);
    final width = math.max(
      grid.widthOf(figure(min)),
      grid.widthOf(figure(max)),
    );
    // The keys are the pointer's: the number holds the keyboard and says
    // what they do, so they need no words of their own.
    Widget key(String glyph, VoidCallback? onPressed) => ExcludeSemantics(
      child: ExcludeFocus(
        child: TermIconButton(
          glyph: glyph,
          semanticLabel: glyph,
          onPressed: onPressed,
          style: style,
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        key('-', down),
        Semantics(
          label: semanticLabel,
          value: unit == null ? shown : '$shown $unit',
          increasedValue: up == null
              ? null
              : figure(math.min(max, value + step)),
          decreasedValue: down == null
              ? null
              : figure(math.max(min, value - step)),
          onIncrease: up,
          onDecrease: down,
          excludeSemantics: true,
          child: _TermNumberFocus(
            enabled: change != null,
            onStep: {
              LogicalKeyboardKey.arrowUp: up,
              LogicalKeyboardKey.arrowDown: down,
              LogicalKeyboardKey.home: change == null || value == min
                  ? null
                  : () => change(min),
              LogicalKeyboardKey.end: change == null || value == max
                  ? null
                  : () => change(max),
            },
            builder: (context, focus) => TermCursorCells(
              focus: focus,
              child: SizedBox(
                width: width + grid.cols(2),
                height: grid.lineHeight,
                child: Center(
                  child: Text(
                    shown,
                    textAlign: TextAlign.center,
                    style: theme.boldStyle.copyWith(
                      color: TermCursorCells.inkOf(
                        context,
                        change == null ? theme.rule : theme.foreground,
                        focus,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        key('+', up),
        if (unit != null) ...[
          SizedBox(width: grid.cellWidth),
          // Where the line ends first (larger text on a phone), the unit is
          // cut with an ellipsis; the number and its keys stay whole.
          Flexible(
            child: ExcludeSemantics(
              child: Text(
                unit!,
                style: theme.dimStyle,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('min', min))
      ..add(IntProperty('max', max));
  }
}

// The number's keyboard stop: Up, Down, Home and End run their [onStep]
// (null: nothing to do there), its focus shown on the keyboard's spring.
class _TermNumberFocus extends StatelessWidget {
  const _TermNumberFocus({
    required this.enabled,
    required this.onStep,
    required this.builder,
  });

  final bool enabled;
  final Map<LogicalKeyboardKey, VoidCallback?> onStep;
  final Widget Function(BuildContext context, double focus) builder;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: enabled,
    skipTraversal: !enabled,
    includeSemantics: false,
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      if (!onStep.containsKey(event.logicalKey)) return KeyEventResult.ignored;
      onStep[event.logicalKey]?.call();
      return KeyEventResult.handled;
    },
    child: Builder(
      builder: (context) => TermStateSprings(
        pressed: false,
        focused: Focus.of(context).hasFocus,
        builder: (context, _, focus) => builder(context, focus),
      ),
    ),
  );
}

/// A field that suggests as you type: the matches listed in a pane right
/// under the frame, the one the arrows are on under the cursor, Return
/// taking it.
///
/// With [search] the options are looked up rather than filtered: while
/// the search runs the pane says [loadingText] by the spinner, and when it
/// fails, [searchFailedText] over a [retryText] row (Down from the field reaches
/// it, Return or a press runs the search again).
///
/// ```dart
/// TermCombobox<String>(
///   labelText: 'branch',
///   options: branches,
///   onSelected: (b) => setState(() => branch = b),
/// )
/// ```
class TermCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const TermCombobox({
    super.key,
    required this.options,
    this.displayStringForOption,
    this.onSelected,
    this.value,
    this.isOptionEnabled,
    this.labelText,
    this.hintText,
    this.helperText,
    this.prompt,
    this.emptyText = 'no match',
    this.search,
    this.debounceDuration,
    this.loadingText = 'searching',
    this.searchFailedText = 'search failed',
    this.retryText = 'try again',
    this.controller,
    this.focusNode,
    this.style,
  });

  /// Overrides for the field, over the theme's
  /// [TermThemeData.textFieldStyle]; the list's rows read
  /// [TermThemeData.menuStyle].
  final TermStyle? style;

  /// The options it filters, when there is no [search].
  final List<T> options;

  /// Looks the options up for the words typed, in place of filtering
  /// [options]; it may be async.
  final RawOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null: at every change.
  final Duration? debounceDuration;

  /// What the list says while [search] runs.
  ///
  /// Left as `'searching'`, it is the reader's words for it
  /// (`TermLocalizations.searchingLabel`): Arabic or German in an app in either.
  final String loadingText;

  /// What the list says when [search] fails.
  ///
  /// Left as `'search failed'`, it is the reader's words for it
  /// (`TermLocalizations.searchFailedLabel`): Arabic or German in an app in either.
  final String searchFailedText;

  /// The row under [searchFailedText] that runs [search] again.
  ///
  /// Left as `'try again'`, it is the reader's words for it
  /// (`TermLocalizations.retryLabel`): Arabic or German in an app in either.
  final String retryText;

  /// The words for an option; null: its `toString`.
  final String Function(T option)? displayStringForOption;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// The option taken, if any.
  final T? value;

  /// Whether an option can be taken; null: every one. One that can't is
  /// drawn dim, passed over by the arrows and taken by neither a tap nor
  /// Return.
  final bool Function(T option)? isOptionEnabled;

  /// What the field is.
  final String? labelText;

  /// The dim words while it is empty.
  final String? hintText;

  /// Help under the words.
  final String? helperText;

  /// A glyph before the words.
  final String? prompt;

  /// What the list says when nothing matches.
  ///
  /// Left as `'no match'`, it is the reader's words for it
  /// (`TermLocalizations.noMatchLabel`): Arabic or German in an app in either.
  final String emptyText;

  /// The words typed; one given is the caller's to dispose.
  final TextEditingController? controller;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final show = displayStringForOption ?? (T option) => '$option';
    // The list goes over a field with too little room under it, as a
    // select's does: its frame and the lines of a failed search, or four
    // options.
    return TermListSide(
      wanted: grid.lines(6),
      builder: (context, above, watch) =>
          _combobox(theme, grid, show, above, watch),
    );
  }

  Widget _combobox(
    TermThemeData theme,
    TermGrid grid,
    String Function(T) show,
    bool above,
    Widget Function(TextEditingController, FocusNode, Widget) watch,
  ) => RawCombobox<T>(
    optionsViewOpenDirection: above
        ? OptionsViewOpenDirection.up
        : OptionsViewOpenDirection.down,
    options: options,
    search: search,
    debounceDuration: debounceDuration,
    loadingBuilder: (context) => _Searching(
      text: termWords(
        context,
        loadingText,
        'searching',
        (w) => w.searchingLabel,
      ),
    ),
    errorBuilder: (context, error) => _SearchFailed(
      error: error,
      text: termWords(
        context,
        searchFailedText,
        'search failed',
        (w) => w.searchFailedLabel,
      ),
      retryText: termWords(
        context,
        retryText,
        'try again',
        (w) => w.retryLabel,
      ),
    ),
    displayStringForOption: show,
    onSelected: onSelected,
    value: value,
    isOptionEnabled: isOptionEnabled,
    // Two marks, apart: the pointer's row takes the accent, the keys' adds
    // a block at its start; the pointer leaves the keys' row where it is.
    highlightFollowsPointer: false,
    controller: controller,
    focusNode: focusNode,
    semanticLabel: labelText,
    optionsMaxHeight: grid.lines(8),
    // While its list is up, the field stands on the list's ground, and its
    // input says the list is expanded.
    fieldBuilder: (context, field) => watch(
      field.controller,
      field.focusNode,
      TermListOpen(
        open: field.isOpen,
        child: TermTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          prompt: prompt,
          autocorrect: false,
          style: style,
          // Return takes the lit option and keeps the focus: no
          // onSubmitted, whose restarted input would take no more typing in
          // a browser.
          onEditingComplete: field.submit,
        ),
      ),
    ),
    optionBuilder: (context, option, states) =>
        TermMenuRow(label: show(option), states: states),
    // As wide as its field: the field's width is the list's most, and a
    // pane left to itself takes whole cells, short of the field's edge.
    surfaceBuilder: (context, list) => SizedBox(
      width: double.infinity,
      child: TermPane(
        raised: true,
        focused: true,
        // A cell inside the frame each side, as a menu's: the keys' block
        // stands as far from the frame's sides as from its top and bottom.
        padding: const TermInset(),
        child: list,
      ),
    ),
    emptyBuilder: (context) => Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: grid.cellWidth),
      child: Text(
        termWords(context, emptyText, 'no match', (w) => w.noMatchLabel),
        style: theme.dimStyle,
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('options', options.length))
      ..add(
        ObjectFlagProperty<bool Function(T)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

// A search's list while it looks: the spinner and the words, a cell in
// from the frame as the words that nothing matches are.
class _Searching extends StatelessWidget {
  const _Searching({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final cw = context.termGrid.cellWidth;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
      child: Row(
        children: [
          const TermSpinner(),
          SizedBox(width: cw),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.dimStyle,
            ),
          ),
        ],
      ),
    );
  }
}

// A search's list when it failed: the words in the danger ink over a row
// that runs it again, lit while the keys are on it (Down from the field).
class _SearchFailed extends StatelessWidget {
  const _SearchFailed({
    required this.error,
    required this.text,
    required this.retryText,
  });

  final RawSearchError error;
  final String text;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final cw = context.termGrid.cellWidth;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ui_core's node says the failure as it shows.
        ExcludeSemantics(
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: cw),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.copyWith(color: theme.danger),
            ),
          ),
        ),
        // The keys reach it from the field, never by Tab.
        ExcludeFocus(
          child: RawButton(
            onPressed: error.retry,
            semanticLabel: retryText,
            excludeSemantics: true,
            builder: (context, states, _) => TermMenuRow(
              label: retryText,
              states: {...states, if (error.focused) WidgetState.focused},
            ),
          ),
        ),
      ],
    );
  }
}

/// A field that gathers tags: each value chosen a [TermTag] with its `×`
/// on the line over the frame, the field suggesting from [options] as you
/// type, a comma or Return making the tag, Backspace in an empty field
/// taking the last one back.
///
/// With [search] the suggestions are looked up rather than filtered, and
/// say so while they are, and when the search fails, as
/// [TermCombobox]'s do.
///
/// ```dart
/// TermTagInput<String>(
///   labelText: 'regions',
///   values: regions,
///   options: allRegions,
///   onChanged: (v) => setState(() => regions = v),
/// )
/// ```
class TermTagInput<T extends Object> extends StatelessWidget {
  /// A tag input over [values].
  const TermTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.displayStringForOption,
    this.isOptionEnabled,
    this.onCreate,
    this.labelText,
    this.hintText,
    this.helperText,
    this.maxTags,
    this.search,
    this.debounceDuration,
    this.loadingText = 'searching',
    this.searchFailedText = 'search failed',
    this.retryText = 'try again',
    this.style,
  });

  /// Looks the suggestions up for the words typed, in place of filtering
  /// [options]; it may be async.
  final RawOptionSearch<T>? search;

  /// How long the typing rests before [search] runs; null: at every change.
  final Duration? debounceDuration;

  /// What the list says while [search] runs.
  ///
  /// Left as `'searching'`, it is the reader's words for it
  /// (`TermLocalizations.searchingLabel`): Arabic or German in an app in either.
  final String loadingText;

  /// What the list says when [search] fails.
  ///
  /// Left as `'search failed'`, it is the reader's words for it
  /// (`TermLocalizations.searchFailedLabel`): Arabic or German in an app in either.
  final String searchFailedText;

  /// The row under [searchFailedText] that runs [search] again.
  ///
  /// Left as `'try again'`, it is the reader's words for it
  /// (`TermLocalizations.retryLabel`): Arabic or German in an app in either.
  final String retryText;

  /// Overrides for the field, over the theme's
  /// [TermThemeData.textFieldStyle]; the tags read
  /// [TermThemeData.tagStyle], the suggestions [TermThemeData.menuStyle].
  final TermStyle? style;

  /// The tags.
  final List<T> values;

  /// Called with the new tags.
  final ValueChanged<List<T>> onChanged;

  /// What it suggests, when there is no [search].
  final List<T> options;

  /// The words for a value; null: its `toString`.
  final String Function(T value)? displayStringForOption;

  /// Whether an option can be taken; null: every one. One that can't is
  /// drawn dim, passed over by the arrows and taken by neither a tap nor
  /// Return.
  final bool Function(T option)? isOptionEnabled;

  /// Makes a value from words typed that match no option; null: only
  /// options become tags.
  final T? Function(String text)? onCreate;

  /// What the field is.
  final String? labelText;

  /// The dim words while it is empty.
  final String? hintText;

  /// Help under the words.
  final String? helperText;

  /// The most tags it takes.
  final int? maxTags;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final show = displayStringForOption ?? (T value) => '$value';
    // While its list is up, the frame stands on the list's ground.
    return TermListUp(
      builder: (context, up, mark) =>
          TermListOpen(open: up, child: _tagInput(grid, show, mark)),
    );
  }

  Widget _tagInput(
    TermGrid grid,
    String Function(T) show,
    Widget Function(Widget list) mark,
  ) => RawTagInput<T>(
    values: values,
    onChanged: onChanged,
    options: options,
    search: search,
    debounceDuration: debounceDuration,
    loadingBuilder: (context) => _Searching(
      text: termWords(
        context,
        loadingText,
        'searching',
        (w) => w.searchingLabel,
      ),
    ),
    errorBuilder: (context, error) => _SearchFailed(
      error: error,
      text: termWords(
        context,
        searchFailedText,
        'search failed',
        (w) => w.searchFailedLabel,
      ),
      retryText: termWords(
        context,
        retryText,
        'try again',
        (w) => w.retryLabel,
      ),
    ),
    displayStringForOption: show,
    isOptionEnabled: isOptionEnabled,
    // Two marks, apart: the pointer's row takes the accent, the keys' adds
    // a block at its start; the pointer leaves the keys' row where it is.
    highlightFollowsPointer: false,
    onCreate: onCreate,
    maxTags: maxTags,
    semanticLabel: labelText,
    optionsMaxHeight: grid.lines(8),
    // Its input says whether the list is expanded.
    fieldBuilder: (context, field) => TermListOpen(
      open: field.isOpen,
      child: TermTextField(
        controller: field.controller,
        focusNode: field.focusNode,
        labelText: labelText,
        hintText: hintText,
        // Read on the words' node, as the label is; the frame draws both.
        helperText: helperText,
        autocorrect: false,
        style: style,
        framed: false,
        // Return adds a tag and keeps the focus for the next: no
        // onSubmitted, whose restarted input would take no more typing in a
        // browser.
        onEditingComplete: field.submit,
      ),
    ),
    optionBuilder: (context, option, states) =>
        TermMenuRow(label: show(option), states: states),
    tagBuilder: (context, value, tag) => TermTag(
      label: show(value),
      focused: tag.focused,
      onDeleted: tag.onDeleted,
    ),
    // On whole cells, as its frame is: the frame round the tags and the
    // words is the field the list hangs from.
    surfaceBuilder: (context, list) => mark(
      TermPane(
        raised: true,
        focused: true,
        // A cell inside the frame each side, as a menu's.
        padding: const TermInset(),
        child: list,
      ),
    ),
    // One frame round the tags and the words typed after them, the label
    // cut into its top line and the help into its bottom, as a field's;
    // heavy in the accent while the words have the keyboard.
    layoutBuilder: (context, tags, field) => _TagFrame(
      label: labelText,
      helper: helperText,
      edge: TermStyleOf([
        style,
        TermTheme.of(context).textFieldStyle,
      ], const {}).edge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tags.isNotEmpty)
            RawChipGroup(
              spacing: grid.cellWidth,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: tags,
            ),
          field,
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('values', values.length))
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

/// A tag input's frame: a field's three-line frame grown round its tags and
/// its words, the label cut into the top line and the help into the bottom
/// (under the frame when it does not fit there), the line heavy in the
/// accent while anything in it has the keyboard.
class _TagFrame extends StatefulWidget {
  const _TagFrame({
    required this.label,
    required this.helper,
    required this.edge,
    required this.child,
  });

  final String? label;
  final String? helper;
  final Color? edge;
  final Widget child;

  @override
  State<_TagFrame> createState() => _TagFrameState();
}

class _TagFrameState extends State<_TagFrame> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? grid.cols(grid.colsIn(constraints.maxWidth))
              : grid.cols(40);
          final room = math.max(0.0, width - cw * 4);
          final label = widget.label == null
              ? null
              : grid.fit(widget.label!, room);
          final helper = widget.helper;
          // The help in the bottom line, where it fits there.
          final inLine = helper != null && grid.widthOf(helper) <= room
              ? helper
              : null;
          TermGap gap(String text) => (
            start: cw * 1.5,
            end: math.min(
              cw * 2 + grid.widthOf(text) + cw / 2,
              width - cw * 1.5,
            ),
          );
          Widget words(String text, TextStyle style) => SizedBox(
            height: lh,
            child: ExcludeSemantics(
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          );
          final frame = TermSpring(
            target: _focused ? 1 : 0,
            token: TermMotion.move,
            focus: true,
            builder: (context, t, child) => Stack(
              children: [
                // While the list is up, the field stands on its ground out
                // to where the list's frame has its outer edge, so the two
                // read as one block, edge on edge; its frame stays drawn on
                // it.
                if (TermListOpen.of(context))
                  Positioned(
                    left: termRaisedEdge(grid, termStrokeWidth(theme, grid)),
                    right: termRaisedEdge(grid, termStrokeWidth(theme, grid)),
                    top: lh / 2,
                    bottom: lh / 2,
                    child: ColoredBox(color: theme.surface),
                  ),
                CustomPaint(
                  painter: TermFramePainter(
                    grid: grid,
                    color:
                        widget.edge ??
                        Color.lerp(theme.rule, theme.accent, t.clamp(0, 1))!,
                    stroke:
                        termStrokeWidth(theme, grid) * (1 + t.clamp(0.0, 1.0)),
                    topGaps: [if (label != null) gap(label)],
                    bottomGaps: [if (inLine != null) gap(inLine)],
                    textDirection: Directionality.of(context),
                  ),
                  child: child,
                ),
              ],
            ),
            child: SizedBox(
              width: width,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: cw * 2,
                      vertical: lh,
                    ),
                    child: widget.child,
                  ),
                  if (label != null)
                    PositionedDirectional(
                      top: 0,
                      start: cw * 2,
                      end: cw * 2,
                      child: words(label, theme.textStyle),
                    ),
                  if (inLine != null)
                    PositionedDirectional(
                      bottom: 0,
                      start: cw * 2,
                      end: cw * 2,
                      child: words(inLine, theme.dimStyle),
                    ),
                ],
              ),
            ),
          );
          return Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: 1,
            child: helper == null || inLine != null
                ? frame
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      frame,
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: cw * 2,
                        ),
                        child: Text(helper, style: theme.dimStyle),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
