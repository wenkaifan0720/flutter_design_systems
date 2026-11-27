/// Gloss's navigation, on its grained chrome: [GlossTopBar], [GlossTabBar],
/// and the three ways between an app's places ([GlossNavigationBar] under
/// 600 px, [GlossNavigationRail] to 1024, [GlossSidebar] past it), which
/// [GlossAppShell] picks by width on ui_core's adaptive shell.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart'
    show RawBranchBackBehavior, RawNavigationDestination;

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'fonts.dart';
import 'surface.dart';
import 'theme.dart';
import 'internal/corners.dart';

/// A Gloss top bar: the grained chrome along a page's top, its [title]
/// letterpressed at the start, a pearl back bead before it when [onBack]
/// is given, and [actions] at its end. With [large], the title stands under
/// the bar in the headline face, on the page.
///
/// ```dart
/// GlossTopBar(title: 'Shopping', onBack: () {})
/// ```
class GlossTopBar extends StatelessWidget {
  /// A bar titled [title].
  const GlossTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.large = false,
    this.bottom,
  });

  /// The way out a page's place calls for: none on a root, a pearl back
  /// bead on a pushed page, a close bead on a sheet ([RoutePresentation]).
  /// Either pops the route. [key] goes on the bead.
  ///
  /// ```dart
  /// GlossTopBar(title: 'Recipe', leading: GlossTopBar.autoLeading(context))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    final close = presentation == RoutePresentation.sheet;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final words = RawWidgetsLocalizations.of(context);
    return _backBead(
      key: key,
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: close ? words.closeButtonLabel : words.backButtonTooltip,
      glyph: close
          ? LucideIcons.x
          : rtl
          ? LucideIcons.chevronRight
          : LucideIcons.chevronLeft,
    );
  }

  // The way out is a pearl bead on the bar (the phone language's back
  // bead), its glyph a size under the bar's own glyphs.
  static Widget _backBead({
    Key? key,
    required VoidCallback? onPressed,
    required String tooltip,
    required IconData glyph,
  }) => GlossIconButton(
    key: key,
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(glyph, size: 18),
  );

  /// The page's name.
  final String title;

  /// Called by the back bead; none shows when null.
  final VoidCallback? onBack;

  /// The bead at the bar's start in place of the back bead, usually
  /// [autoLeading]'s.
  final Widget? leading;

  /// Glyphs or a key at the bar's end (`GlossIconButton.plain`, at most one
  /// `GlossButton.filled`).
  final List<Widget> actions;

  /// Whether the title stands large under the bar (a place's first page);
  /// on a sidebar's width it stays in the strip.
  final bool large;

  /// Something under the title, on the bar: a search field, tabs.
  final Widget? bottom;

  /// The bar's height, past the safe area.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final titleStyle = glossLetterpress(theme.textTheme.title, c);
    // On a desk the place's name sits in the quiet strip with its keys, on
    // one line; the large title under the bar is a phone's and a tablet's.
    final large = this.large && width < GlossMetrics.sidebarBreakpoint;
    final lead =
        leading ??
        (onBack == null
            ? null
            : _backBead(
                onPressed: onBack,
                tooltip: RawWidgetsLocalizations.of(context).backButtonTooltip,
                glyph: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
              ));
    return LayoutBuilder(
      builder: (context, box) {
        // The bar keeps to the page's column: on a wide screen its title
        // and its keys line up with the page's words.
        final margin = GlossSpacing.pageInset(width, box.maxWidth);
        final row = SizedBox(
          height: height,
          child: Row(
            children: [
              if (lead != null)
                Padding(
                  // The bead's face on the page's margin (its tap target
                  // reaches 2 px past it on a touch screen).
                  padding: EdgeInsetsDirectional.only(start: margin - 2),
                  child: lead,
                ),
              Expanded(
                child: large
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: lead == null ? margin : GlossSpacing.medium,
                          end: GlossSpacing.small,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            header: true,
                            child: RawCapCenter(
                              capHeightFactor: glossCapHeightFactor,
                              // The bar's one line grows with the reader's text
                              // up to 1.5x; the large title under it grows all
                              // the way, and wraps.
                              child: Text(
                                title,
                                textScaler: MediaQuery.textScalerOf(context)
                                    .clamp(maxScaleFactor: 1.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(width: GlossSpacing.tight),
                action,
              ],
              // The last bead's face on the page's margin, as the back bead's is
              // at the start.
              SizedBox(width: actions.isEmpty ? 0 : margin - 2),
            ],
          ),
        );
        return GlossBar(
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                if (large)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: margin,
                      end: margin,
                      bottom: GlossSpacing.medium,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: glossLetterpress(theme.textTheme.headline, c),
                      ),
                    ),
                  ),
                if (bottom != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: margin,
                      end: margin,
                      bottom: GlossSpacing.medium,
                    ),
                    child: bottom,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('large', value: large, ifTrue: 'large'))
      ..add(FlagProperty('back', value: onBack != null, ifTrue: 'back'))
      ..add(FlagProperty('leading', value: leading != null, ifTrue: 'leading'));
  }
}

