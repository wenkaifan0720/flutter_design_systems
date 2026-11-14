// The fields and pickers the inventory adds, on ui_core's behaviours: the password field (DesignPasswordReveal), the
// input group (DesignInputGroup), the range slider (DesignRangeSlider), the date range
// picker (DesignCalendar) and the colour picker (DesignColorPicker). Paint rows: the file drop zone, the time picker and
// the wheel.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../icons.dart';
import '../internal/key_focus.dart';
import '../internal/well.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button/button.dart';
import 'date/date_picker.dart';
import 'dialog/dialog.dart';
import 'dropdown/dropdown.dart';
import 'input/field_core.dart';
import 'input/input.dart';
import 'pressable/pressable.dart';
import 'raised.dart';

/// Fluent's Input with its words hidden and the eye that shows them at its
/// end. The eye keeps the keyboard in the field.
///
/// ```dart
/// Fluent2PasswordField(label: 'Password', onChanged: (v) => setState(() => password = v))
/// ```
class Fluent2PasswordField extends StatelessWidget {
  /// A password field.
  const Fluent2PasswordField({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction,
    this.validationMessage,
    this.invalid = false,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
  });

  /// The field's name.
  final String? label;

  /// Its empty words.
  final String? hint;

  /// The text, when the page holds it with [onChanged].
  final String? value;

  /// The text, when a controller holds it.
  final TextEditingController? controller;

  /// Its focus node.
  final FocusNode? focusNode;

  /// Told each edit.
  final ValueChanged<String>? onChanged;

  /// Told the words on the keyboard's action.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The keyboard's action key.
  final TextInputAction? textInputAction;

  /// What is wrong, under the field in the error stroke.
  final String? validationMessage;

  /// Draw the error stroke with no words.
  final bool invalid;

  /// Fluent's `appearance`.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`.
  final Fluent2InputSize size;

  @override
  Widget build(BuildContext context) {
    return DesignPasswordReveal(
      focusNode: focusNode,
      showLabel: DesignLocalizations.of(context).showPasswordLabel,
      hideLabel: DesignLocalizations.of(context).hidePasswordLabel,
      builder: (context, s) => Fluent2TextField(
        label: label,
        hint: hint,
        value: value,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        textInputAction: textInputAction,
        validationMessage: validationMessage,
        invalid: invalid,
        appearance: appearance,
        size: size,
        obscureText: s.obscured,
        trailing: ExcludeFocus(
          child: Fluent2IconButton(
            s.obscured ? Fluent2Icons.eye : Fluent2Icons.eyeOff,
            label: s.toggleLabel,
            size: Fluent2ButtonSize.small,
            appearance: Fluent2ButtonAppearance.transparent,
            onPressed: s.toggle,
          ),
        ),
      ),
    );
  }
}

/// A field with fixed words or glyphs at its ends (`https://`, `.com`): the
/// [prefix] and [suffix] in the third ink, or [leading] and [trailing]
/// controls, inside Fluent's field frame. A press anywhere on the frame
/// focuses the field; the frame draws the underline while focus is anywhere
/// inside.
///
/// ```dart
/// Fluent2InputGroup(label: 'Website', prefix: 'https://', suffix: '.com', onChanged: setSite)
/// ```
class Fluent2InputGroup extends StatefulWidget {
  /// A field grouped with its add-ons.
  const Fluent2InputGroup({
    this.focusNode,
    this.autofocus = false,
    super.key,
    this.label,
    this.prefix,
    this.suffix,
    this.leading,
    this.trailing,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.invalid = false,
    this.appearance = Fluent2InputAppearance.outline,
  });

  /// The field's name.
  final String? label;

  /// Fixed words before the text.
  final String? prefix;

  /// Fixed words after the text.
  final String? suffix;

  /// A control or glyph before [prefix].
  final Widget? leading;

  /// A control or glyph after [suffix].
  final Widget? trailing;

  /// Its empty words.
  final String? hint;

  /// The text; null keeps its own.
  final TextEditingController? controller;

  /// Told each edit.
  final ValueChanged<String>? onChanged;

  /// Told the words on the keyboard's action.
  final ValueChanged<String>? onSubmitted;

