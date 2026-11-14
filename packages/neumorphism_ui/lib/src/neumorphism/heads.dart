// Heads and small words: a section's head, a card, a set straight into the wall, the page's head, states and tags. Sentence
// case throughout, one family, no tracked caps.
import 'package:flutter/widgets.dart';

import 'frames.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'layout.dart';
import 'ornaments.dart';
import 'rows.dart'
    show
        NeumorphicKvRow,
        NeumorphicLevelRow,
        NeumorphicList,
        NeumorphicStepRow,
        NeumorphicTodoRow,
        NeumorphicTotalRow;
import 'theme.dart';
import 'internal/geometry.dart';
import 'internal/cap_label.dart';

/// Text with `*bold*` spans, for a sentence that leans on one fact: 'Lights on: *5 of 9*'.
///
/// ```dart
/// NeumorphicText('Lights on: *5 of 9*', style: TextStyle(fontSize: 16))
/// ```
class NeumorphicText extends StatelessWidget {
  /// Creates a [NeumorphicText].
  const NeumorphicText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
  });

  /// The text to display.
  final String text;

  /// The text style used to draw the words.
  final TextStyle style;

  /// The horizontal alignment of the words.
  final TextAlign? textAlign;

  /// The maximum number of displayed text lines.
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    if (!text.contains('*')) {
      return Text(text, style: style, textAlign: textAlign, maxLines: maxLines);
    }
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: i.isOdd
                    ? style.copyWith(
                        fontWeight: FontWeight.w800,
                        color: NeumorphicTheme.of(context).colors.ink,
                      )
                    : style,
              ),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

/// A small line over a section: 'Household, all home'. 12/16 in the third ink.
///
/// ```dart
/// NeumorphicEyebrow('TODAY')
/// ```
class NeumorphicEyebrow extends StatelessWidget {
  /// Creates a [NeumorphicEyebrow].
  const NeumorphicEyebrow(this.text, {super.key, this.textAlign});

  /// The text to display.
  final String text;

  /// The horizontal alignment of the words.
  final TextAlign? textAlign;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    style: NeumorphicTheme.of(context).textTheme.micro,
  );
}

/// A section's head: a bold title and its meta on one baseline, the meta dropping under when there's no room.
///
/// ```dart
/// NeumorphicSectionHeader(title: 'This week', subtitle: '3 of 7 done')
/// ```
class NeumorphicSectionHeader extends StatelessWidget {
  /// Creates a [NeumorphicSectionHeader].
  const NeumorphicSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.style,
  });

  /// The primary heading.
  final String title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// A widget in the meta's place.
  final Widget? trailing;

  /// Overrides the heading's words. Only foreground and textStyle apply;
  /// the containing card owns the face, inset and shape.
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final look = NeumorphicStyleOf([style], NeumorphicStatesScope.of(context));
    final heading = Text(
      title,
      style: t.textTheme.title
          .merge(look.textStyle)
          .copyWith(color: look.foreground),
    );
    // A head with nothing at its end is its title alone: an empty end dropped under a title that wrapped (large text,
    // a phone) and left a blank line and its gap under the head.
    if (trailing == null && subtitle == null) return heading;
    return NeumorphicSplit(
      gap: 12,
      start: heading,
      end:
          trailing ??
          Text(
            subtitle ?? '',
            style: t.textTheme.caption.tabular
                .merge(look.textStyle)
                .copyWith(color: look.foreground),
            textAlign: TextAlign.end,
          ),
    );
  }
}