/// One of an app's places, for [GlossNavigationBar], [GlossNavigationRail]
/// and [GlossSidebar].
@immutable
class GlossDestination {
  /// A place called [label], shown by [icon].
  const GlossDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
  });

  /// The key for this destination's navigation cell.
  final Key? key;

  /// Its glyph.
  final IconData icon;

  /// Its glyph while it is the current place; [icon] when null.
  final IconData? selectedIcon;

  /// Its name.
  final String label;
}

/// A place's face in a bar or a rail, painted from its pressable [states]:
/// its glyph, its name under it, and, when it is the current place
/// ([WidgetState.selected]), a pocket pressed into the bar round its glyph
/// with the glyph and the name lit jade.
class _PocketFace extends StatelessWidget {
  const _PocketFace({
    required this.destination,
    required this.states,
    required this.style,
  });

  final GlossDestination destination;
  final Set<WidgetState> states;
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final layered = RawStyleOf(
      [style, theme.navigationStyle],
      {...states, if (chosen) WidgetState.selected},
    );
    final pressed = states.contains(WidgetState.pressed);
    final words = layered.foreground ?? (chosen ? c.jadeInk : c.inkSecondary);
    final pocket = GlossFace.well(c).copyWith(
      lift: chosen ? -1 : (pressed ? -0.5 : 0),
      top: chosen || pressed ? null : c.well.withValues(alpha: 0),
      middle: chosen || pressed ? null : c.well.withValues(alpha: 0),
      bottom: chosen || pressed ? null : c.well.withValues(alpha: 0),
      lip: chosen || pressed ? null : c.lip.withValues(alpha: 0),
      foreground: words,
      focus: glossGlazeOf(c, states),
      // An app's corners for the pocket, else its capsule.
      corners: glossCornersOf(
        theme,
        layered,
        RawCorner.full,
        Directionality.of(context),
      ),
    );
    return TapTargetPadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 32,
            child: AnimatedGlossSurface(
              face: pocket,
              child: Center(
                child: Icon(
                  chosen
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: GlossSpacing.tight),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.grid / 2,
            ),
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: glossLetterpress(
                theme.textTheme.caption.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  color: words,
                  fontWeight: chosen ? FontWeight.w700 : FontWeight.w600,
                  fontVariations: glossWeightAxis(
                    chosen ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A place's row in a sidebar, painted from its pressable [states]: the
/// current one ([WidgetState.selected]) stands on a pearl plate raised from
/// the panel, its glyph jade; a press shades a row a breath.
class _SideFace extends StatelessWidget {
  const _SideFace({
    required this.destination,
    required this.states,
    required this.style,
  });

  final GlossDestination destination;
  final Set<WidgetState> states;
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final chosen = states.contains(WidgetState.selected);
    final layered = RawStyleOf(
      [style, theme.navigationStyle],
      {...states, if (chosen) WidgetState.selected},
    );
    final pressed = states.contains(WidgetState.pressed);
    final clear = c.pearlTop.withValues(alpha: 0);
    final light = c.brightness == Brightness.light;
    final shade = light ? const Color(0x0F183048) : const Color(0x14FFFFFF);
    final GlossFace face;
    if (chosen) {
      face = GlossFace.pearl(
        c,
        radius: glossCorner(theme, RawCorner.small),
      ).copyWith(lens: light ? 0.55 : 0.25, lift: 0.6, travel: pressed ? 1 : 0);
    } else {
      final tint = pressed ? shade : clear;
      face = GlossFace(
        top: tint,
        middle: tint,
        bottom: tint,
        foreground: c.ink,
        radius: glossCorner(theme, RawCorner.small),
        shade: c.shadow,
      );
    }
    final words = layered.foreground ?? c.ink;
    return TapTargetPadding(
      child: SizedBox(
        height: math.max(40, theme.controlHeight - 4),
        child: AnimatedGlossSurface(
          face: face.copyWith(
            foreground: words,
            focus: glossGlazeOf(c, states),
            corners: glossCornersOf(
              theme,
              layered,
              RawCorner.small,
              Directionality.of(context),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GlossSpacing.medium,
            ),
            child: Row(
              children: [
                Icon(
                  chosen
                      ? destination.selectedIcon ?? destination.icon
                      : destination.icon,
                  size: 20,
                  color: chosen ? c.jadeInk : c.inkSecondary,
                ),
                const SizedBox(width: GlossSpacing.medium),
                Expanded(
                  child: RawCapCenter(
                    capHeightFactor: glossCapHeightFactor,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.label.copyWith(
                        fontSize: 15,
                        color: words,
                        fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
                        fontVariations: glossWeightAxis(
                          chosen ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A place pressed on its own (a bar, a rail or a sidebar standing alone):
/// each place is a tab stop of its own. In a [GlossAppShell] ui_core's
/// shell presses them instead.
class _Place extends StatelessWidget {
  const _Place({
    required this.destination,
    required this.chosen,
    required this.onPressed,
    required this.face,
  });

  final GlossDestination destination;
  final bool chosen;
  final VoidCallback onPressed;
  final Widget Function(Set<WidgetState> states) face;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: destination.key,
    child: RawButton(
      onPressed: onPressed,
      selected: chosen,
      semanticSelected: chosen,
      semanticLabel: destination.label,
      excludeSemantics: true,
      builder: (context, states, _) => face(states),
    ),
  );
}

// A shell-built rail's or sidebar's: the shell chooses.
void _ignore(int _) {}

// Chrome words grow with the reader's text only so far (1.3x), as a
// platform's bars do: past that they would crowd out the glyphs they name.
Widget _clamped(Widget child) =>
    MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child);

/// The bottom bar's chrome round its [places], [action] in its last cell.
Widget _barFrame(BuildContext context, List<Widget> places, Widget? action) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  return _clamped(
    GlossBar(
      edge: AxisDirection.up,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: GlossNavigationBar.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final place in places) Expanded(child: place),
              if (action != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: GlossSpacing.small,
                    end: GlossSpacing.regular,
                  ),
                  child: Center(child: action),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The rail's chrome round its [places], [leading] above them.
Widget _railFrame(BuildContext context, List<Widget> places, Widget? leading) {
  final top = MediaQuery.paddingOf(context).top;
  return _clamped(
    GlossBar(
      edge: AxisDirection.right,
      child: SizedBox(
        width: GlossNavigationRail.width,
        child: Padding(
          padding: EdgeInsets.only(top: top + GlossSpacing.medium),
          child: Column(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(height: GlossSpacing.large),
              ],
              for (final place in places) SizedBox(height: 72, child: place),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The sidebar's panel round its [places], [header] above, [footer] at
/// its foot.
Widget _sideFrame(
  BuildContext context,
  List<Widget> places,
  Widget? header,
  Widget? footer,
) {
  final theme = GlossTheme.of(context);
  final top = MediaQuery.paddingOf(context).top;
  return GlossBar(
    edge: AxisDirection.right,
    child: SizedBox(
      width: GlossSidebar.width,
      child: Padding(
        // A head starts in the top bar's band (GlossTopBar.height); without
        // one the places start a margin down.
        padding: EdgeInsets.fromLTRB(
          GlossSpacing.medium,
          top + (header == null ? GlossSpacing.regular : 0),
          GlossSpacing.medium,
          GlossSpacing.regular,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: GlossSpacing.medium,
                  bottom: GlossSpacing.large,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: GlossTopBar.height,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DefaultTextStyle(
                      style: glossLetterpress(
                        theme.textTheme.title,
                        theme.colors,
                      ),
                      child: header,
                    ),
                  ),
                ),
              ),
            for (final place in places)
              Padding(
                padding: const EdgeInsets.only(bottom: GlossSpacing.tight),
                child: place,
              ),
            const Spacer(),
            ?footer,
          ],
        ),
      ),
    ),
  );
}

/// A Gloss bottom bar: the grained chrome along a phone's foot, one place
/// per slot; the current place sits in a pocket pressed into the bar.
///
/// ```dart
/// GlossNavigationBar(destinations: const [GlossDestination(icon: LucideIcons.house, label: 'Today'), GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class GlossNavigationBar extends StatelessWidget {
  /// A bar over [destinations], [selectedIndex] current.
  const GlossNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.style,
  });

  /// The places.
  final List<GlossDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The app's one act, a gel bead standing in the bar's last cell, in
  /// reach of the thumb.
  final Widget? action;

  /// This bar's own style, over [GlossThemeData.navigationStyle].
  final GlossStyle? style;

  /// The bar's height, past the safe area.
  static const double height = 68;

  @override
  Widget build(BuildContext context) => _barFrame(context, [
    for (final (i, d) in destinations.indexed)
      _Place(
        destination: d,
        chosen: i == selectedIndex,
        onPressed: () => onDestinationSelected(i),
        face: (states) =>
            _PocketFace(destination: d, states: states, style: style),
      ),
  ], action);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A Gloss rail: the grained chrome down a tablet's start side, the places
/// stacked, the current one in a pocket pressed into it.
///
/// ```dart
/// GlossNavigationRail(destinations: const [GlossDestination(icon: LucideIcons.house, label: 'Today'), GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class GlossNavigationRail extends StatelessWidget {
  /// A rail over [destinations], [selectedIndex] current.
  const GlossNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
    this.style,
  }) : _places = null;

  // A rail round places ui_core's shell presses ([GlossAppShell]).
  const GlossNavigationRail._shell(
    this._places, {
    required this.selectedIndex,
    this.leading,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<GlossDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// Something above the places: the app's mark.
  final Widget? leading;

  /// This rail's own style, over [GlossThemeData.navigationStyle].
  final GlossStyle? style;

  /// The rail's width.
  static const double width = 88;

  @override
  Widget build(BuildContext context) => _railFrame(
    context,
    _places ??
        [
          for (final (i, d) in destinations.indexed)
            _Place(
              destination: d,
              chosen: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              face: (states) =>
                  _PocketFace(destination: d, states: states, style: style),
            ),
        ],
    leading,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// A Gloss sidebar: a grained panel down a desktop's start side, the places
/// as rows; the current one stands on a pearl plate raised from the panel,
/// its glyph jade. A pointer over a row shades it a breath.
///
/// ```dart
/// GlossSidebar(destinations: const [GlossDestination(icon: LucideIcons.house, label: 'Today'), GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes')], selectedIndex: 0, onDestinationSelected: (index) {})
/// ```
class GlossSidebar extends StatelessWidget {
  /// A sidebar over [destinations], [selectedIndex] current.
  const GlossSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
    this.style,
  }) : _places = null;

  // A sidebar round places ui_core's shell presses ([GlossAppShell]).
  const GlossSidebar._shell(
    this._places, {
    required this.selectedIndex,
    this.header,
    this.footer,
  }) : destinations = const [],
       onDestinationSelected = _ignore,
       style = null;

  final List<Widget>? _places;

  /// The places.
  final List<GlossDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// Something above the places: the app's name.
  final Widget? header;

  /// Something at the panel's foot: the account.
  final Widget? footer;

  /// This sidebar's own style, over [GlossThemeData.navigationStyle].
  final GlossStyle? style;

  /// The sidebar's width.
  static const double width = 248;

  @override
  Widget build(BuildContext context) => _sideFrame(
    context,
    _places ??
        [
          for (final (i, d) in destinations.indexed)
            _Place(
              destination: d,
              chosen: i == selectedIndex,
              onPressed: () => onDestinationSelected(i),
              face: (states) =>
                  _SideFace(destination: d, states: states, style: style),
            ),
        ],
    header,
    footer,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

/// An app's frame in Gloss: its places along a phone's foot in the grained
/// bottom bar, down a tablet's start side in the rail from 600 wide, and in
/// the sidebar from 1024, each place keeping its own stack of pages (as
/// Material's `NavigationBar`, `NavigationRail` and `NavigationDrawer`
/// round a `Scaffold`). The current place sits in a pocket pressed into the
/// bar or the rail, on a pearl plate in the sidebar. The app's one act
/// ([action], a [GlossActKey]) is a jade gel key in the chrome, never over
/// the page: the bar's last cell on a phone, under [header] (the app's
/// [GlossBrand]) atop the rail and the sidebar. [footer] stands at the
/// sidebar's foot (the account).
///
/// Built on ui_core's [RawAdaptiveShell] at every width, the phone's bar
/// included: the places are one tab stop, the arrows move along them, F6
/// moves between them and the page, and a screen reader hears each as a tab
/// ("Books, Tab 1 of 3"), the act a button of its own beside the tabs. A
/// page pushed in a place keeps the rail or the sidebar beside it while the
/// bar steps away ([hideBarOnPush]); back pops the place's own stack. Toasts
/// keep clear of the bar and centre on the page beside a rail or a sidebar.
///
/// Each of [destinations] opens its root page from [branches], in order; a
/// page pushes in its own place with `Navigator.of(context).push`, and one
/// pushed on the app's root navigator covers the whole frame. An app on a
/// router that keeps each place's navigator itself (go_router's
/// `StatefulShellRoute`) uses [GlossAppShell.router].
///
/// ```dart
/// GlossAppShell(header: const GlossBrand('Shelf'), destinations: const [RawNavigationDestination(label: 'Books', icon: LucideIcons.bookOpen), RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings)], branches: [(context) => const Text('Books'), (context) => const Text('Settings')])
/// ```
class GlossAppShell extends StatefulWidget {
  /// A frame over [destinations], each opening its page from [branches].
  const GlossAppShell({
    super.key,
    required this.destinations,
    required List<WidgetBuilder> this.branches,
    this.selectedIndex,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.action,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
  }) : body = null,
       showBar = true,
       assert(
         destinations.length == branches.length,
         'Each place has its root page.',
       );

  /// A frame round [body], the page a router shows for the place at
  /// [selectedIndex]: the router keeps each place's pages (go_router's
  /// `StatefulNavigationShell`), and [onDestinationSelected] asks it for
  /// another place. With [showBar] false a phone's bar steps away (a page
  /// pushed over a place's root); a rail or a sidebar stays.
  ///
  /// ```dart
  /// GlossAppShell.router(destinations: const [RawNavigationDestination(label: 'Books', icon: LucideIcons.bookOpen), RawNavigationDestination(label: 'Settings', icon: LucideIcons.settings)], selectedIndex: 0, onDestinationSelected: (index) {}, body: const Text('Books'))
  /// ```
  const GlossAppShell.router({
    super.key,
    required this.destinations,
    required Widget this.body,
    required int this.selectedIndex,
    required ValueChanged<int> this.onDestinationSelected,
    this.header,
    this.footer,
    this.action,
    this.showBar = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// The app's places, two to five, in order. A place whose
  /// [RawNavigationDestination.data] is a [Key] carries it on its cell.
  final List<RawNavigationDestination> destinations;

  /// Each place's root page, in [destinations]' order; null in
  /// [GlossAppShell.router].
  final List<WidgetBuilder>? branches;

  /// The router's page for the current place; null in the branches form.
  final Widget? body;

  /// The place shown, when the page keeps it; null: the frame keeps its own,
  /// starting at the first.
  final int? selectedIndex;

  /// Called with the place chosen (the one shown again included, which pops
  /// it to its root).
  final ValueChanged<int>? onDestinationSelected;

  /// What heads the rail and the sidebar: the app's [GlossBrand].
  final Widget? header;

  /// What stands at the sidebar's foot: the account, say.
  final Widget? footer;

  /// The app's one act, a [GlossActKey]: in a phone's bar, its last cell;
  /// atop the rail and the sidebar, under [header].
  final Widget? action;

  /// The places' navigators' keys, to push in a place from outside (a
  /// notification opening a record); null: the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place at its root page.
  final RawBranchBackBehavior backBehavior;

  /// Whether a phone's bar steps away while a page is pushed over a place's
  /// root (a rail or a sidebar stays). False keeps the bar under pushed
  /// pages, as Cupertino's tab scaffold does.
  final bool hideBarOnPush;

  /// In [GlossAppShell.router], whether a phone's bar stands.
  final bool showBar;

  @override
  State<GlossAppShell> createState() => _GlossAppShellState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>('destinations', [
          for (final d in destinations) d.label,
        ]),
      )
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
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
          ifFalse: 'bar kept under pushed pages',
        ),
      )
      ..add(FlagProperty('showBar', value: showBar, ifFalse: 'bar hidden'));
  }
}

class _GlossAppShellState extends State<GlossAppShell> {
  int _own = 0;

  int get _selected => widget.selectedIndex ?? _own;

  void _select(int index) {
    if (widget.selectedIndex == null) setState(() => _own = index);
    widget.onDestinationSelected?.call(index);
  }

  // Gloss's own widths: the rail from 600, the sidebar from 1024, a little
  // before ui_core's 1200, where a desk's window has room for it.
  static RawNavigationMode _modeFor(double width) =>
      width < GlossMetrics.railBreakpoint
      ? RawNavigationMode.bar
      : width < GlossMetrics.sidebarBreakpoint
      ? RawNavigationMode.rail
      : RawNavigationMode.sidebar;

  Widget _place(
    BuildContext context,
    RawNavigationDestination destination,
    RawDestinationDetails details,
  ) {
    final d = GlossDestination(
      icon: destination.icon,
      selectedIcon: destination.selectedIcon,
      label: destination.label,
    );
    final key = destination.data;
    return KeyedSubtree(
      key: key is Key ? key : null,
      child: details.mode == RawNavigationMode.sidebar
          ? _SideFace(destination: d, states: details.states, style: null)
          : _PocketFace(destination: d, states: details.states, style: null),
    );
  }

  // The brand, and the act under it, atop a rail or a sidebar.
  Widget? _head(bool wide) {
    final act = widget.action;
    if (act == null) return widget.header;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ?widget.header,
        // In a sidebar the act stands on the start line the name and the
        // places' glyphs keep, a gap under the name's band.
        Padding(
          padding: EdgeInsets.only(
            top: wide && widget.header != null
                ? GlossSpacing.large
                : GlossSpacing.small,
            bottom: GlossSpacing.small,
          ),
          child: act,
        ),
      ],
    );
  }

  Widget _navigation(BuildContext context, RawNavigationDetails details) =>
      switch (details.mode) {
        RawNavigationMode.sidebar => GlossSidebar._shell(
          details.destinations,
          selectedIndex: details.selectedIndex,
          header: _head(true),
          footer: widget.footer,
        ),
        RawNavigationMode.rail => GlossNavigationRail._shell(
          details.destinations,
          selectedIndex: details.selectedIndex,
          leading: _head(false),
        ),
        // The bar: the places as the tab bar, the act in a cell of its own
        // beside them, outside the tabs.
        _ => _barFrame(context, [
          details.group(
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in details.destinations)
                  Expanded(child: place),
              ],
            ),
          ),
        ], widget.action),
      };

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final branches = widget.branches;
    final shell = branches == null
        ? RawAdaptiveShell(
            destinations: widget.destinations,
            selectedIndex: _selected,
            onDestinationSelected: _select,
            modeForWidth: _modeFor,
            showNavigation: widget.showBar,
            destinationBuilder: _place,
            navigationBuilder: _navigation,
            body: widget.body!,
          )
        : RawAdaptiveShell.branches(
            destinations: widget.destinations,
            branches: branches,
            navigatorKeys: widget.navigatorKeys,
            backBehavior: widget.backBehavior,
            hideBarOnPush: widget.hideBarOnPush,
            selectedIndex: _selected,
            onDestinationSelected: _select,
            modeForWidth: _modeFor,
            destinationBuilder: _place,
            navigationBuilder: _navigation,
          );
    return ColoredBox(color: theme.colors.page, child: shell);
  }
}

/// The app's name at the head of its places, letterpressed: in the title
/// type where it fits (a sidebar), its first letter where it does not (a
/// rail). A screen reader hears the name once, as a heading.
///
/// ```dart
/// const GlossBrand('Shelf')
/// ```
class GlossBrand extends StatelessWidget {
  /// The app's [name].
  const GlossBrand(this.name, {super.key});

  /// The app's name.
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        final style = glossLetterpress(theme.textTheme.title, theme.colors);
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            // Narrow, atop a rail, its initial is centred.
            child: narrow
                ? Padding(
                    padding: const EdgeInsets.all(GlossSpacing.regular),
                    child: Text(
                      name.isEmpty ? name : name.characters.first.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  )
                // Wide, atop a sidebar, the name stands in the top bar's band
                // with its capitals centred as the bar's title's are, so the
                // two share a line, and on the start line of the places'
                // glyphs. Like the bar's title it grows up to 1.5x.
                : SizedBox(
                    height: GlossTopBar.height,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RawCapCenter(
                        capHeightFactor: glossCapHeightFactor,
                        child: Text(
                          name,
                          textScaler: MediaQuery.textScalerOf(context)
                              .clamp(maxScaleFactor: 1.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
  }
}

/// The app's one act in its [GlossAppShell] (add, plan, capture): a jade gel
/// key, the screen's standing invitation; with [accent] off a pearl one. In
/// a phone's bar and atop a rail it is a round bead wearing [icon], [label]
/// its tooltip and its name to a screen reader; in a desktop's sidebar a key
/// with its glyph and its words.
///
/// ```dart
/// GlossActKey(icon: LucideIcons.plus, label: 'Add book', onPressed: () {})
/// ```
class GlossActKey extends StatelessWidget {
  /// An act named [label], wearing [icon].
  const GlossActKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent = true,
  });

  /// Its glyph.
  final IconData icon;

  /// Its words: on the sidebar's key, else its tooltip and name.
  final String label;

  /// Called when it is pressed; null puts it out of use.
  final VoidCallback? onPressed;

  /// Whether it is the jade gel (true) or pearl.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= GlossMetrics.sidebarBreakpoint;
    if (wide) {
      final glyph = Icon(icon, size: 18);
      return accent
          ? GlossButton.filled(label, onPressed: onPressed, icon: glyph)
          : GlossButton(label, onPressed: onPressed, icon: glyph);
    }
    return accent
        ? GlossIconButton.filled(
            onPressed: onPressed,
            tooltip: label,
            icon: Icon(icon),
          )
        : GlossIconButton(
            onPressed: onPressed,
            tooltip: label,
            icon: Icon(icon),
          );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('accent', value: accent, ifFalse: 'pearl'));
  }
}

/// A page with its places: a [GlossNavigationBar] under it below 600 px
/// of window, a [GlossNavigationRail] beside it to 1024, a [GlossSidebar]
/// past it; [topBar] over [body] either way.
///
/// From the rail up ui_core's adaptive shell runs the places: they are one
/// tab stop, Up and Down moving along them, Home and End to the ends,
/// Enter or Space choosing; F6 moves focus between them and the page; a
/// screen reader hears each as a tab and its place ("Tab 1 of 3"). A
/// phone's bar is Gloss's own: its last cell holds the app's act, which a
/// tab bar may not; there each place is a stop of its own. With
/// [showNavigation] false a phone's bar steps away (a page pushed over the
/// root); a rail or a sidebar stays.
///
/// ```dart
/// GlossScaffold(topBar: const GlossTopBar(title: 'Today'), destinations: const [GlossDestination(icon: LucideIcons.house, label: 'Today'), GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes')], selectedIndex: 0, onDestinationSelected: (index) {}, body: const SizedBox.expand())
/// ```
@Deprecated(
  'Use GlossAppShell, which keeps each place\'s pages, with a GlossScreen '
  '(its topBar) per page. Removed in 0.7.0.',
)
class GlossScaffold extends StatelessWidget {
  /// A page of [body].
  const GlossScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.brand,
    this.action,
    this.sideFooter,
    this.showNavigation = true,
  });

  /// The page.
  final Widget body;

  /// The bar over the page.
  final Widget? topBar;

  /// The app's places; none shows when empty.
  final List<GlossDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int>? onDestinationSelected;

  /// The app's name or mark, atop a rail or a sidebar.
  final Widget? brand;

  /// The app's one act: the bottom bar's last cell on a phone, under
  /// [brand] at the head of the rail or the sidebar.
  final Widget? action;

  /// The sidebar's foot.
  final Widget? sideFooter;

  /// Whether a phone's bar stands: false while a page pushed over the root
  /// covers it (a rail or a sidebar stays).
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final places = destinations.isNotEmpty && onDestinationSelected != null;
    final phone = width < GlossMetrics.railBreakpoint;
    final bar = places && phone && showNavigation;
    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?topBar,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: topBar != null,
            removeBottom: bar,
            // A semantics node of its own: a navigator in the body (a
            // list-and-detail pane) blocks only the body's semantics under
            // its pages, never the bar, rail or sidebar beside it. Its
            // children keep nodes of their own: a route's node there forms
            // only when a list opens over it otherwise, and on the web that
            // moves the field's input and blurs the tap's focus.
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: body,
            ),
          ),
        ),
      ],
    );
    if (!places || phone) {
      return ColoredBox(
        color: theme.colors.page,
        child: !bar
            ? page
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: page),
                  // Toasts stand above the places, as a Scaffold keeps a
                  // snackbar above its navigation bar.
                  RawToasterKeepClear(
                    child: GlossNavigationBar(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected!,
                      action: action,
                    ),
                  ),
                ],
              ),
      );
    }
    // Gloss's own widths: its sidebar opens from 1024, a little before
    // ui_core's 1200, where a desk's window has room for it.
    final wide = width >= GlossMetrics.sidebarBreakpoint;
    return ColoredBox(
      color: theme.colors.page,
      child: RawAdaptiveShell(
        mode: wide ? RawNavigationMode.sidebar : RawNavigationMode.rail,
        destinations: [
          for (final d in destinations)
            RawNavigationDestination(
              label: d.label,
              icon: d.icon,
              selectedIcon: d.selectedIcon,
              data: d,
            ),
        ],
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinationBuilder: (context, destination, details) {
          final d = destination.data! as GlossDestination;
          return KeyedSubtree(
            key: d.key,
            child: details.mode == RawNavigationMode.sidebar
                ? _SideFace(destination: d, states: details.states, style: null)
                : _PocketFace(
                    destination: d,
                    states: details.states,
                    style: null,
                  ),
          );
        },
        navigationBuilder: (context, details) => wide
            ? GlossSidebar._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                header: _head(true),
                footer: sideFooter,
              )
            : GlossNavigationRail._shell(
                details.destinations,
                selectedIndex: details.selectedIndex,
                leading: _head(false),
              ),
        body: page,
      ),
    );
  }

  // The brand, and the act under it, atop a rail or a sidebar.
  Widget? _head(bool wide) {
    final act = action;
    if (act == null) return brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ?brand,
        // In a sidebar the act stands on the start line the name and the
        // places' glyphs keep, a gap under the name's band.
        Padding(
          padding: EdgeInsets.only(
            top: wide && brand != null
                ? GlossSpacing.large
                : GlossSpacing.small,
            bottom: GlossSpacing.small,
          ),
          child: act,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'destinations',
          destinations.map((d) => d.label),
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
        ),
      );
  }
}

