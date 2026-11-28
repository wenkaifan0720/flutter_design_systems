// Fields that take part in a Form, and a field for a day, as Material's TextFormField and date fields do.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawInputDecorator;

import 'component_themes.dart';
import 'controls.dart';
import 'format.dart';
import 'glyphs.dart';
import 'internal/cap_label.dart';
import 'internal/eased_lines.dart';
import 'internal/error_line.dart';
import 'internal/error_mark.dart';
import 'internal/moulded.dart' show neumorphicStyleOf;
import 'internal/out_of_use.dart';
import 'localizations.dart';
import 'pickers.dart';
import 'styled.dart';
import 'theme.dart';

/// A [NeumorphicTextField] in a [Form], as Material's `TextFormField` is: its [validator] runs when the form validates
/// (or as [autovalidateMode] says) and what it returns stands under the groove as the field's error, with the look's
/// error mark; [onSaved] hands the text over when the form saves, and resetting the form brings [initialValue] back.
/// Keep the text in a [controller] or start it at [initialValue], not both.
///
/// ```dart
/// NeumorphicTextFormField(labelText: 'Title', validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the title' : null, onSaved: (v) => title = v!)
/// ```
class NeumorphicTextFormField extends FormField<String> {
  /// A text field named [labelText] that takes part in its [Form].
  NeumorphicTextFormField({
    required String labelText,
    this.controller,
    String? initialValue,
    FocusNode? focusNode,
    String? hintText,
    String? helperText,
    Widget? leading,
    Widget? trailing,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool autofocus = false,
    bool obscureText = false,
    Iterable<String>? autofillHints,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
    this.onChanged,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? onEditingComplete,
    NeumorphicStyle? style,
    super.onSaved,
    super.validator,
    super.forceErrorText,
    super.enabled,
    AutovalidateMode? autovalidateMode,
    super.key,
  }) : assert(
         initialValue == null || controller == null,
         'Start the text in the controller or at initialValue, not both.',
       ),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
         builder: (field) {
           final state = field as _NeumorphicTextFormFieldState;
           return NeumorphicTextField(
             labelText: labelText,
             controller: state._controller,
             focusNode: focusNode,
             hintText: hintText,
             helperText: helperText,
             errorText: field.errorText,
             leading: leading,
             trailing: trailing,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             autofocus: autofocus,
             obscureText: obscureText,
             autofillHints: autofillHints,
             inputFormatters: inputFormatters,
             maxLength: maxLength,
             maxLines: maxLines,
             enabled: field.widget.enabled,
             style: style,
             onChanged: (text) {
               field.didChange(text);
               onChanged?.call(text);
             },
             onSubmitted: onFieldSubmitted,
             onEditingComplete: onEditingComplete,
           );
         },
       );

  /// The text's controller, when the page keeps one; without it the field keeps its own, started at the initial value.
  final TextEditingController? controller;

  /// Called as the text changes, and with the initial text when the form resets.
  final ValueChanged<String>? onChanged;

  @override
  FormFieldState<String> createState() => _NeumorphicTextFormFieldState();

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
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      );
  }
}

class _NeumorphicTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _own;

  NeumorphicTextFormField get _field => widget as NeumorphicTextFormField;

  TextEditingController get _controller => _field.controller ?? _own!;

  @override
  void initState() {
    super.initState();
    if (_field.controller == null) {
      _own = TextEditingController(text: widget.initialValue);
    }
    _controller.addListener(_fromController);
  }

  @override
  void didUpdateWidget(covariant NeumorphicTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_field.controller == oldWidget.controller) return;
    (oldWidget.controller ?? _own)?.removeListener(_fromController);
    if (_field.controller == null) {
      _own = TextEditingController.fromValue(oldWidget.controller?.value);
    } else {
      _own?.dispose();
      _own = null;
      setValue(_field.controller!.text);
    }
    _controller.addListener(_fromController);
  }

  @override
  void dispose() {
    _controller.removeListener(_fromController);
    _own?.dispose();
    super.dispose();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_controller.text != value) _controller.text = value ?? '';
  }

  @override
  void reset() {
    // The text goes back first, so the controller's listener finds nothing changed.
    _controller.text = widget.initialValue ?? '';
    super.reset();
    _field.onChanged?.call(_controller.text);
  }

  // Text set on the controller by the page counts as the field's value.
  void _fromController() {
    if (_controller.text != value) didChange(_controller.text);
  }
}

