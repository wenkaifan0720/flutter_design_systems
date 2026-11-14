import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../internal/bar_gutter.dart';
import '../internal/measure.dart';
import '../localizations.dart';
import '../theme.dart';
import 'avatar/avatar.dart';
import 'button/button.dart';
import 'pressable/pressable.dart';
import 'account.dart';
import 'sheet.dart';
import 'sheet_page.dart';

import 'package:ui_core/ui_core.dart';

/// The way back off a pushed page, or the close of a sheet or a cover, as
/// the route's bar draws it: on a phone the subtle icon button with the
/// back arrow (the dismiss glyph to close), saying "Back to [label]"; at
/// desktop width the crumb over the title: the chevron and [label] in
/// body1, a link in the second ink. [label] names where back goes;
/// unset, the bar's `backLabel` names it.
///
/// ```dart
/// Fluent2Back(label: 'Files', onPressed: () => Navigator.of(context).maybePop())
/// ```
class Fluent2Back extends StatelessWidget {
  /// The way back, calling [onPressed].
  const Fluent2Back({
    required this.onPressed,
    this.label,
    this.close = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Called when it is pressed: pop the route, or close the sheet.
  final VoidCallback? onPressed;

  /// Where back goes.
  final String? label;

  /// Draws the close rather than the way back.
  final bool close;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final where = label ?? _BackLabel.of(context);
    final words = Fluent2Localizations.of(context);
    final spoken = close
        ? DesignLocalizations.of(context).closeButtonLabel
        : where == null
        ? DesignLocalizations.of(context).backButtonTooltip
        : words.backTo(where);
    if (close ||
        !Fluent2Layout.isWide(context) ||
        Fluent2SheetShell.around(context)) {
      return Fluent2IconButton(
        close ? Fluent2Icons.dismiss : Fluent2Icons.arrowLeft,
        label: spoken,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
      );
    }
    return Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: spoken,
      role: Fluent2PressRole.link,
      radius: Fluent2Radius.medium,
      builder: (context, states) {
        final press = states.press;
        final ink = press.pick(
          t.colors.neutralForeground2,
          t.colors.neutralForeground2BrandHover,
          t.colors.neutralForeground2BrandPressed,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Fluent2ChromeMetrics.crumbGap,
            children: [
              Icon(
                Fluent2Icons.chevronLeft16,
                size: Fluent2ChromeMetrics.crumbGlyph,
                color: ink,
              ),
              Flexible(
                child: Text(
                  where ?? DesignLocalizations.of(context).backButtonTooltip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.body1.c(ink),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Publishes the bar's `backLabel` to a [Fluent2Back] inside it.
class _BackLabel extends InheritedWidget {
  const _BackLabel({required this.label, required super.child});

  final String? label;

  static String? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackLabel>()?.label;

  @override
  bool updateShouldNotify(_BackLabel oldWidget) => label != oldWidget.label;
}

/// The head of a page, in the register its route earns
/// (`RoutePresentation.of`):
///
/// - a tab's root: on a phone, the account's avatar at the start (it opens
///   the profile), the page's [title] in subtitle1 with its [caption] over
///   it in caption1, the page's [actions] and the bell at the end, 56
///   tall; on the desktop the caption over the title set in title2, the
///   actions and the account's bell and avatar at the end;
/// - a pushed page: on a phone the back arrow, then the [title] in
///   subtitle1 and the actions; on the desktop the crumb naming where back
///   goes ([backLabel]) over the title in title2;
/// - a sheet's card: its head, the [title] in subtitle1 and the close at
///   its end.
///
/// On a phone the bar is pinned over the page on the acrylic with a hairline
/// under it, and the page scrolls under it; on the desktop it stands in
/// the page and scrolls away with it. Leave [leading] unset: the route's
/// own exit appears ([autoLeading]); a page never authors its own back or
/// close. The bell and avatar come from the app's [Fluent2AccountScope].
/// Commands are [Fluent2IconButton]s (subtle), at most three.
///
/// ```dart
/// Fluent2AppBar(title: 'Files', caption: 'Northwind', actions: [Fluent2IconButton(Fluent2Icons.search, label: 'Search', onPressed: search)])
/// ```
///
/// ```dart
/// Fluent2AppBar(title: 'Q3 plan.docx', backLabel: 'Files')
/// ```
class Fluent2AppBar extends StatelessWidget {
  /// A page's top bar titled [title].
  const Fluent2AppBar({
    super.key,
    this.title,
    this.caption,
    this.leading,
    this.backLabel,
    this.actions = const [],
    this.bellKey,
    this.avatarKey,
  });

  /// The page's name (a tab's), or what the page is (a pushed page's).
  final String? title;

  /// The quiet line over a root's title (the workspace, the month).
  final String? caption;

  /// Replaces the route's own exit; leave null.
  final Widget? leading;

  /// Where back goes, as the crumb and the back button name it.
  final String? backLabel;

  /// The page's own commands, at the bar's end before the account's (at
  /// most three).
  final List<Widget> actions;

  /// The walkthrough keys set on the account's bell and avatar.
  final Key? bellKey;

  /// The account avatar's key, for tests and tours.
  final Key? avatarKey;

  /// The explicit "no bar" for a page whose route would otherwise derive
  /// one (`Fluent2Scaffold(topBar: Fluent2AppBar.none)`).
  static const Widget none = SizedBox.shrink(
    key: ValueKey<String>('fluent2:top-bar:none'),
  );

  /// The route's exit when it can pop: the way back on a pushed page, the
  /// close on a sheet or a cover (the way back on a sheet that closes back,
  /// [Fluent2SheetPage.back]); nothing on a root.
  static Widget? autoLeading(BuildContext context, {Key? key, String? label}) {
    final register = RoutePresentation.of(context);
    if (register == RoutePresentation.root) return null;
    final close =
        register == RoutePresentation.sheet &&
        !Fluent2SheetPage.closesBack(context);
    return Fluent2Back(
      key: key,
      label: label,
      close: close,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      actions.length <= 3,
      'A top bar carries at most three commands; put the rest in a menu.',
    );
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final register = RoutePresentation.of(context);
    final account = Fluent2AccountScope.maybeOf(context);

    if (register == RoutePresentation.sheet &&
        Fluent2SheetShell.around(context)) {
      final exit = leading ?? autoLeading(context);
      final back = Fluent2SheetPage.closesBack(context);
      return _BackLabel(
        label: backLabel,
        child: Fluent2SheetHead(
          title: title ?? '',
          leading: back ? exit : null,
          close: back ? null : exit,
          actions: actions,
        ),
      );
    }

    Widget? avatar() {
      if (account == null) return null;
      final open = account.onProfile;
      return Fluent2Avatar(
        key: avatarKey,
        name: account.name,
        initials: account.initials,
        image: account.image,
        color: Fluent2AvatarColor.colorful,
        label: Fluent2Localizations.of(context).profileAndSettings,
        onPressed: open == null ? null : () => open(context),
      );
    }

    Widget? bell() => account == null || account.onNotifications == null
        ? null
        : KeyedSubtree(
            key: bellKey,
            child: Fluent2Bell(account: account),
          );

    Widget? end(List<Widget?> parts) {
      final shown = [...parts.nonNulls];
      return shown.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Fluent2Spacing.xs,
              children: shown,
            );
    }

    Text heading(String words, TextStyle style, {int lines = 1}) => Text(
      words,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    final root = register == RoutePresentation.root;
    final lead = root ? null : (leading ?? autoLeading(context));

    if (wide) {
      final words = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Fluent2ChromeMetrics.captionGap,
        children: [
          if (root && caption != null)
            heading(caption!, t.body1.c(t.textSecondary)),
          if (!root) ?lead,
          if (title != null)
            Semantics(header: true, child: heading(title!, t.title2, lines: 2)),
        ],
      );
      return _BackLabel(
        label: backLabel,
        child: Padding(
          padding: const EdgeInsets.only(
            top: Fluent2ChromeMetrics.barTopWide,
            bottom: Fluent2ChromeMetrics.barBottomWide,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: Fluent2Spacing.l,
            children: [
              Expanded(child: words),
              ?end([...actions, bell(), avatar()]),
            ],
          ),
        ),
      );
    }

    final Widget? start = root ? avatar() : lead;
    final ends = [...actions, if (root) bell()].nonNulls;
    // A page's name on a phone stays whole: it grows with the reader's text
    // only while it fits on one line (iOS keeps a bar's title at its size),
    // a name too long for one line at its own size runs on to a second, and
    // one too long for two shrinks whole until it fits them. Measured where
    // it is drawn ([at]), in the style it inherits there.
    Widget whole(BuildContext at, String words, TextStyle style, double room) {
      final scale = fluent2WrapScale(at, words, style, room);
      return Text(
        words,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.linear(scale),
        style: style,
      );
    }

    final words = LayoutBuilder(
      builder: (context, box) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (root && caption != null)
            whole(
              context,
              caption!,
              t.caption1.c(t.textSecondary),
              box.maxWidth,
            ),
          Semantics(
            header: true,
            child: whole(context, title ?? '', t.subtitle1, box.maxWidth),
          ),
        ],
      ),
    );
    Widget row = Row(
      spacing: Fluent2Spacing.m,
      children: [
        ?start,
        Expanded(child: words),
        ?end(ends.toList()),
      ],
    );
    // In a screen, each end stands the page's gutter in less the room its
    // part keeps round what it shows: the back arrow, the avatar's
    // face and the last glyph on the keylines the page's words use, every
    // target whole.
    final gutter = Fluent2BarGutter.maybeOf(context);
    if (gutter != null) {
      row = Padding(
        padding: EdgeInsetsDirectional.only(
          start: math.max(0, gutter.start - _roomOf(context, start)),
          end: math.max(0, gutter.end - _roomOf(context, ends.lastOrNull)),
        ),
        child: row,
      );
    }
    return _BackLabel(
      label: backLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Fluent2ChromeMetrics.barHeight,
        ),
        child: row,
      ),
    );
  }
}

/// The room [part] keeps round what it shows at a bar's end: a glyph-only
/// button's round its glyph (half its face less its glyph), a pressable
/// avatar's round its face where a finger reaches it (its 48 target);
/// none round words or any other part.
double _roomOf(BuildContext context, Widget? part) {
  final shown = part is KeyedSubtree ? part.child : part;
  final touch = Fluent2Layout.padded(context);
  double glyph([Fluent2IconButton? b]) {
    final look = Fluent2ButtonLook(
      context.fluent2Theme,
      touch: touch,
      appearance: b?.appearance ?? Fluent2ButtonAppearance.subtle,
      size: b?.size ?? Fluent2ButtonSize.medium,
      style: b?.style,
      shape: b?.shape,
      icon: true,
    );
    return (look.minWidth(const {}, look.height) - look.glyph(const {})) / 2;
  }

  return switch (shown) {
    final Fluent2IconButton b => glyph(b),
    Fluent2Bell() || Fluent2Back() => glyph(),
    final Fluent2Avatar a when touch && a.onPressed != null =>
      (Fluent2Layout.touchHitTarget - a.size) / 2,
    _ => 0,
  };
}
