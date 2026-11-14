import 'package:flutter/foundation.dart' show Unicode;
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/bar_actions.dart';
import '../internal/cap_label.dart';
import '../internal/sheet_header.dart';
import '../localizations.dart';
import '../theme.dart';
import 'icon_button.dart';
import 'route_chrome.dart';

/// The page's header band: 52 px on the ground over a 1 px hairline, its
/// register derived from the route ([MinimalRouteChrome]). [title] and
/// [subtitle] keep Cody's meaning everywhere — the page's own name and one
/// secondary line — and Minimal prints the subtitle as mono meta.
///
/// On a nav root the [title] leads at 17 px semibold with its meta beside
/// it (`Today  Fri 28 Aug`). On a pushed page the route's back button leads
/// and the band turns compact: the [parent] crumb, a slash, then the title
/// in the ink and its meta (`‹  Habits / Morning run  HAB-4`); a page that
/// prints its own heading in the body leaves the title out
/// (`‹  Habits / HAB-4`). In a sheet the band is the card's header:
/// [subtitle] as the context pill, the title beside it, and the close at
/// the far end. [actions] stand at the trailing edge — [MinimalIconButton]s,
/// which wear the bordered 32 px square here, with at most one `solid` for
/// the primary act.
///
/// [titleTrailing] stands a control beside a root's title, where its meta
/// would print (`Orders  Today ▾`: a [MinimalMenu.button] range or scope
/// menu); the compact and sheet registers ignore it.
///
/// `large` pins the root register on or off; null (the default) derives it.
/// Leave [leading] unset so the route's exit appears; never author a back or
/// close control.
///
/// ```dart
/// MinimalAppBar(title: 'Today', subtitle: 'Fri 28 Aug', actions: [MinimalIconButton(LucideIcons.search, label: 'Search', onPressed: search), MinimalIconButton(LucideIcons.plus, label: 'New habit', variant: MinimalIconButtonVariant.primary, onPressed: add)])
/// ```
class MinimalAppBar extends StatelessWidget {
  /// A page's top bar.
  const MinimalAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.parent,
    this.leading,
    this.actions = const <Widget>[],
    this.large,
    this.titleTrailing,
  });

  /// The page's own name.
  final String? title;

  /// One secondary line: the root's mono meta (a date, a count), a pushed
  /// page's id beside its title, or the sheet's context pill.
  final String? subtitle;

  /// Where a pushed page was reached from (`Habits`), printed as the
  /// breadcrumb before the title in the compact register. A root, which
  /// was reached from nowhere, ignores it.
  final String? parent;

  /// What stands before the title: a back button.
  final Widget? leading;

  /// Buttons at its end.
  final List<Widget> actions;

  /// The root register (leading title plus meta) pinned on or off; null
  /// derives it from the route.
  final bool? large;

  /// A control beside the root title (a range or scope menu), before the
  /// meta; ignored by the compact and sheet registers.
  final Widget? titleTrailing;

  /// The route's exit control: the bordered back button on a pushed page,
  /// the bare close on a sheet, nothing on a root. It pops the route, as
  /// Material's `BackButton` does. A page authors no back or close control
  /// of its own — this is it.
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    void onPressed() => Navigator.of(context).maybePop();
    return switch (MinimalRouteChrome.of(context)) {
      MinimalRouteChrome.root => null,
      MinimalRouteChrome.pushed => MinimalIconButton(
        LucideIcons.chevronLeftDir,
        key: key,
        label: MinimalLocalizations.of(context).back,
        variant: MinimalIconButtonVariant.outline,
        onPressed: onPressed,
      ),
      MinimalRouteChrome.sheet => MinimalIconButton(
        LucideIcons.x,
        key: key,
        label: MinimalLocalizations.of(context).close,
        variant: MinimalIconButtonVariant.ghost,
        onPressed: onPressed,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final register = MinimalRouteChrome.of(context);
    final exit = autoLeading(context);
    // An icon button among the actions wears the bar's bordered square
    // unless it names a variant of its own.
    final barActions = [
      for (final action in actions) MinimalBarActions(child: action),
    ];

    if (register == MinimalRouteChrome.sheet) {
      return MinimalSheetHeader(
        title: title,
        scope: subtitle,
        actions: barActions,
        close: leading ?? exit,
      );
    }

    final lead = leading ?? exit;
    final isLarge = large ?? register == MinimalRouteChrome.root;
    return Container(
      height: MinimalChromeMetrics.barHeight,
      padding: const EdgeInsetsDirectional.only(
        start: MinimalChromeMetrics.barInsetStart,
        end: MinimalChromeMetrics.barInsetEnd,
      ),
      decoration: BoxDecoration(
        color: t.background,
        border: Border(bottom: t.rule),
      ),
      child: Row(
        children: [
          if (lead != null) ...[
            lead,
            const SizedBox(width: MinimalChromeMetrics.barCrumbGap),
          ],
          Expanded(
            child: isLarge
                ? _RootTitle(
                    title: title,
                    meta: subtitle,
                    trailing: titleTrailing,
                  )
                : _CompactTitle(
                    parent: register == MinimalRouteChrome.root ? null : parent,
                    title: title,
                    meta: subtitle,
                  ),
          ),
          for (final (i, action) in barActions.indexed) ...[
            SizedBox(
              width: i == 0
                  ? MinimalSpacing.s8
                  : MinimalChromeMetrics.barActionGap,
            ),
            action,
          ],
        ],
      ),
    );
  }
}

