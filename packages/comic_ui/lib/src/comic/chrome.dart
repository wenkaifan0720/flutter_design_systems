// The page's chrome: the top bar (a masthead on a desktop), the phone's tab bar, the page's column, and what the generator's
// routes and stubs stand on. `ComicScaffold` assembles them. The bar stays while a page scrolls under it.
import 'package:ui_core/ui_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';

import 'glyphs.dart';
import 'host.dart';

import 'balloons.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'frames.dart';
import 'internal/geometry.dart';
import 'layout.dart';
import 'people.dart';
import 'print.dart';
import 'signatures/empty.dart';
import 'theme.dart';
import 'localizations.dart';
import 'press.dart';
import 'internal/cap_label.dart';

/// The app, as its chrome names it.
class ComicBrand {
  /// Creates a [ComicBrand].
  const ComicBrand({required this.name});

  /// The displayed name of this record or person.
  final String name;
}

/// One application destination, with its labels, glyph and activation callback.
class ComicNavItem {
  /// Creates a [ComicNavItem].
  const ComicNavItem({
    required this.label,
    required this.short,
    required this.icon,
    this.onPressed,
    this.key,
    this.badge,
    this.badgeLabel,
  });

  /// `label` in the masthead; `short` under the icon in the tab bar.
  final String label, short;

  /// The optional glyph beside the words.
  final IconData icon;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The walkthrough key on its hit target.
  final Key? key;

  /// Printed count or an empty string for a dot; spoken with the destination.
  final String? badge, badgeLabel;
}

class _NavTap extends StatelessWidget {
  const _NavTap({
    required this.item,
    required this.on,
    this.child,
    this.builder,
    this.onPressed,
  });
  final ComicNavItem item;
  final bool on;
  final Widget? child;

  /// A face that puts the press's marks on its own indicator ([ComicHighlight]).
  final Widget Function(BuildContext, Set<WidgetState>)? builder;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => ComicPressable(
    key: item.key,
    onPressed: onPressed ?? item.onPressed,
    label: item.label,
    value: item.badgeLabel,
    selected: on,
    outline: WidgetStatePropertyAll(ComicTheme.of(context).shapes.small),
    wash: builder == null,
    ring: builder == null,
    builder: builder ?? (_, _) => child!,
  );
}

/// The app's name as a logo: lettered in the lamp with an outline and a hard double drop.
///
/// ```dart
/// ComicLogo('Saucepot!')
/// ```
class ComicLogo extends StatelessWidget {
  /// Creates a [ComicLogo].
  const ComicLogo(this.name, {super.key});

  /// The displayed name of this record or person.
  final String name;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 6, 4),
      child: ComicLettering(
        name,
        size: t.desk ? 46 : 34,
        lineHeight: 1,
        tracking: .04,
        fill: t.colors.caption,
        style: ComicLetteringStyle.logo,
      ),
    );
  }
}

