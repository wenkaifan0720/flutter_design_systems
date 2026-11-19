/// Gloss's other typed-in fields, each a well pressed into the porcelain:
/// the text area, the search field, the password field, a field with its
/// add-ons, the one-time code, the combobox, the tag input, and the field
/// that gives any control its label, help and error.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart' show GlossSpinner;
import 'fonts.dart';
import 'internal/chevron.dart';
import 'internal/entry_parts.dart';
import 'internal/menu_parts.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

String _words(Object option) => option.toString();

/// A small bead set at a well's end (clear, show, open): 32 px, its glyph
/// 18.
const GlossStyle _wellBead = GlossStyle(
  minimumSize: WidgetStatePropertyAll(Size(32, 32)),
  iconSize: WidgetStatePropertyAll(18),
);

/// Keeps [child] rebuilt as [focusNode] gains and loses the focus.
class _OnFocus extends StatelessWidget {
  const _OnFocus({required this.focusNode, required this.builder});

  final FocusNode focusNode;
  final Widget Function(BuildContext context, bool focused) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: focusNode,
    builder: (context, _) => builder(context, focusNode.hasFocus),
  );
}

/// Owns a controller and a focus node when the caller gives none.
mixin _OwnsEntry<W extends StatefulWidget> on State<W> {
  TextEditingController? get givenController;
  FocusNode? get givenFocusNode;

  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get controller =>
      givenController ?? (_ownController ??= TextEditingController());
  FocusNode get focusNode => givenFocusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }
}

/// A field for a few lines of words (a note, a recipe's method): the text
/// field's well, growing from [minLines] as the words run on.
///
/// ```dart
/// GlossTextArea(label: 'Notes', hint: 'What to remember next time')
/// ```
class GlossTextArea extends StatelessWidget {
  /// A text area.
  const GlossTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 3,
    this.maxLines,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// The words above the well.
  final String? label;

  /// What the empty area says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well, in the danger ink.
  final String? error;

  /// Each change of the words.
  final ValueChanged<String>? onChanged;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its words can be read and copied but not changed.
  final bool readOnly;

  /// The fewest lines it shows.
  final int minLines;

  /// The most lines it grows to before it scrolls; null: no limit.
  final int? maxLines;

  /// This area's own style, over [GlossThemeData.textFieldStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => GlossTextField(
    controller: controller,
    focusNode: focusNode,
    label: label,
    hint: hint,
    helper: helper,
    error: error,
    onChanged: onChanged,
    enabled: enabled,
    readOnly: readOnly,
    minLines: minLines,
    maxLines: maxLines,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(IntProperty('minLines', minLines))
      ..add(IntProperty('maxLines', maxLines, defaultValue: null));
  }
}

/// A search field: a round-ended well with a magnifier at its start and,
/// once there are words, a bead that clears them.
///
/// ```dart
/// GlossSearchField(hint: 'Search recipes', onChanged: (query) {})
/// ```
class GlossSearchField extends StatefulWidget {
  /// A search field.
  const GlossSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// What the empty field says; null: the platform's word for search.
  final String? hint;

  /// Each change of the query.
  final ValueChanged<String>? onChanged;

  /// Enter: search now.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls it; null: [hint].
  final String? semanticLabel;

  /// This field's own style, over [GlossThemeData.searchFieldStyle].
  final GlossStyle? style;

  @override
  State<GlossSearchField> createState() => _GlossSearchFieldState();
}

class _GlossSearchFieldState extends State<GlossSearchField>
    with _OwnsEntry<GlossSearchField> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  void _clear() {
    controller.clear();
    widget.onChanged?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final words = DesignLocalizations.of(context);
    final hint = widget.hint ?? words.searchFieldLabel;
    return _OnFocus(
      focusNode: focusNode,
      builder: (context, focused) {
        final states = {
          if (!widget.enabled) WidgetState.disabled,
          if (focused) WidgetState.focused,
        };
        final layered = DesignStyleOf([
          widget.style,
          theme.searchFieldStyle,
        ], states);
        return GlossEntryWell(
          focusNode: focusNode,
          enabled: widget.enabled,
          face: glossEntryFace(
            theme,
            states,
            fill: layered.fill,
            edge: layered.edge,
            radius: theme.controlHeight / 2,
          ),
          leading: const Icon(LucideIcons.search),
          trailing: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.text.isEmpty || !widget.enabled
                ? const SizedBox(width: GlossSpacing.small)
                : GlossIconButton.plain(
                    onPressed: _clear,
                    tooltip: words.clearButtonTooltip,
                    style: _wellBead,
                    icon: const Icon(LucideIcons.x),
                  ),
          ),
          child: GlossEntryText(
            controller: controller,
            focusNode: focusNode,
            hint: hint,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            semanticLabel: widget.semanticLabel ?? hint,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textStyle: layered.textStyle,
          ),
        );
      },
    );
  }
}

