// The page's chrome: the top bar (a masthead on a desktop), the phone's tab bar, the page's column, and what the generator's
// routes and stubs stand on. `ComicScaffold` assembles them. The bar stays while a page scrolls under it.
import 'package:flutter/foundation.dart';
import 'package:ui_core/ui_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';

import 'glyphs.dart';
import 'host.dart';
import 'nav.dart';

import 'balloons.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'frames.dart';
import 'internal/footer_clear.dart';
import 'internal/nav_faces.dart';
import 'internal/geometry.dart';
import 'layout.dart';
import 'people.dart';
import 'print.dart';
import 'signatures/empty.dart';
import 'theme.dart';
import 'localizations.dart';
import 'press.dart';
import 'internal/cap_label.dart';
import 'internal/lettering.dart' show comicDisplayFor;
import 'knobs.dart' show ComicSpace;

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
    semanticLabel: item.label,
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
      padding: const EdgeInsetsDirectional.fromSTEB(
        ComicSpace.fine,
        ComicSpace.fine,
        ComicSpace.close,
        ComicSpace.tight,
      ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
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

  /// {@template comic.onPressed}
  /// Called when activated; null disables the action.
  /// {@endtemplate}
  final VoidCallback? onPressed;

  /// {@template comic.focusNode}
  /// The caller's focus node, if any; the part makes its own when null.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      semanticLabel: name,
      button: onPressed != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (people.isNotEmpty) ...[
            ComicPeople(people, overlap: true, max: 3),
            const SizedBox(width: ComicSpace.close),
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
            const SizedBox(width: ComicSpace.close),
            Icon(ComicGlyphs.chevronDown, size: 18, color: t.colors.text),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(
        IterableProperty<ComicPerson>('people', people, defaultValue: const []),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(this.item, this.on);
  final ComicNavItem item;
  final bool on;
  @override
  Widget build(BuildContext context) => _NavTap(
    item: item,
    on: on,
    child: comicLinkFace(context, item, on: on),
  );
}

/// The phone's tab bar: the current tab in a lamp's square, the app-level act a small balloon rising from the middle.
/// An app takes [ComicAppShell], which paints this bar on a phone and the masthead on a desktop and gives the places
/// their tabs, their keys and their selected state; the bar alone is a row of buttons for a frame of the app's own.
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

  /// The app's one act, a balloon rising from the bar's middle.
  final ComicAppAction? action;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget word(String w, Color ink) => comicTabWord(t, w, ink);
    Widget tab(int i) {
      final on = i == selectedIndex;
      return Expanded(
        child: _NavTap(
          item: destinations[i],
          onPressed: onDestinationSelected == null
              ? null
              : () => onDestinationSelected!(i),
          on: on,
          builder: (context, states) =>
              comicTabFace(context, destinations[i], on: on, states: states),
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
        padding: EdgeInsets.fromLTRB(
          ComicSpace.close,
          ComicSpace.close,
          ComicSpace.close,
          10 + bottom,
        ),
        child: Row(
          crossAxisAlignment: action == null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<ComicAppAction>(
          'action',
          action,
          defaultValue: null,
        ),
      );
  }
}

class _TabAct extends StatelessWidget {
  const _TabAct({required this.action, required this.word});
  final ComicAppAction action;
  final Widget Function(String, Color) word;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    return ComicPressable(
      key: action.key,
      onPressed: action.onPressed,
      semanticLabel: action.label,
      wash: false,
      ring: false,
      // The tab face's geometry, a little wider: its glyph on the tabs' glyph line and its words on theirs.
      builder: (context, states) => Padding(
        padding: const EdgeInsets.only(top: ComicSpace.tight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ComicHighlight(
              states: states,
              shape: t.shapes.small,
              washColor: action.accent ? c.onPrimary : null,
              child: ComicStateDecoration.box(
                width: 56,
                height: 32,
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
                  size: 23,
                  color: action.accent
                      ? c.onPrimary
                      : c.dark
                      ? c.text
                      : c.onPaper,
                ),
              ),
            ),
            if (action.label.isNotEmpty) ...[
              const SizedBox(height: ComicSpace.nib),
              word(action.label, c.text),
            ],
          ],
        ),
      ),
    );
  }
}

