/// Keycap's way round an app. The places are legends printed on the case;
/// the current place is a modifier key latched down under its legend. A
/// phone has them in a row at its foot, a tablet in a rail, a desktop in a
/// side column. A top bar is a strip of the case with the page's name and
/// a back key.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'theme.dart';

/// A page's top bar: a strip of the case holding a back key (or [leading]),
/// the page's [title] and its [actions].
///
/// ```dart
/// KeycapAppBar(title: 'Settings', onBack: () => Navigator.pop(context))
/// ```
class KeycapAppBar extends StatelessWidget {
  /// A top bar.
  const KeycapAppBar({
    super.key,
    this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.style,
  });

  /// The page's name.
  final String? title;

  /// Called by the back key; shows one when given.
  final VoidCallback? onBack;

  /// A key at the bar's start, when there is no back key.
  final Widget? leading;

  /// Keys at the bar's end.
  final List<Widget> actions;

  /// A row under the bar (a tab bar, a search field).
  final Widget? bottom;

  /// Overrides, over [KeycapThemeData.appBarStyle]: [DesignStyle.foreground]
  /// the title's colour, [DesignStyle.textStyle] its style,
  /// [DesignStyle.padding] the bar's.
  final KeycapStyle? style;

  /// The bar's height, under the status bar.
  static const double height = 60;

  /// The side of a key in the bar.
  static const double keySide = 40;