/// A password field: the text field's well with a bead at its end that
/// shows and hides the words, keeping the caret where it was.
///
/// ```dart
/// GlossPasswordField(label: 'Password', onChanged: (value) {})
/// ```
class GlossPasswordField extends StatefulWidget {
  /// A password field.
  const GlossPasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// The words above the well.
  final String? label;

  /// What the empty field says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Each change of the password.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  /// What autofill may offer: a password by default; give
  /// [AutofillHints.newPassword] where one is made.
  final Iterable<String> autofillHints;

  /// This field's own style, over [GlossThemeData.textFieldStyle].
  final GlossStyle? style;

  @override
  State<GlossPasswordField> createState() => _GlossPasswordFieldState();
}

class _GlossPasswordFieldState extends State<GlossPasswordField>
    with _OwnsEntry<GlossPasswordField> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: GlossFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        DesignPasswordReveal(
          focusNode: focusNode,
          builder: (context, password) => _OnFocus(
            focusNode: focusNode,
            builder: (context, focused) {
              final states = {
                if (!widget.enabled) WidgetState.disabled,
                if (focused) WidgetState.focused,
                if (widget.error != null) WidgetState.error,
              };
              final layered = DesignStyleOf([
                widget.style,
                theme.textFieldStyle,
              ], states);
              return GlossEntryWell(
                focusNode: focusNode,
                enabled: widget.enabled,
                face: glossEntryFace(
                  theme,
                  states,
                  fill: layered.fill,
                  edge: layered.edge,
                ),
                trailing: GlossIconButton.plain(
                  onPressed: widget.enabled ? password.toggle : null,
                  tooltip: password.toggleLabel,
                  selected: !password.obscured,
                  style: _wellBead,
                  icon: Icon(
                    password.obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                  ),
                ),
                child: GlossEntryText(
                  controller: controller,
                  focusNode: focusNode,
                  hint: widget.hint,
                  obscureText: password.obscured,
                  enabled: widget.enabled,
                  autofillHints: widget.autofillHints,
                  keyboardType: TextInputType.visiblePassword,
                  semanticLabel: widget.label,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textStyle: layered.textStyle,
                ),
              );
            },
          ),
        ),
        GlossFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// A field with its add-ons, one control: a unit or a prefix engraved into
/// the well's ends (kg, https://), or a glyph, a bead.
///
/// ```dart
/// GlossInputGroup(label: 'Weight', suffixText: 'kg', keyboardType: TextInputType.number)
/// ```
class GlossInputGroup extends StatefulWidget {
  /// A field with add-ons.
  const GlossInputGroup({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.prefixText,
    this.suffixText,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.style,
  });

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// The words above the well.
  final String? label;

  /// What the empty field says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Words engraved at the well's start, behind a seam (https://).
  final String? prefixText;

  /// Words engraved at the well's end, behind a seam (kg, per serving).
  final String? suffixText;

  /// A glyph at the start, inside the well.
  final Widget? leading;

  /// A bead at the end, inside the well.
  final Widget? trailing;

  /// The keyboard to show.
  final TextInputType? keyboardType;

  /// What the words may be.
  final List<TextInputFormatter>? inputFormatters;

  /// Each change.
  final ValueChanged<String>? onChanged;

  /// Enter.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes input.
  final bool enabled;

  /// This group's own style, over [GlossThemeData.textFieldStyle].
  final GlossStyle? style;

  @override
  State<GlossInputGroup> createState() => _GlossInputGroupState();
}

