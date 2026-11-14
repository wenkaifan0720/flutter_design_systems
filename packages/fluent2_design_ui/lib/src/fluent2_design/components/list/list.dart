import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/in_row.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import 'check_indicator.dart';

/// Fluent 2's list item: one row of a list (a file, a thread, a meeting, a
/// setting), its [leading] part (or an [icon] in the second ink) before
/// the [title] in body1 over a [subtitle] in caption1, a [value] in body1
/// and the second ink and a [trailing] part (a tag, a switch) at the end,
/// then the [chevron] of a row that opens a page. 44 tall at least on a
/// phone and 40 on the desktop, 8 over and under its words. With [onTap]
/// it is one press on the subtle fill's hover and pressed steps; [selected]
/// marks the page's own row in the selected fill. With [checked] set it is
/// a row of a multiple selection: Fluent's checkbox at its start, a press
/// asking [onChanged] for the other state. [enabled] false draws it
/// in the disabled ink and makes it inert. Read as one: its words, then
/// its parts.
///
/// ```dart
/// Fluent2ListItem(icon: Fluent2Icons.document, title: 'Q3 plan.docx', subtitle: 'Kai Tanaka edited 2h ago', chevron: true, onTap: open)
/// ```
class Fluent2ListItem extends StatelessWidget {
  /// A list item titled [title].
  const Fluent2ListItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.icon,
    this.value,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.checked,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// This row's own look over `Fluent2ThemeData.listItemTheme`, in its
  /// states (hovered, pressed, selected, disabled): `fill`, `overlay`,
  /// `foreground` (the title's ink), `textStyle` (the title's type),
  /// `padding` and `minimumSize`. The theme's density moves a desktop
  /// row's height and padding; a phone's row keeps its 44.
  final Fluent2Style? style;

  /// The item's main words.
  final String title;

  /// The line under the title.
  final String? subtitle;

  /// What stands at the start: an avatar, an image, a control.
  final Widget? leading;

  /// A glyph at the start where there is no [leading] part.
  final IconData? icon;

  /// A value at the end, before [trailing] (Monthly, 12 MB).
  final String? value;

  /// What stands at the end: a tag, a switch, a time.
  final Widget? trailing;

  /// The chevron of a row that opens a page.
  final bool chevron;

  /// What a press on the row does.
  final VoidCallback? onTap;

  /// What a long press does (the row's menu on a phone).
  final VoidCallback? onLongPress;

  /// Marks the row the page is about (the open thread).
  final bool selected;

  /// Set for a row of a multiple selection: chosen or not.
  final bool? checked;

  /// Asked for the other state when a selection row is pressed.
  final ValueChanged<bool>? onChanged;

  /// False draws the row disabled and inert.
  final bool enabled;

  /// What a screen reader says for the words; null says the title and the
  /// subtitle.
  final String? semanticLabel;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  /// The least height of a row at [context]: 40 on the desktop, a target
  /// elsewhere (44, 48 under a finger).
  static double minHeightOf(BuildContext context) =>
      Fluent2Layout.isWide(context) && !Fluent2Layout.padded(context)
      ? 40
      : Fluent2Layout.hitTargetOf(context);

  // The text scale past which a row's words come first (the value under the
  // title): iOS's accessibility sizes start near it.
  static const double _largeText = 1.3;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final check = checked;
    final change = onChanged;
    final VoidCallback? press = !enabled
        ? null
        : check != null
        ? (change == null ? null : () => change(!check))
        : onTap;
    final side = wide ? Fluent2Spacing.m : Fluent2Spacing.l;
    final layers = [style, t.listItemTheme];