  /// A back key: a square key with an arrow pointing against the reading
  /// direction.
  static Widget backKey(BuildContext context, VoidCallback onBack) =>
      KeycapIconButton(
        icon: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: const Icon(LucideIcons.arrowLeft),
        ),
        semanticLabel: DesignLocalizations.of(context).backButtonTooltip,
        onPressed: onBack,
        style: const DesignStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(keySide)),
        ),
      );

  /// A close key, for a page raised as a sheet.
  static Widget closeKey(BuildContext context, VoidCallback onClose) =>
      KeycapIconButton(
        icon: const Icon(LucideIcons.x),
        semanticLabel: DesignLocalizations.of(context).closeButtonLabel,
        onPressed: onClose,
        style: const DesignStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(keySide)),
        ),
      );

  /// The key the route at [context] wants at a bar's start: back on a
  /// pushed page, close on a sheet, none on a root page.
  static Widget? autoLeading(BuildContext context) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    void leave() => Navigator.of(context).maybePop();
    return presentation == RoutePresentation.sheet
        ? closeKey(context, leave)
        : backKey(context, leave);
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style, theme.appBarStyle], const {});
    final media = MediaQuery.of(context);
    final margin = KeycapSpacing.pageMargin(media.size.width);
    final start = onBack != null ? backKey(context, onBack!) : leading;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: layered.fill ?? theme.colors.ground,
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              EdgeInsets.fromLTRB(margin, media.padding.top, margin, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: height,
                child: Row(
                  children: [
                    if (start != null) ...[
                      start,
                      const SizedBox(width: KeycapSpacing.medium),
                    ],
                    Expanded(
                      child: title == null
                          ? const SizedBox()
                          : Semantics(
                              header: true,
                              child: DesignCapCenter(
                                capHeightFactor: theme.capHeightFactor,
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.heading
                                      .merge(layered.textStyle)
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: layered.foreground,
                                      ),
                                ),
                              ),
                            ),
                    ),
                    for (final (i, action) in actions.indexed) ...[
                      SizedBox(
                        width: i == 0
                            ? KeycapSpacing.medium
                            : KeycapMetrics.keyGap * 2,
                      ),
                      action,
                    ],
                  ],
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: KeycapSpacing.medium),
                  child: bottom,
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
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(FlagProperty('back', value: onBack != null, ifTrue: 'back'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// One place in an app's navigation.
///
/// ```dart
/// const KeycapDestination(icon: LucideIcons.notebook, label: 'Notes')
/// ```
@immutable
class KeycapDestination {
  /// A place.
  const KeycapDestination({required this.icon, required this.label, this.key});

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// A key for its legend, for a test to find it by.
  final Key? key;
}

// A place's legend: printed on the case, a modifier key latched under it
// when it is the current place, a key going down under it while pressed.
KeycapFace _placeFace(
  KeycapThemeData theme,
  Set<WidgetState> states,
  bool current,
) {
  final c = theme.colors;
  final pressed = states.contains(WidgetState.pressed);
  final focused = states.contains(WidgetState.focused);
  final off = states.contains(WidgetState.disabled);
  if (current || pressed) {
    final face = keycapKeyFace(theme, KeycapKind.modifier, {
      if (pressed) WidgetState.pressed,
      if (focused) WidgetState.focused,
    }, latched: current);
    return current ? face : face.copyWith(legend: c.ink);
  }
  KeycapCapColors clear(KeycapCapColors k) => k.copyWith(
    top: k.top.withValues(alpha: 0),
    wall: k.wall.withValues(alpha: 0),
    front: k.front.withValues(alpha: 0),
  );
  final none = clear(c.modifier);
  return KeycapFace.of(none, c).copyWith(
    legend: off ? c.inkDisabled : c.inkMuted,
    edge: c.edge.withValues(alpha: 0),
    shadow: c.shadow.withValues(alpha: 0),
    focus: focused ? c.focus : c.focus.withValues(alpha: 0),
  );
}

Widget _stackedLegend(
  BuildContext context,
  KeycapDestination d,
  KeycapFace face,
  bool current,
) {
  final theme = KeycapTheme.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(d.icon, size: 20, color: face.legend),
      const SizedBox(height: KeycapSpacing.tight),
      // A name is never cut short: past its key's width it prints smaller.
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            d.label,
            maxLines: 1,
            textAlign: TextAlign.center,
            textScaler: _placeNameScaler(context),
            style: theme.textTheme.legend.copyWith(
              letterSpacing: 0.2,
              color: face.legend,
              fontWeight: current ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _rowLegend(
  BuildContext context,
  KeycapDestination d,
  KeycapFace face,
  bool current,
) {
  final theme = KeycapTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
    child: Row(
      children: [
        Icon(d.icon, size: 20, color: face.legend),
        const SizedBox(width: KeycapSpacing.medium),
        Expanded(
          child: DesignCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(
              d.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.label.copyWith(
                color: current ? face.legend : theme.colors.ink,
                fontWeight: current ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// A place's name in a bar or a rail grows a third at most: five names share
// a phone's width, and each stays whole, printing smaller past its key's
// width (the side column carries them at full size from 1024).
TextScaler _placeNameScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

Widget _placeKey(
  BuildContext context,
  Set<WidgetState> states,
  bool current,
  double height,
  Widget Function(KeycapFace face) legend, {
  double? width,
  bool stacked = true,
}) {
  final theme = KeycapTheme.of(context);
  final face = _placeFace(theme, states, current);
  // Taller as its name grows: a stacked name (a bar's, a rail's) grows a
  // third at most, a side column's row of words grows in full.
  final tall = stacked
      ? KeycapMetrics.grown(
          context,
          height,
          theme.textTheme.legend,
          scaler: _placeNameScaler(context),
        )
      : KeycapMetrics.grown(context, height, theme.textTheme.label);
  return SizedBox(
    width: width,
    height: tall,
    child: AnimatedKeycapCap(
      face: face,
      walls: KeycapMetrics.walls(tall),
      child: Center(child: legend(face)),
    ),
  );
}

/// A phone's navigation: the places in a row at the screen's foot.
///
/// ```dart
/// KeycapNavigationBar(destinations: places, selectedIndex: at, onSelected: go)
/// ```
class KeycapNavigationBar extends StatelessWidget {
  /// A row of places.
  const KeycapNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.style,
  });

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// Overrides, over [KeycapThemeData.navigationStyle]: [DesignStyle.fill]
  /// the strip's colour.
  final KeycapStyle? style;

  /// A place's key's height.
  static const double keyHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style, theme.navigationStyle], const {});
    final media = MediaQuery.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: layered.fill ?? theme.colors.ground,
          border: Border(top: BorderSide(color: theme.colors.hairline)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            KeycapSpacing.small,
            KeycapSpacing.small,
            KeycapSpacing.small,
            KeycapSpacing.small + media.padding.bottom,
          ),
          child: Row(
            children: [
              for (final (i, d) in destinations.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeycapMetrics.keyGap / 2,
                    ),
                    child: KeyedSubtree(
                      key: d.key,
                      child: DesignPressable(
                        onPressed: () => onSelected(i),
                        selected: i == selectedIndex,
                        semanticSelected: i == selectedIndex,
                        semanticLabel: d.label,
                        excludeSemantics: true,
                        builder: (context, states, _) => DesignTapTarget(
                          child: _placeKey(
                            context,
                            states,
                            i == selectedIndex,
                            keyHeight,
                            (face) => _stackedLegend(
                              context,
                              d,
                              face,
                              i == selectedIndex,
                            ),
                          ),
                        ),
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
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A tablet's navigation: the places stacked down a rail at the screen's
/// start, an [action] key over them. Most apps want [KeycapScaffold], which
/// chooses it by width.
///
/// ```dart
/// KeycapNavigationRail(destinations: places, selectedIndex: at, onSelected: go)
/// ```
class KeycapNavigationRail extends StatelessWidget {
  /// A rail of places.
  const KeycapNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.action,
  }) : _keys = null;

  const KeycapNavigationRail._shell(List<Widget> this._keys, {this.action})
    : destinations = const [],
      selectedIndex = 0,
      onSelected = _ignore;

  static void _ignore(int _) {}

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// A key over the places (a screen's main action).
  final Widget? action;

  final List<Widget>? _keys;

  /// The rail's width.
  static const double width = 88;

  /// A place's key's size.
  static const Size keySize = Size(68, 56);

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final keys =
        _keys ??
        [
          for (final (i, d) in destinations.indexed)
            KeyedSubtree(
              key: d.key,
              child: DesignPressable(
                onPressed: () => onSelected(i),
                selected: i == selectedIndex,
                semanticSelected: i == selectedIndex,
                semanticLabel: d.label,
                excludeSemantics: true,
                builder: (context, states, _) => _placeKey(
                  context,
                  states,
                  i == selectedIndex,
                  keySize.height,
                  (face) =>
                      _stackedLegend(context, d, face, i == selectedIndex),
                  width: keySize.width,
                ),
              ),
            ),
        ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.ground,
        border: BorderDirectional(
          end: BorderSide(color: theme.colors.hairline),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top + KeycapSpacing.regular,
            bottom: media.padding.bottom + KeycapSpacing.regular,
          ),
          child: Column(
            children: [
              if (action != null) ...[
                action!,
                const SizedBox(height: KeycapSpacing.large),
              ],
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) const SizedBox(height: KeycapMetrics.keyGap * 2),
                k,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A desktop's navigation: a column at the screen's start, a [header] over
/// the places and a [footer] under them; the current place a wide
/// modifier key latched under its legend.
///
/// ```dart
/// KeycapSideNavigation(destinations: places, selectedIndex: at, onSelected: go, header: Text('Jotter'))
/// ```
class KeycapSideNavigation extends StatelessWidget {
  /// A column of places.
  const KeycapSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.action,
    this.footer,
  }) : _keys = null;

  const KeycapSideNavigation._shell(
    List<Widget> this._keys, {
    this.header,
    this.action,
    this.footer,
  }) : destinations = const [],
       selectedIndex = 0,
       onSelected = KeycapNavigationRail._ignore;

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands over the places (the app's name).
  final Widget? header;

  /// A key under the header (a screen's main action).
  final Widget? action;

  /// What stands at the column's foot.
  final Widget? footer;

  final List<Widget>? _keys;

  /// The column's width.
  static const double width = 264;

  /// A place's key's height.
  static const double keyHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final keys =
        _keys ??
        [
          for (final (i, d) in destinations.indexed)
            KeyedSubtree(
              key: d.key,
              child: DesignPressable(
                onPressed: () => onSelected(i),
                selected: i == selectedIndex,
                semanticSelected: i == selectedIndex,
                semanticLabel: d.label,
                excludeSemantics: true,
                builder: (context, states, _) => _placeKey(
                  context,
                  states,
                  i == selectedIndex,
                  keyHeight,
                  (face) => _rowLegend(context, d, face, i == selectedIndex),
                  stacked: false,
                ),
              ),
            ),
        ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.ground,
        border: BorderDirectional(
          end: BorderSide(color: theme.colors.hairline),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            KeycapSpacing.regular,
            media.padding.top + KeycapSpacing.large,
            KeycapSpacing.regular,
            media.padding.bottom + KeycapSpacing.regular,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: KeycapSpacing.medium,
                    bottom: KeycapSpacing.large,
                  ),
                  child: header,
                ),
              if (action != null) ...[
                action!,
                const SizedBox(height: KeycapSpacing.large),
              ],
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) const SizedBox(height: KeycapMetrics.keyGap),
                k,
              ],
              const Spacer(),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// An app's frame: its places at a phone's foot below 600 wide, down a
/// rail to 1024, in a side column wider, and [body] beside them. From 600
/// it stands on ui_core's `DesignAdaptiveShell`, which moves the keyboard
/// between the places and the page.
///
/// ```dart
/// KeycapScaffold(destinations: places, selectedIndex: at, onSelected: go, body: page)
/// ```
class KeycapScaffold extends StatelessWidget {
  /// An app's frame.
  const KeycapScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.header,
    this.action,
    this.wideAction,
    this.sideFooter,
    this.showNavigation = true,
  });

  /// The places.
  final List<KeycapDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// The page.
  final Widget body;

  /// The side column's header (from 1024).
  final Widget? header;

  /// A square key over the rail's places (600 to 1024): the main action.
  final Widget? action;

  /// The same action as a key with words, under the side column's header
  /// (from 1024).
  final Widget? wideAction;

  /// The side column's foot.
  final Widget? sideFooter;

  /// Whether the places show (a pushed page may hide them).
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final page = Semantics(container: true, child: body);
    if (width < 600) {
      if (!showNavigation) return page;
      return Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: page,
            ),
          ),
          KeycapNavigationBar(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ],
      );
    }
    return DesignAdaptiveShell(
      mode: width < 1024
          ? DesignNavigationMode.rail
          : DesignNavigationMode.sidebar,
      showNavigation: showNavigation,
      destinations: [
        for (final d in destinations)
          DesignNavigationDestination(label: d.label, icon: d.icon),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinationBuilder: (context, _, details) {
        final d = destinations[details.index];
        final current = details.index == selectedIndex;
        return KeyedSubtree(
          key: d.key,
          child: switch (details.mode) {
            DesignNavigationMode.rail || DesignNavigationMode.bar => _placeKey(
              context,
              details.states,
              current,
              KeycapNavigationRail.keySize.height,
              (face) => _stackedLegend(context, d, face, current),
              width: KeycapNavigationRail.keySize.width,
            ),
            DesignNavigationMode.sidebar => _placeKey(
              context,
              details.states,
              current,
              KeycapSideNavigation.keyHeight,
              (face) => _rowLegend(context, d, face, current),
              stacked: false,
            ),
          },
        );
      },
      navigationBuilder: (context, details) => switch (details.mode) {
        DesignNavigationMode.rail || DesignNavigationMode.bar =>
          KeycapNavigationRail._shell(details.destinations, action: action),
        DesignNavigationMode.sidebar => KeycapSideNavigation._shell(
          details.destinations,
          header: header,
          action: wideAction ?? action,
          footer: sideFooter,
        ),
      },
      body: page,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A page on the case: its [topBar], its [body] inside the page margin (16
/// on a phone, 24 on a tablet, 32 on a desktop) and at most [maxWidth]
/// wide on its start edge (under the bar's title), scrolling, and a
/// [footer] of keys at its foot.
///
/// ```dart
/// KeycapScreen(topBar: const KeycapAppBar(title: 'Settings'), body: settings)
/// ```
class KeycapScreen extends StatelessWidget {
  /// A page.
  const KeycapScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.maxWidth = pageWidth,
    this.scrollController,
  });

  /// The page's content.
  final Widget body;

  /// Its top bar.
  final Widget? topBar;

  /// Keys at its foot (a form's Save).
  final Widget? footer;

  /// Whether the body scrolls.
  final bool scroll;

  /// Whether the body runs edge to edge, with no margin.
  final bool fullBleed;

  /// The widest the body stands.
  final double maxWidth;

  /// The body's scroll controller.
  final ScrollController? scrollController;

  /// The widest a page's content stands by default.
  static const double pageWidth = 1040;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final media = MediaQuery.of(context);
    final margin = KeycapSpacing.pageMargin(media.size.width);
    final bar = topBar;
    final foot = footer;
    final top = bar == null ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              (bar == null ? KeycapSpacing.large : KeycapSpacing.small) + top,
              margin,
              // A scrolling page's last row clears the foot by a huge step;
              // a page that fills the window ends a large step above it.
              (scroll ? KeycapSpacing.huge : KeycapSpacing.large) + bottom,
            ),
            child: body,
          );
    final Widget column = fullBleed
        ? page
        // On the page's start edge, under the top bar's title: one margin
        // from the bar to the last row, whatever the window's width.
        : Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: scroll ? 1 : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth + 2 * margin),
              child: page,
            ),
          );
    final Widget content = scroll
        ? SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: column,
          )
        : column;
    return ColoredBox(
      color: theme.colors.ground,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The bar's title and keys stand over the content's column.
            if (bar != null)
              fullBleed
                  ? bar
                  : Align(
                      alignment: AlignmentDirectional.topStart,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth + 2 * margin,
                        ),
                        child: bar,
                      ),
                    ),
            Expanded(child: content),
            if (foot != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colors.ground,
                  border: Border(top: BorderSide(color: theme.colors.hairline)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    KeycapSpacing.medium,
                    margin,
                    KeycapSpacing.medium + media.padding.bottom,
                  ),
                  child: media.size.width >= 600
                      ? Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: foot,
                        )
                      : foot,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifTrue: 'scroll'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'fullBleed'));
  }
}

/// A short title printed on the case over a page's content, with an
/// optional line under it: the page's name where it has no top bar title.
///
/// ```dart
/// const KeycapPageTitle('Notes', subtitle: '42 notes in 5 folders')
/// ```
class KeycapPageTitle extends StatelessWidget {
  /// A page title.
  const KeycapPageTitle(this.text, {super.key, this.subtitle, this.trailing});

  /// The title.
  final String text;

  /// A line under it.
  final String? subtitle;

  /// A key at its end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: theme.textTheme.title),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: KeycapSpacing.tight),
            child: Text(subtitle!, style: theme.textTheme.secondary),
          ),
      ],
    );
    if (trailing == null) return words;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: words),
        const SizedBox(width: KeycapSpacing.regular),
        trailing!,
      ],
    );
  }
}
