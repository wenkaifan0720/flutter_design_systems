import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../internal/kit_paint.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// Two to four mutually exclusive views of the same content — Week · Month
/// · Year, List · Board — as a bordered 32 px control (28 with
/// `small: true`): a hairline track on the ground, and the chosen segment's
/// hairline in the ink, its words at medium weight, sliding to the chosen
/// segment. Use chips for filters and a picker row
/// for a longer set of choices.
///
/// Segments share the width equally: the whole width by default, or the
/// widest label's with `expand: false` for a control that sits beside other
/// things. The control is ONE focus stop: focused, its thumb wears the 2 px
/// focus ring and the arrow keys move the choice, Home and End jump to the
/// ends — focus and choice never part, so a following Enter or Space
/// changes nothing. A screen reader meets each segment as a button that
/// announces itself selected. A null [onChanged] dims the whole control,
/// track and thumb, and the choice keeps only the thumb's hairline, in the
/// muted ink, its words regular like the rest: a disabled control never
/// reads stronger than an enabled one. The hit area pads out to 44.
///
/// [style] dresses one control, `components.segmentedButton` every one.
/// Per segment, resolved with [WidgetState.selected] on the chosen one:
/// fill (the thumb), foreground, overlay, textStyle, iconSize and padding.
/// The strip: edge or side, shape (else `shapes.small`; the thumb takes
/// the same outline 2 px inside it, concentric) and minimumSize (its
/// height). `density` moves the height.
///
/// ```dart
/// MinimalSegmentedButton<String>(segments: const [MinimalButtonSegment('week', 'Week'), MinimalButtonSegment('month', 'Month')], value: view, onChanged: setView)
/// ```
class MinimalSegmentedButton<T> extends StatefulWidget {
  /// A track of [segments], one chosen.
  const MinimalSegmentedButton({
    super.key,
    required this.segments,
    required this.value,
    this.onChanged,
    this.label,
    this.small = false,
    this.expand = true,
    this.style,
  });

  /// The views, two to four, in order.
  final List<MinimalButtonSegment<T>> segments;

  /// The chosen segment's value: one of [segments]'.
  final T value;

  /// Called with the value of the segment chosen; null disables the control.
  final ValueChanged<T>? onChanged;

  /// What the choice is about, announced before the segments.
  final String? label;

  /// The 28 px register, for a toolbar or a dense header.
  final bool small;

  /// Fill the available width (the default), or hug the labels.
  final bool expand;

  /// This control's style, over `components.segmentedButton`.
  final MinimalStyle? style;

  @override
  State<MinimalSegmentedButton<T>> createState() =>
      _MinimalSegmentedButtonState<T>();
}

/// One segment of a [MinimalSegmentedButton]: the [value] it stands for, its
/// [label] and, optionally, a 16 px [icon] before the words.
///
/// ```dart
/// MinimalButtonSegment('board', 'Board', icon: LucideIcons.kanban)
/// ```
@immutable
class MinimalButtonSegment<T> {
  /// A segment saying [label] for [value].
  const MinimalButtonSegment(this.value, this.label, {this.icon});

  /// What choosing this segment reports.
  final T value;

  /// The segment's words.
  final String label;

  /// A glyph before the words.
  final IconData? icon;
}

class _MinimalSegmentedButtonState<T> extends State<MinimalSegmentedButton<T>> {
  bool _focus = false;

  int get _index =>
      widget.segments.indexWhere((segment) => segment.value == widget.value);

  void _select(int i) {
    final onChanged = widget.onChanged;
    if (onChanged == null || i == _index) return;
    HapticFeedback.selectionClick();
    onChanged(widget.segments[i].value);
  }

