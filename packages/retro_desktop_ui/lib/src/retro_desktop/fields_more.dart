// More fields: a text area, a password field, an input group, a combobox, a multi-select and a form field. The
// last five stand on ui_core's behaviour (reveal, focus-within, the option list, tags, the field's semantics); this
// file paints them in Retro Desktop's hand: white boxes sunk into the machine, the highlight for the keyboard's row.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:ui_core/ui_core.dart';

import 'controls.dart';
import 'glyphs.dart';
import 'internal/face.dart';
import 'internal/parts.dart';
import 'layout.dart' show RetroDesktopReach;
import 'pixels.dart';
import 'press.dart';
import 'theme.dart';
import 'internal/caps.dart';
import 'tokens.dart';

/// A box for a few lines of words: a note, a message, an address. The text
/// field's box, taller, its words from the top.
///
/// ```dart
/// RetroDesktopTextArea(labelText: 'Notes', hintText: 'Anything the courier should know', lines: 4)
/// ```
class RetroDesktopTextArea extends StatelessWidget {
  /// Creates a [RetroDesktopTextArea].
  const RetroDesktopTextArea({
    super.key,
    this.controller,
    this.initial,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.lines = 4,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
  }) : assert(lines > 1);

  /// {@macro retro_desktop.controller}
  final TextEditingController? controller;

  /// The first words when no controller supplies them.
  final String? initial;

  /// The words shown while the box is empty.
  final String? hintText;

  /// The words above the box, under it, and the error that replaces them.
  final String? labelText, helperText, errorText;

  /// How many lines the box shows.
  final int lines;

  /// Whether the box takes input.
  final bool enabled;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// Reports each edit.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => RetroDesktopTextField(
    controller: controller,
    initial: initial,
    hintText: hintText,
    labelText: labelText,
    helperText: helperText,
    errorText: errorText,
    lines: lines,
    enabled: enabled,
    focusNode: focusNode,
    autofocus: autofocus,
    onChanged: onChanged,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('initial', initial, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(IntProperty('lines', lines, defaultValue: 4))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      );
  }
}

/// A password box with an eye that shows and hides what was typed. ui_core's
/// reveal keeps the state and the eye's name; the box is the text field's.
///
/// ```dart
/// RetroDesktopPasswordField(labelText: 'Password', onChanged: (_) {})
/// ```
class RetroDesktopPasswordField extends StatelessWidget {
  /// Creates a [RetroDesktopPasswordField].
  const RetroDesktopPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.newPassword = false,
  });

  /// {@macro retro_desktop.controller}
  final TextEditingController? controller;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// The words above the box, in it while empty, and under it.
  final String? labelText, hintText, helperText;

  /// The error that replaces the helper.
  final String? errorText;

  /// Whether the box takes input.
  final bool enabled;

  /// Reports each edit, and the submit key.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// Whether the platform should offer a new password rather than a saved one.
  final bool newPassword;

  @override
  Widget build(BuildContext context) {
    return RawPasswordReveal(
      focusNode: focusNode,
      showLabel: RawWidgetsLocalizations.of(context).showPasswordLabel,
      hideLabel: RawWidgetsLocalizations.of(context).hidePasswordLabel,
      builder: (context, s) => RetroDesktopTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        obscureText: s.obscured,
        keyboardType: TextInputType.visiblePassword,
        autofillHints: [
          newPassword ? AutofillHints.newPassword : AutofillHints.password,
        ],
        trailing: retroDesktopFieldButton(
          context,
          icon: s.obscured ? RetroDesktopGlyphs.eye : RetroDesktopGlyphs.eyeOff,
          label: s.toggleLabel,
          onPressed: enabled ? s.toggle : null,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
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
        FlagProperty('newPassword', value: newPassword, ifTrue: 'newPassword'),
      );
  }
}