  /// False draws it out of use.
  final bool enabled;

  /// Draw the error stroke.
  final bool invalid;

  /// Fluent's `appearance`.
  final Fluent2InputAppearance appearance;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2InputGroup> createState() => _Fluent2InputGroupState();
}

class _Fluent2InputGroupState extends State<Fluent2InputGroup> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'input group'));
  TextEditingController? _own;

  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void dispose() {
    _ownFocus?.dispose();
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = widget.enabled;
    final ink = live ? c.neutralForeground3 : c.neutralForegroundDisabled;
    Widget words(String w) => Text(w, maxLines: 1, style: t.body1.c(ink));
    return DesignInputGroup(
      focusNode: _focus,
      enabled: live,
      isError: widget.invalid,
      builder: (context, states, field) => Fluent2FieldFrame(
        appearance: widget.appearance,
        focused: states.focused,
        enabled: live,
        invalid: states.error,
        textNode: true,
        padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.mNudge),
        child: Row(
          spacing: Fluent2Spacing.xs,
          children: [
            ?widget.leading,
            if (widget.prefix != null) words(widget.prefix!),
            Expanded(child: field),
            if (widget.suffix != null) words(widget.suffix!),
            ?widget.trailing,
          ],
        ),
      ),
      child: Semantics(
        label: widget.label,
        child: Fluent2FieldEditor(
          autofocus: widget.autofocus,
          controller: _text,
          focusNode: _focus,
          enabled: live,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: t.body1.c(
            live ? c.neutralForeground1 : c.neutralForegroundDisabled,
          ),
          hint: widget.hint,
          hintStyle: t.body1.c(
            live
                ? fluent2PlaceholderInk(t, widget.appearance)
                : c.neutralForegroundDisabled,
          ),
        ),
      ),
    );
  }
}