/// A group's chip for a bar: its overlapping heads and its name in the lettering, and a arrow if it opens a switcher.
///
/// ```dart
/// ComicGroupChip('The Six', people: const [ComicPerson(initials: 'AB', size: 26)], onPressed: () {})
/// ```
class ComicGroupChip extends StatelessWidget {
  /// Creates a [ComicGroupChip].
  const ComicGroupChip(
    this.name, {
    super.key,
    this.people = const [],
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  /// The displayed name of this record or person.
  final String name;

  /// People displayed beside this content.
  final List<ComicPerson> people;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: name,
      button: onPressed != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (people.isNotEmpty) ...[
            ComicPeople(people, overlap: true, max: 3),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: CapLabel(
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.type.letter(
                  t.desk ? 24 : 20,
                  lineHeight: 1,
                  tracking: .05,
                ),
              ),
            ),
          ),
          if (onPressed != null) ...[
            const SizedBox(width: 8),
            Icon(ComicGlyphs.chevronDown, size: 18, color: t.colors.text),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.item, this.on);
  final ComicNavItem item;
  final bool on;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final ink = on ? c.onCaption : c.textSecondary;
    return _NavTap(
      item: item,
      on: on,
      // The lit link fills its press's whole height, the least target, so its ground is the cell a person sees, not a
      // pill inside it.
      child: ComicStateDecoration.box(
        height: ComicTapTarget.targetOf(context) < 40
            ? 40
            : ComicTapTarget.targetOf(context),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: on
            ? ShapeDecoration(
                color: c.caption,
                shape: t.shapes.small.copyWith(
                  side: BorderSide(color: c.nightLine, width: t.rim(2.5)),
                ),
              )
            : ShapeDecoration(shape: t.shapes.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 19, color: ink),
            const SizedBox(width: 7),
            CapLabel(
              child: Text(
                item.label.toUpperCase(),
                maxLines: 1,
                style: t.type.letter(
                  20,
                  lineHeight: 1,
                  color: ink,
                  tracking: .06,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone's tab bar: the current tab in a lamp's square, the app-level act a small balloon rising from the middle.
///
/// ```dart
/// ComicNavigationBar(destinations: const [ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house)], selectedIndex: 0, onDestinationSelected: select)
/// ```
class ComicNavigationBar extends StatelessWidget {
  /// Creates a [ComicNavigationBar].
  const ComicNavigationBar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.action,
  });

  /// Items displayed in their supplied order.
  final List<ComicNavItem> destinations;

  /// The index of the selected destination.
  final int selectedIndex;

  /// Selects a destination by its position. When absent, each item's
  /// `onPressed` handles navigation. When present, only this callback runs.
  final ValueChanged<int>? onDestinationSelected;

  /// The optional action beside this content.
  final ShellAction? action;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget word(String w, Color ink) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        w.toUpperCase(),
        maxLines: 1,
        style: t.type.letter(16, lineHeight: 1, color: ink, tracking: .06),
      ),
    );
    Widget tab(int i) {
      final on = i == selectedIndex;
      return Expanded(
        child: _NavTap(
          item: destinations[i],
          onPressed: onDestinationSelected == null
              ? null
              : () => onDestinationSelected!(i),
          on: on,
          builder: (context, states) => Padding(
            padding: const EdgeInsets.only(top: 4),
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
                    // The count sits on the indicator's top end corner, as on an icon button, so every icon in
                    // the bar keeps one centre whether it has a count or not.
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: ComicStateLerp<Color?>(
                            value: on ? c.onCaption : c.textSecondary,
                            lerp: Color.lerp,
                            builder: (context, ink, _) => Icon(
                              destinations[i].icon,
                              size: 23,
                              color: ink,
                            ),
                          ),
                        ),
                        if (destinations[i].badge case final badge?)
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
                                      (badge.isEmpty
                                              ? t.shapes.full
                                              : t.shapes.capsule)
                                          .copyWith(
                                            side: BorderSide(
                                              color: c.nightLine,
                                            ),
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
                const SizedBox(height: 3),
                ComicStateLerp<Color?>(
                  value: on ? c.text : c.textSecondary,
                  lerp: Color.lerp,
                  builder: (context, ink, _) =>
                      word(destinations[i].short, ink!),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          top: BorderSide(color: c.nightLine, width: t.rim(3)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(6, 7, 6, 10 + bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i <= destinations.length; i++) ...[
              if (action != null && i == (destinations.length + 1) ~/ 2)
                Expanded(
                  child: _TabAct(action: action!, word: word),
                ),
              if (i < destinations.length) tab(i),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabAct extends StatelessWidget {
  const _TabAct({required this.action, required this.word});
  final ShellAction action;
  final Widget Function(String, Color) word;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    return ComicPressable(
      key: action.key,
      onPressed: () => action.onPressed(context),
      label: action.label,
      wash: false,
      ring: false,
      builder: (context, states) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComicHighlight(
            states: states,
            shape: t.shapes.small,
            washColor: action.accent ? c.onPrimary : null,
            child: ComicStateDecoration.box(
              width: 50,
              height: 42,
              decoration: ShapeDecoration(
                color: action.accent
                    ? c.primary
                    : c.dark
                    ? c.card
                    : c.control,
                shape: t.shapes.small.copyWith(
                  side: BorderSide(color: c.nightLine, width: t.rim(3)),
                ),
              ),
              child: Icon(
                action.icon,
                size: 26,
                color: action.accent
                    ? c.onPrimary
                    : c.dark
                    ? c.text
                    : c.onPaper,
              ),
            ),
          ),
          if ((action.label ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            word(action.label!, c.text),
          ],
        ],
      ),
    );
  }
}

// --- What the generator's routes, previews and page stubs stand on. ---

/// One tab as a generated app declares it: its glyph, its label and the walkthrough key on its hit target.
///
/// ```dart
/// ComicTab(ComicGlyphs.house, 'Home', ValueKey('open-home'))
/// ```
@immutable
class ComicTab {
  /// Creates a [ComicTab].
  const ComicTab(this.icon, this.label, [this.key]);

  /// The optional glyph beside the words.
  final IconData icon;

  /// The visible or spoken name of the component.
  final String label;

  /// The key attached to the item's interactive target.
  final Key? key;
}

/// A page: the top bar, then the page's column on newsprint with its gutter. It holds the screen's one burst (see
/// `ComicBurst`). [body] is usually `ComicSections(children: [...])`. A nav root leaves [topBar] out for the app's bar.
///
/// ```dart
/// ComicScaffold(topBar: ComicAppBar(title: 'Your stay'), body: ComicSections(children: [ComicTier(children: [a, b])]))
/// ```
class ComicScaffold extends StatelessWidget {
  /// Creates a [ComicScaffold].
  const ComicScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.scrollController,
  });

  /// The main content of the page or section.
  final Widget body;

  /// Usually `ComicAppBar`: a pushed page's way back and title.
  final Widget? topBar;

  /// What stands fixed at a pushed page's foot (the one action).
  final Widget? footer;

  /// False: [body] takes the height left and scrolls itself.
  final bool scroll;

  /// [body] takes the page's whole width, with no column and no inset.
  final bool fullBleed;

  /// The caller-owned scroll controller.
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final chrome = ComicChromeScope.maybeOf(context);
    final sheet = RoutePresentation.of(context) == RoutePresentation.sheet;
    final inset = t.desk
        ? const EdgeInsets.fromLTRB(32, 24, 32, 56)
        : const EdgeInsets.fromLTRB(12, 12, 12, 22);
    final bar =
        topBar ?? (chrome != null && !sheet ? const ComicAppBar() : null);
    final bar0 = topBar;
    // A desktop bar carries the app's nav, so the page's own title stands at the head of its column.
    final title = t.desk && chrome != null && !sheet && bar0 is ComicAppBar
        ? bar0.title
        : null;
    final inner = title == null
        ? body
        : ComicColumn(
            gap: 16,
            children: [
              Text(title.toUpperCase(), style: t.type.section),
              if (scroll) body else ComicGrow(child: body),
            ],
          );
    // The page body is one keyline region: its panels and words hold the page's margins.
    final Widget region = DesignKeylineRegion(
      label: 'Page',
      child: Padding(padding: inset, child: inner),
    );
    final Widget column = fullBleed
        ? inner
        : scroll
        ? Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1376),
              child: region,
            ),
          )
        : region;
    final Widget content = scroll
        ? ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: t.desk),
            child: SingleChildScrollView(
              controller: scrollController,
              // Scroll offsets repaint the viewport. Keep the static page's
              // display list separate so scrolling only moves its layer.
              child: RepaintBoundary(child: column),
            ),
          )
        : column;
    // Halftone belongs to editorial art. A form or settings page needs a quiet
    // ground so its fields, status and focus are the visual hierarchy.
    final page = ColoredBox(
      color: sheet ? c.card : c.background,
      child: content,
    );
    return ComicBurstLedger(
      child: ColoredBox(
        color: sheet ? c.card : c.background,
        child: Column(
          mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?bar,
            sheet ? Flexible(child: page) : Expanded(child: page),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(
                    top: BorderSide(color: c.nightLine, width: t.rim(3)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: t.desk && !sheet
                        ? Align(
                            alignment: AlignmentDirectional.centerEnd,
                            heightFactor: 1,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: footer!,
                            ),
                          )
                        : footer!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A page's tiers and heads, one under another on the page's gutter: 16 on a desktop, 10 on a phone.
///
/// ```dart
/// ComicSections(children: [ComicTier(children: [a, b]), const ComicSectionHeader('Coming up'), ComicTier(children: [c, d, e])])
/// ```
class ComicSections extends StatelessWidget {
  /// Creates a [ComicSections].
  const ComicSections({super.key, required this.children});

  /// Child widgets in their display order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ComicColumn(
    gap: ComicTheme.of(context).desk ? 16 : 10,
    children: children,
  );
}

/// The way out of a pushed page or a sheet: a square arrow, or a cross.
///
/// ```dart
/// ComicBackButton(onPressed: () => Navigator.of(context).maybePop())
/// ```
class ComicBackButton extends StatelessWidget {
  /// Creates a [ComicBackButton].
  const ComicBackButton({
    super.key,
    this.close = false,
    this.onPressed,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// Overrides the localized back or close label.
  final String? label;

  /// Uses the close action instead of a back arrow.
  final bool close;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ComicIconButton(
      focusNode: focusNode,
      autofocus: autofocus,
      close
          ? ComicGlyphs.x
          : (rtl ? ComicGlyphs.arrowRight : ComicGlyphs.arrowLeft),
      label:
          label ??
          (close
              ? DesignLocalizations.of(context).closeButtonLabel
              : DesignLocalizations.of(context).backButtonTooltip),
      size: 38,
      onPressed: onPressed,
    );
  }
}

/// A page's top bar: the route's way out, the app's name or the page's title in the lettering, the app's places on a desktop, and
/// the page's own [actions] at its end. A page never authors its own back or close: leave [leading] unset, or pass [autoLeading]
/// to key it. On a desktop the title moves to the head of the page's column. [logo] stands in place of the logo, such as a
/// `ComicGroupChip`.
///
/// ```dart
/// ComicAppBar(title: 'The plan', leading: ComicAppBar.autoLeading(context, key: const ValueKey('back')), actions: [ComicIconButton(ComicGlyphs.share2, label: 'Share')])
/// ```
class ComicAppBar extends StatelessWidget {
  /// Creates a [ComicAppBar].
  const ComicAppBar({
    super.key,
    this.title,
    this.leading,
    this.logo,
    this.actions = const [],
  });

  /// The primary heading.
  final String? title;

  /// [leading]: content before the main words. [logo]: an optional caller-supplied graphic.
  final Widget? leading, logo;

  /// Actions displayed in order.
  final List<Widget> actions;

  /// The route's own exit: the way back on a pushed page, the close on a sheet, nothing on a root.
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final register = RoutePresentation.of(context);
    if (register == RoutePresentation.root) return null;
    return ComicBackButton(
      key: key,
      close: register == RoutePresentation.sheet,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final chrome = ComicChromeScope.maybeOf(context);
    final sheet = RoutePresentation.of(context) == RoutePresentation.sheet;
    final exit = leading ?? autoLeading(context);
    final gap = t.desk ? 18.0 : 10.0;
    final masthead = t.desk && chrome != null && !sheet;
    final name = chrome?.brand.name ?? '';
    final showTitle = title != null && !masthead;
    final Widget? who = logo != null
        ? logo!
        : showTitle
        ? CapLabel(
            child: Text(
              title!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.type.letter(t.desk ? 34 : 26, lineHeight: 1),
            ),
          )
        : name.isNotEmpty
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: ComicLogo(name),
          )
        : null;
    final action = masthead ? chrome.action : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          bottom: BorderSide(color: c.nightLine, width: t.rim(3)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: SizedBox(
            height: t.desk ? 75 : 57,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: t.desk ? 32 : 12),
              child: Row(
                children: [
                  if (exit != null) ...[exit, SizedBox(width: gap)],
                  if (who != null)
                    masthead || logo == null && !showTitle
                        ? Flexible(flex: 0, child: who)
                        : Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: who,
                            ),
                          ),
                  if (masthead) ...[
                    const SizedBox(width: 36),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < chrome.nav.length; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                _NavLink(chrome.nav[i], i == chrome.active),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (who == null || (logo == null && !showTitle))
                    const Spacer(),
                  if (action != null) ...[
                    SizedBox(width: gap),
                    _ShellAct(action: action),
                  ],
                  for (final a in actions) ...[SizedBox(width: gap), a],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellAct extends StatelessWidget {
  const _ShellAct({required this.action});
  final ShellAction action;
  @override
  Widget build(BuildContext context) {
    final label = action.label ?? '';
    final t = ComicTheme.of(context);
    // The accent action: the filled button with its words, or, with none, the icon button in its fill.
    return action.accent && label.isNotEmpty
        ? ComicButton.filled(
            label,
            key: action.key,
            icon: action.icon,
            size: ComicButtonSize.small,
            onPressed: () => action.onPressed(context),
          )
        : ComicIconButton(
            action.icon,
            key: action.key,
            label: label,
            onPressed: () => action.onPressed(context),
            style: action.accent
                ? ComicStyle(
                    fill: WidgetStatePropertyAll(t.colors.primary),
                    foreground: WidgetStatePropertyAll(t.colors.onPrimary),
                  )
                : null,
          );
  }
}

/// A one-line text field the generated stubs draw; [ComicTextField] is the same field with more to say.
///
/// ```dart
/// ComicInput(key: const ValueKey('name'), hint: 'Your name', onChanged: (text) {})
/// ```
class ComicInput extends StatelessWidget {
  /// Creates a [ComicInput].
  const ComicInput({
    super.key,
    this.style,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  /// [hint]: placeholder text shown when the field is empty. [initialValue]: initial text when no editing controller is supplied.
  final String? hint, initialValue;

  /// The caller-owned editing controller.
  final TextEditingController? controller;

  /// [onChanged]: reports a new value; null disables changes. [onSubmitted]: reports text submitted from the keyboard.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// Per-state appearance forwarded to the public control.
  final ComicStyle? style;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => ComicTextField(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    hint: hint,
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

class _NoPicturePainter extends CustomPainter {
  _NoPicturePainter(this.fill, this.line, this.small);
  final Color fill, line;
  final bool small;
  @override
  void paint(Canvas canvas, Size s) {
    final w = small ? 26.0 : 72.0, h = small ? 22.0 : 60.0;
    canvas.translate((s.width - w) / 2, (s.height - h) / 2);
    final star = polyPath(burstPoints(w, h, spikes: small ? 8 : 12, pad: 1));
    canvas.drawPath(star, fillPaint(fill));
    canvas.drawPath(
      star,
      strokePaint(line, small ? 1.5 : 2.5)..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_NoPicturePainter o) =>
      o.fill != fill || o.line != line || o.small != small;
}

/// A picture from a declared media slot, in a square contour. Until it loads, or if it never does, a screen of dots a step off
/// the panel and an empty burst on them: at night that stays dark, so a shelf of them isn't a wall of lit blocks. It takes the
/// width it's given and sets its height by [aspect].
///
/// ```dart
/// ComicMedia(slotId: 'item-1', aspect: 1, label: 'First piece')
/// ```
class ComicMedia extends StatelessWidget {
  /// Creates a [ComicMedia].
  const ComicMedia({
    super.key,
    required this.slotId,
    this.aspect = 4 / 3,
    this.label,
    this.fit = BoxFit.cover,
    this.width,
    this.bare = false,
    this.image,
  });

  /// The host image slot supplying this picture.
  final String slotId;

  /// Caller-supplied content instead of a media slot, such as an asset image.
  final Widget? image;

  /// The width divided by the height of the picture.
  final double aspect;

  /// The visible or spoken name of the component.
  final String? label;

  /// How the image or drawing fits its allocated bounds.
  final BoxFit fit;

  /// Only for a thumbnail in a row: 48 to 96. Anywhere else it takes the width it's given.
  final double? width;

  /// No contour of its own: it stands against a panel's, with a rule under it.
  final bool bare;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final small = width != null && width! < 72;
    final fallback = ColoredBox(
      color: c.inset,
      child: ComicBenDay(
        color: c.dotTint,
        pitch: 10,
        radius: 2,
        child: CustomPaint(
          painter: _NoPicturePainter(c.card, c.textSecondary, small),
          child: const SizedBox.expand(),
        ),
      ),
    );
    final picture = Semantics(
      image: label != null,
      label: label,
      child: AspectRatio(
        aspectRatio: aspect,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: bare
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.nightLine, width: t.rim(3)),
                  ),
                )
              : ShapeDecoration(
                  shape: t.shapes.medium.copyWith(
                    side: BorderSide(color: c.nightLine, width: small ? 2 : 3),
                  ),
                ),
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: bare ? const RoundedRectangleBorder() : t.shapes.medium,
            ),
            child:
                image ??
                MediaSlotImage(slotId: slotId, fallback: fallback, fit: fit),
          ),
        ),
      ),
    );
    return width == null
        ? ComicFill(maxWidth: 1200, child: picture)
        : comicOwnSize(width: width, child: picture);
  }
}

/// A picture over its words, bleeding to its panel's contour: one piece of a collection, a place, a person. The picture is your
/// media slot. Lay them out in a `ComicTier`.
///
/// ```dart
/// ComicPictureCard(slotId: 'item-1', title: 'First piece', subtitle: 'Kind A', trailing: const ComicTag('New'), onPressed: () {})
/// ```
class ComicPictureCard extends StatelessWidget {
  /// Creates a [ComicPictureCard].
  const ComicPictureCard({
    super.key,
    required this.slotId,
    required this.title,
    this.subtitle,
    this.figure,
    this.trailing,
    this.aspect = 4 / 3,
    this.onPressed,
    this.image,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// A declared media slot.
  final String slotId;

  /// Caller-supplied content instead of the named media slot.
  final Widget? image;

  /// Appearance above the shared card component theme.
  final ComicStyle? style;

  /// The primary heading.
  final String title;

  /// Secondary information printed with the entry.
  final String? subtitle;

  /// A number that belongs to the piece, in the lettering.
  final String? figure;

  /// A `ComicTag`.
  final Widget? trailing;

  /// The width divided by the height of the picture.
  final double aspect;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicPanel(
      focusNode: focusNode,
      autofocus: autofocus,
      bleed: true,
      style: style,
      onPressed: onPressed,
      label: title,
      child: ComicColumn(
        children: [
          ComicMedia(
            slotId: slotId,
            image: image,
            aspect: aspect,
            label: title,
            bare: true,
          ),
          ComicGrow(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: ComicColumn(
                children: [
                  Text(title, style: t.type.title),
                  if (subtitle != null) Text(subtitle!, style: t.type.meta),
                  if (figure != null || trailing != null) ...[
                    const SizedBox(height: 8),
                    // The figure and the tag stand at the card's foot, so a tier's cards keep them on one line whatever
                    // their titles wrap to.
                    const ComicGrow(child: SizedBox.shrink()),
                    ComicSplit(
                      start: figure == null
                          ? const SizedBox.shrink()
                          : Text(figure!, style: t.type.number(24)),
                      end: trailing ?? const SizedBox.shrink(),
                      gap: 8,
                      runGap: 6,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// While a page's data is on its way: a thought with three dots in it.
///
/// ```dart
/// ComicLoadingState(label: 'Loading issue')
/// ```
class ComicLoadingState extends StatelessWidget {
  /// Creates a [ComicLoadingState].
  const ComicLoadingState({super.key, this.label});

  /// Overrides the localized loading announcement.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Center(
      child: Semantics(
        label: label ?? DesignLocalizations.of(context).loadingLabel,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: ComicThought(
            '...',
            style: t.type.letter(
              28,
              lineHeight: 1,
              color: t.colors.onPaper,
              tracking: .1,
            ),
          ),
        ),
      ),
    );
  }
}

/// When a page's data could not load: what happened, and a way to try again.
///
/// ```dart
/// ComicErrorState(title: 'Could not load', message: 'Check your connection.', onRetry: () {})
/// ```
class ComicErrorState extends StatelessWidget {
  /// Creates a [ComicErrorState].
  const ComicErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.action,
  });

  /// The primary heading.
  final String title;

  /// Supporting message displayed below the main heading.
  final String? message;

  /// Repeats the failed operation.
  final VoidCallback? onRetry;

  /// An application action in place of the retry button.
  final Widget? action;

  /// Overrides the localized retry action.
  final String? retryLabel;
  @override
  Widget build(BuildContext context) => Center(
    child: ComicEmptyState(
      title: title,
      body: message,
      action:
          action ??
          (onRetry == null
              ? null
              : ComicButton(
                  retryLabel ?? ComicLocalizations.of(context).tryAgain,
                  onPressed: onRetry,
                )),
    ),
  );
}
