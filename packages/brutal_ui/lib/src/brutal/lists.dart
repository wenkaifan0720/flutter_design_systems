/// Brutal's lists: [BrutalListGroup], a table of rows in one frame, every
/// row on a full-width rule it shares with the next; [BrutalListTile], one
/// row; and [BrutalSectionHeader], the caption over a group.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/ruled_column.dart';
import 'internal/focus_ink.dart';
import 'surface.dart';
import 'theme.dart';

/// The caption over a group: small capitals in bold, tracked, in ink, with
/// an optional [trailing] action at the end of its line.
///
/// Reads [style]'s `foreground`, `padding` and `textStyle`, then
/// [BrutalThemeData.sectionHeaderStyle]'s.
///
/// ```dart
/// const BrutalSectionHeader('Notifications')
/// ```
class BrutalSectionHeader extends StatelessWidget {
  /// A caption reading [text].
  const BrutalSectionHeader(this.text, {super.key, this.trailing, this.style});

  /// The words; shown in capitals.
  final String text;

  /// An action at the line's end, such as a text button.
  final Widget? trailing;

  /// Its style, over [BrutalThemeData.sectionHeaderStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layered = RawStyleOf([style, theme.sectionHeaderStyle], const {});
    return Padding(
      padding:
          layered.padding(Directionality.of(context)) ??
          const EdgeInsets.only(bottom: BrutalSpacing.small),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text.toUpperCase(),
                style: layered.text(
                  theme.textTheme.caption.copyWith(color: layered.foreground),
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

/// Rows in one square frame, each on a full-width rule it shares with the
/// next: a table you can see. The frame is flat (it has no shadow; only
/// what you press has one) and its rows do not move when pressed: a
/// pressed row turns over to ink.
///
/// The group marks itself a keyline region: its rows' words start on one
/// line, after a leading glyph on a second, and their trailing parts end on
/// one.
///
/// Reads [style]'s `fill` (the frame), `edge` (the frame's and the rows'
/// rules) and `textStyle` (the footer), then
/// [BrutalThemeData.listGroupStyle]'s.
///
/// ```dart
/// BrutalListGroup(header: 'Account', children: [BrutalListTile(title: 'Name', trailingText: 'Ada Park', onTap: () {}), BrutalListTile(title: 'Email', trailingText: 'ada@example.com')])
/// ```
class BrutalListGroup extends StatelessWidget {
  /// A group of [children].
  const BrutalListGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.style,
  });

  /// The rows, usually [BrutalListTile]s.
  final List<Widget> children;

  /// A caption over the frame, as [BrutalSectionHeader] draws it.
  final String? header;

  /// Help under the frame.
  final String? footer;

  /// Its style, over [BrutalThemeData.listGroupStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.listGroupStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    return RawKeylineRegion(
      label: header ?? 'List group',
      indents: const [BrutalListTile.leadingExtent],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) BrutalSectionHeader(header!),
          BrutalSurface(
            face: BrutalFace(
              fill: layered.fill ?? c.surface,
              border: rule,
              foreground: c.ink,
            ),
            // A rule between each two rows; a row that draws nothing adds
            // none.
            child: BrutalRuledColumn(
              gap: theme.borderWidth,
              rule: rule,
              children: children,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: BrutalSpacing.small),
              child: Text(
                footer!,
                style: layered.text(theme.textTheme.secondary),
              ),
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
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A full-width (or, [vertical], full-height) rule in the look's border
/// width: the line two cells share.
///
/// Reads [style]'s `edge` (its colour, under [color]), then
/// [BrutalThemeData.ruleStyle]'s.
///
/// ```dart
/// const BrutalRule()
/// ```
class BrutalRule extends StatelessWidget {
  /// A rule in [color], ink when null.
  const BrutalRule({super.key, this.color, this.vertical = false, this.style});

  /// Its colour; ink when null.
  final Color? color;

  /// Whether it stands upright.
  final bool vertical;

  /// Its style, over [BrutalThemeData.ruleStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layered = RawStyleOf([style, theme.ruleStyle], const {});
    final colour =
        color ?? layered.side?.color ?? layered.edge ?? theme.colors.ink;
    return SizedBox(
      width: vertical ? theme.borderWidth : null,
      height: vertical ? null : theme.borderWidth,
      child: ColoredBox(color: colour),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// One row of a [BrutalListGroup]: an optional [leading] glyph, a [title]
/// and a [subtitle], and at the end a [trailingText] value, a [trailing]
/// control or, when it opens something, a chevron.
///
/// With [onTap] it can be pressed: the cell turns over to ink, its words to
/// paper, and its keyboard focus is a bar inside the lower edge (a row
/// shares its rules, so a ring outside it would sit on its neighbours).
/// [selected] turns it over to ink to stay.
///
/// Reads [style]'s `fill` (in its states: pressed, selected), `foreground`,
/// `padding`, `minimumSize` (its least height), `textStyle` (the title) and
/// `iconSize` (the leading glyph), then [BrutalThemeData.listTileStyle]'s.
///
/// ```dart
/// BrutalListTile(leading: const Icon(LucideIcons.bell), title: 'Reminders', subtitle: 'A day before each event', trailing: BrutalSwitch(value: on, onChanged: (v) => setState(() => on = v)))
/// ```
class BrutalListTile extends StatelessWidget {
  /// A row reading [title].
  const BrutalListTile({
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

  /// The row's words.
  final String title;

  /// A second line under [title].
  final String? subtitle;

  /// A glyph or a person's monogram at the start, 24 px: decoration, kept
  /// out of the row's name ([title] and [semanticLabel] name it).
  final Widget? leading;

  /// A control at the end: a switch, a checkbox, a tag.
  final Widget? trailing;

  /// A value at the end, in the muted ink.
  final String? trailingText;

  /// Called when the row is pressed; null: the row is not a button.
  final VoidCallback? onTap;

  /// Whether the row stands chosen, filled with ink.
  final bool selected;

  /// Whether a chevron ends the row; null: it does when [onTap] is set and
  /// there is no [trailing].
  final bool? showChevron;

  /// Whether the row's action destroys something: its words are red.
  final bool isDestructiveAction;

  /// Whether it can be pressed; off, its words go grey.
  final bool enabled;

  /// What a screen reader calls it when [title] is not the right name.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.listTileStyle].
  final BrutalStyle? style;

  /// How far a row's words stand from its start when it has a [leading]
  /// glyph, past the first keyline.
  static const double leadingExtent = 24 + BrutalSpacing.medium;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final named = semanticLabel != null;
    Widget body(Set<WidgetState> states) {
      final layered = RawStyleOf(
        [style, theme.listTileStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = !enabled;
      final lit = selected || states.contains(WidgetState.pressed);
      final ink =
          layered.foreground ??
          (layered.fill != null && !disabled
              ? c.onColor(layered.fill!)
              : disabled
              ? c.disabled
              : lit
              ? c.paper
              : isDestructiveAction
              ? c.danger
              : c.ink);
      final muted = disabled
          ? c.disabled
          : layered.fill != null
          ? c.onColor(layered.fill!)
          : lit
          ? c.paper
          : c.inkMuted;
      final chevron = showChevron ?? (onTap != null && trailing == null);
      return AnimatedBrutalSurface(
        stiffness: BrutalMotion.colorStiffness,
        face: BrutalFace(
          fill:
              layered.fill ??
              (lit && !disabled ? c.ink : c.ink.withValues(alpha: 0)),
          border: c.ink.withValues(alpha: 0),
          foreground: ink,
          borderWidth: 0,
        ),
        child: CustomPaint(
          foregroundPainter: states.contains(WidgetState.focused)
              ? BrutalInsetFocusPainter(
                  brutalFocusInk(c, layered.fill ?? (lit ? c.ink : c.surface)),
                )
              : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  layered.minimumSize?.height ?? (subtitle == null ? 56 : 72),
            ),
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(
                    horizontal: BrutalSpacing.regular,
                    vertical: BrutalSpacing.medium,
                  ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(
                        size: layered.iconSize ?? 24,
                        color: ink,
                      ),
                      child: SizedBox.square(
                        dimension: 24,
                        // Decoration: the title names the row (a monogram
                        // would say its title again).
                        child: ExcludeSemantics(child: Center(child: leading)),
                      ),
                    ),
                    const SizedBox(width: BrutalSpacing.medium),
                  ],
                  Expanded(
                    child: ExcludeSemantics(
                      excluding: named,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RawCapCenter(
                            capHeightFactor: BrutalTheme.of(context)
                                .capHeightFactor,
                            child: Text(
                              title,
                              style: layered.text(
                                theme.textTheme.label.copyWith(color: ink),
                              ),
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: BrutalSpacing.tight,
                              ),
                              child: Text(
                                subtitle!,
                                style: theme.textTheme.secondary.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (trailingText != null) ...[
                    const SizedBox(width: BrutalSpacing.medium),
                    // The value at the row's end, taking at most half the
                    // row before it ends in an ellipsis.
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ExcludeSemantics(
                          excluding: named,
                          child: Text(
                            trailingText!,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.body.copyWith(color: muted),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: BrutalSpacing.medium),
                    // On the ink of a chosen or pressed row, the control at
                    // its end stands in the look turned over (paper for ink),
                    // so a plain glyph button, a value or a checkbox reads
                    // there as it does on the page, and the row's fill runs
                    // under it to the row's end.
                    AnimatedBrutalTheme(
                      data: lit && !disabled && layered.fill == null
                          ? _turnedOver(theme)
                          : theme,
                      child: trailing!,
                    ),
                  ],
                  if (chevron) ...[
                    const SizedBox(width: BrutalSpacing.small),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: SizedBox.square(
                        dimension: 20,
                        child: CustomPaint(
                          painter: _ArrowPainter(ink, theme.borderWidth),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        label: semanticLabel,
        value: named ? trailingText : null,
        child: body({if (!enabled) WidgetState.disabled}),
      );
    }
    return RawButton(
      onPressed: enabled ? onTap : null,
      selected: selected,
      semanticSelected: selected ? true : null,
      semanticLabel: semanticLabel,
      semanticValue: named ? trailingText : null,
      builder: (context, states, _) => body(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// [theme] turned over for a control on an inked row: its ink is the
/// page's paper, its paper and faces the ink, its supporting words a step
/// toward the ink, and its type recoloured to match.
BrutalThemeData _turnedOver(BrutalThemeData theme) {
  final c = theme.colors;
  final over = c.copyWith(
    brightness: c.brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light,
    paper: c.ink,
    surface: c.ink,
    ink: c.paper,
    inkMuted: Color.lerp(c.paper, c.ink, 0.3),
    disabled: Color.lerp(c.paper, c.ink, 0.45),
  );
  TextStyle recolour(TextStyle style) => style.copyWith(
    color: style.color == c.inkMuted ? over.inkMuted : over.ink,
  );
  final t = theme.textTheme;
  return theme.copyWith(
    colors: over,
    textTheme: t.copyWith(
      display: recolour(t.display),
      headline: recolour(t.headline),
      title: recolour(t.title),
      body: recolour(t.body),
      label: recolour(t.label),
      secondary: recolour(t.secondary),
      caption: recolour(t.caption),
    ),
  );
}

/// A plain arrow pointing to the end side: the row opens something. Drawn
/// with square caps, mirrored in right-to-left text.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color, this.width);

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = color;
    canvas
      ..drawLine(Offset(w * 0.2, h / 2), Offset(w * 0.8, h / 2), paint)
      ..drawPath(
        Path()
          ..moveTo(w * 0.55, h * 0.25)
          ..lineTo(w * 0.8, h / 2)
          ..lineTo(w * 0.55, h * 0.75),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.width != width;
}