class _GlossInputGroupState extends State<GlossInputGroup>
    with _OwnsEntry<GlossInputGroup> {
  @override
  TextEditingController? get givenController => widget.controller;
  @override
  FocusNode? get givenFocusNode => widget.focusNode;

  Widget _addOn(GlossThemeData theme, String words, {required bool start}) {
    final c = theme.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!start) const _Seam(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GlossSpacing.medium),
          child: DesignCapCenter(
            capHeightFactor: glossCapHeightFactor,
            child: Text(
              words,
              style: theme.textTheme.body.copyWith(
                color: widget.enabled ? c.inkSecondary : c.inkDisabled,
              ),
            ),
          ),
        ),
        if (start) const _Seam(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          ExcludeSemantics(
            child: GlossFieldLabel(widget.label!, enabled: widget.enabled),
          ),
        DesignInputGroup(
          focusNode: focusNode,
          enabled: widget.enabled,
          isError: widget.error != null,
          builder: (context, states, child) {
            final layered = DesignStyleOf([
              widget.style,
              theme.textFieldStyle,
            ], states);
            return SizedBox(
              height: theme.controlHeight,
              child: AnimatedGlossSurface(
                face: glossEntryFace(
                  theme,
                  states,
                  fill: layered.fill,
                  edge: layered.edge,
                ),
                child: child,
              ),
            );
          },
          child: Row(
            children: [
              if (widget.prefixText != null)
                _addOn(theme, widget.prefixText!, start: true),
              if (widget.leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: GlossSpacing.medium,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: 20,
                      color: theme.colors.inkSecondary,
                    ),
                    child: widget.leading!,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GlossSpacing.medium,
                  ),
                  child: GlossEntryText(
                    controller: controller,
                    focusNode: focusNode,
                    hint: widget.hint,
                    enabled: widget.enabled,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    semanticLabel: widget.label,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: GlossSpacing.tight,
                  ),
                  child: widget.trailing,
                ),
              if (widget.suffixText != null)
                _addOn(theme, widget.suffixText!, start: false),
            ],
          ),
        ),
        GlossFieldMessage(helper: widget.helper, error: widget.error),
      ],
    );
  }
}

/// An engraved seam across a well: a dark line with a light one beside it.
class _Seam extends StatelessWidget {
  const _Seam();

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return SizedBox(
      width: 2,
      height: 24,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: c.wellShade)),
          Expanded(child: ColoredBox(color: c.lip.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

/// A one-time code: a socket for each character, pressed into the
/// porcelain, the next one ringed. Paste fills them all.
///
/// ```dart
/// GlossOtpField(length: 6, onCompleted: (code) {})
/// ```
class GlossOtpField extends StatelessWidget {
  /// A code of [length] characters.
  const GlossOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.isError = false,
    this.obscureText = false,
    this.autofocus = false,
    this.semanticLabel,
    this.style,
  });

  /// How many characters.
  final int length;

  /// The code, for a caller that reads or sets it.
  final DesignOtpController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// Each change of the code.
  final ValueChanged<String>? onChanged;

  /// The whole code, once every socket is filled.
  final ValueChanged<String>? onCompleted;

  /// Whether it takes input.
  final bool enabled;

  /// Whether the code was wrong.
  final bool isError;

  /// Whether the characters are hidden.
  final bool obscureText;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This field's own style, over [GlossThemeData.otpFieldStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    // The boxes start under the label, as every field's words do (the
    // code centres them in whatever width it is given).
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: DesignOtpField(
        length: length,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onCompleted: onCompleted,
        enabled: enabled,
        isError: isError,
        obscureText: obscureText,
        autofocus: autofocus,
        textDirection: TextDirection.ltr,
        semanticLabel: semanticLabel ?? 'One-time code',
        layoutBuilder: (context, slots) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, slot) in slots.indexed) ...[
              if (i > 0)
                SizedBox(
                  width: length == 6 && i == 3
                      ? GlossSpacing.large
                      : GlossSpacing.small,
                ),
              slot,
            ],
          ],
        ),
        slotBuilder: (context, slot) {
          final states = {
            if (!slot.enabled) WidgetState.disabled,
            if (slot.focused && slot.active) WidgetState.focused,
            if (slot.isError) WidgetState.error,
          };
          final layered = DesignStyleOf([style, theme.otpFieldStyle], states);
          return SizedBox(
            width: 44,
            height: theme.controlHeight + 4,
            child: AnimatedGlossSurface(
              face: glossEntryFace(
                theme,
                states,
                fill: layered.fill,
                edge: layered.edge,
              ),
              child: Center(
                child: Text(
                  slot.obscured && slot.character.isNotEmpty
                      ? '•'
                      : slot.character,
                  style: theme.textTheme.title
                      .copyWith(
                        color: slot.enabled ? c.ink : c.inkDisabled,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )
                      .merge(layered.textStyle),
                ),
              ),
            ),
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

/// A row of a Gloss list of options: its words on the row's plate, the
/// chosen one in jade ink with a tick.
class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.states});

  final String label;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final disabled = states.contains(WidgetState.disabled);
    final ink = disabled
        ? c.inkDisabled
        : chosen
        ? c.jadeInk
        : c.ink;
    final focused = !disabled && states.contains(WidgetState.focused);
    return SizedBox(
      height: theme.controlHeight - 4,
      child: GlossFocusHalo(
        focused: focused,
        inside: true,
        radius: glossPanelCorner - glossPanelInset,
        child: AnimatedGlossSurface(
          face: glossRowPlate(
            c,
            lit: focused,
            pressed: states.contains(WidgetState.pressed),
          ).copyWith(foreground: ink),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: DesignCapCenter(
                    capHeightFactor: glossCapHeightFactor,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.body.copyWith(color: ink),
                    ),
                  ),
                ),
                if (chosen) Icon(LucideIcons.check, size: 18, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _panel(BuildContext context, Widget list) => GlossSurface(
  face: glossPanelFace(GlossTheme.of(context).colors),
  child: Padding(padding: const EdgeInsets.all(glossPanelInset), child: list),
);

Widget _nothing(BuildContext context) {
  final theme = GlossTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: GlossSpacing.medium,
      vertical: GlossSpacing.medium,
    ),
    child: Text(
      DesignLocalizations.of(context).noResultsLabel,
      style: theme.textTheme.secondary,
    ),
  );
}

