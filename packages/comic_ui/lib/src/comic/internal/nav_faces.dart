// The faces of the app's places, as each form of navigation draws them: the phone bar's tab, the masthead's link, the
// rail's stop and the drawer's row. The navigation parts (ComicNavigationBar, ComicNavigationRail, ComicNavigationDrawer,
// the masthead) and ComicAppShell, whose places ui_core's shell presses and names, draw the same ones.
import 'package:flutter/widgets.dart';

import '../nav.dart';
import '../press.dart';
import '../theme.dart';
import 'cap_label.dart';
import '../knobs.dart' show ComicSpace;

/// A place's words in the tab bar: its short name in the lettering, centred under its indicator.
Widget comicTabWord(ComicThemeData t, String words, Color ink) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: ComicSpace.tight),
  child: Text(
    words.toUpperCase(),
    textAlign: TextAlign.center,
    style: t.type.letter(16, lineHeight: 1, color: ink, tracking: .06),
  ),
);

/// A place in the phone's tab bar: its glyph in the indicator (the lamp's square while it is [on]), a count on the
/// indicator's top end corner, its short name under it. The press's marks sit on the indicator.
Widget comicTabFace(
  BuildContext context,
  ComicNavItem item, {
  required bool on,
  required Set<WidgetState> states,
}) {
  final t = ComicTheme.of(context), c = t.colors;
  return Padding(
    padding: const EdgeInsets.only(top: ComicSpace.tight),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The marks sit on the indicator, in its shape, not on the whole item.
        ComicHighlight(
          states: states,
          shape: t.shapes.small,
          child: ComicStateDecoration.box(
            width: 46,
            height: 32,
            decoration: ShapeDecoration(
              color: on ? c.caption : null,
              shape: t.shapes.small.copyWith(
                side: on
                    ? BorderSide(color: c.nightLine, width: t.rim(2.5))
                    : BorderSide.none,
              ),
            ),
            // The count sits on the indicator's top end corner, as on an icon button, so every icon in the bar keeps
            // one centre whether it has a count or not.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: ComicStateLerp<Color?>(
                    value: on ? c.onCaption : c.textSecondary,
                    lerp: Color.lerp,
                    builder: (context, ink, _) =>
                        Icon(item.icon, size: 23, color: ink),
                  ),
                ),
                if (item.badge case final badge?)
                  PositionedDirectional(
                    top: -6,
                    end: -6,
                    child: ExcludeSemantics(
                      child: ComicStateDecoration.box(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                        decoration: ShapeDecoration(
                          color: c.caption,
                          shape:
                              (badge.isEmpty ? t.shapes.full : t.shapes.capsule)
                                  .copyWith(
                                    side: BorderSide(color: c.nightLine),
                                  ),
                        ),
                        child: badge.isEmpty
                            ? null
                            : Text(
                                badge,
                                style: t.type.label.copyWith(
                                  color: c.onCaption,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ComicSpace.nib),
        ComicStateLerp<Color?>(
          value: on ? c.text : c.textSecondary,
          lerp: Color.lerp,
          builder: (context, ink, _) => comicTabWord(t, item.short, ink!),
        ),
      ],
    ),
  );
}

/// A place in the desktop's masthead: its glyph and name in the lettering, the lit one on the lamp's ground, the
/// cell its press's whole height.
Widget comicLinkFace(
  BuildContext context,
  ComicNavItem item, {
  required bool on,
}) {
  final t = ComicTheme.of(context);
  final c = t.colors;
  final ink = on ? c.onCaption : c.textSecondary;
  // The lit link fills its press's whole height, the least target, so its ground is the cell a person sees, not a
  // pill inside it.
  return ComicStateDecoration.box(
    height: ComicTapTarget.targetOf(context) < 40
        ? 40
        : ComicTapTarget.targetOf(context),
    padding: const EdgeInsets.symmetric(horizontal: ComicSpace.gap),
    decoration: on
        ? ShapeDecoration(
            color: c.caption,
            shape: t.shapes.small.copyWith(
              side: BorderSide(color: c.nightLine, width: t.rim(2.5)),
            ),
          )
        // The same rim, clear: a link takes the room the lit one takes, so the places stand still as the choice moves.
        : ShapeDecoration(
            shape: t.shapes.small.copyWith(
              side: BorderSide(
                color: const Color(0x00000000),
                width: t.rim(2.5),
              ),
            ),
          ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 19, color: ink),
        const SizedBox(width: ComicSpace.close),
        CapLabel(
          child: Text(
            item.label.toUpperCase(),
            maxLines: 1,
            style: t.type.letter(20, lineHeight: 1, color: ink, tracking: .06),
          ),
        ),
      ],
    ),
  );
}

/// A place on the rail: its glyph in the indicator over its short name, lit as the tab bar lights it. The press's marks
/// sit on the indicator.
Widget comicRailFace(
  BuildContext context,
  ComicNavItem item, {
  required bool on,
  required Set<WidgetState> states,
}) {
  final t = ComicTheme.of(context);
  final c = t.colors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: ComicSpace.close),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The marks sit on the indicator, in its shape.
        ComicHighlight(
          states: states,
          shape: t.shapes.small,
          child: Container(
            width: 56,
            height: 34,
            decoration: ShapeDecoration(
              color: on ? c.caption : null,
              shape: t.shapes.small.copyWith(
                side: on
                    ? BorderSide(color: c.nightLine, width: t.rim(2.5))
                    : BorderSide.none,
              ),
            ),
            child: Center(
              child: ComicStateLerp<Color?>(
                value: on ? c.onCaption : c.textSecondary,
                lerp: Color.lerp,
                builder: (context, ink, _) =>
                    Icon(item.icon, size: 20, color: ink),
              ),
            ),
          ),
        ),
        const SizedBox(height: ComicSpace.tight),
        SizedBox(
          width: 80,
          child: Text(
            item.short.toUpperCase(),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: t.type.letter(
              15,
              lineHeight: 1,
              color: on ? c.text : c.textSecondary,
              tracking: .06,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A place in the drawer: its glyph and whole name in a row, the current one on the lamp's ground.
Widget comicDrawerFace(
  BuildContext context,
  ComicNavItem item, {
  required bool on,
}) {
  final t = ComicTheme.of(context);
  return ComicStateDecoration(
    decoration: ShapeDecoration(
      color: on ? t.colors.caption : t.colors.card,
      shape: t.shapes.small,
    ),
    child: Padding(
      padding: const EdgeInsets.all(ComicSpace.near),
      child: Row(
        children: [
          Icon(item.icon, color: on ? t.colors.onCaption : t.colors.text),
          const SizedBox(width: ComicSpace.near),
          Expanded(
            child: CapLabel(
              child: Text(
                item.label,
                style: t.type.body.copyWith(
                  color: on ? t.colors.onCaption : t.colors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