    Widget face(Fluent2Press state) {
      final inert = !enabled || (check != null && change == null);
      final look = Fluent2StyleOf(layers, {
        if (inert || state == Fluent2Press.disabled) WidgetState.disabled,
        if (state == Fluent2Press.hover) WidgetState.hovered,
        if (state == Fluent2Press.pressed) WidgetState.pressed,
        if (selected || (check ?? false)) WidgetState.selected,
      });
      final ink = look.foreground ?? (inert ? t.textDisabled : t.textPrimary);
      final quiet = inert ? t.textDisabled : t.textSecondary;
      final glyph = inert ? t.textDisabled : t.textSecondary;
      final subtitle = this.subtitle;
      // At a large text size the words come first: the title runs on to
      // more lines and the value stands under it, as iOS lays out a row at
      // the accessibility sizes, rather than the title cut beside a value.
      final large =
          MediaQuery.textScalerOf(context).scale(14) > 14 * _largeText;
      final value = large ? null : this.value;
      final under = large ? this.value : null;
      final head = Text(
        title,
        maxLines: large ? 3 : 1,
        overflow: TextOverflow.ellipsis,
        style: t.body1.merge(look.textStyle).c(ink),
      );
      // A title alone stands on the row's middle by its capitals.
      final words = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle == null && under == null)
            fluent2CapCentred(head)
          else
            head,
          // A subtitle of one word (an address, a path) keeps to one line,
          // cut at its end, rather than broken inside the word.
          if (subtitle != null)
            Text(
              subtitle,
              maxLines: subtitle.contains(' ') ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption1.c(quiet),
            ),
          if (under != null) Text(under, style: t.body1.c(quiet)),
        ],
      );
      final lead =
          leading ??
          (icon == null
              ? null
              : Icon(
                  icon,
                  size: wide ? Fluent2IconSize.i20 : Fluent2IconSize.i24,
                  color: glyph,
                ));
      final own = state == Fluent2Press.disabled
          ? t.colors.subtleBackground
          : selected
          ? fluent2Step(t, t.colors.subtleBackgroundSelected)
          : state.pick(
              t.colors.subtleBackground,
              t.colors.subtleBackgroundHover,
              t.colors.subtleBackgroundPressed,
            );
      final fill = look.fill ?? own;
      return fluent2EasedInks([fill], (context, inks) {
        final [fill] = inks;
        final wash = look.overlay?.resolve(look.states);
        // The density moves the desktop row; a phone's row keeps its 44.
        final least =
            look.minimumSize?.height ??
            (wide
                ? t.density.height(minHeightOf(context), least: 24)
                : minHeightOf(context));
        final room =
            look.padding(Directionality.of(context)) ??
            t.density.padding(
              EdgeInsets.symmetric(
                horizontal: side,
                vertical: Fluent2Spacing.s,
              ),
            );
        // The room over and under is the words': a part at the end (a
        // switch's 48 touch target) stands in the row's height, centred,
        // and never makes it taller than its neighbours.
        return ColoredBox(
          color: wash == null ? fill : Color.alphaBlend(wash, fill),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: least),
            child: Padding(
              padding: EdgeInsets.only(left: room.left, right: room.right),
              child: Row(
                spacing: Fluent2Spacing.m,
                children: [
                  if (check != null)
                    Fluent2CheckIndicator(
                      checked: check,
                      press: inert ? Fluent2Press.disabled : state,
                    ),
                  ?lead,
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: room.top,
                        bottom: room.bottom,
                      ),
                      child: words,
                    ),
                  ),
                  if (value != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: fluent2CapCentred(
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: t.body1.c(quiet),
                        ),
                      ),
                    ),
                  if (trailing case final end?) Fluent2InRow(child: end),
                  if (chevron)
                    Icon(
                      Fluent2Icons.chevronRight16,
                      size: Fluent2IconSize.i16,
                      color: inert ? t.textDisabled : t.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        );
      });
    }

    final spoken = semanticLabel ?? [title, ?subtitle].join(', ');
    if (press == null && onTap == null && check == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        child: face(enabled ? Fluent2Press.rest : Fluent2Press.disabled),
      );
    }
    return Semantics(
      container: true,
      checked: check,
      child: Fluent2Pressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: press,
        onLongPress: onLongPress,
        label: spoken,
        value: value,
        selected: check == null && selected ? true : null,
        excludeChild: false,
        radius: 0,
        builder: (context, states) => face(states.press),
      ),
    );
  }
}

/// Fluent 2's list as a grouped list: its rows ([Fluent2ListItem]s) on a
/// card's surface (`neutralBackground1` at the medium corner, raised by
/// `shadow4`) with a hairline between each pair, under an optional [title]
/// (a [Fluent2SectionHeader] with its [action]) and over a quiet [footer]
/// line. [asCard] false lays the rows on the bare ground with the hairlines
/// alone. Read as its title's heading over the rows.
///
/// ```dart
/// Fluent2ListGroup(title: 'Recent files', children: [Fluent2ListItem(icon: Fluent2Icons.document, title: 'Q3 plan.docx', onTap: open), Fluent2ListItem(icon: Fluent2Icons.documentText, title: 'Brand guidelines.pdf', onTap: open)])
/// ```
class Fluent2ListGroup extends StatelessWidget {
  /// A grouped list of [children].
  const Fluent2ListGroup({
    required this.children,
    this.title,
    this.aside,
    this.action,
    this.footer,
    this.asCard = true,
    this.dividers = true,
    super.key,
  });