// A search on its way: a small spinner and its word.
Widget _searching(BuildContext context) {
  final theme = GlossTheme.of(context);
  return Padding(
    padding: const EdgeInsets.all(GlossSpacing.medium),
    child: Row(
      children: [
        const ExcludeSemantics(child: GlossSpinner(size: 16)),
        const SizedBox(width: GlossSpacing.small),
        Flexible(
          child: Text(
            DesignLocalizations.of(context).loadingLabel,
            style: theme.textTheme.secondary,
          ),
        ),
      ],
    ),
  );
}

// A search that failed: what happened, and Try again as an option row, lit
// while the keys are on it (the focus stays in the field).
Widget _failed(BuildContext context, DesignSearchError error) {
  final theme = GlossTheme.of(context);
  final words = DesignLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          GlossSpacing.medium,
          GlossSpacing.medium,
          GlossSpacing.medium,
          GlossSpacing.small,
        ),
        child: Text(
          words.searchFailedMessage,
          style: theme.textTheme.secondary,
        ),
      ),
      Semantics(
        button: true,
        label: words.retryButtonLabel,
        onTap: error.retry,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: error.retry,
            child: _OptionRow(
              label: words.retryButtonLabel,
              states: {if (error.focused) WidgetState.focused},
            ),
          ),
        ),
      ),
    ],
  );
}