/// Fluent's slider with two thumbs: a span between [min] and [max], the rail
/// filled in the brand between them. Each thumb takes the arrows. Null
/// [onChanged] draws it out of use.
///
/// ```dart
/// Fluent2RangeSlider(label: 'Price', values: const DesignRangeValues(20, 80), onChanged: setPrice)
/// ```
class Fluent2RangeSlider extends StatelessWidget {
  /// A slider over [values].
  const Fluent2RangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.label,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.minGap = 0,
    this.onChangeEnd,
    this.valueLabel,
  });

  /// The span.
  final DesignRangeValues values;

  /// Told each span as it moves; null draws it out of use.
  final ValueChanged<DesignRangeValues>? onChanged;

  /// Told the span let go at.
  final ValueChanged<DesignRangeValues>? onChangeEnd;

  /// Its name; each thumb's is this with its end.
  final String? label;

  /// The low end of the rail.
  final double min;

  /// The high end of the rail.
  final double max;

  /// How many steps the rail has; null is continuous.
  final int? divisions;

  /// The least the two may stand apart.
  final double minGap;

  /// A value's words; null says the number.
  final String Function(double value)? valueLabel;

  static const _thumb = 20.0;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = onChanged != null;
    String say(double v) =>
        valueLabel?.call(v) ??
        (v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1));
    return DesignRangeSlider(
      values: values,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      divisions: divisions,
      minGap: minGap,
      semanticFormatterCallback: say,
      startLabel: label == null
          ? DesignLocalizations.of(context).rangeSliderStartLabel
          : '$label, ${DesignLocalizations.of(context).rangeSliderStartLabel}',
      endLabel: label == null
          ? DesignLocalizations.of(context).rangeSliderEndLabel
          : '$label, ${DesignLocalizations.of(context).rangeSliderEndLabel}',
      trackBuilder: (context, track) => SizedBox(
        height: 32,
        child: CustomPaint(
          painter: _RailPainter(
            start: track.start,
            end: track.end,
            inset: _thumb / 2,
            rail: live
                ? c.neutralStrokeAccessible
                : fluent2Step(t, c.neutralStrokeDisabled),
            fill: live
                ? c.compoundBrandBackground
                : c.neutralForegroundDisabled,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
      thumbBuilder: (context, index, states) {
        final fill = !live
            ? c.neutralForegroundDisabled
            : states.press.pick(
                c.compoundBrandBackground,
                c.compoundBrandBackgroundHover,
                c.compoundBrandBackgroundPressed,
              );
        return Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.neutralBackground1,
                  border: Border.all(
                    color: live
                        ? c.neutralStroke1
                        : c.neutralForegroundDisabled,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                  ),
                ),
              ),
              if (states.focused)
                const SizedBox(
                  width: _thumb + 4,
                  height: _thumb + 4,
                  child: IgnorePointer(child: Fluent2FocusRing(radius: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.start,
    required this.end,
    required this.inset,
    required this.rail,
    required this.fill,
    required this.rtl,
  });

  final double start;
  final double end;
  final double inset;
  final Color rail;
  final Color fill;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.max(0.0, size.width - inset * 2);
    final cy = size.height / 2;
    final r = const Radius.circular(Fluent2Radius.xLarge);
    final whole = Rect.fromLTWH(inset, cy - 2, width, 4);
    canvas.drawRRect(RRect.fromRectAndRadius(whole, r), Paint()..color = rail);
    final a = rtl ? 1 - end : start;
    final b = rtl ? 1 - start : end;
    canvas.drawRect(
      Rect.fromLTRB(inset + width * a, cy - 2, inset + width * b, cy + 2),
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.start != start ||
      old.end != end ||
      old.rail != rail ||
      old.fill != fill ||
      old.inset != inset ||
      old.rtl != rtl;
}

/// A place to drop or browse for files: a subtle plane (Fluent's second
/// background, a shade darker under the pointer and pressed) met by its solid
/// 1 hairline, its corners 8, the upload glyph over [label] in body1 strong
/// and the [hint] in caption1, with the browse link at its foot. A press anywhere on it calls [onPressed]; null
/// draws it out of use. The app reads the files; the zone is only the place.
///
/// ```dart
/// Fluent2FileUpload(label: 'Upload the contract', hint: 'PDF or DOCX, up to 10 MB', onPressed: pick)
/// ```
class Fluent2FileUpload extends StatelessWidget {
  /// A drop zone.
  const Fluent2FileUpload({
    this.focusNode,
    this.autofocus = false,
    super.key,
    required this.onPressed,
    this.label,
    this.hint,
    this.browseLabel,
    this.invalid = false,
  });

  /// What a press does: open the platform's file chooser.
  final VoidCallback? onPressed;

  /// What to put here; null is [Fluent2Localizations.dropFiles].
  final String? label;

  /// What it takes.
  final String? hint;

  /// The link's words; null is [Fluent2Localizations.browseFiles].
  final String? browseLabel;

  /// The last file was refused: the danger stroke.
  final bool invalid;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final words = Fluent2Localizations.of(context);
    final title = label ?? words.dropFiles;
    return Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: title,
      hint: hint,
      isError: invalid,
      radius: Fluent2Radius.xLarge,
      builder: (context, states) {
        final live = states.enabled;
        final press = states.press;
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(Fluent2Spacing.l),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Fluent2Radius.xLarge),
            border: Border.all(
              color: !live
                  ? fluent2Step(t, c.neutralStrokeDisabled)
                  : states.error
                  ? c.statusDangerBorder2
                  : press.pick(
                      c.neutralStroke1,
                      c.neutralStroke1Hover,
                      c.neutralStroke1Pressed,
                    ),
            ),
            color: !live
                ? fluent2WellDisabled(t)
                : press.pick(
                    c.neutralBackground2,
                    c.neutralBackground2Hover,
                    c.neutralBackground2Pressed,
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Fluent2Spacing.xs,
            children: [
              Icon(
                Fluent2Icons.arrowUpload,
                size: 24,
                color: live
                    ? c.neutralForeground3
                    : c.neutralForegroundDisabled,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: t.body1Strong.c(
                  live ? c.neutralForeground1 : c.neutralForegroundDisabled,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: t.caption1.c(
                    live ? t.textTertiary : c.neutralForegroundDisabled,
                  ),
                ),
              Text(
                browseLabel ?? words.browseFiles,
                style: t.body1.c(
                  live ? c.brandForegroundLink : c.neutralForegroundDisabled,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A span of days on Fluent's calendar: two months side by side where there's
/// room and one where there's not, the ends on the brand disc and the days
/// between on its tint. Holds its range in [controller], which should be in
/// range mode. [showFluent2DateRangePicker] raises one in a dialog.
///
/// ```dart
/// Fluent2DateRangePicker(controller: DesignCalendarController(firstDate: start, lastDate: end, mode: DesignCalendarMode.range))
/// ```
class Fluent2DateRangePicker extends StatelessWidget {
  /// A range picker over [controller].
  const Fluent2DateRangePicker({
    super.key,
    required this.controller,
    this.onChanged,
    this.months,
    this.firstDayOfWeek,
  });

  /// The days and the range.
  final DesignCalendarController controller;

  /// Told the range as it changes.
  final ValueChanged<DesignDateRange?>? onChanged;

  /// How many months show; null fits the room.
  final int? months;

  /// The week's first day ([DateTime.monday] … [DateTime.sunday]); null is
  /// the app's localizations' (DesignLocalizations.firstDayOfWeek; English is
  /// Sunday). Pass it only to override the locale.
  final int? firstDayOfWeek;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final words = Fluent2Localizations.of(context);
    // A day is 32 square, a whole target (48) under a finger.
    final cell = Fluent2Layout.padded(context)
        ? Fluent2Layout.touchHitTarget
        : 32.0;
    // The month buttons come before the grid, as they stand over it.
    Widget first(Widget button) =>
        FocusTraversalOrder(order: const NumericFocusOrder(0), child: button);
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.hasBoundedWidth ? box.maxWidth : 640.0;
        final count = months ?? (room >= 640 ? 2 : 1);
        final least = 7 * cell * count + Fluent2Spacing.xxl * (count - 1);
        final grid = DesignCalendar(
          controller: controller,
          months: count,
          firstWeekday: firstDayOfWeek,
          minDayWidth: cell,
          onChanged: (_) => onChanged?.call(controller.selectedRange),
          monthLabel: words.monthYear,
          dayLabel: words.fullDate,
          monthsBuilder: (context, list) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Fluent2Spacing.xxl,
            children: [for (final m in list) Expanded(child: m)],
          ),
          weekdayBuilder: (context, weekday, label) => Center(
            child: ExcludeSemantics(
              child: Text(
                words.weekdaysShort[weekday - 1],
                style: t.caption1Strong.c(c.neutralForeground2),
              ),
            ),
          ),
          headerBuilder: (context, h) => Padding(
            padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: Fluent2Spacing.xs,
                    ),
                    child: Text(
                      h.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.body1Strong,
                    ),
                  ),
                ),
                first(
                  Fluent2IconButton(
                    Fluent2Icons.chevronLeft,
                    label: DesignLocalizations.of(context).previousMonthTooltip,
                    size: Fluent2ButtonSize.small,
                    onPressed: h.previous,
                  ),
                ),
                first(
                  Fluent2IconButton(
                    Fluent2Icons.chevronRight,
                    label: DesignLocalizations.of(context).nextMonthTooltip,
                    size: Fluent2ButtonSize.small,
                    onPressed: h.next,
                  ),
                ),
              ],
            ),
          ),
          // The band runs from the start to the end, or to the day the
          // pointer or the keyboard rests on after the first press
          // (isPreviewEnd), which stands as the end it would be. A start
          // leads the band only when the range or its preview runs past it.
          dayBuilder: (context, day, states) => _RangeDay(
            day,
            states,
            cell,
            lead:
                day.isRangeStart &&
                ((day.inRange && !day.isRangeEnd) ||
                    (day.inPreview && !day.isPreviewEnd)),
            tail: !day.isRangeStart && (day.isRangeEnd || day.isPreviewEnd),
          ),
        );
        final calendar = FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: grid,
          ),
        );
        return !box.hasBoundedWidth || room >= least
            ? calendar
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: least, child: calendar),
              );
      },
    );
  }
}