/// The root register's title: 17 px semibold, the mono meta on its
/// baseline. The title is primary: it takes the width it needs before the
/// meta gets any, and the meta is what yields to an ellipsis.
class _RootTitle extends StatelessWidget {
  const _RootTitle({required this.title, required this.meta, this.trailing});

  final String? title;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final meta = this.meta;
    final trailing = this.trailing;
    final titleText = Text(
      title ?? '',
      style: t.h2.copyWith(fontSize: MinimalChromeMetrics.barTitle),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final metaText = meta == null
        ? null
        : Text(
            meta,
            style: t.mono.c(t.mutedForeground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    // The meta alone (a record's id over its page) starts where a title
    // would: on the bar's inset, the content's keyline, with no gap before it.
    if ((title ?? '').isEmpty && trailing == null && metaText != null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: minimalCapLabel(metaText),
      );
    }
    if (trailing != null) {
      // A control beside the title: centred on the band rather than on a
      // baseline, and whole — the title and then the meta yield first.
      return Row(
        children: [
          Flexible(flex: 2, child: minimalCapLabel(titleText)),
          const SizedBox(width: MinimalChromeMetrics.barTitleGap),
          trailing,
          if (metaText != null) ...[
            const SizedBox(width: MinimalChromeMetrics.barTitleGap),
            Flexible(child: minimalCapLabel(metaText)),
          ],
        ],
      );
    }
    // The title alone is centred on the band by its capitals; beside its
    // meta the two share a baseline, which the pair keeps.
    if (metaText == null) return minimalCapLabel(titleText);
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth - MinimalChromeMetrics.barTitleGap,
            ),
            child: titleText,
          ),
          const SizedBox(width: MinimalChromeMetrics.barTitleGap),
          Flexible(child: metaText),
        ],
      ),
    );
  }
}

/// The compact register — a pushed page's, or a root pinned `large: false`:
/// the [parent] crumb in the quiet ink and a slash, the page's own title in
/// the ink, and its mono meta. One line that ellipsizes at its end, so the
/// crumb and the title read first. Where bidi could reorder them (a right to
/// left page, or a piece in a right to left script) each piece is isolated,
/// so the pieces stand in the page's reading order whatever their script:
/// right to left, the crumb leads at the right even in English. A left to
/// right page of left to right words keeps its plain text (`Find  /  Bugs`).
class _CompactTitle extends StatelessWidget {
  const _CompactTitle({
    required this.parent,
    required this.title,
    required this.meta,
  });

  final String? parent;
  final String? title;
  final String? meta;

  /// A letter of a right to left script (Hebrew, Arabic, Syriac, Thaana,
  /// N'Ko and their presentation forms).
  static final RegExp _rtlScript = RegExp(
    '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final parent = this.parent;
    final title = this.title;
    final meta = this.meta;
    // A first-strong isolate round each piece: to the line around it a
    // piece is neutral, so the pieces stand in the line's order, while each
    // reads its own way inside (`HAB-4` stays left to right). Only where it
    // matters: the marks would otherwise ride along in the line's plain text
    // and in the header a screen reader names the route by.
    final isolate =
        Directionality.of(context) == TextDirection.rtl ||
        [parent, title, meta].any((s) => s != null && _rtlScript.hasMatch(s));
    String piece(String text) =>
        isolate ? '${Unicode.FSI}$text${Unicode.PDI}' : text;
    return Text.rich(
      TextSpan(
        children: [
          if (parent != null) ...[
            TextSpan(
              text: piece(parent),
              style: t.bodySmall.c(t.mutedForeground),
            ),
            if (title != null || meta != null)
              TextSpan(text: '  /  ', style: t.bodySmall.c(t.textTertiary)),
          ],
          if (title != null) TextSpan(text: piece(title), style: t.body.medium),
          if (meta != null) ...[
            if (title != null) TextSpan(text: '  ', style: t.body),
            TextSpan(text: piece(meta), style: t.mono.c(t.mutedForeground)),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
