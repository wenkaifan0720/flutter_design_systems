import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A box to write in: square, on the page's white, inside a 2-point ink
/// edge, 48 tall, its [labelText] above it in bold, its [helperText] under
/// that, and its [errorText] in words above the box with the whole field on
/// the error rule and the box's edge doubled in the error colour. Focus, by
/// any means, doubles the edge in ink and rings it in yellow; the box keeps
/// its white so the words stay readable.
///
/// [widthInCharacters] sizes the box for what it takes (a postcode is 10, a
/// year 4), which tells the reader what to write as much as the label does;
/// null spans the column. [prefix] and [suffix] stand in cells joined to
/// the box (a currency sign, a unit, a small glyph), on the band's grey in
/// the label's bold; [suffixIcon] is a control joined at
/// its end over the edge (a search button), the box's height and a box's
/// height wide. The box and what is joined to it are one control: a focus
/// anywhere in it rings the whole.
/// [maxLines] other than 1 makes it a
/// box for a paragraph. [isPageHeading] makes the label the page's heading,
/// for a page that asks this one question.
///
/// Reads [CivicStyle]'s fill, foreground, edge, textStyle and padding, by
/// state (`focused`, `error`, `disabled`): its `style:`, then
/// [CivicThemeData.textFieldStyle]. The edge's width, its doubling on focus
/// and the yellow ring are the look's.
///
/// ```dart
/// CivicTextField(
///   labelText: 'Postcode',
///   widthInCharacters: 10,
///   autofillHints: const [AutofillHints.postalCode],
///   errorText: postcodeError,
///   onChanged: (value) => postcode = value,
/// )
/// ```
class CivicTextField extends StatefulWidget {
  /// A box to write in.
  const CivicTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.helperText,
    this.errorText,
    this.hintText,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.widthInCharacters,
    this.isPageHeading = false,
    this.isQuestion = false,
    this.isError = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.style,
  }) : assert(maxLines == null || maxLines > 0),
       assert(minLines == null || minLines > 0),
       assert(widthInCharacters == null || widthInCharacters > 0),
       assert(
         (prefix == null && suffix == null && suffixIcon == null) ||
             maxLines == 1,
         'A joined cell stands beside one line.',
       );

  /// The words; the field's own when null, and never disposed when given.
  final TextEditingController? controller;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// What the field asks, above the box; its spoken name.
  final String? labelText;

  /// Help under the label: what form the answer takes.
  final String? helperText;

  /// What is wrong and how to put it right, in words; null while it is fine.
  final String? errorText;

  /// Shown in the box while it is empty. Put what the reader needs in
  /// [helperText]: a hint goes as they start writing.
  final String? hintText;

  /// What stands in a joined cell before the box: a currency sign, as
  /// `Text('£')`. A screen reader skips it: say it in [labelText] too.
  final Widget? prefix;

  /// What stands in a joined cell after the box: a unit, as `Text('kg')`.
  /// A screen reader skips it: say it in [labelText] too.
  final Widget? suffix;

  /// A control joined at the box's end, over its edge, the box's height
  /// and [CivicMetrics.controlHeight] wide: a search button. It takes its
  /// own taps and its own node, and paints its own face.
  final Widget? suffixIcon;

  /// How many characters the answer takes: the box is sized for them.
  final int? widthInCharacters;

  /// Whether the label is the page's heading.
  final bool isPageHeading;

  /// Whether the label is a question of its own on a page that asks a few
  /// (What is your name?): it stands at a fieldset's legend size, as the
  /// questions beside it do, so one field is never asked twice.
  final bool isQuestion;

  /// Whether it takes the error edge with no words of its own: a date's
  /// box, whose question says what is wrong.
  final bool isError;

  /// Whether it takes input.
  final bool enabled;

  /// Whether its words can be selected but not changed.
  final bool readOnly;

  /// Whether the words are hidden (a password).
  final bool obscureText;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// The keyboard it asks for.
  final TextInputType? keyboardType;

  /// The keyboard's act key.
  final TextInputAction? textInputAction;

  /// How the keyboard capitalises the words.
  final TextCapitalization textCapitalization;

  /// Formatters run over the words as they are typed.
  final List<TextInputFormatter>? inputFormatters;

  /// What the platform's autofill may fill in.
  final Iterable<String>? autofillHints;

  /// How many lines it grows to; 1 keeps it to one, null lets it grow.
  final int? maxLines;

  /// How many lines it stands at the least.
  final int? minLines;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the keyboard submits them; the field then
  /// gives up the focus. Give a field that should keep the focus after
  /// the act key (one that adds another, say) [onEditingComplete] instead,
  /// never both: a field told of a submit that keeps its focus has its text
  /// input restarted, and in a browser that input takes no more typing.
  final ValueChanged<String>? onSubmitted;

  /// Called when the keyboard's act key is pressed, in place of the field
  /// giving up the focus: the field keeps it (see [onSubmitted]).
  final VoidCallback? onEditingComplete;

  /// Overrides for this field's look.
  final CivicStyle? style;

  /// The box's width for [characters] in [words] (at the size they are
  /// drawn, the text scale applied): the characters at their average
  /// advance, the padding and the edges.
  static double widthFor(int characters, TextStyle words) {
    final size = words.fontSize ?? 19;
    return characters * size * 0.62 + 2 * (_inset + CivicMetrics.edge) + 4;
  }

  static const double _inset = CivicSpacing.s12;

  @override
  State<CivicTextField> createState() => _CivicTextFieldState();

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
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('prefix', prefix, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('suffix', suffix, defaultValue: null))
      ..add(
        DiagnosticsProperty<Widget>(
          'suffixIcon',
          suffixIcon,
          defaultValue: null,
        ),
      )
      ..add(
        IntProperty('widthInCharacters', widthInCharacters, defaultValue: null),
      )
      ..add(
        FlagProperty(
          'isPageHeading',
          value: isPageHeading,
          ifTrue: 'page heading',
        ),
      )
      ..add(FlagProperty('isQuestion', value: isQuestion, ifTrue: 'question'))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        FlagProperty('obscureText', value: obscureText, ifTrue: 'obscureText'),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TextInputAction>(
          'textInputAction',
          textInputAction,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<TextCapitalization>(
          'textCapitalization',
          textCapitalization,
          defaultValue: TextCapitalization.none,
        ),
      )
      ..add(
        IterableProperty<TextInputFormatter>(
          'inputFormatters',
          inputFormatters,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<String>(
          'autofillHints',
          autofillHints,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('maxLines', maxLines, defaultValue: 1))
      ..add(IntProperty('minLines', minLines, defaultValue: null))
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
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicTextFieldState extends State<CivicTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void didUpdateWidget(CivicTextField old) {
    super.didUpdateWidget(old);
    // Flutter's TextField's swap: the words carry over when the caller
    // takes its controller back, and the field's own goes when one comes.
    if (widget.controller == null && old.controller != null) {
      _ownController = TextEditingController.fromValue(old.controller!.value);
    } else if (widget.controller != null && old.controller == null) {
      _ownController?.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final enabled = widget.enabled;
    final hasError = widget.errorText != null || widget.isError;
    final oneLine = widget.maxLines == 1 || widget.obscureText;
    return DesignField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) {
        final so = DesignStyleOf(
          [widget.style, t.textFieldStyle],
          {
            if (!enabled) WidgetState.disabled,
            if (hasError) WidgetState.error,
            if (parts.focused) WidgetState.focused,
          },
        );
        final words = text.body
            .merge(so.textStyle)
            .copyWith(
              color:
                  so.foreground ?? (enabled ? t.textPrimary : t.textDisabled),
            );
        final fill = so.fill ?? (enabled ? t.background : t.disabledFill);
        final edge =
            so.edge ??
            (!enabled
                ? t.rule
                : hasError
                ? t.danger
                : t.border);
        final width = widget.widthInCharacters;
        // One control: a focus on the box or on what is joined to it (the
        // search button) rings the whole.
        Widget well = DesignInputGroup(
          focusNode: _focus,
          enabled: enabled,
          isError: hasError,
          mouseCursor: enabled
              ? SystemMouseCursors.text
              : SystemMouseCursors.basic,
          builder: (context, states, line) => CivicSpringValue(
            value: states.contains(WidgetState.focused) ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            child: line,
            builder: (context, focus, line) => CustomPaint(
              painter: CivicWellPainter(
                fill: fill,
                edgeColor: edge,
                // An error doubles the edge, as a focus does: the focus then
                // takes it to its own colour at the same width.
                edge: hasError && enabled
                    ? CivicMetrics.edge +
                          CivicMetrics.focusEdgeGrowth *
                              (1 - focus.clamp(0.0, 1.0))
                    : CivicMetrics.edge,
                focus: focus,
                focusColor: t.focus,
                focusEdgeColor: t.border,
              ),
              child: line,
            ),
          ),
          child: _line(
            context,
            parts.control,
            oneLine,
            boxWidth: width == null
                ? null
                : CivicTextField.widthFor(
                        width,
                        words.copyWith(
                          fontSize: MediaQuery.textScalerOf(context)
                              .scale(words.fontSize ?? 0),
                        ),
                      ) -
                      2 * CivicMetrics.edge,
          ),
        );
        if (width != null) {
          // The line hugs what it holds: the box sized for the characters
          // and whatever is joined to it.
          well = Align(
            alignment: AlignmentDirectional.centerStart,
            child: well,
          );
        }
        return CivicFieldFrame(
          parts: parts,
          isPageHeading: widget.isPageHeading,
          isLegend: widget.isQuestion,
          labelFocuses: true,
          control: well,
        );
      },
      // The whole box is the field's: a tap on a joined cell or beside the
      // words focuses it as a tap on them does.
      child: _editable(context),
    );
  }

  Widget _editable(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf(
      [widget.style, t.textFieldStyle],
      {
        if (!widget.enabled) WidgetState.disabled,
        if (widget.errorText != null || widget.isError) WidgetState.error,
      },
    );
    final words = text.body
        .merge(so.textStyle)
        .copyWith(
          color:
              so.foreground ??
              (widget.enabled ? t.textPrimary : t.textDisabled),
        );
    final editable = Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        decoration: null,
        style: words,
        cursorColor: t.textPrimary,
        cursorWidth: 2,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
      ),
    );
    final hint = widget.hintText;
    final box = DesignTextEntryBox(
      minHeight: CivicMetrics.controlHeight - 2 * CivicMetrics.edge,
      controller: hint == null ? null : _controller,
      hint: hint == null
          ? null
          : Text(
              hint,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: words.copyWith(color: t.textSecondary),
            ),
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      child: editable,
    );
    final oneLine = widget.maxLines == 1 || widget.obscureText;
    final entry = oneLine
        ? DesignCapCenter(
            capHeightFactor: context.civicText.capHeight,
            child: box,
          )
        : box;
    final typed = hint == null ? entry : Semantics(hint: hint, child: entry);
    // The seat: the box's whole width inside its edge is the field's, so a
    // tap in the padding beside the words focuses it as a tap on them does.
    return TextFieldTapRegion(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.text
              : SystemMouseCursors.basic,
          child: Padding(
            padding:
                so.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: CivicTextField._inset),
            child: typed,
          ),
        ),
      ),
    );
  }

  /// The box's line: the joined cells and the editable between them.
  Widget _line(
    BuildContext context,
    Widget control,
    bool oneLine, {
    double? boxWidth,
  }) {
    final t = context.civicTheme;
    // A joined cell: a box's height inside the edge, on the band's grey.
    const inner = CivicMetrics.controlHeight - 2 * CivicMetrics.edge;
    final ink = context.civicText.label.copyWith(color: t.textPrimary);
    Widget cell(Widget child) => ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: CivicMetrics.box,
          minHeight: inner,
        ),
        padding: const EdgeInsets.symmetric(horizontal: CivicSpacing.s12),
        alignment: Alignment.center,
        color: t.surface,
        child: DesignCapCenter(
          capHeightFactor: context.civicText.capHeight,
          child: DefaultTextStyle(
            style: ink,
            child: IconTheme.merge(
              data: IconThemeData(
                color: t.textPrimary,
                size: CivicSpacing.s20,
                applyTextScaling: true,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    final prefix = widget.prefix;
    final suffix = widget.suffix;
    final suffixIcon = widget.suffixIcon;
    final editable = Align(
      alignment: oneLine
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.topStart,
      heightFactor: 1,
      child: control,
    );
    final line = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        CivicMetrics.edge,
        CivicMetrics.edge,
        suffixIcon == null ? CivicMetrics.edge : CivicMetrics.controlHeight,
        CivicMetrics.edge,
      ),
      child: Row(
        mainAxisSize: boxWidth == null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: oneLine
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (prefix != null) ...[cell(prefix), _divider(t)],
          if (boxWidth == null)
            Expanded(child: editable)
          else
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: boxWidth),
                child: editable,
              ),
            ),
          if (suffix != null) ...[_divider(t), cell(suffix)],
        ],
      ),
    );
    if (suffixIcon == null) return line;
    // The control stands over the end edge, as tall as the box however
    // large the words grow it.
    return Stack(
      children: [
        line,
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          width: CivicMetrics.controlHeight,
          child: suffixIcon,
        ),
      ],
    );
  }

  Widget _divider(CivicThemeData t) => SizedBox(
    width: CivicMetrics.edge,
    height: CivicMetrics.controlHeight - 2 * CivicMetrics.edge,
    child: ColoredBox(color: t.border),
  );
}