class _RangeDay extends StatelessWidget {
  const _RangeDay(
    this.day,
    this.states,
    this.cell, {
    required this.lead,
    required this.tail,
  });

  final DesignCalendarDay day;
  final Set<WidgetState> states;

  /// The day's height: 32, or 48 under a finger (its disc and band 28,
  /// or 40).
  final double cell;

  /// The band starts here, at the disc's centre, and runs on.
  final bool lead;

  /// The band ends here, at the disc's centre.
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final end =
        day.isRangeStart || day.isRangeEnd || day.selected || day.isPreviewEnd;
    final half = lead || tail;
    final band = half || ((day.inRange || day.inPreview) && !end);
    final live = day.enabled;
    final press = states.press;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The disc and the band: 28 on a 32 day; 40 on a finger's 48, as the
    // date picker's phone disc, so the chosen ground fills its cell.
    final disc = cell > 32 ? 40.0 : 28.0;
    final ink = !live
        ? c.neutralForegroundDisabled
        : end
        ? c.neutralForegroundOnBrand
        : !day.inMonth
        ? c.neutralForeground3
        : band
        ? c.brandForeground2
        : c.neutralForeground1;
    final Widget face = Stack(
      alignment: Alignment.center,
      children: [
        if (band && day.inMonth)
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: !half
                  ? Alignment.center
                  : lead != rtl
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              widthFactor: half ? 0.5 : 1,
              heightFactor: disc / cell,
              child: ColoredBox(color: fluent2BrandWell(t)),
            ),
          ),
        Container(
          width: disc,
          height: disc,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: end && live
                ? press.pick(
                    c.brandBackground,
                    c.brandBackgroundHover,
                    c.brandBackgroundPressed,
                  )
                : band
                ? null
                : live
                ? press.pick(
                    c.transparentBackground,
                    c.subtleBackgroundHover,
                    c.subtleBackgroundPressed,
                  )
                : null,
            border: day.isToday && !end
                ? Border.all(color: c.compoundBrandStroke)
                : null,
          ),
          child: Text(
            '${day.date.day}',
            textScaler: TextScaler.noScaling,
            style: (end ? t.body1Strong : t.body1).tabular.c(ink),
          ),
        ),
        if (states.focused)
          SizedBox(
            width: disc + 4,
            height: disc + 4,
            child: IgnorePointer(child: Fluent2FocusRing(radius: disc / 2 + 2)),
          ),
      ],
    );
    return SizedBox(height: cell, child: face);
  }
}

