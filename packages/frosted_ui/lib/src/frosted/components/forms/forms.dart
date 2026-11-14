import 'package:material_ui/material_ui.dart'
    show
        InputBorder,
        InputDecoration,
        Material,
        MaterialType,
        TextField,
        Theme,
        VisualDensity;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/css_shadow.dart';
import '../../internal/face.dart';
import '../../internal/well.dart';
import '../../internal/field_owner.dart';
import '../../internal/styled.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../theme.dart';
import '../icon-button/round_button.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';
import '../../editing.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

import 'package:ui_core/ui_core.dart';

// metric: `.stepper .inp--amt { width: 3ch }`, the stepper's figure room
// (FrostedChromeMetrics names the well, not the input's width).
const int _stepperFigureChars = 3;

// metric: `.inp--amt::placeholder { color: rgba(21,21,45,.22) }`, the amount
// well's placeholder share of the ink (no FrostedThemeData role names it).
const double _amountPlaceholderOpacity = 0.22;

// metric: `.search { font: 400 16px/1 var(--font-t) }`, the search pill's
// line (FrostedChromeMetrics names the pill's height, inset and glyph).
const double _searchLine = 16;

// metric: `.search--on { background: rgba(255,255,255,.9) }`, the search
// pill's face once it holds a query, as a share of the plane.
const double _searchTypedOpacity = 0.9;

// metric: `.swap span { box-shadow: ..., 0 4px 10px -6px rgba(42,36,100,.3) }`,
// the swap disc's lift in the raised shade (FrostedThemeData.raisedShadow is the
// softer 0 2px 6px -2px at .18).
const double _swapShadowY = 4;
const double _swapShadowBlur = 10;
const double _swapShadowSpread = -6;
const double _swapShadowOpacity = 0.3;

/// The source's `--edge` (`0 0 0 1px`): a hairline ring just outside a
/// white or glass face, taking no room, as the tiles draw it.
BoxShadow _edge(FrostedThemeData t) =>
    frostedShadow(color: t.glass.edge, spread: FrostedChromeMetrics.outline);

// ---------------------------------------------------------------------------
// Text field
// ---------------------------------------------------------------------------