/// A slab with its head: the part most screens are built from. Its children stack on an 18 gap, and a `NeumorphicGrow` among
/// them takes a stretched card's spare height. A run of ruled rows stands together as one list, so each row's words sit
/// midway between its rules. Radius 20; it takes no radius or colour of its own.
///
/// ```dart
/// NeumorphicCard(title: 'This week', subtitle: '3 of 7 done', children: [NeumorphicKvRow('A label', 'A value', isFirst: true)])
/// ```
class NeumorphicCard extends StatelessWidget {
  /// Creates a [NeumorphicCard].
  const NeumorphicCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.gap = 18,
    this.children = const [],
    this.style,
  });

  /// The primary heading.
  final String? title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// Optional content at the end of the card heading.
  final Widget? trailing;

  /// Space between adjacent children, in logical pixels.
  final double gap;

  /// The content widgets, in reading order.
  final List<Widget> children;

  /// Frame and heading styling, before the card component theme. Unstyled
  /// child text and icons inherit its content settings; inner controls retain
  /// their own component styles.
  final NeumorphicStyle? style;
  @override
  Widget build(BuildContext context) => NeumorphicSlab(
    style: style,
    child: NeumorphicColumn(
      gap: gap,
      children: [
        if (title != null)
          NeumorphicSectionHeader(
            title: title!,
            subtitle: subtitle,
            trailing: trailing,
            style: NeumorphicStyle.cascade([
              style,
              NeumorphicTheme.of(context).cardTheme,
            ]),
          ),
        ..._rowsTogether(children),
      ],
    ),
  );

  // On the card's gap a run of rows stood each rule twice as far from the row above it as from the row below.
  static List<Widget> _rowsTogether(List<Widget> children) {
    final out = <Widget>[];
    var run = <Widget>[];
    void close() {
      if (run.isEmpty) return;
      out.add(run.length == 1 ? run.single : NeumorphicList(children: run));
      run = <Widget>[];
    }

    for (final child in children) {
      if (child is NeumorphicKvRow ||
          child is NeumorphicTotalRow ||
          child is NeumorphicStepRow ||
          child is NeumorphicTodoRow ||
          child is NeumorphicLevelRow) {
        run.add(child);
      } else {
        close();
        out.add(child);
      }
    }
    close();
    return out;
  }
}

/// A heading and its parts set straight into the wall, with no slab behind them: a control you use, not data you read.
/// The second level of a page, between the hero and the cards.
///
/// ```dart
/// NeumorphicWallSet(title: 'Modes', subtitle: 'Next at 22:30', child: NeumorphicPushGroup(items: const []))
/// ```
class NeumorphicWallSet extends StatelessWidget {
  /// Creates a [NeumorphicWallSet].
  const NeumorphicWallSet({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.gap = 14,
  });

  /// The primary heading.
  final String? title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;

  /// Optional content at the end of the section heading.
  final Widget? trailing;

  /// The content placed inside this component.
  final Widget child;

  /// Space between adjacent children, in logical pixels.
  final double gap;
  @override
  Widget build(BuildContext context) => NeumorphicColumn(
    gap: gap,
    children: [
      if (title != null)
        NeumorphicSectionHeader(
          title: title!,
          subtitle: subtitle,
          trailing: trailing,
        ),
      child,
    ],
  );
}

/// A small head inside a card: 'By use, kWh'.
///
/// ```dart
/// NeumorphicSubHead('Rooms', subtitle: 'Three available')
/// ```
class NeumorphicSubHead extends StatelessWidget {
  /// Creates a [NeumorphicSubHead].
  const NeumorphicSubHead(this.title, {super.key, this.subtitle});

  /// The primary heading.
  final String title;

  /// Secondary information displayed beside the heading.
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    // With nothing beside it the head is its words alone: an empty end that couldn't share a wrapped title's line
    // dropped under it as a blank line, a hole over what the head names.
    if (subtitle == null) return Text(title, style: t.textTheme.micro);
    return NeumorphicSplit(
      gap: 12,
      start: Text(title, style: t.textTheme.micro),
      end: Text(
        subtitle!,
        style: t.textTheme.micro.tabular,
        textAlign: TextAlign.end,
      ),
    );
  }
}

