import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// A segmented control's height: 24, 32 or 40.
enum Fluent2SegmentedButtonSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// One choice of a [Fluent2SegmentedButton]: its [value], its words, an optional
/// glyph before them.
///
/// ```dart
/// Fluent2ButtonSegment('week', 'Week')
/// ```
class Fluent2ButtonSegment<T> {
  /// A segment for [value], labelled [label].
  const Fluent2ButtonSegment(
    this.value,
    this.label, {
    this.icon,
    this.enabled = true,
  });

  /// The value the segment stands for.
  final T value;

  /// The segment's words.
  final String label;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// False draws the segment disabled; it cannot be chosen.
  final bool enabled;
}

/// A segmented control in Fluent 2's terms: a TabList of the
/// filled-circular appearance joined into one strip, since Fluent on the
/// web has no segmented control of its own: under a finger a pill, as
/// Fluent 2's iOS and Android segmented control; with a pointer the
/// buttons' medium corner, as Fluent's toggle buttons on the web and
/// Windows. One grey track (Fluent's grey step laid over the ground it
/// stands on, so it shows on the page, a card or a tinted ground) holding
/// [segments] of one width, the chosen one on a brand thumb that slides
/// to the choice, its words in body1 strong in the on-brand ink; the
/// others in body1 in the second ink, tinted under the pointer. 32 tall
/// (24 small, 40 large); [expand] fills the row's width, else the widest
/// segment sets every segment's width. The arrows move the choice. Read
/// as a group named [label] of selectable buttons.
///
/// ```dart
/// Fluent2SegmentedButton(label: 'Calendar view', segments: const [Fluent2ButtonSegment('day', 'Day'), Fluent2ButtonSegment('week', 'Week')], value: view, onChanged: (v) => setState(() => view = v))
/// ```
class Fluent2SegmentedButton<T> extends StatelessWidget {
  /// A segmented button of [segments], [value] chosen.
  const Fluent2SegmentedButton({
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.label,
    this.size = Fluent2SegmentedButtonSize.medium,
    this.expand = false,
    this.style,
    super.key,
  });

  /// The segments, in order.
  final List<Fluent2ButtonSegment<T>> segments;

  /// The chosen segment's value.
  final T value;

  /// Called with the value of the segment chosen; null puts it out of use.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the group.
  final String label;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2SegmentedButtonSize size;

  /// Whether it fills its row's width, the segments sharing it.
  final bool expand;

  /// The strip's own look over `Fluent2ThemeData.segmentedButtonTheme`:
  /// `fill` (the track at rest, the thumb when [WidgetState.selected]),
  /// `foreground` and `overlay` (a segment's words and wash in its
  /// states), `shape` (the corner of the strip and its thumb, at most a
  /// pill; without one a pill under a finger and the medium corner with a
  /// pointer).
  final Fluent2Style? style;

  void _move(int by) {
    final change = onChanged;
    if (change == null) return;
    final at = segments.indexWhere((s) => s.value == value);
    var i = at;
    for (var n = 0; n < segments.length; n++) {
      i = (i + by) % segments.length;
      if (i < 0) i += segments.length;
      if (segments[i].enabled) break;
    }
    if (i != at && segments[i].enabled) change(segments[i].value);
  }