/// A day in a field's groove, picked from the look's calendar: the label over the groove, the day in it with its year
/// ([NeumorphicFormat.mediumDate]: "Nov 26, 2026"), or the [hintText] in the tertiary ink while there is none, and a
/// calendar glyph at its end. A press raises [showNeumorphicDatePicker] on the day, between [firstDate] and [lastDate];
/// the day chosen comes back through [onChanged], and a cancel changes nothing. A null [value] is no day yet; a null
/// [onChanged] leaves the field out of use. In a column it takes the column, as every field does. A screen reader
/// hears a button named [labelText] with the day.
///
/// ```dart
/// NeumorphicDateField(labelText: 'Started', value: started, lastDate: DateTime.now(), onChanged: (day) => setState(() => started = day))
/// ```
class NeumorphicDateField extends StatefulWidget {
  /// A field for a day named [labelText]; a null [onChanged] puts it out of use.
  const NeumorphicDateField({
    required this.labelText,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.hintText,
    this.helperText,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  });

  /// The words over the groove, the field's spoken name and the calendar's title.
  final String labelText;

  /// The day shown; null shows the [hintText].
  final DateTime? value;

  /// Hands over the day chosen in the calendar.
  final ValueChanged<DateTime>? onChanged;

  /// The first day the calendar offers; null leaves it open.
  final DateTime? firstDate;

  /// The last day the calendar offers; null leaves it open.
  final DateTime? lastDate;

  /// What the groove says before a day is chosen ("Choose a date", by default).
  final String? hintText;

  /// Help under the groove.
  final String? helperText;

  /// A failure under the groove, with the look's error mark at its end.
  final String? errorText;

  /// An optional focus node for the field; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when it first appears.
  final bool autofocus;

  /// The groove's face and words, before the text-field component theme.
  final NeumorphicStyle? style;

  @override
  State<NeumorphicDateField> createState() => _NeumorphicDateFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'firstDate',
          firstDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>('lastDate', lastDate, defaultValue: null),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

class _NeumorphicDateFieldState extends State<NeumorphicDateField> {
  bool _focused = false;

  Future<void> _pick(ValueChanged<DateTime> change) async {
    final day = widget.value;
    final picked = await showNeumorphicDatePicker(
      context,
      value: day,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      title: widget.labelText,
    );
    if (picked != null && picked != day) change(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final day = widget.value;
    final change = widget.onChanged;
    final shown = day == null
        ? null
        : NeumorphicFormat.mediumDate(context, day);
    final hint =
        widget.hintText ?? NeumorphicLocalizations.of(context).chooseDate;
    final error = widget.errorText;
    final helper = widget.helperText;
    final face = NeumorphicTap(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: widget.style,
      themeStyle: t.textFieldTheme,
      // A field: its focus deepens its groove and lights its label, as a text field's does, and never raises the face.
      showFocus: false,
      onStatesChanged: (states) {
        final focused = states.contains(WidgetState.focused);
        if (focused != _focused) setState(() => _focused = focused);
      },
      semanticLabel: widget.labelText,
      semanticValue: shown,
      onPressed: change == null ? null : () => _pick(change),
      child: Builder(
        builder: (context) {
          final states = {
            ...NeumorphicStatesScope.of(context),
            if (error != null) WidgetState.error,
          };
          final look = neumorphicStyleOf([
            widget.style,
            t.textFieldTheme,
          ], states);
          final words = t.textTheme.body.merge(look.textStyle);
          return NeumorphicOutOfUse(
            off: change == null,
            child: NeumorphicStatesScope(
              states: states,
              child: NeumorphicFieldBox(
                style: widget.style,
                states: states,
                child: Padding(
                  padding: t.density.padding(
                    const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: neumorphicLabel(
                          Text(
                            shown ?? hint,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: words.copyWith(
                              color:
                                  look.foreground ??
                                  (shown == null ? t.colors.inkTertiary : null),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Failed, the mark takes the calendar's place, crossing to it.
                      AnimatedSwitcher(
                        duration: NeumorphicMotion.of(context).state,
                        child: error != null
                            ? const NeumorphicErrorMark(
                                key: ValueKey<bool>(true),
                              )
                            : Icon(
                                key: const ValueKey<bool>(false),
                                NeumorphicGlyphs.calendarDays,
                                size: look.iconSize ?? 18,
                                color: look.foreground ?? t.colors.inkSecondary,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return RawInputDecorator(
      helperText: helper,
      errorText: error,
      enabled: change != null,
      builder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The one label style, lit in the pigment's ink while focused, as a text field's.
          NeumorphicLabelInk(
            lit: _focused,
            style: t.textTheme.caption.copyWith(fontWeight: FontWeight.w700),
            child: ExcludeSemantics(child: Text(widget.labelText)),
          ),
          const SizedBox(height: 8),
          parts.control,
          // The help or the failure eases in under the face.
          NeumorphicHintSlot(
            child: error != null
                // The field carries the mark at its end, in the calendar's place.
                ? NeumorphicErrorLine(
                    live: false,
                    mark: false,
                    child: parts.error!,
                  )
                : helper != null
                ? DefaultTextStyle.merge(
                    style: t.textTheme.caption,
                    child: parts.helper!,
                  )
                : null,
          ),
        ],
      ),
      child: face,
    );
  }
}