/// A field that suggests as you type: the text field's well with the
/// options in a porcelain list under it, as wide as the field. The
/// pointer's row and the keys' row are one row.
///
/// Enter takes the lit option and keeps the focus in the field.
///
/// ```dart
/// GlossCombobox<String>(label: 'Cuisine', options: const ['Indian', 'Italian', 'Japanese'], onSelected: (cuisine) {})
/// ```
class GlossCombobox<T extends Object> extends StatelessWidget {
  /// A combobox over [options].
  const GlossCombobox({
    super.key,
    this.options = const [],
    this.search,
    this.value,
    this.onSelected,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.requireSelection = false,
    this.debounceDuration,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The options, filtered by the words typed.
  final Iterable<T> options;

  /// Finds the options for a query itself (a server's search), instead of
  /// filtering [options].
  final DesignOptionSearch<T>? search;

  /// The option taken.
  final T? value;

  /// An option taken.
  final ValueChanged<T>? onSelected;

  /// An option's words; null: its `toString`.
  final String Function(T option)? displayStringForOption;

  /// Whether an option can be taken; null: all can.
  final bool Function(T option)? isOptionEnabled;

  /// Whether the field must hold an option's words when it loses the focus.
  final bool requireSelection;

  /// How long the typing rests before [search] runs; null runs it at once.
  /// While a search is on its way the list says so; when it fails, the list
  /// says that and offers Try again.
  final Duration? debounceDuration;

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// The words above the well.
  final String? label;

  /// What the empty field says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Whether it takes input.
  final bool enabled;

  /// What a screen reader calls it; null: [label].
  final String? semanticLabel;

  /// This field's own style, over [GlossThemeData.comboboxStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final words = displayStringForOption ?? _words;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: GlossFieldLabel(label!, enabled: enabled)),
        DesignCombobox<T>(
          options: options,
          search: search,
          value: value,
          onSelected: onSelected,
          displayStringForOption: words,
          isOptionEnabled: isOptionEnabled,
          requireSelection: requireSelection,
          controller: controller,
          focusNode: focusNode,
          highlightFollowsPointer: true,
          semanticLabel: semanticLabel ?? label,
          fieldBuilder: (context, field) => _OnFocus(
            focusNode: field.focusNode,
            builder: (context, focused) {
              final states = {
                if (!enabled) WidgetState.disabled,
                if (focused) WidgetState.focused,
                if (error != null) WidgetState.error,
              };
              final layered = DesignStyleOf([
                style,
                theme.comboboxStyle,
              ], states);
              return GlossEntryWell(
                focusNode: field.focusNode,
                enabled: enabled,
                face: glossEntryFace(
                  theme,
                  states,
                  fill: layered.fill,
                  edge: layered.edge,
                ),
                trailing: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: GlossSpacing.small,
                  ),
                  child: GlossChevron(
                    open: focused,
                    color: enabled
                        ? theme.colors.inkSecondary
                        : theme.colors.inkDisabled,
                  ),
                ),
                // Enter takes the lit option and keeps the focus here (on
                // the web a restarted input would lose the typing).
                child: GlossEntryText(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  hint: hint,
                  enabled: enabled,
                  // The field is named as its label reads (ui_core's
                  // semanticLabel names the list of options).
                  semanticLabel: semanticLabel ?? label,
                  onEditingComplete: field.submit,
                  textStyle: layered.textStyle,
                ),
              );
            },
          ),
          optionBuilder: (context, option, states) =>
              _OptionRow(label: words(option), states: states),
          surfaceBuilder: _panel,
          emptyBuilder: _nothing,
          debounceDuration: debounceDuration,
          loadingBuilder: _searching,
          errorBuilder: _failed,
        ),
        GlossFieldMessage(helper: helper, error: error),
      ],
    );
  }
}

/// Values held as pearl tags in a well, with a field after them that
/// suggests and makes more. Enter, or a comma, makes the typed words a tag
/// and keeps the focus for the next.
///
/// ```dart
/// GlossTagInput<String>(label: 'Pantry', values: const ['Rice'], onChanged: (values) {}, onCreate: (text) => text)
/// ```
class GlossTagInput<T extends Object> extends StatelessWidget {
  /// A tag input over [values].
  const GlossTagInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.onCreate,
    this.displayStringForOption,
    this.isOptionEnabled,
    this.maxTags,
    this.debounceDuration,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The tags.
  final List<T> values;

  /// The new tags; a disabled input ignores it.
  final ValueChanged<List<T>> onChanged;

  /// Suggestions, filtered by the words typed.
  final Iterable<T> options;

  /// Finds the suggestions for a query itself.
  final DesignOptionSearch<T>? search;

  /// Makes a tag of typed words; null: only suggestions become tags.
  final T? Function(String text)? onCreate;

  /// A value's words; null: its `toString`.
  final String Function(T value)? displayStringForOption;

  /// Whether a suggestion can be taken; null: all can.
  final bool Function(T option)? isOptionEnabled;

  /// The most tags it holds.
  final int? maxTags;

  /// How long the typing rests before [search] runs; null runs it at once.
  /// While a search is on its way the list says so; when it fails, the list
  /// says that and offers Try again.
  final Duration? debounceDuration;