/// A text field with a fixed prefix, suffix, or both.
///
/// Tapping an add-on focuses the field. When the text does not fit across
/// the available width, the prefix and suffix move above and below the input.
///
/// ```dart
/// RetroDesktopInputGroup(labelText: 'Site', prefix: 'https://', suffix: '.example.com', hintText: 'studio')
/// ```
class RetroDesktopInputGroup extends StatefulWidget {
  /// Creates a [RetroDesktopInputGroup].
  const RetroDesktopInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefix,
    this.suffix,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  /// {@macro retro_desktop.controller}
  final TextEditingController? controller;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  /// The words above the box, in it while empty, and under it.
  final String? labelText, hintText, helperText;

  /// The error that replaces the helper.
  final String? errorText;

  /// The fixed words before and after the typed ones.
  final String? prefix, suffix;

  /// A widget at the box's start, usually an `Icon`, which takes the box's
  /// icon size and ink.
  final Widget? leading;

  /// A small button at the box's end.
  final Widget? trailing;

  /// Whether the box takes input.
  final bool enabled;

  /// The platform keyboard requested.
  final TextInputType? keyboardType;

  /// Reports each edit, and the submit key.
  final ValueChanged<String>? onChanged, onSubmitted;

  @override
  State<RetroDesktopInputGroup> createState() => _InputGroupState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(StringProperty('suffix', suffix, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
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
      );
  }
}

class _InputGroupState extends State<RetroDesktopInputGroup> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;
  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownText?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  Widget _addOn(
    RetroDesktopThemeData t,
    String words, {
    required bool start,
    required bool stacked,
  }) {
    final c = t.colors;
    final rule = BorderSide(
      color: c.outline,
      width: t.strokes.regular == 0 ? 1 : t.strokes.regular,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.platinumLight,
        border: stacked
            ? Border(
                top: start ? BorderSide.none : rule,
                bottom: start ? rule : BorderSide.none,
              )
            : BorderDirectional(
                end: start ? rule : BorderSide.none,
                start: start ? BorderSide.none : rule,
              ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: RetroDesktopSpacing.s8,
          vertical: stacked ? RetroDesktopSpacing.s4 : 0,
        ),
        child: Align(
          alignment: stacked && !start
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: Text(
            words,
            style: t.textTheme.body.copyWith(color: c.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final error = widget.errorText;
    final editor = retroDesktopBareEditor(
      context,
      controller: _text,
      focusNode: _focus,
      autofocus: widget.autofocus,
      hint: widget.hintText,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      semanticLabel: widget.labelText,
      semanticHint: error ?? widget.helperText,
    );
    // Keep the complete address readable when its fixed parts outgrow one line.
    final group = LayoutBuilder(
      builder: (context, room) {
        double natural(String? words) {
          if (words == null) return 0;
          final tp = TextPainter(
            text: TextSpan(text: words, style: t.textTheme.body),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final width = tp.width + 16 + 2;
          tp.dispose();
          return width;
        }

        final stacked =
            room.hasBoundedWidth &&
            room.maxWidth <
                natural(widget.prefix) +
                    natural(widget.suffix) +
                    math.max(56, natural(widget.hintText)) +
                    4 +
                    (widget.leading == null ? 0 : 24) +
                    (widget.trailing == null ? 0 : 44);
        final prefix = widget.prefix == null
            ? null
            : _addOn(t, widget.prefix!, start: true, stacked: stacked);
        final suffix = widget.suffix == null
            ? null
            : _addOn(t, widget.suffix!, start: false, stacked: stacked);
        Widget input(Widget? edit) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!stacked && prefix != null) prefix,
              if (widget.leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: RetroDesktopSpacing.s8,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(size: 15, color: c.text),
                    child: widget.leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RetroDesktopSpacing.s8,
                  ),
                  child: edit,
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: RetroDesktopSpacing.s4,
                  ),
                  child: Center(widthFactor: 1, child: widget.trailing),
                ),
              if (!stacked && suffix != null) suffix,
            ],
          ),
        );
        return DesignInputGroup(
          focusNode: _focus,
          enabled: widget.enabled,
          isError: error != null,
          builder: (context, states, child) => RetroDesktopHighlight(
            shape: t.shapes.small,
            focused: states.contains(WidgetState.focused),
            child: Opacity(
              opacity: widget.enabled ? 1 : .5,
              child: retroDesktopSunkenBox(
                context,
                states: states,
                padding: EdgeInsets.zero,
                child: stacked
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [?prefix, input(child), ?suffix],
                      )
                    : input(child),
              ),
            ),
          ),
          child: editor,
        );
      },
    );
    return _Labelled(
      label: widget.labelText,
      note: error ?? widget.helperText,
      error: error != null,
      child: group,
    );
  }
}