/// A line of text in a well (`.field` + `.inp`): the label 8 over a 48
/// well, 12 round, 14 in at each side, the text 400 16 in the ink and the
/// placeholder in the tertiary ink, an optional help line 8 under
/// (`.field-h`). The page owns the text through [value] and [onChanged],
/// or hands a [controller]; with neither callback nor controller the
/// field is read only. A screen reader hears a text field named [label].
///
/// ```dart
/// FrostedTextField(label: 'Name', hint: 'What are you saving for?', value: name, onChanged: (v) => setState(() => name = v))
/// ```
class FrostedTextField extends StatefulWidget {
  /// Creates a [FrostedTextField].
  const FrostedTextField({
    required this.label,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.leading,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.error,
    this.enabled = true,
    this.obscureText = false,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.style,
    this.textDirection,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String label;

  /// The direction the words are typed in; null follows the page. Codes,
  /// addresses and hex values read left to right in any language
  /// ([TextDirection.ltr]): under a right-to-left page "#FF7A59B3" would
  /// otherwise show as "FF7A59B3#".
  final TextDirection? textDirection;

  /// The fewest lines the well stands for; null for one.
  final int? minLines;

  /// The most lines the well grows to before it scrolls; 1 is a single
  /// line, null grows without end ([FrostedTextArea] sets several).
  final int? maxLines;

  /// What is wrong with the text: drawn under the well in the over ink, in
  /// place of [helper], with the well's edge in the same ink.
  final String? error;

  /// Whether the field takes text; a disabled field stands at half strength
  /// and takes no focus.
  final bool enabled;

  /// Whether the text is hidden as it is typed (a passcode).
  final bool obscureText;

  /// What the platform's autofill may offer (`AutofillHints.email`, ...).
  final Iterable<String>? autofillHints;

  /// What the text is held to as it is typed.
  final List<TextInputFormatter>? inputFormatters;

  /// The longest the text may grow, in characters.
  final int? maxLength;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called with the text when the keyboard's done key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The text's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// What the empty well says (What are you saving for?).
  final String? hint;

  /// The help line under the well.
  final String? helper;

  /// A glyph or word before the text, drawn in the tertiary ink.
  final Widget? leading;

  /// A control after the text.
  final Widget? trailing;

  /// Which keyboard it raises.
  final TextInputType? keyboardType;

  /// This field's own style, over `FrostedThemeData.components.textField`:
  /// the well's fill, the text's colour and style, the ring's colour or a
  /// whole side, an overlay, its shape ([FrostedCorners.small] by
  /// default), padding and least size, each per state (focused, error,
  /// disabled).
  ///
  /// ```dart
  /// FrostedTextField(
  ///   label: 'Name',
  ///   value: name,
  ///   onChanged: setName,
  ///   style: FrostedStyle(
  ///     edge: WidgetStateProperty.resolveWith(
  ///       (states) => states.contains(WidgetState.focused)
  ///           ? const Color(0xFF5B5BD6)
  ///           : null,
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  /// The keyboard's done key.
  final TextInputAction? textInputAction;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  @override
  State<FrostedTextField> createState() => _FrostedTextFieldState();
}

class _FrostedTextFieldState extends State<FrostedTextField>
    with FrostedFieldOwner<FrostedTextField> {
  @override
  TextEditingController? controllerOf(FrostedTextField w) => w.controller;

  @override
  String? valueOf(FrostedTextField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedTextField w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .inp { height: 48px; padding: 0 14px; border-radius: 12px;
    //   font: 400 16px/1.2 var(--font-t); color: var(--ink) }
    // .inp::placeholder { color: var(--ink-3) }
    final layers = FrostedStyleLayers(widget.style, t.components.textField);
    final style = layers
        .at({
          if (fieldFocus.hasFocus) WidgetState.focused,
          if (widget.error != null) WidgetState.error,
          if (!widget.enabled) WidgetState.disabled,
        })
        .words(t.textTheme.bodyLarge.line(19.2));
    final readOnly = widget.onChanged == null && widget.controller == null;
    final multi = widget.maxLines != 1;
    // The well is at least the field's height and grows with larger text;
    // one line stands on its centre by alignment. Several lines start
    // where the one line stands: half the well's room over the line.
    final line =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 16) *
        (style.height ?? 1.2);
    final over = multi
        ? ((FrostedChromeMetrics.field - line) / 2).clamp(0.0, double.infinity)
        : 0.0;
    final maxLength = widget.maxLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        FrostedFieldLabel(widget.label),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FrostedChromeMetrics.field,
          ),
          child: FrostedWell(
            layers: layers,
            focused: fieldFocus.hasFocus,
            error: widget.error != null,
            enabled: widget.enabled,
            padding: EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.fieldInset,
              vertical: over,
            ),
            child: Row(
              spacing: FrostedSpacing.s8,
              crossAxisAlignment: multi
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (widget.leading case final leading?)
                  DefaultTextStyle.merge(
                    style: style.c(t.colorScheme.textTertiary),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        size: FrostedIconSize.i18,
                        color: t.colorScheme.textTertiary,
                      ),
                      child: leading,
                    ),
                  ),
                Expanded(
                  child: FrostedFieldTarget(
                    label: widget.label,
                    child: Material(
                      type: MaterialType.transparency,
                      child: frostedCapCentredEntry(
                        style,
                        one: !multi,
                        TextField(
                          contextMenuBuilder: FrostedTextContextMenu.editable,
                          selectionControls: FrostedTextSelectionControls.of(
                            Theme.of(context).platform,
                          ),
                          controller: fieldController,
                          focusNode: fieldFocus,
                          textDirection: widget.textDirection,
                          autofocus: widget.autofocus,
                          readOnly: readOnly,
                          enabled: widget.enabled,
                          obscureText: widget.obscureText,
                          autofillHints: widget.autofillHints,
                          // The length is held by a formatter: a maxLength
                          // on the TextField adds a counter line under it.
                          inputFormatters: [
                            ...?widget.inputFormatters,
                            if (maxLength != null)
                              LengthLimitingTextInputFormatter(maxLength),
                          ],
                          minLines: widget.minLines,
                          maxLines: widget.maxLines,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          keyboardType:
                              widget.keyboardType ??
                              (multi ? TextInputType.multiline : null),
                          textInputAction:
                              widget.textInputAction ??
                              (multi ? TextInputAction.newline : null),
                          style: style,
                          cursorColor: t.colorScheme.textPrimary,
                          decoration: _bareDecoration(
                            hint: widget.hint,
                            hintStyle: style.c(t.colorScheme.textTertiary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ?widget.trailing,
              ],
            ),
          ),
        ),
        if (widget.error case final error?)
          FrostedFieldHint(error, error: true)
        else if (widget.helper case final helper?)
          FrostedFieldHint(helper),
      ],
    );
  }
}

/// A field for a few lines of text (a note, a message, a description):
/// [FrostedTextField]'s well standing [minLines] lines tall and growing to
/// [maxLines] before it scrolls, its label over it and its help or error
/// under it. Return starts a new line.
///
/// ```dart
/// FrostedTextArea(label: 'Notes', hint: 'Anything the team should know', value: notes, onChanged: (v) => setState(() => notes = v))
/// ```
class FrostedTextArea extends StatelessWidget {
  /// A text area labelled [label].
  const FrostedTextArea({
    required this.label,
    this.value,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 8,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String label;

  /// The text, when the page owns it.
  final String? value;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// The text's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// The words in the empty well.
  final String? hint;

  /// One line of help under the well.
  final String? helper;

  /// What is wrong with the text, in place of [helper].
  final String? error;

  /// Whether it takes text.
  final bool enabled;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The longest the text may grow, in characters.
  final int? maxLength;

  /// The lines it stands at empty, and the most it grows to.
  final int minLines;

  /// The most lines it grows to before it scrolls.
  final int maxLines;

  @override
  Widget build(BuildContext context) => FrostedTextField(
    label: label,
    value: value,
    onChanged: onChanged,
    controller: controller,
    focusNode: focusNode,
    hint: hint,
    helper: helper,
    error: error,
    enabled: enabled,
    autofocus: autofocus,
    maxLength: maxLength,
    minLines: minLines,
    maxLines: maxLines,
  );
}

// ---------------------------------------------------------------------------
// Amount field
// ---------------------------------------------------------------------------

/// How large a [FrostedAmountField] stands.
enum FrostedAmountFieldSize {
  /// A 64 well, 14 round, the figure 500 40 in the display face: a page's
  /// own amount.
  regular,

  /// A 48 well, 12 round, the figure 400 16 in the text face on the centre
  /// line (`.amount-in--sm`): an amount among a form's fields.
  small,
}

/// An amount in a well (`.amount-in`): the label 8 over a 64 well, 14
/// round, with the dollar sign in the quiet ink (500 16 display, dropped 6)
/// before the figure in the 500 40 display face, tabular and tracked
/// −.03em, 12 under the top; the placeholder at .22 of the ink. A small
/// [size] is the form's `.amount-in--sm`: a 48 well, 12 round, the figure 400 16 in
/// the text face on the centre line. [centered] is a stepper's
/// `.amount-in--c`: the sign and figure together on the well's centre, the
/// figure given three characters' room. [showLabel] false drops the label,
/// keeping it as the spoken name. Takes digits and one point; the page owns the text
/// through [value] and [onChanged], or a [controller]; with neither it is
/// read only. A screen reader hears a text field named [label].
///
/// ```dart
/// FrostedAmountField(label: 'Amount', value: amount, onChanged: (v) => setState(() => amount = v))
/// ```
class FrostedAmountField extends StatefulWidget {
  /// Creates a [FrostedAmountField].
  const FrostedAmountField({
    required this.label,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.hint = '0',
    this.helper,
    this.size = FrostedAmountFieldSize.regular,
    this.centered = false,
    this.showLabel = true,
    this.autofocus = false,
    super.key,
  });

  /// The label over the well, and the field's spoken name.
  final String label;

  /// The figure's text, when the page owns it (500.00).
  final String? value;

  /// Called as the figure changes.
  final ValueChanged<String>? onChanged;

  /// Called with the figure when the keyboard's done key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The figure's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// What the empty well shows after the sign.
  final String hint;

  /// The help line under the well.
  final String? helper;

  /// How large the field stands: the 64 well, or the form's 48
  /// (`.amount-in--sm`).
  final FrostedAmountFieldSize size;

  /// The sign and figure on the well's centre (`.amount-in--c`).
  final bool centered;

  /// Whether the [label] stands over the well; without it the label stays
  /// the spoken name.
  final bool showLabel;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  @override
  State<FrostedAmountField> createState() => _FrostedAmountFieldState();
}

class _FrostedAmountFieldState extends State<FrostedAmountField>
    with FrostedFieldOwner<FrostedAmountField> {
  static final _allowed = FilteringTextInputFormatter.allow(RegExp('[0-9.]'));

  @override
  TextEditingController? controllerOf(FrostedAmountField w) => w.controller;

  @override
  String? valueOf(FrostedAmountField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedAmountField w) => w.focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final small = widget.size == FrostedAmountFieldSize.small;
    // .amount-in { align-items: flex-start; gap: 2px; height: 64px;
    //   padding: 12px 16px 0; border-radius: 14px }
    // .amount-in .cur { font: 500 16px/1 var(--font-d); color: var(--ink-q);
    //   margin-top: 6px }
    // .inp--amt { height: 40px; font: 500 40px/1 var(--font-d);
    //   letter-spacing: -.03em; font-variant-numeric: tabular-nums }
    // .amount-in--sm { height: 48px; align-items: center; padding: 0 14px;
    //   border-radius: 12px }  .amount-in--sm .cur { margin-top: 0 }
    // .amount-in--sm .inp--amt { font: 400 16px/1.2 var(--font-t) }
    final style = small
        ? t.textTheme.bodyLarge.line(19.2)
        : t.textTheme.displaySmall
              .line(FrostedChromeMetrics.amountWellFigure)
              .tracked(-0.03)
              .tabular;
    final placeholderInk = small
        ? t.colorScheme.textTertiary
        : t.colorScheme.textPrimary.withValues(
            alpha: _amountPlaceholderOpacity,
          );
    final readOnly = widget.onChanged == null && widget.controller == null;
    Widget input = FrostedFieldTarget(
      label: widget.label,
      child: Material(
        type: MaterialType.transparency,
        child: frostedCapCentredEntry(
          style,
          TextField(
            contextMenuBuilder: FrostedTextContextMenu.editable,
            selectionControls: FrostedTextSelectionControls.of(
              Theme.of(context).platform,
            ),
            controller: fieldController,
            focusNode: fieldFocus,
            autofocus: widget.autofocus,
            readOnly: readOnly,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_allowed],
            style: style,
            cursorColor: t.colorScheme.textPrimary,
            decoration: _bareDecoration(
              hint: widget.hint,
              hintStyle: style.c(placeholderInk),
            ),
          ),
        ),
      ),
    );
    if (widget.centered) {
      // .stepper .inp--amt { width: 3ch; text-align: left }: a ch is the
      // zero's own advance, without the figure's tracking or its tabular
      // figures (taken with them, the room stood 3.6 narrower and the
      // sign and figure 2.8 right of the source's).
      final room = TextPainter(
        text: TextSpan(
          text: '0' * _stepperFigureChars,
          style: style.copyWith(letterSpacing: 0, fontFeatures: const []),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = room.width;
      room.dispose();
      // A stepper's figure: its entry as tall as the rounds beside it
      // (48), so the row shows one top and one bottom; its capitals stay on
      // the middle.
      // Flexible: at large text the figure's room can outgrow the well, and
      // the entry then scrolls within what is left beside the sign.
      input = Flexible(
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: width,
              minHeight: FrostedChromeMetrics.stepper,
            ),
            child: input,
          ),
        ),
      );
    } else {
      input = Expanded(child: input);
    }
    final sign = Padding(
      padding: EdgeInsets.only(
        // In a stepper the figure's line stands 4 lower in its 48 entry.
        top: small
            ? 0
            : FrostedChromeMetrics.amountWellCurrencyDrop +
                  (widget.centered
                      ? (FrostedChromeMetrics.stepper -
                                FrostedChromeMetrics.amountWellFigure) /
                            2
                      : 0),
      ),
      child: Text(
        r'$',
        textScaler: TextScaler.noScaling,
        style: t.textTheme.titleMedium.display
            .line(FrostedChromeMetrics.amountWellCurrency)
            .c(t.colorScheme.textTertiary),
      ),
    );
    // The well is at least its height and grows with larger text; the sign
    // and figure stand on its centre line by alignment, which at the
    // figure's own size is the source's 12 under the top.
    final well = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: small
            ? FrostedChromeMetrics.amountWellSmall
            : FrostedChromeMetrics.amountWell,
      ),
      child: FrostedWell(
        radius: small
            ? FrostedChromeMetrics.amountWellSmallRadius
            : FrostedChromeMetrics.amountWellRadius,
        focused: fieldFocus.hasFocus,
        padding: EdgeInsets.symmetric(
          horizontal: small
              ? FrostedChromeMetrics.amountWellSmallInset
              : FrostedChromeMetrics.amountWellInset,
        ),
        // heightFactor: given room to spare (a dialog, a tile with a
        // ceiling) the well keeps its own height rather than filling it.
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          // The sign before the figure, and the figure typed left to right,
          // in any language ("$500.00", never "500.00 $").
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: widget.centered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: small
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.amountWellGap,
              children: [sign, input],
            ),
          ),
        ),
      ),
    );
    if (!widget.showLabel && widget.helper == null) return well;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        if (widget.showLabel) FrostedFieldLabel(widget.label),
        well,
        if (widget.helper case final helper?) FrostedFieldHint(helper),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// The search pill's face (`.search`): 44 tall on the brighter glass with