  /// The rows.
  final List<Widget> children;

  /// The group's head.
  final String? title;

  /// A count or a note at the head's end.
  final String? aside;

  /// The head's act (a [Fluent2SectionHeader.action]).
  final Widget? action;

  /// The quiet line under the group.
  final String? footer;

  /// Whether the rows stand on a card (true) or on the bare ground.
  final bool asCard;

  /// Whether a hairline stands between each pair of rows.
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final title = this.title;
    final footer = this.footer;
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in children.indexed) ...[
          if (i > 0 && dividers)
            SizedBox(
              height: Fluent2Stroke.thin,
              child: ColoredBox(color: fluent2Step(t, t.colors.neutralStroke2)),
            ),
          row,
        ],
      ],
    );
    // The list's card is a card: the card theme styles it.
    final look = Fluent2StyleOf([t.cardTheme], const {});
    final body = asCard
        ? Fluent2Plate(
            fill: look.fill ?? t.colors.neutralBackground1,
            side:
                look.side ??
                (look.edge == null
                    ? BorderSide.none
                    : BorderSide(color: look.edge!, width: Fluent2Stroke.thin)),
            radius: BorderRadius.circular(Fluent2Radius.medium),
            shape: look.shape,
            shadows: t.shadows.shadow4,
            clip: true,
            // The rows share the card's keylines (the keyline check).
            child: DesignKeylineRegion(label: title ?? 'List', child: rows),
          )
        : DesignKeylineRegion(label: title ?? 'List', child: rows);
    // The section header reads the title as a heading over the rows; a
    // label here as well would say it twice.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Fluent2SectionHeader(title, aside: aside, action: action),
          body,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: Fluent2Spacing.s),
              child: Text(footer, style: t.caption1.c(t.textTertiary)),
            ),
        ],
      ),
    );
  }
}

/// A section's title as Fluent 2 sets one: [title] in subtitle2 with a
/// quiet [aside] (a count) after it, and at its end the section's one
/// [action] (a [Fluent2SectionHeader.link], See all), 8 over what it heads.
/// Read as a heading.
///
/// ```dart
/// Fluent2SectionHeader('Meetings today', aside: '3', action: Fluent2SectionHeader.link('See all', onPressed: openCalendar))
/// ```
class Fluent2SectionHeader extends StatelessWidget {
  /// A section header reading [title].
  const Fluent2SectionHeader(this.title, {this.aside, this.action, super.key});

  /// The header's words.
  final String title;

  /// A count or a note after the title.
  final String? aside;

  /// What stands at the end: a [link], a small button.
  final Widget? action;

  /// The header's act as Fluent's Link: [label] in body1 and the link ink,
  /// underlined under the pointer, its hit target 44.
  static Widget link(String label, {required VoidCallback? onPressed}) =>
      _HeaderLink(label, onTap: onPressed);

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final aside = this.aside;
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          spacing: Fluent2Spacing.s,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: title),
                      if (aside != null)
                        TextSpan(
                          text: '  $aside',
                          style: t.body1.c(t.textTertiary),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.subtitle2,
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink(this.label, {required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2HitSlop(
      child: Fluent2Pressable(
        onPressed: onTap,
        label: label,
        role: Fluent2PressRole.link,
        radius: Fluent2Radius.small,
        builder: (context, states) {
          final press = states.press;
          final ink = press.pick(
            t.colors.brandForegroundLink,
            t.colors.brandForegroundLinkHover,
            t.colors.brandForegroundLinkPressed,
            t.textDisabled,
          );
          return fluent2EasedInks([ink], (context, inks) {
            final [ink] = inks;
            return Text(
              label,
              maxLines: 1,
              style: t.body1
                  .c(ink)
                  .copyWith(
                    decoration: press == Fluent2Press.hover
                        ? TextDecoration.underline
                        : null,
                    decorationColor: ink,
                  ),
            );
          });
        },
      ),
    );
  }
}