/// A field's words above it and its note under it, the text field's way.
class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.child,
    this.label,
    this.note,
    this.error = false,
    this.dropdown = false,
  });
  final Widget child;
  final String? label, note;
  final bool error;
  // A dropdown: from 600 up it doesn't stretch to its column, it stands at
  // its start at most 320 wide, as a select does.
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Under a pointer the box is drawn one line tall and its reach stands
    // around it, as a text field's does, so stacked fields keep one rhythm.
    final child = RetroDesktopReach.padsAcross(context)
        ? this.child
        : RetroDesktopReach(keepsPoint: true, child: this.child);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s6),
            child: ExcludeSemantics(
              child: Text(label!, style: t.textTheme.body),
            ),
          ),
        if (dropdown && MediaQuery.sizeOf(context).width >= 600)
          Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: child,
            ),
          )
        else
          child,
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: RetroDesktopSpacing.s6),
            child: error
                ? Semantics(
                    liveRegion: true,
                    child: retroDesktopFieldNote(t, note!, error: true),
                  )
                : ExcludeSemantics(
                    child: retroDesktopFieldNote(t, note!, error: false),
                  ),
          ),
      ],
    );
  }
}

/// The arrows a Platinum field draws when it has a list behind it, the
/// popup's pair (Chisel's field has the select's drop button instead).
const Widget _listMark = Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    RetroDesktopTriangleMark(AxisDirection.up, size: 8),
    RetroDesktopTriangleMark(AxisDirection.down, size: 8),
  ],
);