  /// The words, when the caller reads or sets them; null: the field keeps
  /// its own.
  final TextEditingController? controller;

  /// The focus, when the caller moves it; null: the field keeps its own.
  final FocusNode? focusNode;

  /// The words above the well.
  final String? label;

  /// What the empty field says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Whether it takes input.
  final bool enabled;

  /// What a screen reader calls it; null: [label].
  final String? semanticLabel;

  /// This input's own style, over [GlossThemeData.tagInputStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = displayStringForOption ?? _words;
    final input = DesignTagInput<T>(
      values: values,
      onChanged: enabled ? onChanged : (_) {},
      options: options,
      search: search,
      onCreate: onCreate,
      displayStringForOption: words,
      isOptionEnabled: isOptionEnabled,
      maxTags: maxTags,
      controller: controller,
      focusNode: focusNode,
      highlightFollowsPointer: true,
      semanticLabel: semanticLabel ?? label,
      // The typing line: its whole slot takes a tap (as a field's well
      // does), and its words stand where every field's and its list's do.
      // Beside tags it is a short line after the last (it scrolls as it
      // fills), so the tags and the line share a row; alone it spans the
      // well and shows its hint.
      fieldBuilder: (context, field) => ConstrainedBox(
        constraints: values.isEmpty
            ? const BoxConstraints(minWidth: 96)
            : const BoxConstraints(minWidth: 96, maxWidth: 168),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? field.focusNode.requestFocus : null,
          child: Padding(
            // Alone in the well its words stand where every field's do: the
            // well keeps a tag's inset, the line makes up the rest.
            padding: EdgeInsetsDirectional.only(
              start: values.isEmpty
                  ? 2 * GlossSpacing.small - _tagInset(theme)
                  : GlossSpacing.small,
            ),
            child: SizedBox(
              height: _tagSlot,
              // Enter makes a tag and keeps the focus for the next one.
              child: GlossEntryText(
                controller: field.controller,
                focusNode: field.focusNode,
                hint: values.isEmpty ? hint : null,
                enabled: enabled,
                semanticLabel: semanticLabel ?? label,
                minHeight: _tagSlot,
                onEditingComplete: field.submit,
              ),
            ),
          ),
        ),
      ),
      optionBuilder: (context, option, states) =>
          _OptionRow(label: words(option), states: states),
      tagBuilder: (context, value, tag) =>
          _Tag(label: words(value), tag: tag, enabled: enabled),
      surfaceBuilder: _panel,
      debounceDuration: debounceDuration,
      loadingBuilder: _searching,
      errorBuilder: _failed,
      layoutBuilder: (context, tags, field) => _TagWell(
        enabled: enabled,
        error: error != null,
        style: style,
        tags: tags,
        field: field,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: GlossFieldLabel(label!, enabled: enabled)),
        DefaultTextStyle.merge(
          style: TextStyle(color: c.ink),
          child: input,
        ),
        GlossFieldMessage(helper: helper, error: error),
      ],
    );
  }
}

class _TagWell extends StatefulWidget {
  const _TagWell({
    required this.enabled,
    required this.error,
    required this.style,
    required this.tags,
    required this.field,
  });

  final bool enabled;
  final bool error;
  final GlossStyle? style;
  final List<Widget> tags;
  final Widget field;

  @override
  State<_TagWell> createState() => _TagWellState();
}