/// The app's one act beside its places (add, write, capture): a key in the act's colour in the middle of the phone's tab
/// bar, at the rail's head, and a button at the masthead's end on a desktop. [accent] fills it with the act's colour; off, it is a plain square.
///
/// ```dart
/// ComicAppAction(icon: ComicGlyphs.plus, label: 'Add', onPressed: add)
/// ```
@immutable
class ComicAppAction with Diagnosticable {
  /// An act wearing [icon], called [label].
  const ComicAppAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent = true,
    this.key,
  });

  /// Its glyph.
  final IconData icon;

  /// Its words: under it in the tab bar, beside its glyph on a desktop, and its name to a screen reader.
  final String label;

  /// Called when it is pressed.
  final VoidCallback onPressed;

  /// Whether it wears the act's colour (the app's standing invitation); false: a plain square.
  final bool accent;

  /// The key on its button.
  final Key? key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty(
          'accent',
          value: accent,
          ifFalse: 'plain',
          defaultValue: true,
        ),
      );
  }
}

/// The app's frame: its places and its pages, at every width, through ui_core's `RawAdaptiveShell`. On a phone (under
/// 600 wide) the places stand in the tab bar at the foot, the [action] a key in the act's colour in its middle; on a
/// tablet or a narrow window they stand in a rail of glyphs down the start, the act at its head; on a desktop (from
/// [comicDeskWidth] wide) they are the masthead's links across the top, the app's [brand] at its start and the act at
/// its end, and each page's own bar stands under it with its way back and its actions. [modeForWidth] moves those
/// widths. A screen reader hears the places as tabs; the arrows move along them, Enter or Space chooses one, and F6
/// moves to the page. Toasts keep clear of the tab bar and the masthead.
///
/// [ComicAppShell.branches] keeps a stack of pages for each place: a page pushed on one
/// (`Navigator.of(context).push`) keeps the masthead or the rail beside it while the tab bar steps away, and back pops it.
/// [ComicAppShell] stands round the app's own [body] (an `IndexedStack`, a router's shell), and [showNavigation]
/// hides its tab bar.
///
/// ```dart
/// ComicAppShell.branches(destinations: const [ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house), ComicNavItem(label: 'Alerts', short: 'Alerts', icon: ComicGlyphs.bell)], selectedIndex: place, onDestinationSelected: (index) => setState(() => place = index), branches: [(context) => const Text('Home'), (context) => const Text('Alerts')])
/// ```
class ComicAppShell extends StatefulWidget {
  /// The app's places round its own [body].
  const ComicAppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.brand,
    this.action,
    this.modeForWidth = ComicAppShell.modeFor,
    this.showNavigation = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// The app's places, each with a stack of pages of its own, starting on its [branches] page.
  const ComicAppShell.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.brand,
    this.action,
    this.modeForWidth = ComicAppShell.modeFor,
    this.showNavigation = true,
  }) : body = null;

  /// Comic's places for a shell [width] wide: the tab bar on a phone (under 600), a rail of glyphs down the start
  /// from there (a tablet, a narrow window: a tab bar that wide would spread a few words over the screen), and the
  /// masthead from [comicDeskWidth].
  static RawNavigationMode modeFor(double width) => width < 600
      ? RawNavigationMode.bar
      : width < comicDeskWidth
      ? RawNavigationMode.rail
      : RawNavigationMode.top;

  /// The app's places, in order. Each one's `label` names it in the masthead and to a screen reader, its `short`
  /// under its glyph in the tab bar; [onDestinationSelected] chooses it (its own `onPressed` is not called).
  final List<ComicNavItem> destinations;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The app's own pages ([ComicAppShell]); null for [ComicAppShell.branches].
  final Widget? body;

  /// Each place's first page ([ComicAppShell.branches]); null round a [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators, to push onto one from outside it (a notification opening a page).
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// Whether the tab bar steps away while a page is pushed over a place's first page; the masthead stays.
  final bool hideBarOnPush;

  /// The app's name, lettered at the masthead's start and on a phone's page bar.
  final String? brand;

  /// The app's one act.
  final ComicAppAction? action;

  /// How the places show for the shell's width: [modeFor] by default. A sidebar shows them as
  /// [ComicNavigationDrawer] draws them, a rail as [ComicNavigationRail] does.
  final RawNavigationModeForWidth modeForWidth;

  /// Whether the tab bar shows: false while a page of the app's own covers a place's first page.
  final bool showNavigation;

  @override
  State<ComicAppShell> createState() => _ComicAppShellState();

  Widget _build(BuildContext context, GlobalKey bar) {
    final places = [
      for (final d in destinations)
        RawNavigationDestination(
          label: d.badgeLabel == null ? d.label : '${d.label}, ${d.badgeLabel}',
          icon: d.icon,
        ),
    ];
    Widget destination(
      BuildContext context,
      RawNavigationDestination place,
      RawDestinationDetails details,
    ) {
      final t = ComicTheme.of(context);
      final item = destinations[details.index];
      final on = details.states.contains(WidgetState.selected);
      return KeyedSubtree(
        key: item.key,
        child: switch (details.mode) {
          RawNavigationMode.bar => comicTabFace(
            context,
            item,
            on: on,
            states: details.states,
          ),
          RawNavigationMode.top => ComicHighlight(
            states: details.states,
            shape: t.shapes.small,
            child: comicLinkFace(context, item, on: on),
          ),
          RawNavigationMode.rail => comicRailFace(
            context,
            item,
            on: on,
            states: details.states,
          ),
          RawNavigationMode.sidebar => ComicHighlight(
            states: details.states,
            shape: t.shapes.small,
            child: comicDrawerFace(context, item, on: on),
          ),
        },
      );
    }

    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        switch (details.mode) {
          RawNavigationMode.bar => _ShellBar(
            key: bar,
            details: details,
            action: action,
          ),
          RawNavigationMode.top => _ShellMasthead(
            details: details,
            brand: brand,
            action: action,
          ),
          RawNavigationMode.rail => _ShellSide(
            details: details,
            action: action,
            width: 88,
          ),
          RawNavigationMode.sidebar => _ShellSide(
            details: details,
            brand: brand,
            action: action,
            width: 304,
          ),
        };
    final branches = this.branches;
    // A toast or a snack bar raised over the app's own pages stands above the tab bar.
    return ComicFooterClear(
      footer: bar,
      child: ComicChromeScope(
        brand: ComicBrand(name: brand ?? ''),
        nav: destinations,
        active: selectedIndex,
        shellDrawn: true,
        child: branches == null
            ? RawAdaptiveShell(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: destination,
                navigationBuilder: navigation,
                modeForWidth: modeForWidth,
                showNavigation: showNavigation,
                body: body!,
              )
            : RawAdaptiveShell.branches(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: destination,
                navigationBuilder: navigation,
                modeForWidth: modeForWidth,
                showNavigation: showNavigation,
                hideBarOnPush: hideBarOnPush,
                backBehavior: backBehavior,
                navigatorKeys: navigatorKeys,
                branches: branches,
              ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifTrue: 'bar hidden on push',
        ),
      )
      ..add(
        ObjectFlagProperty<RawNavigationModeForWidth>(
          'modeForWidth',
          modeForWidth,
          ifPresent: modeForWidth == ComicAppShell.modeFor ? null : 'custom',
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicAppAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
          defaultValue: true,
        ),
      );
  }
}