/// its rim and hairline edge, 16 in at each side; once it holds a query
/// (`.search--on`) the plane at .9 and the ink.
class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.typed,
    required this.child,
    this.clearing = false,
    this.focused = false,
  });

  final bool typed;

  /// Whether the clear round stands at the end, pulled 6 into the inset.
  final bool clearing;

  /// Whether the field holds focus: the edge takes the accent, as a
  /// well's does.
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .search { gap: 10px; height: 44px; padding: 0 16px;
    //   border-radius: 999px; background: var(--glass-hi);
    //   box-shadow: var(--rim), var(--edge); color: var(--ink-3);
    //   font: 400 16px/1 var(--font-t) }  .search .i { 18px }
    // .search--on { color: var(--ink); background: rgba(255,255,255,.9) }
    // .search-x { margin-right: -6px }
    // At least the pill's height, growing with larger text; the line
    // stands on its centre by the row's alignment.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FrostedChromeMetrics.search),
      child: FrostedFace(
        material: FrostedMaterial.well,
        radius: BorderRadius.circular(FrostedChromeMetrics.search / 2),
        color: typed || (focused && !t.isDark)
            ? t.glass.plane.withValues(alpha: _searchTypedOpacity)
            : null,
        // By day the well wears one even lit rim all round, and holding
        // focus it brightens, glows and its edge takes the ring's ink; by
        // night its edge is the night glass's rim (the accent while it
        // holds focus).
        sheen: t.isDark ? t.glass.rim : null,
        ring: t.isDark
            ? null
            : focused
            ? t.colorScheme.ringOuter
            : FrostedChromeMetrics.litEdge,
        shadows: [
          if (t.isDark && focused)
            frostedShadow(
              color: t.colorScheme.accent,
              spread: FrostedChromeMetrics.outline,
            )
          else if (t.isDark)
            frostedShadow(
              color: t.controlEdge,
              spread: FrostedChromeMetrics.outline,
            )
          else if (focused)
            ...frostedFocusGlow,
        ],
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: FrostedChromeMetrics.searchInset,
            end: clearing
                ? FrostedChromeMetrics.searchInset -
                      FrostedChromeMetrics.searchClearPull
                : FrostedChromeMetrics.searchInset,
          ),
          child: Row(
            spacing: FrostedChromeMetrics.searchGap,
            children: [
              Icon(
                FrostedGlyphs.search,
                size: FrostedChromeMetrics.searchGlyph,
                color: typed
                    ? t.colorScheme.textPrimary
                    : t.colorScheme.textTertiary,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line of search (`.search` with its input): the pill with the 18 glass
/// glyph, the query 400 16 in the ink, the placeholder in the tertiary
/// ink; once it holds a query the pill brightens and a 28 round of the
/// wash with a 14 cross clears it (`.search-x`). The page owns the query
/// through [value] and [onChanged], or hands a [controller]. [onClear]
/// makes the clear a link of the page's (back to the plain list); without
/// it the clear empties the field. A screen reader hears a search field
/// named [label] (else [hint]) and a button, [clearLabel] (Clear).
///
/// ```dart
/// FrostedSearchField(hint: 'Search activity', value: query, onChanged: (v) => setState(() => query = v))
/// ```
class FrostedSearchField extends StatefulWidget {
  /// Creates a [FrostedSearchField].
  const FrostedSearchField({
    required this.hint,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.label,
    this.autofocus = false,
    this.onClear,
    this.clearLabel,
    this.clearKey,
    super.key,
  });

  /// What the empty pill says (Search activity).
  final String hint;

  /// The query, when the page owns it.
  final String? value;

  /// Called as the query changes.
  final ValueChanged<String>? onChanged;

  /// Called with the query when the keyboard's search key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// The query's controller, when the page keeps one.
  final TextEditingController? controller;

  /// The field's focus, when the page keeps one.
  final FocusNode? focusNode;

  /// The field's spoken name; null speaks [placeholder].
  final String? label;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Where the clear goes instead of emptying the field: the page's own
  /// way back to the plain list.
  final VoidCallback? onClear;

  /// What a screen reader calls the clear; null says `DesignLocalizations.clearButtonTooltip` ("Clear").
  final String? clearLabel;

  /// The walkthrough key set on the clear's hit target.
  final Key? clearKey;

  @override
  State<FrostedSearchField> createState() => _FrostedSearchFieldState();
}

class _FrostedSearchFieldState extends State<FrostedSearchField>
    with FrostedFieldOwner<FrostedSearchField> {
  @override
  TextEditingController? controllerOf(FrostedSearchField w) => w.controller;

  @override
  String? valueOf(FrostedSearchField w) => w.value;

  @override
  FocusNode? focusNodeOf(FrostedSearchField w) => w.focusNode;

  void _clear() {
    fieldController.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final typed = fieldController.text.isNotEmpty;
    final style = t.textTheme.bodyLarge.line(_searchLine);
    // .search-x { width: 28px; height: 28px; border-radius: 999px;
    //   background: var(--wash); color: var(--ink-2) }  .search-x .i { 14px }
    final clear = FrostedHitSlop(
      child: FrostedPressable(
        key: widget.clearKey,
        onPressed: widget.onClear ?? _clear,
        label:
            widget.clearLabel ??
            DesignLocalizations.of(context).clearButtonTooltip,
        role: widget.onClear == null
            ? FrostedPressRole.button
            : FrostedPressRole.link,
        radius: FrostedChromeMetrics.searchClear / 2,
        child: SizedBox.square(
          dimension: FrostedChromeMetrics.searchClear,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.searchClear / 2),
            color: t.glass.wash,
            child: Center(
              child: Icon(
                FrostedGlyphs.close,
                size: FrostedChromeMetrics.searchClearGlyph,
                color: t.colorScheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    return _SearchPill(
      typed: typed,
      clearing: typed,
      focused: fieldFocus.hasFocus,
      child: Row(
        spacing: FrostedChromeMetrics.searchGap,
        children: [
          Expanded(
            child: FrostedFieldTarget(
              label: widget.label ?? widget.hint,
              child: Material(
                type: MaterialType.transparency,
                child: frostedCapCentredEntry(
                  style,
                  TextField(
                    contextMenuBuilder: FrostedTextContextMenu.editable,
                    selectionControls: FrostedTextSelectionControls.of(
                      Theme.of(context).platform,
                    ),
                    controller: fieldController,
                    focusNode: fieldFocus,
                    autofocus: widget.autofocus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    style: style.c(t.colorScheme.textPrimary),
                    cursorColor: t.colorScheme.textPrimary,
                    decoration: _bareDecoration(
                      hint: widget.hint,
                      hintStyle: style.c(t.colorScheme.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (typed) clear,
        ],
      ),
    );
  }
}

/// The search pill as a way in (`<a class="search">`): the same face and
/// glyph with [placeholder] in the tertiary ink, or [value], a query the
/// page already holds, in the ink on the brightened pill; one link that
/// opens the search. A null [onPressed] leaves it inert.
///
/// ```dart
/// FrostedSearchLink(hint: 'Search activity', onPressed: () => Navigator.of(context).pushNamed('/activity/search'))
/// ```
class FrostedSearchLink extends StatelessWidget {
  /// Creates a [FrostedSearchLink].
  const FrostedSearchLink({
    required this.hint,
    required this.onPressed,
    this.value,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What the pill says with no query (Search activity).
  final String hint;

  /// Opens the search; null leaves the pill inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// A query the page already holds, shown in the ink.
  final String? value;

  /// The link's spoken name; null speaks [placeholder].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final typed = value != null && value!.isNotEmpty;
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label ?? hint,
      value: typed ? value : null,
      role: FrostedPressRole.link,
      radius: FrostedChromeMetrics.search / 2,
      child: _SearchPill(
        typed: typed,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: frostedCapCentred(
            Text(
              typed ? value! : hint,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodyLarge
                  .line(_searchLine)
                  .c(
                    typed
                        ? t.colorScheme.textPrimary
                        : t.colorScheme.textTertiary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker row and swap
// ---------------------------------------------------------------------------

/// A choice that opens a picker (`.pick`): the label 8 over a well at least
/// 60 tall, 14 round, 10 in (14 at its end), holding the choice's mark
/// ([leading], a [FrostedIconMark]), its [title] in the body over a quiet
/// [subtitle], what the page puts at the end ([trailing], a [FrostedAmount])
/// and a 16 chevron down. One button read as the label, the title and the
/// subtitle; a null [onPressed] leaves it inert.
///
/// ```dart
/// FrostedPickerRow(label: 'From', title: 'Everyday', subtitle: 'Checking ·· 4821', leading: FrostedIconMark(FrostedGlyphs.wallet, hue: t.hues.cyan), trailing: const FrostedAmount(6248.30, signed: false), onPressed: pickFrom)
/// ```
class FrostedPickerRow extends StatelessWidget {
  /// Creates a [FrostedPickerRow].
  const FrostedPickerRow({
    required this.label,
    required this.title,
    required this.onPressed,
    this.leading,
    this.subtitle,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The label over the well (From, To).
  final String label;

  /// The choice's name (Everyday).
  final String title;

  /// The quiet line under the title (Checking ·· 4821).
  final String? subtitle;

  /// The choice's mark, before the words.
  final Widget? leading;

  /// What stands at the end before the chevron: the account's balance.
  final Widget? trailing;

  /// What a press does (opens the picker); null leaves it inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .pick-r { gap: 12px; min-height: 60px; padding: 10px 14px 10px 10px;
    //   border-radius: 14px }  .pick-r .i-chevron-down { 16px; ink-3 }
    // .row-main { gap: 1px }  .row-t { font: 500 16px/1.25 var(--font-t) }
    // .row-s { font: 400 14px/1.3 var(--font-t); color: var(--ink-2) }
    final well = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FrostedChromeMetrics.picker),
      child: FrostedWell(
        radius: FrostedChromeMetrics.pickerRadius,
        padding: FrostedChromeMetrics.pickerInset,
        child: Row(
          spacing: FrostedChromeMetrics.pickerGap,
          children: [
            ?leading,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rowLineGap,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleMedium,
                  ),
                  if (subtitle case final subtitle?)
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium.line(18.2),
                    ),
                ],
              ),
            ),
            ?trailing,
            Icon(
              FrostedGlyphs.chevronDown,
              size: FrostedChromeMetrics.pickerGlyph,
              color: t.colorScheme.textTertiary,
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.fieldLabelGap,
      children: [
        FrostedFieldLabel(label),
        FrostedPressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: onPressed,
          label: subtitle == null
              ? '$label: $title'
              : '$label: $title, $subtitle',
          radius: FrostedChromeMetrics.pickerRadius,
          child: well,
        ),
      ],
    );
  }
}

/// The arrow between a transfer's From and To (`.swap`): a 32 white round
/// with its hairline edge and lift, a 16 arrow down in the secondary ink,
/// centred on the 16 between the two [FrostedPickerRow]s and over both wells.
/// It is that 16: a [FrostedFormSection] puts no gap of its own round it. The
/// source draws it as a mark a screen reader skips; with [onPressed] it is a
/// button named [label] that swaps the two (DERIVED).
///
/// ```dart
/// FrostedSwapButton()
/// ```
class FrostedSwapButton extends StatelessWidget {
  /// Creates a [FrostedSwapButton].
  const FrostedSwapButton({
    this.onPressed,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Swaps From and To; null draws the mark alone.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The button's spoken name, with [onPressed].
  final String? label;

  /// The height the swap stands in: the form's gap, the mark's own line
  /// and its two negative margins (`.swap { margin: -14px 0; height: 12px }`
  /// in a `.form { gap: 16px }`), which come to the one gap again.
  static const double height =
      FrostedChromeMetrics.formGap -
      FrostedChromeMetrics.swapPull +
      FrostedChromeMetrics.swapLine -
      FrostedChromeMetrics.swapPull +
      FrostedChromeMetrics.formGap;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? FrostedLocalizations.of(context).swap;
    final t = context.frostedTheme;
    const d = FrostedChromeMetrics.swap;
    // .swap span { width: 32px; height: 32px; background: #fff;
    //   color: var(--ink-2); box-shadow: var(--edge),
    //   0 4px 10px -6px rgba(42,36,100,.3) }  .swap .i { 16px }
    final shade = t.shadows.raised.first.color;
    Widget disc = SizedBox.square(
      dimension: d,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(d / 2),
        color: t.glass.plane,
        shadows: [
          _edge(t),
          frostedShadow(
            color: shade.withValues(alpha: _swapShadowOpacity),
            y: _swapShadowY,
            blur: _swapShadowBlur,
            spread: _swapShadowSpread,
          ),
        ],
        child: Center(
          child: Icon(
            FrostedGlyphs.arrowDown,
            size: FrostedChromeMetrics.swapGlyph,
            color: t.colorScheme.textSecondary,
          ),
        ),
      ),
    );
    disc = onPressed == null
        ? ExcludeSemantics(child: disc)
        : FrostedHitSlop(
            child: FrostedPressable(
              focusNode: focusNode,
              autofocus: autofocus,
              onPressed: onPressed,
              label: label,
              radius: d / 2,
              child: disc,
            ),
          );
    return SizedBox(
      height: height,
      child: OverflowBox(
        minHeight: d,
        maxHeight: d,
        child: Center(child: disc),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper
// ---------------------------------------------------------------------------

/// A budget's stepper (`.stepper`): a 48 glass round with a minus, the
/// amount well with the sign and figure on its centre, and a 48 round
/// with a plus, 12 apart; an optional [note] centred 8 under (a month).
/// The page owns [value]; each round moves it by [step], never under [min]
/// or over [max] (a round with nowhere to go is disabled), and the figure
/// typed into the well is handed back whole. A null [onChanged] leaves it
/// inert. A screen reader hears two buttons, Lower [label] and Raise
/// [label], round a text field named [label].
///
/// ```dart
/// FrostedNumberField(value: budget, onChanged: (v) => setState(() => budget = v), label: 'the budget', step: 10, note: 'a month')
/// ```
class FrostedNumberField extends StatelessWidget {
  /// Creates a [FrostedNumberField].
  const FrostedNumberField({
    required this.value,
    required this.onChanged,
    required this.label,
    this.step = 10,
    this.min = 0,
    this.max,
    this.note,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The number.
  final int value;

  /// Called with the new number; null leaves it inert.
  final ValueChanged<int>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What the rounds and the well are named by (the budget).
  final String label;

  /// How far one press moves the value.
  final int step;

  /// The floor the value never goes under.
  final int min;

  /// The ceiling, if any.
  final int? max;

  /// The quiet line centred under the stepper (a month).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = onChanged != null;
    final canLower = live && value - step >= min;
    final canRaise = live && (max == null || value + step <= max!);
    void typed(String text) {
      final n = int.tryParse(text);
      if (n == null) return;
      var next = n < min ? min : n;
      if (max case final max? when next > max) next = max;
      onChanged!(next);
    }

    // .stepper { gap: 12px }  .step-b { width: 48px; height: 48px }
    // .stepper .amount-in { flex: 1; justify-content: center }
    // .stepper-c { text-align: center; margin-top: -8px }
    final well = FrostedAmountField(
      focusNode: focusNode,
      autofocus: autofocus,
      label: label,
      value: '$value',
      onChanged: live ? typed : null,
      centered: true,
      showLabel: false,
    );
    final row = Row(
      spacing: FrostedChromeMetrics.stepperGap,
      children: [
        FrostedIconButton(
          FrostedGlyphs.remove,
          label: FrostedLocalizations.of(context).lower(label),
          size: FrostedIconButtonSize.large,
          onPressed: canLower ? () => onChanged!(value - step) : null,
          style: t.components.numberField,
        ),
        // Inert, the well dims with its rounds, as a disabled field does.
        Expanded(
          child: FrostedDim(off: !live, child: well),
        ),
        FrostedIconButton(
          FrostedGlyphs.add,
          label: FrostedLocalizations.of(context).raise(label),
          size: FrostedIconButtonSize.large,
          onPressed: canRaise ? () => onChanged!(value + step) : null,
          style: t.components.numberField,
        ),
      ],
    );
    if (note == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        const SizedBox(
          height:
              FrostedChromeMetrics.formGap -
              FrostedChromeMetrics.stepperNotePull,
        ),
        Text(
          note!,
          textAlign: TextAlign.center,
          style: t.textTheme.labelMedium.line(15.6),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Select
// ---------------------------------------------------------------------------

/// One value a [FrostedSelect] offers: its [value], the [label] shown and
/// spoken, a quiet [note] at the row's end, and whether it can be chosen.
@immutable
class FrostedSelectOption<T> {
  /// An option for [value], named [label].
  const FrostedSelectOption(
    this.value,
    this.label, {
    this.note,
    this.enabled = true,
  });

  /// What choosing it hands to [FrostedSelect.onChanged].
  final T value;

  /// Its words, in the well once chosen and in the menu.
  final String label;

  /// A quiet note at the end of its menu row.
  final String? note;

  /// Whether it can be chosen; a disabled one stands faded in the menu.
  final bool enabled;
}

/// One value of a few, chosen from a menu (Material's `DropdownMenu`): the
/// [label] 8 over a 48 well like a text field's, the chosen option's words
/// in it (or the [prompt] in the tertiary ink) and a 16 chevron down at its
/// end; a press drops a [FrostedMenu] of the [options] from the well, the
/// chosen one checked. The [helper] or the [error] (the well ringed in the
/// over ink) stands 8 under, fading out while the list drops over it. A null
/// [onChanged] leaves it faded and inert.
/// A screen reader hears a button named [label] with the chosen words as
/// its value.
///
/// ```dart
/// FrostedSelect<String>(label: 'Room', options: const [FrostedSelectOption('k', 'Kitchen'), FrostedSelectOption('s', 'Study')], value: room, onChanged: (v) => setState(() => room = v))
/// ```
class FrostedSelect<T> extends StatefulWidget {
  /// A select over [options]; a null [onChanged] disables it.
  const FrostedSelect({
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.prompt,
    this.helper,
    this.error,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The choices, in the menu's order.
  final List<FrostedSelectOption<T>> options;

  /// The chosen value; null shows the [prompt].
  final T? value;

  /// Hands over the value chosen in the menu.
  final ValueChanged<T>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The words over the well.
  final String? label;

  /// What the well says before anything is chosen (Select, by default).
  final String? prompt;

  /// A help line under the well.
  final String? helper;

  /// What is wrong, under the well in place of the [helper].
  final String? error;

  /// This select's own style, over `FrostedThemeData.components.textField`
  /// (a select wears a field's well): the well's fill, ring, shape,
  /// padding and least size, each per state.
  final FrostedStyle? style;

  @override
  State<FrostedSelect<T>> createState() => _FrostedSelectState<T>();
}

class _FrostedSelectState<T> extends State<FrostedSelect<T>> {
  // Whether its list is open. The line under the well fades out with the
  // list dropping over it, so no letter of it peeks past the list's rounded
  // corner, and back in as the list goes.
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final FrostedSelect<T>(
      :options,
      :value,
      :onChanged,
      :label,
      :prompt,
      :helper,
      :error,
      :style,
    ) = widget;
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final chosen = options.where((o) => o.value == value).firstOrNull;
    final change = onChanged;
    final shown = chosen?.label ?? prompt ?? words.select;
    final wrong = error;
    final help = helper;
    final field = Builder(
      builder: (anchor) => FrostedPressable(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onPressed: change == null
            ? null
            : () async {
                setState(() => _open = true);
                final picked = await FrostedMenu.show<T>(
                  anchor,
                  fitAnchor: true,
                  label: label ?? words.select,
                  items: [
                    for (final o in options)
                      FrostedMenuItem<T>(
                        o.value,
                        o.label,
                        checked: o.value == value,
                        enabled: o.enabled,
                        trailing: o.note == null
                            ? null
                            : Text(o.note!, style: t.textTheme.bodySmall),
                      ),
                  ],
                );
                if (mounted) setState(() => _open = false);
                if (picked != null && picked != value) change(picked);
              },
        label: label ?? words.select,
        value: chosen?.label,
        radius: FrostedCorners.r12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FrostedChromeMetrics.field,
          ),
          child: FrostedWell(
            layers: FrostedStyleLayers(style, t.components.textField),
            error: wrong != null,
            enabled: change != null,
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.fieldInset,
            ),
            child: Row(
              spacing: FrostedSpacing.s8,
              children: [
                Expanded(
                  child: frostedCapCentred(
                    Text(
                      shown,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: chosen == null
                          ? t.textTheme.bodyLarge
                                .line(19.2)
                                .c(t.colorScheme.textTertiary)
                          : t.textTheme.bodyLarge.line(19.2),
                    ),
                  ),
                ),
                Icon(
                  FrostedGlyphs.chevronDown,
                  size: FrostedChromeMetrics.pickerGlyph,
                  color: t.colorScheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // From 600 up the select stands at most 320 wide at its column's start
    // (design6 P): one word never runs the width of a page.
    return FrostedControlMeasure(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.fieldLabelGap,
        children: [
          if (label case final label?) FrostedFieldLabel(label),
          field,
          if (wrong != null || help != null)
            AnimatedOpacity(
              opacity: _open ? 0 : 1,
              duration: FrostedMotion.of(context).fast,
              child: wrong != null
                  ? FrostedFieldHint(wrong, error: true)
                  : FrostedFieldHint(help!),
            ),
        ],
      ),
    );
  }
}

// The decoration of every text entry in Frosted (kept the same in
// bare_field.dart, forms.dart and composer.dart): the hint only, and every
// field that could size or place the line set, so that no
// InputDecorationTheme above the field (its padding, isDense, its
// constraints, a fill or a border) and no platform's density moves it. The
// decorator stands exactly the line's height; the look's own well draws the
// box round it and centres the line by alignment.
// InputDecoration.collapsed alone leaves the constraints and density to the
// theme.
InputDecoration _bareDecoration({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      isCollapsed: true,
      isDense: false,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