/// The page's title: a small line over it, a small line under, what stands beside it. 30 on a phone, 48 at 300 on a desktop.
///
/// ```dart
/// NeumorphicPageHead(overline: 'Today, 13:05', title: 'A page', subtitle: '4 items')
/// ```
class NeumorphicPageHead extends StatelessWidget {
  /// Creates a [NeumorphicPageHead].
  const NeumorphicPageHead({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.trailing,
    this.chips = const [],
  });

  /// The primary heading.
  final String title;

  /// Short text displayed above the main heading.
  final String? overline;

  /// Supporting text displayed below the main heading.
  final String? subtitle;

  /// At the head's end, on a desktop and a phone alike.
  final Widget? trailing;

  /// Small raised facts under the title.
  final List<Widget> chips;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicColumn(
      gap: t.desk ? 8 : 4,
      children: [
        if (overline != null) Text(overline!, style: t.textTheme.caption),
        Text(title, style: t.textTheme.page),
        if (subtitle != null)
          Text(subtitle!, style: t.textTheme.caption.tabular),
      ],
    );
    return NeumorphicColumn(
      gap: 18,
      children: [
        if (trailing == null)
          words
        else
          NeumorphicFitRow(
            fill: 0,
            gap: 16,
            fillShare: .5,
            align: NeumorphicFitAlign.bottom,
            children: [words, trailing!],
          ),
        if (chips.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 10, children: chips),
      ],
    );
  }
}

/// A label over what it names.
///
/// ```dart
/// NeumorphicLabel('EMAIL')
/// ```
class NeumorphicLabel extends StatelessWidget {
  /// Creates a [NeumorphicLabel].
  const NeumorphicLabel(this.text, {super.key});

  /// The text to display.
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: NeumorphicTheme.of(context).textTheme.micro);
}

/// Where a thing stands, in words. Live is the pigment's: an LED and pigment words. Any other state is plain ink.
///
/// ```dart
/// NeumorphicStatus('On, 30%', live: true)
/// ```
class NeumorphicStatus extends StatelessWidget {
  /// Creates a [NeumorphicStatus].
  const NeumorphicStatus(this.words, {super.key, this.live = false, this.icon});

  /// The text displayed by this indicator.
  final String words;

  /// Whether to emphasize the active state with the pigment colour.
  final bool live;

  /// The glyph displayed with the content.
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    if (live) return NeumorphicLiveText(words, icon: icon, led: icon == null);
    return NeumorphicFitRow(
      fill: icon == null ? 0 : 1,
      shrink: true,
      gap: 4,
      children: [
        if (icon != null) Icon(icon, size: 14, color: t.colors.inkTertiary),
        Text(words, style: t.textTheme.micro.tabular),
      ],
    );
  }
}

/// A small stamped label: a count, a kind. A small box on the control scale, never a pill.
///
/// ```dart
/// NeumorphicTag('New')
/// ```
class NeumorphicTag extends StatelessWidget {
  /// Creates a [NeumorphicTag].
  const NeumorphicTag(this.text, {super.key, this.style});

  /// Chip plate and words before the chip component theme.
  final NeumorphicStyle? style;

  /// The text to display.
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _build);

  Widget _build(BuildContext context, BoxConstraints box) {
    final t = NeumorphicTheme.of(context);
    final look = NeumorphicStyleOf([
      style,
      t.chipTheme,
    ], NeumorphicStatesScope.of(context));
    final words = t.textTheme.micro
        .copyWith(color: t.colors.inkSecondary)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    const padding = EdgeInsets.fromLTRB(8, 3, 8, 3);
    final shape = neumorphicInlineRoleShape(
      context,
      shape: t.shapes.capsule,
      text: text,
      textStyle: words,
      width: box.hasBoundedWidth ? box.maxWidth : double.infinity,
      padding: look.padding(Directionality.of(context)) ?? padding,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: NeumorphicSurface(
        style: style,
        themeStyle: t.chipTheme,
        shape: shape,
        cast: NeumorphicSurfaceLevel.groove,
        radius: NeumorphicRadii.cap,
        padding: padding,
        child: neumorphicLabel(Text(text, style: words)),
      ),
    );
  }
}
