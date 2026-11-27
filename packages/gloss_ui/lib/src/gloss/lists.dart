/// Gloss's lists: groups of rows in a well pressed into the porcelain, the
/// rows between engraved lines, and the letterpressed heads above them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'display.dart' show GlossAvatar;
import 'fonts.dart';
import 'internal/glaze_state.dart';
import 'surface.dart';
import 'theme.dart';
import 'internal/corners.dart';

/// A section's head: its words letterpressed into the page, in sentence
/// case, 8 px above the well it heads, on the rows' keyline.
///
/// ```dart
/// const GlossSectionHeader('Notifications')
/// ```
class GlossSectionHeader extends StatelessWidget {
  /// A head reading [text], [trailing] at its end (a count, a text button).
  const GlossSectionHeader(this.text, {super.key, this.trailing});

  /// The words.
  final String text;

  /// Something at the end of the head.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: GlossSpacing.regular,
        end: GlossSpacing.tight,
        bottom: GlossSpacing.small,
      ),
      child: Semantics(
        header: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                text,
                style: glossLetterpress(
                  theme.textTheme.caption.copyWith(color: c.inkSecondary),
                  c,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

/// A group of rows in a well pressed into the porcelain, rounded 16, an
/// engraved line between rows from the words' keyline to the end. [header]
/// is letterpressed above it, [footer] under it.
///
/// ```dart
/// GlossWell(header: 'Account', children: [GlossListTile(title: 'Name', trailingText: 'Ada', onTap: () {}), GlossListTile(title: 'Email', trailingText: 'ada@example.com')])
/// ```
class GlossWell extends StatelessWidget {
  /// A well holding [children], one row each.
  const GlossWell({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.dividerIndent,
  });

  /// The rows.
  final List<Widget> children;

  /// A head above the well.
  final String? header;

  /// A note under the well.
  final String? footer;

  /// Where the engraved lines start; the rows' words when null (past a
  /// leading glyph when the first row has one).
  final double? dividerIndent;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final first = children.isEmpty ? null : children.first;
    final indent =
        dividerIndent ??
        (first is GlossListTile && first.leading != null
            ? GlossListTile.leadingExtent
            : GlossSpacing.regular);
    return RawKeylineRegion(
      label: header ?? 'Well',
      indents: [indent],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) GlossSectionHeader(header!),
          GlossSurface(
            face: GlossFace.well(
              c,
              radius: glossCorner(theme, RawCorner.medium),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                glossCorner(theme, RawCorner.medium),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, row) in children.indexed) ...[
                    // The line stops at the well's wall, not across it.
                    if (i > 0) GlossEngravedLine(indent: indent, endIndent: 2),
                    row,
                  ],
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: GlossSpacing.regular,
                end: GlossSpacing.regular,
                top: GlossSpacing.small,
              ),
              child: Text(footer!, style: theme.textTheme.secondary),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('header', header, defaultValue: null))
      ..add(StringProperty('footer', footer, defaultValue: null))
      ..add(IntProperty('rows', children.length));
  }
}

/// A row: [title], a [subtitle] under it, a [leading] glyph, and at its end
/// a [trailingText] value, a [trailing] control or a chevron when it opens
/// something. A press shades the well's floor under it; [selected] seats a
/// pearl plate in the well under the row, inset 4 px with its corners
/// concentric with the well's.
///
/// A screen reader hears the row by its words, a tag at its end among them;
/// a [GlossAvatar] at its start stays out, the title naming what it
/// pictures. A row without [onTap] is one node with its control, the title
/// naming the switch at its end, as Flutter's `SwitchListTile` is; a row
/// that opens something keeps a control at its end (its menu) a node of its
/// own, as a Material `ListTile` does.
///
/// ```dart
/// GlossListTile(leading: const Icon(LucideIcons.bell), title: 'Reminders', trailing: GlossSwitch(value: true, onChanged: (value) {}))
/// ```
class GlossListTile extends StatelessWidget {
  /// A row titled [title].
  const GlossListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.selected = false,
    this.showChevron,
    this.isDestructiveAction = false,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The row's name.
  final String title;

  /// A second line.
  final String? subtitle;

  /// A glyph or a [GlossAvatar] at the row's start.
  final Widget? leading;

  /// A control or a tag at the row's end (a switch, a stepper, a status).
  final Widget? trailing;

  /// A value at the row's end.
  final String? trailingText;

  /// Called on a press; null for a row that only shows.
  final VoidCallback? onTap;

  /// Whether the row is the one shown beside its list (a list and its
  /// detail): a pearl plate under it, its glyph jade.
  final bool selected;

  /// Whether a chevron shows; by default when it opens something and has no
  /// [trailing].
  final bool? showChevron;

  /// Whether the row destroys something: ruby words.
  final bool isDestructiveAction;

  /// Whether the row takes presses.
  final bool enabled;

  /// What a screen reader says, when not the row's words.
  final String? semanticLabel;