/// Gloss's tabs: a capsule trough pressed into the surface with equal
/// slots, and a pearl thumb that slides to the current tab on a spring.
/// ui_core's tab bar runs them: one tab stop, Left and Right (mirrored in
/// right to left), Home and End move between tabs, and a screen reader hears
/// "Method, Tab 2 of 2".
///
/// ```dart
/// GlossTabBar(tabs: const ['Ingredients', 'Method'], selectedIndex: 0, onTap: (index) {})
/// ```
class GlossTabBar extends StatefulWidget {
  /// Tabs reading [tabs], [selectedIndex] current.
  const GlossTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.expand,
    this.style,
  });

  /// The tabs' words.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// Called with the tab chosen.
  final ValueChanged<int> onTap;

  /// Whether it fills its row; null fills below 600 px and hugs above.
  final bool? expand;

  /// This bar's own style, over [GlossThemeData.tabBarStyle].
  final GlossStyle? style;

  @override
  State<GlossTabBar> createState() => _GlossTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex));
  }
}

class _GlossTabBarState extends State<GlossTabBar>
    with TickerProviderStateMixin {
  late RawTabController _tabs = _controller();

  // The tab last reported (or given): a choice is reported once, even while
  // the thumb's spring runs on and the parent has not chosen it yet.
  late int _reported = widget.selectedIndex;

  // The thumb's spring is Gloss's (a little give as it lands).
  RawTabController _controller() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.selectedIndex,
    vsync: this,
    dampingRatio: 0.8,
    stiffness: 600,
  )..addListener(_chosen);

  void _chosen() {
    if (_tabs.index == _reported) return;
    _reported = _tabs.index;
    widget.onTap(_tabs.index);
  }

  @override
  void didUpdateWidget(GlossTabBar old) {
    super.didUpdateWidget(old);
    _reported = widget.selectedIndex;
    if (old.tabs.length != widget.tabs.length) {
      _tabs.dispose();
      _tabs = _controller();
    } else if (_tabs.index != widget.selectedIndex) {
      _tabs.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // A tab's words grow with the reader's text up to 1.5x: past that two tabs no longer share a phone's width.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.5,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final tabs = widget.tabs;
    assert(tabs.length >= 2, 'A tab bar has two tabs or more.');
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final fill = widget.expand ?? MediaQuery.sizeOf(context).width < 600;
    final height = theme.controlHeight - 4;
    final label = theme.textTheme.label.copyWith(fontSize: 15);
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var widest = 0.0;
    for (final t in tabs) {
      painter
        ..text = TextSpan(text: t, style: label)
        ..layout();
      widest = math.max(widest, painter.width);
    }
    painter.dispose();
    final slot =
        widest * MediaQuery.textScalerOf(context).scale(1) +
        2 * GlossSpacing.large;
    const inset = 3.0;
    return LayoutBuilder(
      builder: (context, box) {
        final width = fill && box.hasBoundedWidth
            ? box.maxWidth
            : math.min(
                slot * tabs.length + 2 * inset,
                box.hasBoundedWidth ? box.maxWidth : double.infinity,
              );
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: GlossSurface(face: GlossFace.well(c))),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(inset),
                    child: RawTabBar(
                      controller: _tabs,
                      tabs: [for (final t in tabs) RawTab(label: t)],
                      indicatorBuilder: (context, details) => GlossSurface(
                        face: GlossFace.pearl(c).copyWith(lift: 0.75),
                      ),
                      tabBuilder: (context, tab, details) =>
                          _tab(context, tab, details, height - 2 * inset),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tab(
    BuildContext context,
    RawTab tab,
    RawTabDetails details,
    double height,
  ) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final label = theme.textTheme.label.copyWith(fontSize: 15);
    final chosen = details.selection >= 0.5;
    final layered = RawStyleOf(
      [widget.style, theme.tabBarStyle],
      {...details.states, if (chosen) WidgetState.selected},
    );
    final weight = chosen ? FontWeight.w700 : FontWeight.w600;
    return TapTargetPadding(
      child: SizedBox(
        height: height,
        child: GlossGlazeHighlight(
          focused: details.states.contains(WidgetState.focused),
          hovered: details.states.contains(WidgetState.hovered),
          pressed: details.states.contains(WidgetState.pressed),
          inside: true,
          corners: glossCornersOf(
            theme,
            layered,
            RawCorner.full,
            Directionality.of(context),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlossSpacing.small,
              ),
              // Too long for its tab at a large size: a little smaller, never
              // cut.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RawCapCenter(
                  capHeightFactor: glossCapHeightFactor,
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: label
                        .copyWith(
                          color:
                              layered.foreground ??
                              (chosen ? c.ink : c.inkSecondary),
                          fontWeight: weight,
                          fontVariations: glossWeightAxis(weight),
                        )
                        .merge(layered.textStyle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