/// Raises a [Fluent2DateRangePicker] in Fluent's dialog; answers the range on
/// OK, or null.
///
/// ```dart
/// final stay = await showFluent2DateRangePicker(context, firstDate: today, lastDate: nextYear);
/// ```
Future<DesignDateRange?> showFluent2DateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DesignDateRange? initial,
  String? title,
}) {
  final controller = DesignCalendarController(
    firstDate: firstDate,
    lastDate: lastDate,
    mode: DesignCalendarMode.range,
    selectedRange: initial,
  );
  final words = Fluent2Localizations.of(context);
  return showFluent2Dialog<DesignDateRange>(
    context,
    builder: (dialogContext) => Fluent2Dialog(
      title: title ?? words.chooseDates,
      content: Fluent2DateRangePicker(controller: controller),
      actions: [
        Fluent2Button(
          DesignLocalizations.of(context).cancelButtonLabel,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Fluent2Button(
            DesignLocalizations.of(context).okButtonLabel,
            appearance: Fluent2ButtonAppearance.primary,
            onPressed: controller.selectedRange?.isComplete ?? false
                ? () =>
                      Navigator.of(dialogContext).pop(controller.selectedRange)
                : null,
          ),
        ),
      ],
    ),
  );
}

/// Raises a [Fluent2Calendar] in Fluent's dialog; answers the day pressed, or
/// null.
///
/// ```dart
/// final due = await showFluent2DatePicker(context, value: DateTime(2026, 11, 12));
/// ```
Future<DateTime?> showFluent2DatePicker(
  BuildContext context, {
  DateTime? value,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? today,
  String? title,
}) => showFluent2Dialog<DateTime>(
  context,
  builder: (dialogContext) {
    final words = Fluent2Localizations.of(dialogContext);
    return Fluent2Dialog(
      title: title ?? words.chooseDate,
      content: Center(
        child: Fluent2Calendar(
          value: value,
          firstDate: firstDate,
          lastDate: lastDate,
          today: today,
          onChanged: (d) => Navigator.of(dialogContext).pop(d),
        ),
      ),
      actions: [
        Fluent2Button(
          DesignLocalizations.of(dialogContext).cancelButtonLabel,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    );
  },
);

/// A time of day, neutral of any toolkit: [hour] 0 to 23, [minute] 0 to 59.
///
/// ```dart
/// const Fluent2Time(14, 30)
/// ```
@immutable
class Fluent2Time {
  /// [hour] and [minute] of a day.
  const Fluent2Time(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// 0 to 23.
  final int hour;

  /// 0 to 59.
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is Fluent2Time && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  String _say(Fluent2Localizations words, bool use24Hour) {
    final mm = minute.toString().padLeft(2, '0');
    if (use24Hour) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$mm ${hour < 12 ? words.am : words.pm}';
  }
}

/// Fluent's TimePicker: a select of the day's times every [minuteStep]
/// minutes, in the field's own dropdown. Null [onChanged] draws it out of
/// use. [showFluent2TimePicker] asks with two wheels instead.
///
/// ```dart
/// Fluent2TimePicker(label: 'Starts', value: const Fluent2Time(9, 30), onChanged: setStart)
/// ```
class Fluent2TimePicker extends StatelessWidget {
  /// A time picker.
  const Fluent2TimePicker({
    super.key,
    required this.onChanged,
    this.value,
    this.label,
    this.minuteStep = 30,
    this.use24Hour,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.invalid = false,
  }) : assert(minuteStep > 0 && minuteStep <= 60);

  /// The time chosen.
  final Fluent2Time? value;

  /// Told the time pressed; null draws it out of use.
  final ValueChanged<Fluent2Time>? onChanged;

  /// Its name.
  final String? label;

  /// The minutes between the times it lists.
  final int minuteStep;

  /// `14:30` rather than `2:30 PM`; null follows the platform's setting
  /// (`MediaQuery.alwaysUse24HourFormatOf`).
  final bool? use24Hour;

  /// Fluent's `appearance`.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`.
  final Fluent2InputSize size;

  /// Draw the error stroke.
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final words = Fluent2Localizations.of(context);
    final clock24 = use24Hour ?? MediaQuery.alwaysUse24HourFormatOf(context);
    final times = <Fluent2Time>[
      for (var m = 0; m < 24 * 60; m += minuteStep)
        Fluent2Time(m ~/ 60, m % 60),
      if (value != null && value!.minute % minuteStep != 0) value!,
    ]..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    return Fluent2Select<Fluent2Time>(
      options: [
        for (final time in times)
          Fluent2Option(time, time._say(words, clock24)),
      ],
      value: value,
      onChanged: onChanged,
      label: label,
      prompt: words.chooseTime,
      appearance: appearance,
      size: size,
      invalid: invalid,
    );
  }
}

/// Asks for a time with an hour wheel and a minute wheel in Fluent's dialog;
/// answers it on OK, or null.
///
/// ```dart
/// final at = await showFluent2TimePicker(context, value: const Fluent2Time(9, 30));
/// ```
Future<Fluent2Time?> showFluent2TimePicker(
  BuildContext context, {
  Fluent2Time? value,
  String? title,
}) {
  var hour = value?.hour ?? 9;
  var minute = value?.minute ?? 0;
  final words = Fluent2Localizations.of(context);
  return showFluent2Dialog<Fluent2Time>(
    context,
    builder: (dialogContext) => Fluent2Dialog(
      title: title ?? words.chooseTime,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Fluent2Spacing.l,
        children: [
          SizedBox(
            width: 88,
            child: Fluent2WheelPicker<int>(
              label: words.hour,
              items: [for (var h = 0; h < 24; h++) h],
              value: hour,
              looping: true,
              itemLabel: (h) => h.toString().padLeft(2, '0'),
              onChanged: (h) => hour = h,
            ),
          ),
          SizedBox(
            width: 88,
            child: Fluent2WheelPicker<int>(
              label: words.minute,
              items: [for (var m = 0; m < 60; m++) m],
              value: minute,
              looping: true,
              itemLabel: (m) => m.toString().padLeft(2, '0'),
              onChanged: (m) => minute = m,
            ),
          ),
        ],
      ),
      actions: [
        Fluent2Button(
          DesignLocalizations.of(context).cancelButtonLabel,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        Fluent2Button(
          DesignLocalizations.of(context).okButtonLabel,
          appearance: Fluent2ButtonAppearance.primary,
          onPressed: () =>
              Navigator.of(dialogContext).pop(Fluent2Time(hour, minute)),
        ),
      ],
    ),
  );
}

/// A turning drum of choices: the chosen line on the subtle selected fill, its
/// words strong, the lines above and below in the third ink, drawn smaller
/// round the drum. Drag or fling it; the arrows step it.
///
/// ```dart
/// Fluent2WheelPicker<int>(label: 'Guests', items: const [1, 2, 3, 4], value: guests, onChanged: setGuests)
/// ```
class Fluent2WheelPicker<T> extends StatefulWidget {
  /// A wheel of [items].
  const Fluent2WheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.label,
    this.itemLabel,
    this.rows = 5,
    this.looping = false,
  }) : assert(rows % 2 == 1 && rows >= 3);

  /// The choices, in order.
  final List<T> items;

  /// The one chosen.
  final T value;

  /// Told each choice it settles on; null draws it out of use.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls it.
  final String label;

  /// A choice's words; null is its `toString`.
  final String Function(T item)? itemLabel;

  /// How many lines show; odd, so one stands in the middle.
  final int rows;

  /// Whether it turns past its ends.
  final bool looping;

  @override
  State<Fluent2WheelPicker<T>> createState() => _Fluent2WheelPickerState<T>();
}