  /// This row's own style, over [GlossThemeData.listTileStyle].
  final GlossStyle? style;

  /// Where a row's words start when it has a leading glyph.
  static const double leadingExtent =
      GlossSpacing.regular + 24 + GlossSpacing.medium;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    Widget body(Set<WidgetState> states) {
      final layered = RawStyleOf(
        [style, theme.listTileStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = !enabled;
      final pressed = states.contains(WidgetState.pressed);
      final ink =
          layered.foreground ??
          (disabled
              ? c.inkDisabled
              : isDestructiveAction
              ? c.danger
              : c.ink);
      final plate = GlossFace.pearl(c);
      // On a selected row's pearl plate the supporting words take the
      // secondary ink's nearest tone that reads at 4.5:1 where they stand:
      // by night the moonlit pearl is lighter than the well round it.
      final muted = disabled
          ? c.inkDisabled
          : selected
          ? RawPalette.readableTone(
              c.inkSecondary,
              on: [Color.lerp(plate.top, plate.middle, 0.4)!, plate.middle],
            )
          : c.inkSecondary;
      final glyph = disabled
          ? c.inkDisabled
          : selected
          ? c.jadeInk
          : isDestructiveAction
          ? c.danger
          : c.inkSecondary;
      final chevron = showChevron ?? (onTap != null && trailing == null);
      final light = c.brightness == Brightness.light;
      // The floor under the row darkens as a finger presses it.
      final floor = pressed
          ? (light ? const Color(0x14183048) : const Color(0x33000000))
          : const Color(0x00000000);
      final rowHeight = subtitle == null
          ? theme.rowHeight
          : theme.rowHeight + 16;
      final largeText = MediaQuery.textScalerOf(context).scale(10) >= 15;
      return animatedGlazePaint(
        context,
        glossGlazeOf(c, states),
        (light) => _RowPainter(
          colors: c,
          corner: glossCorner(GlossTheme.of(context), RawCorner.medium),
          floor: floor,
          selected: selected && !disabled,
          focus: light,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.regular,
              vertical: GlossSpacing.small + 2,
            ),
            // A value at the end takes its own width (up to under half the
            // row), the title the rest, so the value sits at the row's end.
            child: LayoutBuilder(
              builder: (context, box) {
                final heading = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      IconTheme.merge(
                        data: IconThemeData(size: 22, color: glyph),
                        child: SizedBox.square(
                          dimension: 24,
                          // An avatar at the start pictures what the title
                          // names: it stays out of the row's name, which
                          // would say the name twice.
                          child: Center(
                            child: leading is GlossAvatar
                                ? ExcludeSemantics(child: leading)
                                : leading,
                          ),
                        ),
                      ),
                      const SizedBox(width: GlossSpacing.medium),
                    ],
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RawCapCenter(
                            capHeightFactor: glossCapHeightFactor,
                            child: Text(
                              title,
                              style: theme.textTheme.body
                                  .copyWith(
                                    color: ink,
                                    fontWeight: FontWeight.w500,
                                    fontVariations: glossWeightAxis(
                                      FontWeight.w500,
                                    ),
                                  )
                                  .merge(layered.textStyle),
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: theme.textTheme.secondary.copyWith(
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
                final end = [
                  if (trailingText != null) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth.isFinite
                            ? box.maxWidth * 0.45
                            : double.infinity,
                      ),
                      child: Text(
                        trailingText!,
                        textAlign: TextAlign.end,
                        maxLines: largeText ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body.copyWith(color: muted),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    if (trailingText != null)
                      const SizedBox(width: GlossSpacing.medium),
                    // The control at the end takes its own width, up to three
                    // fifths of the row, the title keeping the rest: a
                    // control isn't squeezed (a stepper keeps its well), and
                    // a long one never pushes the title out.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: box.maxWidth.isFinite
                            ? box.maxWidth * 0.6
                            : double.infinity,
                      ),
                      child: trailing,
                    ),
                  ],
                  if (chevron) ...[
                    if (trailingText != null || trailing != null)
                      const SizedBox(width: GlossSpacing.small),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: SizedBox(
                        width: 8,
                        height: 14,
                        child: CustomPaint(
                          painter: GlossChevronPainter(
                            disabled ? c.inkDisabled : c.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ];
                if (largeText && trailing != null) {
                  // Measure the actual words and control before deciding
                  // whether the control needs its own line.
                  return OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    spacing: GlossSpacing.medium,
                    overflowSpacing: GlossSpacing.small,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      heading,
                      Row(mainAxisSize: MainAxisSize.min, children: end),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    if (end.isNotEmpty)
                      SizedBox(
                        width: trailing != null || trailingText != null
                            ? GlossSpacing.medium
                            : GlossSpacing.small,
                      ),
                    ...end,
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    if (onTap == null) {
      // A row without a press of its own is one node with its control (a
      // switch at its end), the title naming it, as Flutter's
      // SwitchListTile is.
      return MergeSemantics(
        child: Semantics(
          container: true,
          selected: selected ? true : null,
          label: semanticLabel,
          child: body({if (!enabled) WidgetState.disabled}),
        ),
      );
    }
    return RawButton(
      onPressed: enabled ? onTap : null,
      selected: selected,
      semanticSelected: selected ? true : null,
      semanticLabel: semanticLabel,
      // A control at the row's end (its menu, a switch) keeps a node of its
      // own, which a screen reader reaches apart from the row, as in a
      // Material ListTile; the row's words still name the row.
      mergeSemantics: trailing == null,
      builder: (context, states, _) => body(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('trailingText', trailingText, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      );
  }
}

class _RowPainter extends CustomPainter {
  _RowPainter({
    required this.colors,
    required this.floor,
    required this.selected,
    required this.focus,
    required this.rtl,
    required this.corner,
  });

  final GlossColors colors;
  // The well's corner: the theme's medium step.
  final double corner;
  final Color floor;
  final bool selected;
  final Color focus;
  final bool rtl;

  // Its plate fits 4 px inside the wall of the well.
  static const double _inset = 4;
  double get _radius => corner - _inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (floor.a > 0) canvas.drawRect(rect, Paint()..color = floor);
    final plate = rect.deflate(_inset);
    if (selected) {
      _fromStart(
        canvas,
        plate,
        rtl,
        () => paintGlossFace(
          canvas,
          plate,
          // A plate that carries words: by night no band of light across
          // its crown, where it would run behind the title.
          GlossFace.pearl(colors, radius: _radius).copyWith(
            lift: 0.45,
            focus: focus,
            lens: colors.brightness == Brightness.light ? 0.4 : 0,
          ),
          brightness: colors.brightness,
        ),
      );
      return;
    }
    // An unselected row catches the light on the well floor.
    _fromStart(
      canvas,
      plate,
      rtl,
      () => paintGlossHalo(
        canvas,
        RRect.fromRectAndRadius(plate, Radius.circular(_radius)),
        focus,
        brightness: colors.brightness,
        inside: true,
      ),
    );
  }

  @override
  bool shouldRepaint(_RowPainter old) =>
      old.colors != colors ||
      old.floor != floor ||
      old.selected != selected ||
      old.focus != focus ||
      old.rtl != rtl ||
      old.corner != corner;
}

// Gloss is lit once, from above and the reading start: right to left, what
// [paint] draws in [rect] (a face, even about its middle) is turned about
// its middle, so its light runs from the right.
void _fromStart(Canvas canvas, Rect rect, bool rtl, VoidCallback paint) {
  if (!rtl) {
    paint();
    return;
  }
  canvas
    ..save()
    ..translate(rect.center.dx * 2, 0)
    ..scale(-1, 1);
  paint();
  canvas.restore();
}

/// The chevron a row that opens something ends with: a fine stroke pointing
/// to the end side.
class GlossChevronPainter extends CustomPainter {
  /// A chevron in [color].
  GlossChevronPainter(this.color);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.15, size.height * 0.1)
        ..lineTo(size.width * 0.85, size.height * 0.5)
        ..lineTo(size.width * 0.15, size.height * 0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(GlossChevronPainter old) => old.color != color;
}

/// A Gloss card: an object's tile, level porcelain glazed onto the page,
/// rounded 18, a light along its top and a soft shadow under it. Pressable
/// with [onTap]: a press settles it into the page.
///
/// ```dart
/// GlossCard(onTap: () {}, child: const Text('Miso aubergine'))
/// ```
class GlossCard extends StatelessWidget {
  /// A tile holding [child].
  const GlossCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(GlossSpacing.regular),
    this.semanticLabel,
    this.style,
  });

  /// What it holds.
  final Widget child;

  /// Called on a press; null for a tile that only shows.
  final VoidCallback? onTap;

  /// The room inside its rim.
  final EdgeInsetsGeometry padding;

  /// What a screen reader says for a pressable card.
  final String? semanticLabel;

  /// This card's own style, over [GlossThemeData.cardStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    Widget tile(Set<WidgetState> states) {
      final layered = RawStyleOf([style, theme.cardStyle], states);
      var face = GlossFace.porcelain(
        c,
        radius: glossCorner(theme, RawCorner.large),
      );
      if (layered.fill != null) face = face.glazed(layered.fill!);
      final pressed = states.contains(WidgetState.pressed);
      face = face.copyWith(
        edge: layered.edge,
        lift: pressed ? 0.1 : 0.35,
        focus: glossGlazeOf(c, states),
      );
      return AnimatedGlossSurface(
        face: face,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            glossCorner(theme, RawCorner.large),
          ),
          child: Padding(
            padding: layered.padding(Directionality.of(context)) ?? padding,
            child: child,
          ),
        ),
      );
    }

    if (onTap == null) return tile(const {});
    return RawButton(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => tile(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty('pressable', value: onTap != null, ifTrue: 'pressable'),
      )
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}