  @override
  Widget build(BuildContext context) {
    assert(segments.length >= 2, 'a segmented control offers two or more');
    final t = context.fluent2Theme;
    final c = t.colors;
    var (
      double height,
      double side,
      TextStyle type,
      double glyph,
    ) = switch (size) {
      Fluent2SegmentedButtonSize.small => (
        24.0,
        Fluent2Spacing.s,
        t.caption1,
        16.0,
      ),
      Fluent2SegmentedButtonSize.medium => (
        32.0,
        Fluent2Spacing.m,
        t.body1,
        20.0,
      ),
      Fluent2SegmentedButtonSize.large => (
        40.0,
        Fluent2Spacing.l,
        t.body2,
        20.0,
      ),
    };
    // With a pointer Fluent's height at the theme's density (never under
    // 20, as a button); under a finger the whole 48 target, as every
    // control's face, so a row shows one height.
    height = Fluent2Layout.padded(context)
        ? Fluent2Layout.touchHitTarget
        : t.density.height(height, least: 20);
    final layers = [style, t.segmentedButtonTheme];
    // The style's or the theme's outline rounds the strip and its thumb, at most to a pill; without one
    // a pill under a finger (Fluent 2 iOS and Android) and the buttons'
    // medium corner with a pointer (Fluent's toggle buttons on the web).
    final corner = fluent2CornerOf(
      Fluent2Style.first(layers, (s) => s.shape, const {}),
      height,
      Fluent2Layout.padded(context) ? height / 2 : Fluent2Radius.medium,
    ).clamp(0, height / 2).toDouble();
    final live = onChanged != null;
    final n = segments.length;
    final at = segments.indexWhere((s) => s.value == value);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final duration = Fluent2Motion.on(context)
        ? Fluent2Motion.normal
        : Duration.zero;
    final change = onChanged;
    Widget segment(int i) {
      final s = segments[i];
      final chosen = i == at;
      final on = live && s.enabled;
      return Expanded(
        child: Fluent2Pressable(
          onPressed: on && change != null ? () => change(s.value) : null,
          label: s.label,
          selected: chosen,
          radius: corner,
          builder: (context, states) {
            final press = states.press;
            final look = Fluent2StyleOf(layers, states);
            final fill = chosen
                ? press.pick(
                    const Color(0x00000000),
                    c.brandBackgroundHover,
                    c.brandBackgroundPressed,
                    const Color(0x00000000),
                  )
                : fluent2WellWash(t, press);
            final ink =
                look.foreground ??
                (!on
                    ? c.neutralForegroundDisabled
                    : chosen
                    ? c.neutralForegroundOnBrand
                    : press.pick(
                        c.neutralForeground2,
                        c.neutralForeground2Hover,
                        c.neutralForeground2Pressed,
                      ));
            return fluent2EasedInks([fill, ink], (context, inks) {
              final [fill, ink] = inks;
              final wash = look.overlay?.resolve(look.states);
              final icon = s.icon;
              return Container(
                constraints: BoxConstraints(minHeight: height),
                padding: EdgeInsets.symmetric(horizontal: side),
                decoration: BoxDecoration(
                  color: wash == null ? fill : Color.alphaBlend(wash, fill),
                  borderRadius: BorderRadius.circular(corner),
                ),
                child: Align(
                  heightFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Fluent2Spacing.xs,
                    children: [
                      if (icon != null) Icon(icon, size: glyph, color: ink),
                      // Segments share the track evenly, so a label that
                      // outgrows its share (a large text size) is drawn
                      // smaller, whole, as iOS's segmented control does,
                      // never cut to a letter.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: fluent2CapCentred(
                            Text(
                              s.label,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: (chosen ? t.body1Strong : type).copyWith(
                                fontSize: type.fontSize,
                                height: type.height,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      );
    }

    final x = n == 1 || at < 0 ? -1.0 : -1 + 2 * at / (n - 1);
    final track = Container(
      decoration: BoxDecoration(
        color:
            Fluent2Style.first(layers, (s) => s.fill, {
              if (!live) WidgetState.disabled,
            }) ??
            (live ? fluent2Well(t) : fluent2WellDisabled(t)),
        borderRadius: BorderRadius.circular(corner),
      ),
      child: Stack(
        children: [
          if (at >= 0)
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: Fluent2Motion.easyEase,
                alignment: Alignment(rtl ? -x : x, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / n,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          Fluent2Style.first(layers, (s) => s.fill, {
                            WidgetState.selected,
                            if (!live) WidgetState.disabled,
                          }) ??
                          (live ? c.brandBackground : c.neutralBackground1),
                      border: live
                          ? null
                          : Border.all(
                              color: fluent2Step(t, c.neutralStrokeDisabled),
                            ),
                      borderRadius: BorderRadius.circular(corner),
                    ),
                  ),
                ),
              ),
            ),
          // Every segment as tall as the track (a finger's row is taller
          // than the face), so a pressed or hovered fill covers its whole
          // cell as the thumb does.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = 0; i < n; i++) segment(i)],
            ),
          ),
        ],
      ),
    );
    // Filling a phone's row; from 600 it keeps its segments' width.
    final sized = expand && !fluent2Roomy(context)
        ? track
        : Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: IntrinsicWidth(child: track),
          );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _move(rtl ? -1 : 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _move(rtl ? 1 : -1),
        },
        child: FocusTraversalGroup(child: Fluent2HitSlop(child: sized)),
      ),
    );
  }
}