  void _move(MinimalSeek seek, bool rtl) {
    _select(
      minimalSeekIndex(
        seek,
        index: math.max(_index, 0),
        last: widget.segments.length - 1,
        rtl: rtl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    final index = _index;
    assert(segments.length >= 2 && segments.length <= 4, 'two to four views');
    assert(index >= 0, 'value is none of the segments');
    final t = context.minimalTheme;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final instant = context.minimalStill;
    final layers = <MinimalStyle?>[widget.style, t.components.segmentedButton];
    final strip = MinimalStyleOf(
      layers,
      minimalStates(enabled: enabled, focused: _focus),
    );
    final height =
        strip.minimumSize?.height ??
        minimalGrownHeight(
          context,
          t.density.height(
            widget.small
                ? MinimalChromeMetrics.controlSm
                : MinimalChromeMetrics.control,
          ),
        );
    const pad = MinimalControlMetrics.segmentInset;
    final outline = strip.shape ?? t.shapes.small;
    // The thumb sits 2 px inside the strip, its corners as much rounder
    // as keeps the two concentric.
    final inner = MinimalShapes.inset(outline, pad);
    final chosen = MinimalStyleOf(
      layers,
      minimalStates(enabled: enabled, focused: _focus, selected: true),
    );
    final n = segments.length;
    final ground = minimalGround(context);

    final thumb = Positioned.fill(
      child: AnimatedAlign(
        duration: instant ? Duration.zero : MinimalMotion.base,
        curve: MinimalMotion.out,
        alignment: AlignmentDirectional(
          -1 + 2 * math.max(index, 0) / (n - 1),
          0,
        ),
        child: FractionallySizedBox(
          widthFactor: 1 / n,
          heightFactor: 1,
          child: Container(
            decoration: minimalFrame(
              inner,
              // A choice is said in ink, not a raised or tinted thumb: the
              // chosen segment's hairline turns to the ink, on the ground
              // (the muted ink while the control is disabled).
              fill: chosen.fill,
              side: BorderSide(
                color: enabled ? t.foreground : t.mutedForeground,
                width: t.rim,
              ),
            ),
            // The control's one focus stop shows on the choice it moves,
            // past a gap of the ground it sits on.
            foregroundDecoration: _focus && enabled
                ? minimalRingFrame(
                    inner,
                    ring: t.ring,
                    ground: ground,
                    width: t.focusWidth,
                  )
                : null,
          ),
        ),
      ),
    );

    Widget segment(int i) {
      final selected = i == index;
      // Disabled, the chosen words keep the rest's ink and weight; the
      // thumb's hairline alone says which it is.
      final strong = selected && enabled;
      final segment = segments[i];
      Widget content(Set<WidgetState> states) {
        final so = MinimalStyleOf(layers, {
          ...states,
          if (selected) WidgetState.selected,
        });
        final inkTo =
            so.foreground ?? (strong ? t.foreground : t.mutedForeground);
        final icon = segment.icon;
        // The segment's ink lerps to each state (Minimal's short fade).
        return MinimalFace(
          ink: inkTo,
          alignment: Alignment.center,
          padding:
              so.padding ??
              const EdgeInsets.symmetric(
                horizontal: MinimalControlMetrics.segmentPad,
              ),
          builder: (context, lerped) {
            final ink = lerped ?? inkTo;
            final text = minimalCapLabel(
              Text(
                segment.label,
                // The chosen words at medium weight, the rest regular.
                style: so.text(
                  strong
                      ? (widget.small ? t.caption : t.bodySmall).medium
                      : (widget.small ? t.caption : t.bodySmall),
                  ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            );
            return icon == null
                ? text
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: so.iconSize ?? MinimalIconSize.i16,
                        color: ink,
                      ),
                      const MinimalGap(MinimalSpacing.s4),
                      Flexible(child: text),
                    ],
                  );
          },
        );
      }

      // Disabled, the whole track dims below; a segment only says so.
      if (!enabled) {
        return Semantics(
          container: true,
          button: true,
          enabled: false,
          selected: selected,
          child: content(const {WidgetState.disabled}),
        );
      }
      // The track is the focus stop, so a segment is a tap and a
      // screen-reader button but never a stop of its own.
      return MinimalPressable(
        onPressed: () => _select(i),
        shape: inner,
        style: MinimalStyleOf(layers, const {}).press,
        selected: selected,
        focusable: false,
        builder: (context, states) => content(states),
      );
    }

    Widget track = Container(
      height: height,
      padding: const EdgeInsets.all(pad),
      // The track stands on the ground in its hairline; no well.
      decoration: minimalFrame(outline, side: strip.rim(t.border, t.rim)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumb,
          Row(
            children: [for (var i = 0; i < n; i++) Expanded(child: segment(i))],
          ),
        ],
      ),
    );
    if (!widget.expand) track = IntrinsicWidth(child: track);
    // Filling its column on a phone; from the compact width up it stops at
    // a control's measure (design6 P (a)).
    if (widget.expand) track = MinimalLayout.capControl(context, track);
    if (!enabled) track = Opacity(opacity: 0.45, child: track);

    return MinimalHitTarget(
      child: Semantics(
        container: true,
        label: widget.label,
        explicitChildNodes: true,
        child: FocusableActionDetector(
          enabled: enabled,
          onShowFocusHighlight: (v) => setState(() => _focus = v),
          shortcuts: minimalSeekShortcuts,
          actions: <Type, Action<Intent>>{
            MinimalSeekIntent: CallbackAction<MinimalSeekIntent>(
              onInvoke: (intent) {
                _move(intent.seek, rtl);
                return null;
              },
            ),
          },
          child: track,
        ),
      ),
    );
  }
}