class _TagWellState extends State<_TagWell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final states = {
      if (!widget.enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
      if (widget.error) WidgetState.error,
    };
    final layered = DesignStyleOf([widget.style, theme.tagInputStyle], states);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.controlHeight),
          child: AnimatedGlossSurface(
            face: glossEntryFace(
              theme,
              states,
              fill: layered.fill,
              edge: layered.edge,
            ),
            // Each tag and the line stand in a slot a finger's height; the
            // well round them is a control's height for one row.
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _tagInset(theme),
                vertical: math.max(0, (theme.controlHeight - _tagSlot) / 2),
              ),
              child: Wrap(
                spacing: GlossSpacing.tight,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [...widget.tags, widget.field],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The slot a tag or the tag input's line stands in: a finger's height, so
/// the bead that removes a tag and the line itself each take a whole tap.
const double _tagSlot = 44;

/// A tag's capsule: a control's height less the room round it in the well.
double _tagHeight(GlossThemeData theme) => theme.controlHeight - 12;

/// How far a tag stands in from the well's rim: the same at its start as
/// above and below it, so the capsule sits evenly in the field's corner.
double _tagInset(GlossThemeData theme) =>
    (math.max(theme.controlHeight, _tagSlot) - _tagHeight(theme)) / 2;

/// A tag: a small pearl capsule with its words and a bead that removes it.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tag, required this.enabled});

  final String label;
  final DesignTagDetails tag;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    // The capsule stands in a slot a finger's height; the bead that removes
    // it is the slot's whole square at the capsule's end, over the end of
    // its words' cell.
    return SizedBox(
      height: _tagSlot,
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          SizedBox(
            height: _tagHeight(theme),
            child: GlossSurface(
              face: GlossFace.pearl(c).copyWith(
                foreground: enabled ? c.ink : c.inkDisabled,
                lens: enabled ? null : 0.25,
                focus: glossFocusOf(c, focused: tag.focused),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: GlossSpacing.medium,
                  end: _tagSlot - GlossSpacing.small,
                ),
                // The words centred in the capsule's height, level with
                // the bead that removes it.
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: DesignCapCenter(
                    capHeightFactor: glossCapHeightFactor,
                    child: Text(
                      label,
                      style: theme.textTheme.secondary.copyWith(
                        color: enabled ? c.ink : c.inkDisabled,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: _tagSlot,
            child: DesignPressable(
              onPressed: enabled ? tag.onDeleted : null,
              semanticLabel: '${words.tagInputDeleteLabel} $label',
              builder: (context, states, _) => Center(
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: enabled ? c.inkSecondary : c.inkDisabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A form: [GlossFormField]s inside it are checked together, and a failed
/// submit moves the focus to the first one that is wrong.
typedef GlossForm = DesignForm;

/// Any control with its label, help and error, as one field: the label
/// above it names it to a screen reader, the error under it is announced
/// as it appears. A group of controls (a row or column of them, a
/// segmented choice, a stepper, chips) keeps each control's own node and
/// tap, and the label names the group ([mergeSemantics]).
///
/// ```dart
/// GlossFormField(labelText: 'Units', helperText: 'For every recipe', child: GlossSwitch(value: true, onChanged: (_) {}))
/// ```
class GlossFormField extends StatelessWidget {
  /// A field around [child].
  const GlossFormField({
    super.key,
    required this.child,
    this.labelText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.focusNode,
    this.mergeSemantics,
  });

  /// The control.
  final Widget child;

  /// The words above it.
  final String? labelText;

  /// Help under it.
  final String? helperText;

  /// What is wrong, under it.
  final String? errorText;

  /// Whether it must be filled: a jade mark after the label.
  final bool isRequired;

  /// Whether it takes input.
  final bool enabled;

  /// The control's focus, which a tap on the label asks for.
  final FocusNode? focusNode;

  /// Whether the control is one node that takes the label as its name
  /// (true) or a group the label names (false). Left null, ui_core's
  /// DesignField reads what the child brings to the semantics tree: one
  /// control is one node; several (a stepper's keys, a segmented choice,
  /// radios, chips) keep each its own node and tap, the label naming them;
  /// and a group that already names itself is not named again.
  final bool? mergeSemantics;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignField(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      required: isRequired,
      enabled: enabled,
      focusNode: focusNode,
      mergeSemantics: mergeSemantics,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: GlossSpacing.small),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.label.copyWith(
                  color: enabled ? c.inkSecondary : c.inkDisabled,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: parts.label!),
                    if (isRequired)
                      Text(
                        ' *',
                        style: theme.textTheme.label.copyWith(color: c.jadeInk),
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: parts.control,
          ),
          if (parts.error != null)
            Padding(
              padding: const EdgeInsets.only(top: GlossSpacing.tight + 2),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.secondary.copyWith(color: c.danger),
                child: parts.error!,
              ),
            )
          else if (parts.helper != null)
            Padding(
              padding: const EdgeInsets.only(top: GlossSpacing.tight + 2),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.secondary,
                child: parts.helper!,
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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(FlagProperty('isRequired', value: isRequired, ifTrue: 'required'));
  }
}