class _ComicAppShellState extends State<ComicAppShell> {
  final _bar = GlobalKey(debugLabel: 'ComicAppShell bar');

  @override
  Widget build(BuildContext context) => widget._build(context, _bar);
}

// The shell's tab bar: the places' tabs across a phone's foot, the act a balloon rising from the middle. The act stands
// over a gap among the tabs, outside the tab bar a screen reader hears, which holds the tabs alone.
class _ShellBar extends StatelessWidget {
  const _ShellBar({super.key, required this.details, required this.action});
  final RawNavigationDetails details;
  final ComicAppAction? action;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final act = action;
    final count = details.destinations.length;
    final middle = (count + 1) ~/ 2;
    final slots = act == null ? count : count + 1;
    final tabs = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i <= count; i++) ...[
          if (act != null && i == middle) const Expanded(child: SizedBox()),
          if (i < count) Expanded(child: details.destinations[i]),
        ],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(
          top: BorderSide(color: c.nightLine, width: t.rim(3)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ComicSpace.close,
          ComicSpace.close,
          ComicSpace.close,
          10 + bottom,
        ),
        child: act == null
            ? details.group(tabs)
            : Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  details.group(tabs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < slots; i++)
                        Expanded(
                          child: i == middle
                              ? _TabAct(
                                  action: act,
                                  word: (w, ink) => comicTabWord(t, w, ink),
                                )
                              : const SizedBox(),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// The shell's masthead: the app's name, its places as lettered links, and the act at the end, on the page's measure.
class _ShellMasthead extends StatelessWidget {
  const _ShellMasthead({
    required this.details,
    required this.brand,
    required this.action,
  });
  final RawNavigationDetails details;
  final String? brand;
  final ComicAppAction? action;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final name = brand ?? '';
    final act = action;
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
          padding: const EdgeInsets.only(bottom: ComicSpace.nib),
          child: SizedBox(
            height: 75,
            child: _OnMeasure(
              measure: _pageMeasure,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ComicSpace.tier,
                ),
                child: Row(
                  children: [
                    if (name.isNotEmpty) ...[
                      Flexible(
                        flex: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            header: true,
                            child: ComicLogo(name),
                          ),
                        ),
                      ),
                      const SizedBox(width: ComicSpace.tier + ComicSpace.tight),
                    ],
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: details.group(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final (i, place)
                                    in details.destinations.indexed) ...[
                                  if (i > 0)
                                    const SizedBox(width: ComicSpace.close),
                                  place,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (act != null) ...[
                      const SizedBox(width: 18),
                      _ShellAct(action: act),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The shell's rail or sidebar: the places in a column at the window's start, on the card with the bar's rule at its
// end; the act above them, and on a sidebar the app's name at its head.
class _ShellSide extends StatelessWidget {
  const _ShellSide({
    required this.details,
    required this.action,
    required this.width,
    this.brand,
  });
  final RawNavigationDetails details;
  final ComicAppAction? action;
  final double width;
  final String? brand;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final name = brand ?? '';
    final act = action;
    final rail = width < 120;
    return ComicStateDecoration(
      decoration: BoxDecoration(
        color: c.card,
        border: BorderDirectional(
          end: BorderSide(color: c.nightLine, width: t.rim(3)),
        ),
      ),
      child: SizedBox(
        width: width,
        // The window's start edge: its notch or rounded corner stays clear; the page beside keeps the end's.
        child: SafeArea(
          left: Directionality.of(context) == TextDirection.ltr,
          right: Directionality.of(context) == TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: rail ? 0 : ComicSpace.near,
              vertical: ComicSpace.near,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: rail
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.stretch,
              children: [
                if (name.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Semantics(header: true, child: ComicLogo(name)),
                    ),
                  ),
                  const SizedBox(height: ComicSpace.gap),
                ],
                if (act != null) ...[
                  Align(
                    alignment: rail
                        ? Alignment.center
                        : AlignmentDirectional.centerStart,
                    child: _ShellAct(action: act),
                  ),
                  const SizedBox(height: ComicSpace.gap),
                ],
                for (final (i, place) in details.destinations.indexed) ...[
                  if (i > 0 && !rail)
                    SizedBox(height: t.focus.gap + t.focus.width),
                  place,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- What the generator's routes, previews and page stubs stand on. ---

/// A tab with an icon, a label and an optional key for its tap target.
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

  /// {@template comic.label}
  /// The words drawn for it, which a screen reader reads as they are.
  /// {@endtemplate}
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
        ? const EdgeInsets.fromLTRB(
            ComicSpace.tier,
            ComicSpace.room,
            ComicSpace.tier,
            ComicSpace.spread + ComicSpace.gap,
          )
        : const EdgeInsets.fromLTRB(
            ComicSpace.near,
            ComicSpace.near,
            ComicSpace.near,
            ComicSpace.room,
          );
    final bar =
        topBar ?? (chrome != null && !sheet ? const ComicAppBar() : null);
    final bar0 = topBar;
    // A desktop bar carries the app's nav, so the page's own title stands at the head of its column.
    final title = t.desk && chrome != null && !sheet && bar0 is ComicAppBar
        ? bar0.title
        : null;
    // Under ComicAppShell's masthead a page has no bar of its own: its way back and its actions stand in that head,
    // beside its title.
    final head =
        t.desk &&
            !sheet &&
            (chrome?.shellDrawn ?? false) &&
            bar0 is ComicAppBar &&
            bar0.logo == null
        ? bar0
        : null;
    final exit = head == null
        ? null
        : head.leading ?? ComicAppBar.autoLeading(context);
    final Widget? heading = title == null
        ? null
        : Text(
            title.toUpperCase(),
            style: comicDisplayFor(title, t.type.section),
          );
    final Widget? headRow =
        head == null || (exit == null && head.actions.isEmpty)
        ? heading
        : Row(
            children: [
              if (exit != null) ...[exit, const SizedBox(width: 18)],
              Expanded(child: heading ?? const SizedBox.shrink()),
              for (final a in head.actions) ...[const SizedBox(width: 18), a],
            ],
          );
    final inner = headRow == null
        ? body
        : ComicColumn(
            gap: 16,
            children: [
              headRow,
              if (scroll) body else ComicGrow(child: body),
            ],
          );
    // The page's measure: the width of its column, which the top bar's and the footer's contents keep to.
    final measure = !fullBleed && scroll ? _pageMeasure : double.infinity;
    // The page body is one keyline region: its panels and words hold the page's margins.
    final Widget region = RawKeylineRegion(
      label: 'Page',
      child: Padding(padding: inset, child: inner),
    );
    final Widget column = fullBleed
        ? inner
        : scroll
        ? Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _pageMeasure),
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
    // A snack bar raised from the page stands above its footer.
    return _FooterHost(
      builder: (footerKey) => ComicBurstLedger(
        child: ColoredBox(
          color: sheet ? c.card : c.background,
          child: Column(
            mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bar != null && head == null)
                _PageMeasure(measure: measure, child: bar),
              sheet ? Flexible(child: page) : Expanded(child: page),
              // The tab bar draws its own rule and keeps clear of the home indicator: it stands bare.
              if (footer is ComicNavigationBar)
                KeyedSubtree(key: footerKey, child: footer!)
              else if (footer != null)
                DecoratedBox(
                  key: footerKey,
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border(
                      top: BorderSide(color: c.nightLine, width: t.rim(3)),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    // On a desktop the act ends where the page's column ends.
                    child: _OnMeasure(
                      measure: sheet ? double.infinity : measure,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: t.desk && !sheet
                              ? ComicSpace.tier
                              : ComicSpace.near,
                          vertical: ComicSpace.near,
                        ),
                        child: t.desk && !sheet
                            ? Align(
                                alignment: AlignmentDirectional.centerEnd,
                                heightFactor: 1,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 360,
                                  ),
                                  child: footer!,
                                ),
                              )
                            : footer!,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty(
          'scroll',
          value: scroll,
          ifFalse: 'scroll: false',
          defaultValue: true,
        ),
      )
      ..add(
        FlagProperty(
          'fullBleed',
          value: fullBleed,
          ifTrue: 'fullBleed',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
          defaultValue: null,
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
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Overrides the localized back or close label.
  final String? semanticLabel;

  /// Uses the close action instead of a back arrow.
  final bool close;

  /// {@macro comic.onPressed}
  final VoidCallback? onPressed;

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
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
      semanticLabel:
          semanticLabel ??
          (close
              ? RawWidgetsLocalizations.of(context).closeButtonLabel
              : RawWidgetsLocalizations.of(context).backButtonTooltip),
      size: 38,
      // The way out stands on its bar's start keyline, its target growing toward the end.
      targetAlignment: AlignmentDirectional.centerStart,
      onPressed: onPressed,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'close',
          value: close,
          ifTrue: 'close',
          defaultValue: false,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// A page's top bar: the route's way out, the app's name or the page's title in the lettering, the app's places on a desktop, and
/// the page's own [actions] at its end. A page never authors its own back or close: leave [leading] unset, or pass [autoLeading]
/// to key it. On a desktop the title moves to the head of the page's column, and in a [ComicScaffold] under
/// [ComicAppShell]'s masthead its way back and its actions join it there. [logo] stands in place of the logo, such as a
/// `ComicGroupChip`.
///
/// ```dart
/// ComicAppBar(title: 'The plan', leading: ComicAppBar.autoLeading(context, key: const ValueKey('back')), actions: [ComicIconButton(ComicGlyphs.share2, semanticLabel: 'Share')])
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
    // Under ComicAppShell on a desktop the shell's masthead carries the app's name, its places and its act: the page's
    // bar keeps its way back and its own actions, and stands away when it has neither.
    final underMasthead = t.desk && !sheet && (chrome?.shellDrawn ?? false);
    if (underMasthead && exit == null && actions.isEmpty && logo == null) {
      return const SizedBox.shrink();
    }
    final masthead = t.desk && chrome != null && !sheet && !underMasthead;
    final name = underMasthead ? '' : chrome?.brand.name ?? '';
    final showTitle = title != null && !masthead && !underMasthead;
    final Widget? who = logo != null
        ? logo!
        : showTitle
        ? CapLabel(
            child: Text(
              title!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: comicDisplayFor(
                title!,
                t.type.letter(t.desk ? 34 : 26, lineHeight: 1),
              ),
            ),
          )
        : name.isNotEmpty
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: ComicLogo(name),
          )
        : null;
    final shellAction = masthead ? chrome.action : null;
    final action = shellAction == null
        ? null
        : ComicAppAction(
            icon: shellAction.icon,
            label: shellAction.label ?? '',
            accent: shellAction.accent,
            key: shellAction.key,
            onPressed: () => shellAction.onPressed(context),
          );
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
          padding: const EdgeInsets.only(bottom: ComicSpace.nib),
          child: SizedBox(
            height: t.desk && !underMasthead ? 75 : 57,
            // On a desktop the bar's words keep to the page's column, as the title at its head does.
            child: _OnMeasure(
              measure: t.desk ? _PageMeasure.of(context) : double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: t.desk ? ComicSpace.tier : ComicSpace.near,
                ),
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
                      const SizedBox(width: ComicSpace.tier + ComicSpace.tight),
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
                                  if (i > 0)
                                    const SizedBox(width: ComicSpace.close),
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
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('leading', leading, defaultValue: null))
      ..add(DiagnosticsProperty<Widget>('logo', logo, defaultValue: null));
  }
}

class _ShellAct extends StatelessWidget {
  const _ShellAct({required this.action});
  final ComicAppAction action;
  @override
  Widget build(BuildContext context) {
    final label = action.label;
    final t = ComicTheme.of(context);
    // The accent action: the filled button with its words, or, with none, the icon button in its fill.
    return action.accent && label.isNotEmpty
        ? ComicButton.filled(
            label,
            key: action.key,
            icon: action.icon,
            size: ComicButtonSize.small,
            onPressed: action.onPressed,
          )
        : ComicIconButton(
            action.icon,
            key: action.key,
            semanticLabel: label,
            onPressed: action.onPressed,
            style: action.accent
                ? ComicStyle(
                    fill: WidgetStatePropertyAll(t.colors.primary),
                    foreground: WidgetStatePropertyAll(t.colors.onPrimary),
                  )
                : null,
          );
  }
}

/// A plain one-line text field; [ComicTextField] is the same field with a label, help and an error.
///
/// ```dart
/// ComicInput(key: const ValueKey('name'), hintText: 'Your name', onChanged: (text) {})
/// ```
class ComicInput extends StatelessWidget {
  /// Creates a [ComicInput].
  const ComicInput({
    super.key,
    this.style,
    this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  /// [hintText]: placeholder text shown when the field is empty. [initialValue]: initial text when no editing controller is supplied.
  final String? hintText, initialValue;

  /// The caller-owned editing controller.
  final TextEditingController? controller;

  /// [onChanged]: reports a new value; null disables changes. [onSubmitted]: reports text submitted from the keyboard.
  final ValueChanged<String>? onChanged, onSubmitted;

  /// Per-state appearance forwarded to the public control.
  final ComicStyle? style;

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) => ComicTextField(
    focusNode: focusNode,
    autofocus: autofocus,
    style: style,
    hintText: hintText,
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('initialValue', initialValue, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
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
/// ComicMedia(slotId: 'item-1', aspect: 1, semanticLabel: 'First piece')
/// ```
class ComicMedia extends StatelessWidget {
  /// Creates a [ComicMedia].
  const ComicMedia({
    super.key,
    required this.slotId,
    this.aspect = 4 / 3,
    this.semanticLabel,
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

  /// What a screen reader calls the picture; null leaves it out as decoration.
  final String? semanticLabel;

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
      image: semanticLabel != null,
      label: semanticLabel,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('slotId', slotId))
      ..add(DoubleProperty('aspect', aspect, defaultValue: 4 / 3))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(EnumProperty<BoxFit>('fit', fit, defaultValue: BoxFit.cover))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(
        FlagProperty('bare', value: bare, ifTrue: 'bare', defaultValue: false),
      );
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

  /// {@macro comic.onPressed}
  final VoidCallback? onPressed;

  /// {@macro comic.focusNode}
  final FocusNode? focusNode;

  /// {@macro comic.autofocus}
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
      semanticLabel: title,
      child: ComicColumn(
        children: [
          ComicMedia(
            slotId: slotId,
            image: image,
            aspect: aspect,
            semanticLabel: title,
            bare: true,
          ),
          ComicGrow(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ComicSpace.near,
                ComicSpace.close,
                ComicSpace.near,
                ComicSpace.near,
              ),
              child: ComicColumn(
                children: [
                  Text(title, style: t.type.title),
                  if (subtitle != null) Text(subtitle!, style: t.type.meta),
                  if (figure != null || trailing != null) ...[
                    const SizedBox(height: ComicSpace.close),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('slotId', slotId))
      ..add(DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null))
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('figure', figure, defaultValue: null))
      ..add(DoubleProperty('aspect', aspect, defaultValue: 4 / 3))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// While a page's data is on its way: a thought with three dots in it.
///
/// ```dart
/// ComicLoadingState(semanticLabel: 'Loading issue')
/// ```
class ComicLoadingState extends StatelessWidget {
  /// Creates a [ComicLoadingState].
  const ComicLoadingState({super.key, this.semanticLabel});

  /// Overrides the localized loading announcement.
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Center(
      child: Semantics(
        label:
            semanticLabel ?? RawWidgetsLocalizations.of(context).loadingLabel,
        child: Padding(
          padding: const EdgeInsets.all(ComicSpace.spread),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('semanticLabel', semanticLabel, defaultValue: null),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry))
      ..add(StringProperty('retryLabel', retryLabel, defaultValue: null));
  }
}

// The widest a page's column stands; past it the page centres the column.
const double _pageMeasure = 1376;

// The measure of the page a top bar stands on, so its words keep to the page's column.
class _PageMeasure extends InheritedWidget {
  const _PageMeasure({required this.measure, required super.child});

  final double measure;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageMeasure>()?.measure ??
      double.infinity;

  @override
  bool updateShouldNotify(_PageMeasure old) => measure != old.measure;
}

// [child], no wider than [measure], centred in the width it is given.
class _OnMeasure extends StatelessWidget {
  const _OnMeasure({required this.measure, required this.child});

  final double measure;
  final Widget child;

  @override
  Widget build(BuildContext context) => measure == double.infinity
      ? child
      : Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: measure),
            child: child,
          ),
        );
}

// Holds a page's footer key for as long as the page stands, and tells what is
// raised from the page where the footer is ([ComicFooterClear]).
class _FooterHost extends StatefulWidget {
  const _FooterHost({required this.builder});

  final Widget Function(GlobalKey footerKey) builder;

  @override
  State<_FooterHost> createState() => _FooterHostState();
}

class _FooterHostState extends State<_FooterHost> {
  final _footer = GlobalKey(debugLabel: 'ComicScaffold.footer');

  @override
  Widget build(BuildContext context) =>
      ComicFooterClear(footer: _footer, child: widget.builder(_footer));
}
