import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../glyphs.dart';

import '../chrome_metrics.dart';
import '../internal/hit_slop.dart';
import '../theme.dart';
import 'icon-button/round_button.dart';
import 'pressable/pressable.dart';
import 'account.dart';
import 'sheet.dart';
import 'sheet_page.dart';
import '../internal/cap.dart';

/// The way back off a pushed page, or the close of a cover or a sheet, as
/// the route's bar draws it. On a phone it is the round glass button with
/// the chevron (the cross to close), saying "Back to [label]"; at desktop
/// width the crumb over the title: the small chevron and [label] in the
/// caption type; on a sheet's card the small round cross. [label] names
/// where back goes (Home, Activity); unset, the bar's `backLabel` names it.
///
/// ```dart
/// FrostedBack(label: 'Activity', onPressed: () => Navigator.of(context).maybePop())
/// ```
class FrostedBack extends StatelessWidget {
  /// Creates a [FrostedBack].
  const FrostedBack({
    required this.onPressed,
    this.label,
    this.close = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What a press does: pop the route.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Where back goes.
  final String? label;

  /// Draws the close (a cover's, a sheet's) rather than the way back.
  final bool close;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final where = label ?? _BackLabel.of(context);
    final spoken = close
        ? DesignLocalizations.of(context).closeButtonLabel
        : where == null
        ? DesignLocalizations.of(context).backButtonTooltip
        : 'Back to $where';
    if (FrostedSheetShell.around(context)) {
      return FrostedIconButton(
        focusNode: focusNode,
        autofocus: autofocus,
        close ? FrostedGlyphs.close : FrostedGlyphs.chevronLeft,
        label: spoken,
        size: FrostedIconButtonSize.small,
        onPressed: onPressed,
      );
    }
    if (!FrostedBreakpoints.isWide(context)) {
      return FrostedIconButton(
        focusNode: focusNode,
        autofocus: autofocus,
        close ? FrostedGlyphs.close : FrostedGlyphs.chevronLeft,
        label: spoken,
        onPressed: onPressed,
      );
    }
    // The crumb: its chevron 2 from its word, the whole pulled 3 into the
    // gutter (a row keeps no negative gap, so the pull is the row's).
    final pull = Directionality.of(context) == TextDirection.rtl
        ? FrostedChromeMetrics.crumbPull
        : -FrostedChromeMetrics.crumbPull;
    final crumb = Transform.translate(
      offset: Offset(pull, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.crumbGap,
        children: [
          Icon(
            close ? FrostedGlyphs.close : FrostedGlyphs.chevronLeft,
            size: FrostedChromeMetrics.crumbGlyph,
            color: t.colorScheme.textTertiary,
          ),
          frostedCapCentred(
            Text(
              close
                  ? DesignLocalizations.of(context).closeButtonLabel
                  : where ?? DesignLocalizations.of(context).backButtonTooltip,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
    return FrostedHitSlop(
      child: FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: spoken,
        role: FrostedPressRole.link,
        child: crumb,
      ),
    );
  }
}

/// Publishes the bar's `backLabel` to a [FrostedBack] inside it.
class _BackLabel extends InheritedWidget {
  const _BackLabel({required this.label, required super.child});

  final String? label;

  static String? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackLabel>()?.label;

  @override
  bool updateShouldNotify(_BackLabel oldWidget) => label != oldWidget.label;
}

/// The head of a page, in the register its route earns
/// (`RoutePresentation.of`), as the source sets its three (`.top`):
///
/// - a tab's root: the [caption] in the quiet caption type ("October
///   2026") 2 over the page's [title] in the h1 type, the page's own
///   [actions], the bell and the avatar at its end; Home's greeting is the
///   same bar with the day for its caption ([FrostedAppBar.greeting]); on the
///   desktop the title is set large, 6 under its caption, and the bar
///   stands 32 under the window's top;
/// - a pushed page (`.top--detail`): the round back button, the [title]
///   (what the page is: Account, Transaction) centred in the h2 type, and a
///   balancing space; on the desktop the crumb naming where back goes
///   ([backLabel]) 6 over the title set large, the bell and avatar at the
///   end;
/// - a sheet's card: its head, the [title] in the sheet's type and the
///   small round close at its end (a full-screen cover is drawn as a pushed
///   page with the close).
///
/// On a phone the bar is pinned over the page on its frost, 10 over and
/// under its parts, and the page scrolls under it; on the desktop it stands
/// in the page and scrolls away with it. Leave [leading] unset: the route's
/// own exit appears ([autoLeading]). A page never authors its own back or
/// close. The bell and avatar come from the app's [FrostedAccountScope].
///
/// ```dart
/// FrostedAppBar(title: 'Spending', caption: 'October 2026')
/// ```
///
/// ```dart
/// FrostedAppBar(title: 'Account', backLabel: 'Home')
/// ```
class FrostedAppBar extends StatelessWidget {
  /// Creates a [FrostedAppBar].
  const FrostedAppBar({
    super.key,
    this.title,
    this.caption,
    this.leading,
    this.backLabel,
    this.actions = const [],
    this.bellKey,
    this.avatarKey,
  }) : _greeting = false;

  /// Home's greeting: [title] is the greeting ("Good evening, Maren"),
  /// [subtitle] the day over it ("Wednesday, October 28").
  ///
  /// ```dart
  /// FrostedAppBar.greeting(title: FrostedFormat.greeting('Maren', now: now), subtitle: FrostedFormat.longDate(now))
  /// ```
  const FrostedAppBar.greeting({
    required String this.title,
    String? subtitle,
    this.actions = const [],
    this.bellKey,
    this.avatarKey,
    super.key,
  }) : caption = subtitle,
       leading = null,
       backLabel = null,
       _greeting = true;

  /// The page's name (a tab's), or what the page is (a pushed page's).
  final String? title;

  /// The quiet line over a root's title: the month, the day.
  final String? caption;

  /// Replaces the route's own exit; leave null.
  final Widget? leading;

  /// Where back goes, as the crumb and the back button name it (Home,
  /// Spending).
  final String? backLabel;

  /// The page's own controls, at the bar's end before the account's (at
  /// most two).
  final List<Widget> actions;

  /// The walkthrough keys set on the account's bell and avatar where the
  /// bar draws them.
  final Key? bellKey;

  /// A key for the avatar.
  final Key? avatarKey;

  final bool _greeting;

  /// Home's greeting's quiet line, as [FrostedAppBar.greeting] names it.
  String? get subtitle => _greeting ? caption : null;

  /// The explicit "no bar" for a page whose route would otherwise derive one
  /// (`FrostedScaffold(topBar: FrostedAppBar.none)`).
  static const Widget none = SizedBox.shrink(
    key: ValueKey<String>('frosted:top-bar:none'),
  );

  /// The route's exit when it can pop: the way back on a pushed page, the
  /// close on a sheet or a cover (the way back on a sheet that closes back,
  /// [FrostedSheetPage.back]), each popping the route; nothing on a root.
  /// This is the only back or close a Frosted page has.
  static Widget? autoLeading(BuildContext context, {Key? key, String? label}) {
    // The page's own route, not its navigator: a root stays exitless while a
    // sheet or a page stands over it.
    final register = RoutePresentation.of(context);
    if (register == RoutePresentation.root) return null;
    final close =
        register == RoutePresentation.sheet &&
        !FrostedSheetPage.closesBack(context);
    return FrostedBack(
      key: key,
      label: label,
      close: close,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      actions.length <= 2,
      'A top bar carries at most two actions; a third has no place in it.',
    );
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final register = RoutePresentation.of(context);
    final account = FrostedAccountScope.maybeOf(context);

    if (register == RoutePresentation.sheet &&
        FrostedSheetShell.around(context)) {
      final exit = leading ?? autoLeading(context);
      final back = FrostedSheetPage.closesBack(context);
      return _BackLabel(
        label: backLabel,
        child: FrostedSheetHead(
          title: title ?? '',
          leading: back ? exit : null,
          close: back ? null : exit,
          actions: actions,
        ),
      );
    }

    Widget frame(Widget child) => Padding(
      padding: wide
          ? const EdgeInsets.only(
              top: FrostedChromeMetrics.barTopWide,
              bottom: FrostedChromeMetrics.barBottomWide,
            )
          : const EdgeInsets.symmetric(vertical: FrostedChromeMetrics.barInset),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.barControl,
        ),
        child: child,
      ),
    );

    Widget? end(List<Widget> parts) => parts.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedChromeMetrics.barEndGap,
            children: parts,
          );

    if (register == RoutePresentation.root) {
      final words = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: wide
            ? FrostedChromeMetrics.captionGapWide
            : FrostedChromeMetrics.captionGap,
        children: [
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.labelMedium,
            ),
          Semantics(
            header: true,
            child: frostedCapCentred(
              Text(
                title ?? '',
                maxLines: _greeting ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: wide
                    ? t.textTheme.headlineMedium
                    : t.textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      );
      return frame(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: FrostedChromeMetrics.barGap,
          children: [
            Expanded(child: words),
            ?end([
              ...actions,
              if (account != null)
                FrostedAccountMarks(
                  account: account,
                  bellKey: bellKey,
                  avatarKey: avatarKey,
                ),
            ]),
          ],
        ),
      );
    }

    // A pushed page, or a full-screen cover.
    final lead = leading ?? autoLeading(context);
    if (wide) {
      return _BackLabel(
        label: backLabel,
        child: frame(
          Row(
            spacing: FrostedChromeMetrics.barGap,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.crumbTitleGap,
                  children: [
                    ?lead,
                    if (title != null)
                      Semantics(
                        header: true,
                        child: frostedCapCentred(
                          Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ?end([
                ...actions,
                if (account != null)
                  FrostedAccountMarks(
                    account: account,
                    bellKey: bellKey,
                    avatarKey: avatarKey,
                  ),
              ]),
            ],
          ),
        ),
      );
    }
    // The title stays centred between the back button and a space as wide
    // (`.top--detail`: 40, the title, 40); the page's actions take that
    // space when it has any.
    final trailing = end(actions);
    return _BackLabel(
      label: backLabel,
      child: frame(
        Row(
          spacing: FrostedChromeMetrics.barGap,
          children: [
            SizedBox(
              width: FrostedChromeMetrics.detailColumn,
              child: lead == null ? null : Center(child: lead),
            ),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      header: true,
                      child: frostedCapCentred(
                        Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: t.textTheme.titleLarge,
                        ),
                      ),
                    ),
            ),
            if (trailing == null)
              const SizedBox(width: FrostedChromeMetrics.detailColumn)
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: FrostedChromeMetrics.detailColumn,
                ),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }
}
