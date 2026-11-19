import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/bidi.dart';
import '../../internal/field_frame.dart';
import '../../internal/key_focus.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A score out of a few: a row of numbered square marks, filled in the
/// action colour up to the score, and the score said in words under it
/// ("4 of 5: Easy", with [labels], in the reader's words and figures).
/// Numbers, not stars: a mark that says its own number reads the same to
/// everyone, in every language.
///
/// A press or a drag sets it; a pointer over a mark previews that score,
/// the marks up to it in a deeper tint. The arrow keys step it, Home and
/// End go to its ends; the keyboard's mark, the one the arrows move, floods
/// yellow over the ink bar. [readOnly] shows a score with no input (an
/// average, which may fill part of a mark).
///
/// For a question on a form with a word for each answer (Very satisfied …
/// Very dissatisfied), radios say more.
///
/// Reads [CivicStyle]'s fill (a filled mark) and foreground (its number)
/// by state: its `style:`, then [CivicThemeData.ratingStyle].
///
/// ```dart
/// CivicRating(
///   labelText: 'How easy was it to apply?',
///   value: score,
///   labels: const ['Very hard', 'Hard', 'Neither', 'Easy', 'Very easy'],
///   onChanged: (v) => setState(() => score = v),
/// )
/// ```
class CivicRating extends StatefulWidget {
  /// A rating.
  const CivicRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.itemCount = 5,
    this.allowHalf = false,
    this.readOnly = false,
    this.labels,
    this.labelText,
    this.helperText,
    this.errorText,
    this.valueLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(itemCount > 0);

  /// The score, 0 (none) to [itemCount].
  final double value;

  /// Called with each score set; null disables it.
  final ValueChanged<double>? onChanged;

  /// How many marks.
  final int itemCount;

  /// Whether a score can end in a half.
  final bool allowHalf;

  /// Whether it only shows [value].
  final bool readOnly;

  /// A word for each whole score, from 1 up, said after the score.
  final List<String>? labels;

  /// The question.
  final String? labelText;

  /// How to answer.
  final String? helperText;

  /// What to fix; null while the score is fine.
  final String? errorText;

  /// The score in words, shown and said; null: the reader's "4 of 5", and
  /// its label.
  final String Function(double value)? valueLabel;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the marks' look.
  final CivicStyle? style;

  @override
  State<CivicRating> createState() => _CivicRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('itemCount', itemCount, defaultValue: 5))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'read only'))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicRatingState extends State<CivicRating> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  String _say(double v) {
    final custom = widget.valueLabel;
    if (custom != null) return custom(v);
    final words = DesignLocalizations.of(context)
        .ratingValueLabel(v, widget.itemCount);
    final labels = widget.labels;
    final whole = v.round();
    if (labels != null && v == whole && whole >= 1) {
      return '${civicIsolate(words)}: ${labels[whole - 1]}';
    }
    return words;
  }

  @override
  Widget build(BuildContext context) {
    // Checked here, not in the constructor, so a rating with its labels
    // can still be const.
    assert(
      widget.labels == null || widget.labels!.length == widget.itemCount,
      'CivicRating needs one label for each of its ${widget.itemCount} '
      'marks.',
    );
    final t = context.civicTheme;
    final text = context.civicText;
    final live = widget.onChanged != null && !widget.readOnly;
    // The keyboard's mark: the one the arrows move, at the score (the
    // first while there is none).
    final at = widget.value <= 0
        ? 0
        : (widget.value.ceil() - 1).clamp(0, widget.itemCount - 1);
    final rating = CivicKeyFocus(
      node: _focus,
      builder: (context, shown) => DesignRating(
        value: widget.value,
        onChanged: widget.onChanged,
        itemCount: widget.itemCount,
        allowHalf: widget.allowHalf,
        readOnly: widget.readOnly,
        focusNode: _focus,
        autofocus: widget.autofocus,
        semanticLabel: widget.labelText,
        semanticFormatterCallback: _say,
        layoutBuilder: (context, items) => Padding(
          // Room for the focus bar under a mark, so nothing moves.
          padding: const EdgeInsets.only(bottom: CivicMetrics.bar + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: CivicSpacing.s4,
            children: items,
          ),
        ),
        itemBuilder: (context, item) => _Mark(
          item: item,
          styles: [widget.style, t.ratingStyle],
          live: live || widget.readOnly,
          focused: shown && live && item.index == at,
        ),
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        rating,
        const SizedBox(height: CivicSpacing.s4),
        ExcludeSemantics(
          child: Text(
            _say(widget.value),
            style: text.body.copyWith(
              color: widget.onChanged == null && !widget.readOnly
                  ? t.textDisabled
                  : t.textPrimary,
            ),
          ),
        ),
      ],
    );
    if (widget.labelText == null &&
        widget.helperText == null &&
        widget.errorText == null) {
      return body;
    }
    return DesignField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: widget.onChanged != null,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: body,
    );
  }
}