class _Fluent2WheelPickerState<T> extends State<Fluent2WheelPicker<T>> {
  static const _line = 36.0;
  late final _wheel = FixedExtentScrollController(
    initialItem: math.max(0, widget.items.indexOf(widget.value)),
  );
  late int _at = math.max(0, widget.items.indexOf(widget.value));

  String _say(T item) => widget.itemLabel?.call(item) ?? '$item';

  @override
  void didUpdateWidget(Fluent2WheelPicker<T> old) {
    super.didUpdateWidget(old);
    final i = widget.items.indexOf(widget.value);
    if (i >= 0 && i != _at) {
      _at = i;
      if (_wheel.hasClients) _wheel.jumpToItem(i);
    }
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _step(int by) {
    final n = widget.items.length;
    final to = widget.looping ? (_at + by) % n : (_at + by).clamp(0, n - 1);
    if (to == _at) return;
    if (!Fluent2Motion.on(context)) {
      _wheel.jumpToItem(to);
      return;
    }
    _wheel.animateToItem(
      to,
      duration: Fluent2Motion.fast,
      curve: Fluent2Motion.decelerateMid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = widget.onChanged != null;
    final n = widget.items.length;
    Text line(int i, bool chosen) => Text(
      _say(widget.items[i]),
      maxLines: 1,
      style: (chosen ? t.body1Strong : t.body1).tabular.c(
        !live
            ? c.neutralForegroundDisabled
            : chosen
            ? c.neutralForeground1
            : t.textTertiary,
      ),
    );
    return Semantics(
      container: true,
      label: widget.label,
      value: _say(widget.items[_at]),
      increasedValue: live ? _say(widget.items[(_at + 1) % n]) : null,
      decreasedValue: live ? _say(widget.items[(_at - 1) % n]) : null,
      onIncrease: live ? () => _step(1) : null,
      onDecrease: live ? () => _step(-1) : null,
      child: Fluent2KeyFocus(
        enabled: live,
        radius: Fluent2Radius.medium,
        keys: {
          LogicalKeyboardKey.arrowDown: () => _step(1),
          LogicalKeyboardKey.arrowUp: () => _step(-1),
          LogicalKeyboardKey.pageDown: () => _step(5),
          LogicalKeyboardKey.pageUp: () => _step(-5),
        },
        child: SizedBox(
          height: _line * widget.rows,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: _line,
                decoration: BoxDecoration(
                  // iOS's selection band in Fluent's grey step, laid over
                  // the ground so it shows on the tinted page.
                  color: live ? fluent2Well(t) : fluent2WellDisabled(t),
                  borderRadius: BorderRadius.circular(Fluent2Radius.medium),
                ),
              ),
              ExcludeSemantics(
                child: IgnorePointer(
                  ignoring: !live,
                  child: ListWheelScrollView.useDelegate(
                    controller: _wheel,
                    itemExtent: _line,
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    diameterRatio: 2.2,
                    onSelectedItemChanged: (raw) {
                      final i = raw % n;
                      setState(() => _at = i);
                      widget.onChanged?.call(widget.items[i]);
                    },
                    childDelegate: widget.looping
                        ? ListWheelChildLoopingListDelegate(
                            children: [
                              for (var i = 0; i < n; i++)
                                Center(child: line(i, i == _at)),
                            ],
                          )
                        : ListWheelChildBuilderDelegate(
                            childCount: n,
                            builder: (context, i) =>
                                Center(child: line(i, i == _at)),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fluent's colour picker: the saturation and brightness area, the hue strip
/// and with [showAlpha] the opacity strip, each thumb a white ring round its
/// colour, then a swatch and the hex field.
///
/// ```dart
/// Fluent2ColorPicker(controller: DesignColorController(const Color(0xFF0F6CBD)))
/// ```
class Fluent2ColorPicker extends StatelessWidget {
  /// A picker over [controller].
  const Fluent2ColorPicker({
    super.key,
    required this.controller,
    this.showAlpha = false,
  });

  /// The colour.
  final DesignColorController controller;

  /// Show the opacity strip.
  final bool showAlpha;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final r = BorderRadius.circular(Fluent2Radius.medium);
    final edge = Border.all(color: c.neutralStroke1);
    Widget knob(Set<WidgetState> states, Color fill, double size) => Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
              boxShadow: t.shadows.shadow2,
            ),
          ),
          if (states.focused)
            SizedBox(
              width: size + 6,
              height: size + 6,
              child: IgnorePointer(
                child: Fluent2FocusRing(radius: (size + 6) / 2),
              ),
            ),
        ],
      ),
    );
    return DesignColorPicker(
      controller: controller,
      showAlpha: showAlpha,
      areaHeight: 160,
      areaBuilder: (context, a) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFFFFF),
              HSVColor.fromAHSV(1, a.color.hue, 1, 1).toColor(),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: edge,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xFF000000)],
            ),
          ),
        ),
      ),
      areaThumbBuilder: (context, a) =>
          knob(a.states, a.color.withAlpha(1).toColor(), 16),
      trackBuilder: (context, channel, colour) => SizedBox(
        height: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            border: edge,
            // From the reading start, as the slider's thumb runs: right to
            // left the rainbow mirrors with it, so the thumb stands on the
            // value's own hue.
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: channel == DesignColorChannel.alpha
                  ? [
                      colour.withAlpha(0).toColor(),
                      colour.withAlpha(1).toColor(),
                    ]
                  : [
                      for (var h = 0; h <= 360; h += 60)
                        HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                    ],
            ),
          ),
        ),
      ),
      thumbBuilder: (context, states) => knob(states, c.neutralBackground1, 16),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.s,
        children: [
          ...parts,
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Row(
              spacing: Fluent2Spacing.s,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: controller.color,
                    borderRadius: r,
                    border: edge,
                  ),
                ),
                Expanded(child: _HexField(controller: controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HexField extends StatefulWidget {
  const _HexField({required this.controller});

  final DesignColorController controller;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late final _text = TextEditingController(text: widget.controller.hex);
  final _focus = FocusNode(debugLabel: 'hex');

  @override
  void didUpdateWidget(_HexField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _text.text != widget.controller.hex) {
      _text.text = widget.controller.hex;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  // A hex code reads left to right in any page, `#` first.
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Fluent2TextField(
      label: Fluent2Localizations.of(context).hexColor,
      controller: _text,
      focusNode: _focus,
      onChanged: widget.controller.setHex,
      onSubmitted: widget.controller.setHex,
    ),
  );
}