/// An option in a field's list, as a select's list draws one: the row runs
/// rim to rim, the keyboard's row lit; its words start where the field's do
/// (8 px in at the density), on one x down the list; the chosen one stands in
/// the look's held well while unlit, its tick at the end, in a column every
/// row keeps.
Widget _optionRow(BuildContext context, String words, Set<WidgetState> states) {
  final t = RetroDesktopTheme.of(context);
  final chosen = states.contains(WidgetState.selected);
  final lit = states.contains(WidgetState.focused);
  return retroDesktopHeldGround(
    t,
    held: chosen && !lit,
    sink: false,
    child: retroDesktopLitRow(
      context,
      lit: lit,
      enabled: !states.contains(WidgetState.disabled),
      shape: const RoundedRectangleBorder(),
      padding: _optionPadding(t),
      child: Row(
        children: [
          Expanded(child: RetroDesktopCaps(Text(words))),
          SizedBox(
            width: 20,
            child: chosen
                ? const Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Icon(RetroDesktopGlyphs.check, size: 14),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

/// An option's room in a field's list: its words on the field's.
EdgeInsetsGeometry _optionPadding(RetroDesktopThemeData t) =>
    EdgeInsetsDirectional.fromSTEB(
      8 * t.density.horizontal,
      RetroDesktopSpacing.s8,
      RetroDesktopSpacing.s8,
      RetroDesktopSpacing.s8,
    );

/// A field's list: no room at its sides, so its rows reach the rims.
Widget _listPanel(BuildContext context, Widget list) => retroDesktopPanel(
  context,
  padding: const EdgeInsets.symmetric(vertical: RetroDesktopSpacing.s4),
  child: list,
);

/// A box that suggests as you type: the options that match open under it, the
/// arrows move along them, Enter takes one. ui_core's combobox carries the
/// list, its keys and its announcements. With a [search] (options that take
/// time to find, from a server), the list says it is looking while the search
/// runs and, should it fail, says so with a row that tries again.
///
/// ```dart
/// RetroDesktopCombobox<String>(labelText: 'Country', options: const ['Austria', 'Belgium', 'Chile'], onSelected: (_) {})
/// ```
class RetroDesktopCombobox<T extends Object> extends StatelessWidget {
  /// Creates a [RetroDesktopCombobox].
  const RetroDesktopCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.displayString,
    this.value,
    this.onSelected,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.requireSelection = false,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  /// The options in their order.
  final List<T> options;

  /// Finds the options for the words typed, in place of [options]; it may
  /// take time (a future) and fail. While it runs the list says it is
  /// loading; a failure says so in the list, with a "Try again" row the
  /// arrows reach and Enter runs.
  final DesignOptionSearch<T>? search;

  /// How long typing rests before [search] runs; null (the default) runs it
  /// at every change.
  final Duration? debounceDuration;

  /// Each option's words; null uses its `toString`.
  final String Function(T option)? displayString;

  /// The chosen option.
  final T? value;

  /// Reports the option taken.
  final ValueChanged<T>? onSelected;

  /// The words above the box, in it while empty, and under it.
  final String? labelText, hintText, helperText;

  /// The error that replaces the helper.
  final String? errorText;

  /// Whether the box keeps only an option (it clears free words on leaving).
  final bool requireSelection;

  /// Whether the box takes input.
  final bool enabled;

  /// {@macro retro_desktop.controller}
  final TextEditingController? controller;

  /// {@macro retro_desktop.focusNode}
  final FocusNode? focusNode;

  /// {@macro retro_desktop.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final words = displayString ?? (T option) => '$option';
    final box = RawCombobox<T>(
      options: options,
      search: search,
      debounceDuration: debounceDuration,
      displayStringForOption: words,
      value: value,
      onSelected: onSelected,
      requireSelection: requireSelection,
      // One lit row, as in the period's pop-up menus and the look's select: the pointer moves it and the keys go on
      // from there.
      highlightFollowsPointer: true,
      controller: controller,
      focusNode: focusNode,
      semanticLabel: labelText,
      fieldBuilder: (context, f) => _ListField(
        focusNode: f.focusNode,
        error: errorText != null,
        enabled: enabled,
        child: retroDesktopBareEditor(
          context,
          controller: f.controller,
          focusNode: f.focusNode,
          autofocus: autofocus,
          hint: hintText,
          enabled: enabled,
          // Enter takes the lit option and the field keeps the focus, so it
          // comes through onEditingComplete with no onSubmitted: a submit
          // with the focus kept restarts the text input, and in a browser
          // typing then goes nowhere.
          onEditingComplete: f.submit,
          semanticLabel: labelText,
          semanticHint: errorText ?? helperText,
          // The text input says whether the list shows under it, where a
          // screen reader hears it, as the select's button does.
          expanded: f.isOpen,
        ),
      ),
      optionBuilder: (context, option, states) =>
          _optionRow(context, words(option), states),
      surfaceBuilder: _listPanel,
      emptyBuilder: _noMatchesRow,
      loadingBuilder: _searchingRow,
      errorBuilder: _failedRows,
    );
    return _Labelled(
      label: labelText,
      note: errorText ?? helperText,
      error: errorText != null,
      dropdown: true,
      child: box,
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        FlagProperty(
          'requireSelection',
          value: requireSelection,
          ifTrue: 'requireSelection',
        ),
      )
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
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// Says in the list that no option fits, on the line an option's words take.
Widget _noMatchesRow(BuildContext context) {
  final t = RetroDesktopTheme.of(context);
  return _listWide(
    Padding(
      padding: _optionPadding(t),
      child: Text(
        RawWidgetsLocalizations.of(context).noResultsLabel,
        style: t.textTheme.body.copyWith(color: t.colors.textSecondary),
      ),
    ),
  );
}

// A line said in the list stands as wide as the list's options would, the field's width, at its start; not just as wide
// as its words.
Widget _listWide(Widget line) => Align(
  alignment: AlignmentDirectional.centerStart,
  heightFactor: 1,
  child: line,
);

/// Says in the list that the search is still finding options, as the words
/// that none match are said.
Widget _searchingRow(BuildContext context) {
  final t = RetroDesktopTheme.of(context);
  return _listWide(
    Padding(
      padding: _optionPadding(t),
      child: Text(
        RawWidgetsLocalizations.of(context).loadingLabel,
        style: t.textTheme.body.copyWith(color: t.colors.textSecondary),
      ),
    ),
  );
}

/// Says in the list that the search failed, then a "Try again" row drawn as an
/// option is: lit while the keys are on it, run by Enter or a press.
Widget _failedRows(BuildContext context, RawSearchError failed) {
  final t = RetroDesktopTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: _optionPadding(t),
        child: ExcludeSemantics(
          child: Text(
            words.searchFailedMessage,
            style: t.textTheme.body.copyWith(color: t.colors.textSecondary),
          ),
        ),
      ),
      Semantics(
        button: true,
        onTap: failed.retry,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: failed.retry,
            child: retroDesktopLitRow(
              context,
              lit: failed.focused,
              shape: const RoundedRectangleBorder(),
              padding: _optionPadding(t),
              child: RetroDesktopCaps(Text(words.retryButtonLabel)),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The sunken box round a field with a list behind it, ringed while focused.
class _ListField extends StatelessWidget {
  const _ListField({
    required this.focusNode,
    required this.child,
    this.error = false,
    this.enabled = true,
  });
  final FocusNode focusNode;
  final Widget child;
  final bool error, enabled;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final states = <WidgetState>{
          if (focusNode.hasFocus) WidgetState.focused,
          if (error) WidgetState.error,
          if (!enabled) WidgetState.disabled,
        };
        return RetroDesktopHighlight(
          shape: t.shapes.small,
          focused: focusNode.hasFocus,
          child: Opacity(
            opacity: enabled ? 1 : .5,
            child: t.chisel
                // The PC's combo box: the select's bevelled drop button at
                // its end, two pixels in from the well.
                ? retroDesktopSunkenBox(
                    context,
                    states: states,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      RetroDesktopSpacing.s8,
                      0,
                      RetroDesktopSpacing.s2,
                      0,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: Center(child: child)),
                          const SizedBox(width: RetroDesktopSpacing.s6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: RetroDesktopSpacing.s2,
                            ),
                            child: SizedBox(
                              width: 18,
                              child: RetroDesktopPixelPaint(
                                painter: RetroDesktopArrowButtonPainter(
                                  t.colors,
                                  false,
                                  t.strokes.regular,
                                  t.strokes.hairline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : retroDesktopSunkenBox(
                    context,
                    states: states,
                    child: Row(
                      children: [
                        Expanded(child: child),
                        const SizedBox(width: RetroDesktopSpacing.s6),
                        _listMark,
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// A control with its words: the name above it, its help under it, and the
/// error that replaces the help, the way every Retro Desktop field reads.
/// ui_core's field gives one control its name, help and error for a screen
/// reader, and marks it required; a group of controls (radios, a segmented
/// button, chips, a number field's value and its steps, a password and its
/// Show button) is named by them, each control keeping its own node, so every
/// one takes a tap from a screen reader or a browser with semantics on
/// ([mergeSemantics]). A control that already says the name is not named
/// again.
///
/// ```dart
/// RetroDesktopFormField(labelText: 'Email', helperText: 'We send the receipt here', required: true, child: RetroDesktopTextField(hintText: 'name@example.com'))
/// ```
class RetroDesktopFormField extends StatelessWidget {
  /// Creates a [RetroDesktopFormField].
  const RetroDesktopFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.required = false,
    this.enabled = true,
    this.focusNode,
    this.requiredHint,
    this.mergeSemantics,
  });

  /// The word a screen reader hears for a required field.
  final String? requiredHint;

  /// The control: a field, a select, a group of boxes.
  final Widget child;

  /// The name above the control, the help under it, and the error that
  /// replaces the help.
  final String? labelText, helperText, errorText;

  /// Whether the field must be filled.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus, so a press on the name reaches it.
  final FocusNode? focusNode;

  /// Whether the label, help and error join [child]'s one node. Null, the
  /// default, decides by what [child] brings to the semantics tree, as ui_core's
  /// field does: one control (a text field, a select, a switch) is one node
  /// with the label as its name and the help and error as its hint; several
  /// (radios, segments, chips, a number field's value and its steps, a password
  /// and its Show button) keep their own nodes, which the label names as a
  /// group; and the label is left out where a control already says it. True
  /// makes one node of them all; false a group named by the label.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final decide = mergeSemantics == null;
    final requiredWords =
        requiredHint ?? RawWidgetsLocalizations.of(context).requiredHint;
    final hint = [?errorText, ?helperText].join('. ');
    return RawInputDecorator(
      // Left to Retro (null), the field is told to merge, which adds no node round the field, and the builder places
      // the look's own node in place of the merged control: ui_core's field told to merge merges whatever it holds.
      mergeSemantics: mergeSemantics ?? true,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      requiredHint: requiredWords,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: RetroDesktopSpacing.s6),
              child: DefaultTextStyle.merge(
                style: t.textTheme.body.copyWith(
                  color: enabled ? c.text : c.textTertiary,
                ),
                child: Row(
                  children: [
                    Flexible(child: parts.label!),
                    if (parts.required)
                      ExcludeSemantics(
                        child: Text(' *', style: t.textTheme.body),
                      ),
                  ],
                ),
              ),
            ),
          if (decide)
            _FieldNode(
              label: labelText == null
                  ? null
                  : required
                  ? '$labelText, $requiredWords'
                  : labelText,
              words: labelText,
              hint: hint.isEmpty ? null : hint,
              invalid: parts.invalid,
              textDirection: Directionality.maybeOf(context),
              child: child,
            )
          else
            parts.control,
          if (parts.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: RetroDesktopSpacing.s6),
              child: ExcludeSemantics(
                child: retroDesktopFieldNote(t, parts.errorText!, error: true),
              ),
            )
          else if (parts.helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: RetroDesktopSpacing.s6),
              child: ExcludeSemantics(
                child: retroDesktopFieldNote(
                  t,
                  parts.helperText!,
                  error: false,
                ),
              ),
            ),
        ],
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('requiredHint', requiredHint, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool>(
          'mergeSemantics',
          mergeSemantics,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('required', value: required, ifTrue: 'required'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}

// The field's own node, shaped by the controls under it, as ui_core's field shapes it: one control is merged with
// the name, hint and validity; several keep their own nodes under a node that names them; the name is left out when a
// control already says it. Merged into one node, a group's controls would give a tap through the semantics tree on any
// of them to the first (a form's priority segments and its label chips), a password's Show button would stand under
// its entry, and a field named as its number field would read its name twice.
class _FieldNode extends SingleChildRenderObjectWidget {
  const _FieldNode({
    required this.label,
    required this.words,
    required this.hint,
    required this.invalid,
    required this.textDirection,
    required super.child,
  });

  final String? label;
  final String? words;
  final String? hint;
  final bool invalid;
  final TextDirection? textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFieldNode(label, words, hint, invalid, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderFieldNode renderObject) {
    renderObject
      ..label = label
      ..words = words
      ..hint = hint
      ..invalid = invalid
      ..textDirection = textDirection;
  }
}

class _RenderFieldNode extends RenderProxyBox {
  _RenderFieldNode(
    this._label,
    this._words,
    this._hint,
    this._invalid,
    this._textDirection,
  );

  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  String? _words;
  set words(String? value) {
    if (value == _words) return;
    _words = value;
    markNeedsSemanticsUpdate();
  }

  String? _hint;
  set hint(String? value) {
    if (value == _hint) return;
    _hint = value;
    markNeedsSemanticsUpdate();
  }

  bool _invalid;
  set invalid(bool value) {
    if (value == _invalid) return;
    _invalid = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  // The controls under the field as last described, to describe it again when a layout changes them (a search
  // field's clear button comes with its text).
  ({bool single, bool said})? _shape;

  @override
  void performLayout() {
    super.performLayout();
    if (_shape != null && _read() != _shape) markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final shape = _shape = _read();
    config.isSemanticBoundary = true;
    if (shape.single) {
      config.isMergingSemanticsOfDescendants = true;
    } else {
      config.explicitChildNodes = true;
    }
    final label = _label;
    if (label != null && !shape.said) config.label = label;
    if (_hint case final hint?) config.hint = hint;
    if (config.label.isNotEmpty || config.hint.isNotEmpty) {
      config.textDirection = _textDirection;
    }
    config.validationResult = _invalid
        ? SemanticsValidationResult.invalid
        : SemanticsValidationResult.none;
  }

  // Whether the child holds one control at most, and whether anything in it already says the name (a line of its own
  // that is the name, or starts with it and a comma, as a required field's does): a control, or a group that names
  // itself, as a radio group or a segmented button does on a node of its own that takes no action.
  ({bool single, bool said}) _read() {
    var controls = 0;
    var said = false;
    final words = _words?.trim().toLowerCase() ?? '';
    bool says(String text) => text
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .any((line) => line == words || line.startsWith('$words,'));
    bool hears(RenderObject control) {
      if (words.isEmpty) return false;
      var heard = false;
      void hear(RenderObject n) {
        if (heard || (n is RenderExcludeSemantics && n.excluding)) return;
        if (n is RenderSemanticsAnnotations) {
          if (says(n.properties.label ?? '')) heard = true;
          if (n.excludeSemantics) return;
        }
        if (n is RenderParagraph &&
            says(n.text.toPlainText(includeSemanticsLabels: true))) {
          heard = true;
        }
        n.visitChildrenForSemantics(hear);
      }

      hear(control);
      return heard;
    }

    bool holdsEntry(RenderObject n) {
      if (n is RenderEditable) return true;
      var found = false;
      n.visitChildrenForSemantics((c) => found = found || holdsEntry(c));
      return found;
    }

    // The controls under [n]: those that hold no control of their own (a text field's tap wraps its entry: one
    // control), and an adjustment round an entry (a number field's steps round the value it types in), which a tap
    // on its parts would not reach once merged with them.
    int leaves(RenderObject n) {
      if (n is RenderExcludeSemantics && n.excluding) return 0;
      if (n is RenderEditable) return 1;
      var below = 0;
      if (!(n is RenderSemanticsAnnotations && n.excludeSemantics)) {
        n.visitChildrenForSemantics((c) => below += leaves(c));
      }
      if (below == 0) return _acts(n) ? 1 : 0;
      final adjusts =
          n is RenderSemanticsAnnotations &&
          (n.properties.onIncrease != null ||
              n.properties.onDecrease != null) &&
          holdsEntry(n);
      return below + (adjusts ? 1 : 0);
    }

    void visit(RenderObject n) {
      if (n is RenderExcludeSemantics && n.excluding) return;
      if (n is RenderEditable || _acts(n)) {
        controls += math.max(1, leaves(n));
        return;
      }
      n.visitChildrenForSemantics(visit);
    }

    visitChildrenForSemantics(visit);
    visitChildrenForSemantics((c) => said = said || hears(c));
    return (single: controls <= 1, said: said);
  }

  // A node a press, a drag or an adjustment acts on, or one with a value or a state of its own.
  static bool _acts(RenderObject n) {
    if (n is RenderSemanticsGestureHandler) {
      return n.onTap != null ||
          n.onLongPress != null ||
          n.onHorizontalDragUpdate != null ||
          n.onVerticalDragUpdate != null;
    }
    if (n is RenderSemanticsAnnotations) {
      final p = n.properties;
      return p.button == true ||
          p.link == true ||
          p.textField == true ||
          p.slider == true ||
          p.toggled != null ||
          p.checked != null ||
          p.inMutuallyExclusiveGroup == true ||
          p.onTap != null ||
          p.onLongPress != null ||
          p.onIncrease != null ||
          p.onDecrease != null ||
          (p.value?.isNotEmpty ?? false);
    }
    return false;
  }
}