/// One numbered mark: its number on the action colour up to the score, on
/// the action's tint past it. A pointer's preview fills up to the mark under
/// it in a deeper tint; a press darkens the mark pressed; the keyboard's
/// mark floods yellow over the ink bar.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.item,
    required this.styles,
    required this.live,
    required this.focused,
  });

  final DesignRatingItemDetails item;
  final List<DesignStyle?> styles;
  final bool live;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf(styles, item.states);
    final disabled = !live;
    final on = disabled ? t.textDisabled : (so.fill ?? t.action);
    final onInk = disabled ? t.background : (so.foreground ?? t.onAction);
    final off = disabled ? t.disabledFill : t.secondaryFill;
    final offInk = disabled ? t.textDisabled : t.onSecondary;
    final preview = item.isPreview;
    final fill = preview ? t.secondaryEdge : on;
    final ink = preview ? t.onSecondary : onInk;
    final pressed = item.states.contains(WidgetState.pressed);
    final size = MediaQuery.textScalerOf(context).scale(40).clamp(40.0, 64.0);
    final figure = DesignLocalizations.of(context)
        .formatDecimal(item.index + 1);
    Widget number(Color color) => Center(
      child: Text(
        figure,
        style: context.civicText.label.copyWith(height: 1, color: color),
      ),
    );
    return CivicSpringValue(
      value: focused ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      builder: (context, focus, _) => CivicSpringValue(
        value: pressed ? 1 : 0,
        spring: CivicMotion.press,
        effects: true,
        builder: (context, press, _) => CivicSpringValue(
          value: item.fill,
          spring: CivicMotion.press,
          effects: true,
          builder: (context, f, _) => SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(CivicMetrics.corner),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: off),
                      number(offInk),
                      // The filled part, from the start edge, carries its
                      // own number in the face's colour, so a half mark
                      // reads both ways.
                      ClipRect(
                        clipper: _Part(f, Directionality.of(context)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: fill),
                            number(ink),
                          ],
                        ),
                      ),
                      if (press > 0)
                        ColoredBox(
                          color:
                              (t.isDark
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF000000))
                                  .withValues(alpha: 0.22 * press),
                        ),
                    ],
                  ),
                ),
                // The focus plate and its bar over the mark, its number on
                // the plate in the plate's ink.
                if (focus > 0) ...[
                  CustomPaint(
                    painter: CivicFacePainter(
                      fill: const Color(0x00000000),
                      edgeColor: t.onFocus,
                      edgeHeight: 0,
                      press: 0,
                      focus: focus,
                      focusColor: t.focus,
                      barColor: t.focusBar,
                    ),
                  ),
                  Opacity(opacity: focus, child: number(t.onFocus)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Part extends CustomClipper<Rect> {
  _Part(this.fraction, this.direction);

  final double fraction;
  final TextDirection direction;

  @override
  Rect getClip(Size size) {
    final w = size.width * fraction.clamp(0.0, 1.0);
    return direction == TextDirection.rtl
        ? Rect.fromLTWH(size.width - w, 0, w, size.height)
        : Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(_Part old) =>
      old.fraction != fraction || old.direction != direction;
}
