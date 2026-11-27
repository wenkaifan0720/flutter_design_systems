/// Appliance's frame: [ApplianceAppBar] (a moulded top bar), the three ways
/// round an app by width ([ApplianceNavigationBar], a strip of keys under a
/// phone's screen; [ApplianceNavigationRail], a column of keys down a
/// tablet's side; [ApplianceSideNavigation], a moulded side panel on a
/// desktop, a lamp beside every place), [ApplianceScaffold], which picks
/// one, and [ApplianceScreen], a page on the housing. The current place is
/// always a latched key with its lamp lit, never a tint.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'actions.dart';
import 'button.dart';
import 'material.dart';
import 'theme.dart';

Color _none(Color c) => c.withValues(alpha: 0);

/// The widest a page's content stands, inside its margins.
const double _pageWidth = 1200;

/// A top bar: a strip of the grained housing across the top of a page, its
/// parting line under it. A [title] (17 px), a way back at its start when
/// [onBack] is given (a square key), and [actions] at its end (square keys:
/// [ApplianceIconButton]). Its height is 56 plus the status bar's.
///
/// ```dart
/// ApplianceAppBar(title: 'Basket', onBack: () => Navigator.pop(context), actions: [ApplianceIconButton(icon: const Icon(LucideIcons.search), semanticLabel: 'Search', onPressed: () {})])
/// ```
class ApplianceAppBar extends StatelessWidget {
  /// A top bar.
  const ApplianceAppBar({
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

  /// Goes back; null: no way back.
  final VoidCallback? onBack;

  /// What stands at its start in place of the way back (a brand).
  final Widget? leading;

  /// The keys at its end.
  final List<Widget> actions;

  /// What stands under the title row, on the same housing (a search field,
  /// a selector).
  final Widget? bottom;

  /// Its style: `fill` (the housing's tint), `foreground` and `textStyle`
  /// (the title), `padding`.
  final ApplianceStyle? style;

  /// The bar's row height.
  static const double height = 56;

  // The bar's keys: 40 square, the way back's size, so a key the app puts
  // at the bar's end stands as the one at its start does.
  static const RawStyle _barKey = RawStyle(
    minimumSize: WidgetStatePropertyAll(Size.square(40)),
  );

  /// The way back as [ApplianceAppBar] draws it, for a bar of your own.
  ///
  /// ```dart
  /// ApplianceAppBar.backKey(context, () => Navigator.pop(context))
  /// ```
  static Widget backKey(BuildContext context, VoidCallback onBack) =>
      ApplianceIconButton(
        icon: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: const Icon(LucideIcons.arrowLeft),
        ),
        semanticLabel: RawWidgetsLocalizations.of(context).backButtonTooltip,
        onPressed: onBack,
        style: _barKey,
      );

  /// The close key a sheet's bar wears, for a bar of your own.
  ///
  /// ```dart
  /// ApplianceAppBar.closeKey(context, () => Navigator.pop(context))
  /// ```
  static Widget closeKey(BuildContext context, VoidCallback onClose) =>
      ApplianceIconButton(
        icon: const Icon(LucideIcons.x),
        semanticLabel: RawWidgetsLocalizations.of(context).closeButtonLabel,
        onPressed: onClose,
        style: _barKey,
      );

  /// The route's own way out, by how it stands ([RoutePresentation]): the
  /// way back on a pushed page, the close key on a sheet, nothing on a
  /// place. [key] goes on its hit target.
  ///
  /// ```dart
  /// ApplianceAppBar(title: 'Order', leading: ApplianceAppBar.autoLeading(context, key: const ValueKey('back')))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final presentation = RoutePresentation.of(context);
    if (presentation == RoutePresentation.root) return null;
    void leave() => Navigator.of(context).maybePop();
    return KeyedSubtree(
      key: key,
      child: presentation == RoutePresentation.sheet
          ? closeKey(context, leave)
          : backKey(context, leave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final layered = RawStyleOf([style], const {});
    final media = MediaQuery.of(context);
    final margin = ApplianceSpacing.pageMargin(media.size.width);
    final start = onBack != null ? backKey(context, onBack!) : leading;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ApplianceHousing(
        seam: AxisDirection.down,
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              EdgeInsets.fromLTRB(
                margin,
                media.padding.top,
                margin,
                ApplianceMetrics.seamWidth,
              ),
          // On an ApplianceScreen's measure: the title starts where the
          // body does, the actions end where it ends.
          child: _onMeasure(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: height,
                  child: Row(
                    children: [
                      if (start != null) ...[
                        start,
                        const SizedBox(width: ApplianceSpacing.medium),
                      ],
                      Expanded(
                        child: title == null
                            ? const SizedBox()
                            : Semantics(
                                header: true,
                                child: RawCapCenter(
                                  capHeightFactor: theme.capHeightFactor,
                                  child: Text(
                                    title!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: layered.text(
                                      theme.textTheme.heading.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: layered.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      if (actions.isNotEmpty)
                        // An icon key at the end stands as the way back
                        // does, unless the app's theme sizes its icon keys.
                        ApplianceTheme(
                          data: theme.copyWith(
                            iconButtonStyle:
                                (theme.iconButtonStyle ?? const RawStyle())
                                    .merge(_barKey),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final (i, action) in actions.indexed) ...[
                                if (i > 0)
                                  const SizedBox(width: ApplianceSpacing.small),
                                action,
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: ApplianceSpacing.medium,
                    ),
                    child: bottom,
                  ),
              ],
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
      ..add(FlagProperty('back', value: onBack != null, ifTrue: 'back'))
      ..add(IntProperty('actions', actions.length));
  }
}

/// One place an app's navigation goes to.
@immutable
class ApplianceDestination {
  /// The place called [label], marked by [icon].
  const ApplianceDestination({
    required this.icon,
    required this.label,
    this.badge,
    this.key,
  });

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// A short figure beside it (a basket's count), in a small display
  /// window; null: none.
  final String? badge;

  /// The key on its hit target (a test finds and presses it by that key).
  final Key? key;
}

void _ignore(int _) {}

/// A navigation key's face: raised, or latched down when current.
ApplianceFace _navFace(
  ApplianceThemeData theme,
  Set<WidgetState> states,
  bool current,
  double radius,
) {
  final c = theme.colors;
  final down = current || states.contains(WidgetState.pressed);
  return (down
          ? ApplianceFace.keyDown(c, radius: radius)
          : ApplianceFace.key(c, radius: radius))
      .copyWith(
        foreground: current ? c.print : c.printMuted,
        focus: states.contains(WidgetState.focused) ? c.focus : _none(c.focus),
      );
}

/// A small display window holding a short figure (a count): smoked glass,
/// the figure lit.
class ApplianceBadge extends StatelessWidget {
  /// A window showing [text].
  const ApplianceBadge(this.text, {super.key, this.style});

  /// The figure.
  final String text;

  /// Its style, over [ApplianceThemeData.tagStyle]: fill, foreground.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).tagStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return ApplianceSurface(
      face: ApplianceFace.well(c, fill: look.fill ?? c.display, radius: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApplianceMetrics.windowInset,
        ),
        child: Text(
          text,
          style: theme.textTheme.figure.copyWith(
            fontSize: 12,
            height: 16 / 12,
            color: look.foreground ?? c.onDisplay,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

// A destination's icon with its count (if any) riding on its top end
// corner, said to a screen reader by the key's own name.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({
    required this.icon,
    required this.size,
    required this.color,
    this.badge,
  });

  /// The destination's glyph.
  final IconData icon;

  /// The glyph's size.
  final double size;

  /// The glyph's colour.
  final Color color;

  /// The count riding on its corner, if any.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: size, color: color);
    final count = badge;
    if (count == null) return glyph;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        glyph,
        PositionedDirectional(
          top: -ApplianceSpacing.tight,
          start: size - ApplianceSpacing.tight,
          child: ExcludeSemantics(child: ApplianceBadge(count)),
        ),
      ],
    );
  }
}

/// A phone's way round: a strip of keys on the housing under the screen,
/// one per place, each its glyph over its name. The current place is
/// latched down with its lamp lit.
///
/// Reads [style]'s `fill`, `foreground` and `textStyle` per key in its
/// states, then [ApplianceThemeData.navigationStyle]'s.
///
/// ```dart
/// ApplianceNavigationBar(destinations: const [ApplianceDestination(icon: LucideIcons.house, label: 'Home'), ApplianceDestination(icon: LucideIcons.shoppingBasket, label: 'Basket')], selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class ApplianceNavigationBar extends StatelessWidget {
  /// A key strip over [destinations].
  const ApplianceNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.trailing,
    this.style,
  }) : _keys = null,
       _group = null;

  // The strip of ApplianceScaffold's shell, round the keys ui_core built.
  const ApplianceNavigationBar._shell({
    required List<Widget> this._keys,
    required this.destinations,
    required Widget Function(Widget keys) this._group,
    this.trailing,
  }) : selectedIndex = 0,
       onSelected = _ignore,
       style = null;

  final List<Widget>? _keys;

  final Widget Function(Widget keys)? _group;

  /// The places.
  final List<ApplianceDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands at the strip's end, after the places (the app's act).
  final Widget? trailing;

  /// Its style, over [ApplianceThemeData.navigationStyle].
  final ApplianceStyle? style;

  /// A key's height.
  static const double keyHeight = 52;

  @override
  Widget build(BuildContext context) {
    final layers = [style, ApplianceTheme.of(context).navigationStyle];
    final keys = _keys;
    if (keys != null) {
      return _barFrame(
        context,
        keys,
        minWidth: _navigationKeyWidth(context, destinations, layers),
        trailing: trailing,
        group: _group,
      );
    }
    return _barFrame(
      context,
      [
        for (final (i, d) in destinations.indexed)
          _NavKey(
            destination: d,
            current: i == selectedIndex,
            onPressed: () => onSelected(i),
            layers: layers,
            builder: (context, face, layered) =>
                _stackedKey(context, d, i == selectedIndex, face, layered),
          ),
      ],
      minWidth: _navigationKeyWidth(context, destinations, layers),
      trailing: trailing,
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

/// The app's act as a key: square in the strip and on the rail, a wide
/// key with its name in the side panel; the signal key when it is the
/// app's invitation.
class _ActKey extends StatelessWidget {
  const _ActKey({required this.action, this.wide = false});

  final ApplianceShellAction action;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final label = action.label;
    void press() => action.onPressed(context);
    if (wide && label != null && label.isNotEmpty) {
      final icon = Icon(action.icon);
      return KeyedSubtree(
        key: action.key,
        child: action.accent
            ? ApplianceButton.filled(label, icon: icon, onPressed: press)
            : ApplianceButton(label, icon: icon, onPressed: press),
      );
    }
    final theme = ApplianceTheme.of(context);
    return KeyedSubtree(
      key: action.key,
      child: RawButton(
        onPressed: press,
        semanticLabel: label,
        excludeSemantics: true,
        builder: (context, states, _) {
          final face = applianceKeyFace(
            theme.colors,
            filled: action.accent,
            down: states.contains(WidgetState.pressed),
            focused: states.contains(WidgetState.focused),
            radius: theme.radiusKey,
          );
          return TapTargetPadding(
            child: SizedBox(
              width: 64,
              height: ApplianceNavigationBar.keyHeight,
              child: AnimatedApplianceSurface(
                face: face,
                child: Center(
                  child: Icon(action.icon, size: 22, color: face.foreground),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef _KeyContent = Widget Function(
  BuildContext context,
  ApplianceFace face,
  RawStyleOf layered,
);

class _NavKey extends StatelessWidget {
  const _NavKey({
    required this.destination,
    required this.current,
    required this.onPressed,
    required this.layers,
    required this.builder,
  });

  final ApplianceDestination destination;
  final bool current;
  final VoidCallback onPressed;
  final List<ApplianceStyle?> layers;
  final _KeyContent builder;

  @override
  Widget build(BuildContext context) {
    final badge = destination.badge;
    return KeyedSubtree(
      key: destination.key,
      child: RawButton(
        onPressed: onPressed,
        selected: current,
        semanticSelected: current,
        semanticLabel: badge == null
            ? destination.label
            : '${destination.label}, $badge',
        excludeSemantics: true,
        builder: (context, states, _) =>
            _navKeyPaint(context, states, current, layers, builder),
      ),
    );
  }
}

/// A navigation key in [states]: raised, or latched down when [current],
/// round [content].
Widget _navKeyPaint(
  BuildContext context,
  Set<WidgetState> states,
  bool current,
  List<ApplianceStyle?> layers,
  _KeyContent content,
) {
  final theme = ApplianceTheme.of(context);
  final layered = RawStyleOf(layers, {
    ...states,
    if (current) WidgetState.selected,
  });
  final face = layered.on(_navFace(theme, states, current, theme.radiusKey));
  return TapTargetPadding(
    child: AnimatedApplianceSurface(
      face: face,
      child: content(context, face, layered),
    ),
  );
}

TextStyle _navLabel(BuildContext context, RawStyleOf style) => style.text(
  ApplianceTheme.of(context).textTheme.secondary
      .copyWith(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
);

double _navigationKeyWidth(
  BuildContext context,
  List<ApplianceDestination> destinations,
  List<ApplianceStyle?> layers,
) {
  var width = 48.0;
  for (final states in [
    <WidgetState>{},
    {WidgetState.selected},
  ]) {
    final label = _navLabel(context, RawStyleOf(layers, states));
    // Measured as the keys set their names: at most 1.3x.
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _navigationTextScale);
    for (final d in destinations) {
      final painter = TextPainter(
        text: TextSpan(text: d.label, style: label),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      width = math.max(width, painter.width.ceilToDouble() + 8);
      painter.dispose();
    }
  }
  return width;
}

/// A strip's or a rail's key: its glyph over its name, its lamp in its
/// corner.
Widget _stackedKey(
  BuildContext context,
  ApplianceDestination d,
  bool current,
  ApplianceFace face,
  RawStyleOf layered, {
  bool rail = false,
}) {
  final name = Text(
    d.label,
    textAlign: TextAlign.center,
    style: _navLabel(context, layered).copyWith(color: face.foreground),
  );
  // A key's name and badge grow with the text up to 1.3x, as Material's
  // navigation bar labels do, so the name keeps its words whole and the
  // badge stays on its glyph.
  return MediaQuery.withClampedTextScaling(
    maxScaleFactor: _navigationTextScale,
    child: _stackedFace(context, d, current, face, layered, name, rail: rail),
  );
}

/// How far a strip's or a rail's key lets its words grow.
const double _navigationTextScale = 1.3;

Widget _stackedFace(
  BuildContext context,
  ApplianceDestination d,
  bool current,
  ApplianceFace face,
  RawStyleOf layered,
  Widget name, {
  required bool rail,
}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: rail ? 60 : ApplianceNavigationBar.keyHeight,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgedIcon(
                icon: d.icon,
                size: layered.iconSize ?? 20,
                color: face.foreground,
                badge: d.badge,
              ),
              const SizedBox(height: ApplianceSpacing.tight),
              if (rail)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.tight,
                  ),
                  child: name,
                )
              else
                name,
            ],
          ),
        ),
        PositionedDirectional(
          top: ApplianceMetrics.lampInset,
          start: ApplianceMetrics.lampInset,
          child: ApplianceLamp(
            lit: current,
            size: ApplianceMetrics.lampSize - 1,
          ),
        ),
      ],
    ),
  );
}

/// A side panel's row key: its lamp, its glyph, its name and its badge.
Widget _rowKey(
  BuildContext context,
  ApplianceDestination d,
  bool current,
  ApplianceFace face,
  RawStyleOf layered,
) {
  final theme = ApplianceTheme.of(context);
  return SizedBox(
    height: 44,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: ApplianceSpacing.medium),
      child: Row(
        children: [
          ApplianceLamp(lit: current),
          const SizedBox(width: ApplianceSpacing.medium),
          Icon(d.icon, size: layered.iconSize ?? 18, color: face.foreground),
          const SizedBox(width: ApplianceSpacing.medium),
          Expanded(
            child: RawCapCenter(
              capHeightFactor: theme.capHeightFactor,
              child: Text(
                d.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: layered.text(
                  theme.textTheme.body.copyWith(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                    color: face.foreground,
                  ),
                ),
              ),
            ),
          ),
          if (d.badge != null)
            ExcludeSemantics(child: ApplianceBadge(d.badge!)),
        ],
      ),
    ),
  );
}

/// A phone's key strip round [keys], sharing its width, [trailing] at its
/// end.
Widget _barFrame(
  BuildContext context,
  List<Widget> keys, {
  required double minWidth,
  Widget? trailing,
  Widget Function(Widget keys)? group,
}) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  return Semantics(
    container: true,
    explicitChildNodes: true,
    child: ApplianceHousing(
      seam: AxisDirection.up,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ApplianceSpacing.small,
          ApplianceSpacing.small + 2,
          ApplianceSpacing.small,
          ApplianceSpacing.small + bottom,
        ),
        child: Row(
          children: [
            if (keys.isNotEmpty)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    const gap = ApplianceSpacing.small;
                    final count = ((box.maxWidth + gap) / (minWidth + gap))
                        .floor()
                        .clamp(1, keys.length);
                    final width = math.max(
                      0.0,
                      (box.maxWidth - gap * (count - 1)) / count,
                    );
                    final strip = Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final key in keys)
                          SizedBox(width: width, child: key),
                      ],
                    );
                    // The shell's tab bar round the places alone: the act
                    // beside them is a button of its own.
                    return group?.call(strip) ?? strip;
                  },
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: ApplianceSpacing.small),
              trailing,
            ],
          ],
        ),
      ),
    ),
  );
}

/// A tablet's rail of [keys] down the housing, [leading] at its top.
Widget _railFrame(
  BuildContext context,
  List<Widget> keys, {
  required double keyWidth,
  Widget? leading,
}) {
  final media = MediaQuery.of(context);
  final availableWidth = math.max(
    ApplianceNavigationRail.width,
    media.size.width / 3,
  );
  final railWidth = (keyWidth + 2 * ApplianceSpacing.medium + 2).clamp(
    ApplianceNavigationRail.width,
    availableWidth,
  );
  return Semantics(
    container: true,
    explicitChildNodes: true,
    child: SizedBox(
      width: railWidth + media.padding.left,
      child: ApplianceHousing(
        seam: AxisDirection.right,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            ApplianceSpacing.medium,
            media.padding.top + ApplianceSpacing.medium,
            ApplianceSpacing.medium + 2,
            ApplianceSpacing.medium,
          ),
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  Center(child: leading),
                  const SizedBox(height: ApplianceSpacing.large),
                ],
                for (final (i, k) in keys.indexed) ...[
                  if (i > 0) const SizedBox(height: ApplianceSpacing.small),
                  k,
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A desk's side panel of [keys], [header] at its top, [legend] over the
/// keys, [footer] at its foot.
Widget _sideFrame(
  BuildContext context,
  List<Widget> keys, {
  Widget? header,
  Widget? act,
  Widget? footer,
  String? legend,
}) {
  final theme = ApplianceTheme.of(context);
  final media = MediaQuery.of(context);
  return Semantics(
    container: true,
    explicitChildNodes: true,
    child: SizedBox(
      width: ApplianceSideNavigation.width + media.padding.left,
      child: ApplianceHousing(
        seam: AxisDirection.right,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            ApplianceSpacing.regular,
            media.padding.top + (header == null ? ApplianceSpacing.large : 0),
            ApplianceSpacing.regular + 2,
            ApplianceSpacing.regular,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                // The brand on the top bar's title line: a band of the
                // bar's height, a one-line brand's capitals on its middle.
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ApplianceAppBar.height,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: RawCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: header,
                    ),
                  ),
                ),
                const SizedBox(height: ApplianceSpacing.medium),
              ],
              if (act != null) ...[
                act,
                const SizedBox(height: ApplianceSpacing.large),
              ],
              if (legend != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: ApplianceSpacing.tight,
                    bottom: ApplianceSpacing.small,
                  ),
                  child: Semantics(
                    header: true,
                    label: legend,
                    excludeSemantics: true,
                    child: Text(
                      legend.toUpperCase(),
                      style: theme.textTheme.legend,
                    ),
                  ),
                ),
              for (final (i, k) in keys.indexed) ...[
                if (i > 0) const SizedBox(height: ApplianceSpacing.small),
                k,
              ],
              const Spacer(),
              ?footer,
            ],
          ),
        ),
      ),
    ),
  );
}

/// A tablet's way round: a column of keys down the housing at the screen's
/// start, a parting line at its end, each key its glyph over its name. The
/// current place is latched down with its lamp lit. [leading] stands at its
/// top (a brand).
///
/// ```dart
/// ApplianceNavigationRail(destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class ApplianceNavigationRail extends StatelessWidget {
  /// A rail over [destinations].
  const ApplianceNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.leading,
    this.style,
  }) : _keys = null;

  // The rail of ApplianceScaffold's shell, round the keys ui_core built.
  const ApplianceNavigationRail._shell({
    required List<Widget> this._keys,
    required this.destinations,
    this.leading,
  }) : selectedIndex = 0,
       onSelected = _ignore,
       style = null;

  /// The places.
  final List<ApplianceDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands at its top.
  final Widget? leading;

  final List<Widget>? _keys;

  /// Its style, over [ApplianceThemeData.navigationStyle].
  final ApplianceStyle? style;

  /// The rail's width.
  static const double width = 92;

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    final layers = [style, ApplianceTheme.of(context).navigationStyle];
    final keyWidth = _navigationKeyWidth(context, destinations, layers);
    if (keys != null) {
      return _railFrame(context, keys, keyWidth: keyWidth, leading: leading);
    }
    return _railFrame(
      context,
      [
        for (final (i, d) in destinations.indexed)
          _NavKey(
            destination: d,
            current: i == selectedIndex,
            onPressed: () => onSelected(i),
            layers: layers,
            builder: (context, face, layered) => _stackedKey(
              context,
              d,
              i == selectedIndex,
              face,
              layered,
              rail: true,
            ),
          ),
      ],
      keyWidth: keyWidth,
      leading: leading,
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

/// A desktop's way round: a moulded side panel at the window's start, a
/// parting line at its end. Each place is a row key with a lamp at its
/// start, its glyph and its name; the current place is latched down with
/// its lamp lit, so the panel reads as a bank of preset keys. [header]
/// stands at its top (a brand), [footer] at its foot.
///
/// ```dart
/// ApplianceSideNavigation(destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i), header: const Text('Larder'))
/// ```
class ApplianceSideNavigation extends StatelessWidget {
  /// A side panel over [destinations].
  const ApplianceSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.footer,
    this.legend,
    this.style,
  }) : _keys = null,
       _act = null;

  // The side panel of ApplianceScaffold's shell, round the keys ui_core
  // built.
  const ApplianceSideNavigation._shell({
    required List<Widget> this._keys,
    this.header,
    this._act,
    this.footer,
    this.legend,
  }) : destinations = const [],
       selectedIndex = 0,
       onSelected = _ignore,
       style = null;

  final List<Widget>? _keys;

  // The app's act under the brand, in ApplianceScaffold's shell.
  final Widget? _act;

  /// The places.
  final List<ApplianceDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands at its top, on the top bar's title line.
  final Widget? header;

  /// What stands at its foot.
  final Widget? footer;

  /// A caps legend printed over the places.
  final String? legend;

  /// Its style, over [ApplianceThemeData.navigationStyle].
  final ApplianceStyle? style;

  /// The panel's width.
  static const double width = 256;

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    if (keys != null) {
      return _sideFrame(
        context,
        keys,
        header: header,
        act: _act,
        footer: footer,
        legend: legend,
      );
    }
    final layers = [style, ApplianceTheme.of(context).navigationStyle];
    return _sideFrame(
      context,
      [
        for (final (i, d) in destinations.indexed)
          _NavKey(
            destination: d,
            current: i == selectedIndex,
            onPressed: () => onSelected(i),
            layers: layers,
            builder: (context, face, layered) =>
                _rowKey(context, d, i == selectedIndex, face, layered),
          ),
      ],
      header: header,
      footer: footer,
      legend: legend,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(StringProperty('legend', legend, defaultValue: null));
  }
}

/// The app's one act beside its places (add, write, capture): on a phone a
/// square key at the end of the key strip, on a tablet a key at the top of
/// the rail, on a desk a wide key at the top of the side panel. The signal
/// key when [accent], a plain key otherwise.
///
/// ```dart
/// ApplianceShellAction(icon: LucideIcons.plus, label: 'New list', accent: true, onPressed: (context) {})
/// ```
@immutable
class ApplianceShellAction with Diagnosticable {
  /// The act [onPressed], wearing [icon].
  const ApplianceShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.accent = false,
    this.key,
  });

  /// The glyph it wears.
  final IconData icon;

  /// What it does, run with a context under the app's navigator.
  final void Function(BuildContext context) onPressed;

  /// Its name: the side panel's key prints it, and a screen reader says it.
  final String? label;

  /// Whether it is the app's standing invitation: the signal key.
  final bool accent;

  /// The key on its key.
  final Key? key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('accent', value: accent, ifTrue: 'accent'));
  }
}

/// An app's frame by its width: below 600 px its [body] over an
/// [ApplianceNavigationBar]; to 1024 px an [ApplianceNavigationRail] at its
/// start; wider, an [ApplianceSideNavigation] with [header] and
/// [sideFooter].
///
/// It stands on ui_core's [RawAdaptiveShell] at every width: the places
/// are one tab stop, the arrows moving along them, each a tab to a screen
/// reader ("Tab 2 of 4") that says which is chosen, the side panel named
/// the navigation menu; F6 moves focus between the places and the page. The
/// app's [action] stands at the end of a phone's key strip, at the top of
/// the rail and under the side panel's [header].
///
/// [ApplianceScaffold.branches] gives each place a navigator of its own: a
/// page pushed on one keeps the rail or the side panel beside it while a
/// phone's key strip steps away for it, and back pops it before it leaves
/// the place. Each route draws its own [ApplianceScreen].
///
/// ```dart
/// ApplianceScaffold(destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i), body: pages[index])
/// ```
class ApplianceScaffold extends StatelessWidget {
  /// A frame round [body].
  const ApplianceScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required Widget this.body,
    this.header,
    this.railLeading,
    this.sideFooter,
    this.sideLegend,
    this.action,
    this.showNavigation = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination;

  /// A frame whose places each keep a navigator of their own, starting on
  /// its [branches] page: a page pushed on a place keeps the rail or the
  /// side panel, a phone's key strip steps away for it, and back pops it,
  /// then goes where [backBehavior] says.
  ///
  /// ```dart
  /// ApplianceScaffold.branches(destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i), branches: [(context) => const ListsPage(), (context) => const BasketPage()])
  /// ```
  const ApplianceScaffold.branches({
    super.key,
    required this.destinations,
    required this.onSelected,
    required List<WidgetBuilder> this.branches,
    this.selectedIndex = 0,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.header,
    this.railLeading,
    this.sideFooter,
    this.sideLegend,
    this.action,
  }) : body = null,
       showNavigation = true;

  /// The places.
  final List<ApplianceDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// The current place's page; null with [branches].
  final Widget? body;

  /// Each place's first page; null with [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside it;
  /// null keeps the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// The side panel's top (a brand), on the top bar's title line.
  final Widget? header;

  /// The rail's top (a brand mark).
  final Widget? railLeading;

  /// The side panel's foot.
  final Widget? sideFooter;

  /// The side panel's caps legend over its places.
  final String? sideLegend;

  /// The app's one act (add, write, capture): a square key at the strip's
  /// end on a phone, at the rail's top on a tablet, a wide key under the
  /// side panel's [header] on a desk.
  final ApplianceShellAction? action;

  /// Whether a phone's key strip stands: a router's shell lowers it while
  /// a page is pushed on the place. The rail and the side panel stay.
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layers = [ApplianceTheme.of(context).navigationStyle];
    final act = action;
    final railTop = railLeading;
    final top = header;
    // Appliance's widths: the key strip under 600, a rail to 1024, the side
    // panel wider.
    final mode = width < 600
        ? RawNavigationMode.bar
        : width < 1024
        ? RawNavigationMode.rail
        : RawNavigationMode.sidebar;
    final places = [
      for (final d in destinations)
        RawNavigationDestination(
          label: d.badge == null ? d.label : '${d.label}, ${d.badge}',
          icon: d.icon,
        ),
    ];
    Widget destinationBuilder(
      BuildContext context,
      RawNavigationDestination _,
      RawDestinationDetails details,
    ) {
      final d = destinations[details.index];
      final current = details.states.contains(WidgetState.selected);
      return KeyedSubtree(
        key: d.key,
        child: _navKeyPaint(
          context,
          details.states,
          current,
          layers,
          (context, face, layered) => switch (details.mode) {
            RawNavigationMode.bar || RawNavigationMode.top => _stackedKey(
              context,
              d,
              current,
              face,
              layered,
            ),
            RawNavigationMode.rail => _stackedKey(
              context,
              d,
              current,
              face,
              layered,
              rail: true,
            ),
            RawNavigationMode.sidebar => _rowKey(
              context,
              d,
              current,
              face,
              layered,
            ),
          },
        ),
      );
    }

    Widget navigationBuilder(
      BuildContext context,
      RawNavigationDetails details,
    ) => switch (details.mode) {
      // The shell never asks for places across the top (it keeps
      // Appliance's widths); were it to, the strip would stand for them.
      // Toasts stand above the strip, and drop to the screen's foot while a
      // page covers it.
      RawNavigationMode.bar || RawNavigationMode.top => RawToasterKeepClear(
        child: ApplianceNavigationBar._shell(
          keys: details.destinations,
          destinations: destinations,
          group: details.group,
          trailing: act == null ? null : _ActKey(action: act),
        ),
      ),
      RawNavigationMode.rail => ApplianceNavigationRail._shell(
        destinations: destinations,
        keys: details.destinations,
        leading: act == null
            ? railTop
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (railTop != null) ...[
                    railTop,
                    const SizedBox(height: ApplianceSpacing.medium),
                  ],
                  _ActKey(action: act),
                ],
              ),
      ),
      RawNavigationMode.sidebar => ApplianceSideNavigation._shell(
        keys: details.destinations,
        header: top,
        act: act == null
            ? null
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: _ActKey(action: act, wide: true),
              ),
        footer: sideFooter,
        legend: sideLegend,
      ),
    };
    final branches = this.branches;
    if (branches != null) {
      return RawAdaptiveShell.branches(
        mode: mode,
        destinations: places,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinationBuilder: destinationBuilder,
        navigationBuilder: navigationBuilder,
        branches: branches,
        navigatorKeys: navigatorKeys,
        backBehavior: backBehavior,
      );
    }
    return RawAdaptiveShell(
      mode: mode,
      showNavigation: showNavigation,
      destinations: places,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinationBuilder: destinationBuilder,
      navigationBuilder: navigationBuilder,
      // The body is a semantics container of its own, so a navigator in it
      // (a router's shell) hides only what lies under its page, never the
      // places beside it or below it. Routes under it keep nodes of their
      // own, as the app's navigator's do: otherwise a pushed route's node
      // forms only when a list opens over it, and on the web the focused
      // field's input moves into that node and loses the focus the tap just
      // gave it.
      body: Semantics(container: true, explicitChildNodes: true, child: body),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        DiagnosticsProperty<ApplianceShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      );
  }
}

/// A page: its [topBar], its [body] on the housing in the page's margins
/// (16, 24 or 32 by width), no wider than 1200 px, and its [footer] fixed
/// at its foot on the housing above a parting line. The body's content
/// stands on faceplates ([AppliancePanel], [ApplianceListGroup]).
///
/// ```dart
/// ApplianceScreen(topBar: const ApplianceAppBar(title: 'Settings'), body: settings)
/// ```
class ApplianceScreen extends StatelessWidget {
  /// A page of [body].
  const ApplianceScreen({
    super.key,
    required this.body,
    this.topBar,
    this.footer,
    this.scroll = true,
    this.fullBleed = false,
    this.maxWidth = _pageWidth,
    this.scrollController,
  });

  /// The page's content.
  final Widget body;

  /// Its top bar.
  final Widget? topBar;

  /// What stands fixed at its foot (a checkout's total and its key). Toasts
  /// stand above it.
  final Widget? footer;

  /// Whether the body scrolls.
  final bool scroll;

  /// Whether the body takes the page's whole width, with no margins.
  final bool fullBleed;

  /// The widest the content stands, inside its margins.
  final double maxWidth;

  /// The body's scroll controller.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final margin = ApplianceSpacing.pageMargin(media.size.width);
    final bar = topBar;
    final foot = footer;
    final top = bar == null ? media.padding.top : 0.0;
    final bottom = foot == null ? media.padding.bottom : 0.0;
    final Widget page = fullBleed
        ? body
        : Padding(
            padding: EdgeInsets.fromLTRB(
              margin,
              ApplianceSpacing.large + top,
              margin,
              ApplianceSpacing.huge + bottom,
            ),
            child: body,
          );
    final Widget column = fullBleed
        ? page
        : Align(
            alignment: Alignment.topCenter,
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
    return ApplianceHousing(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bar != null)
              _PageMeasure(maxWidth: fullBleed ? null : maxWidth, child: bar),
            Expanded(child: content),
            if (foot != null)
              _PageMeasure(
                maxWidth: fullBleed ? null : maxWidth,
                // Toasts stand above the footer's band (and above a key
                // strip under it), as over the strip itself.
                child: RawToasterKeepClear(
                  child: Builder(
                    builder: (context) => ApplianceHousing(
                      seam: AxisDirection.up,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          margin,
                          ApplianceSpacing.regular,
                          margin,
                          ApplianceSpacing.regular + media.padding.bottom,
                        ),
                        // At the end of the body's measure, not the window's.
                        child: media.size.width >= 600
                            ? _onMeasure(
                                context,
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                    ),
                                    child: foot,
                                  ),
                                ),
                              )
                            : foot,
                      ),
                    ),
                  ),
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

// The measure an ApplianceScreen holds its body to, for its bar and footer.
class _PageMeasure extends InheritedWidget {
  const _PageMeasure({required this.maxWidth, required super.child});

  // Null: the page is full bleed.
  final double? maxWidth;

  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageMeasure>()?.maxWidth;

  @override
  bool updateShouldNotify(_PageMeasure oldWidget) =>
      maxWidth != oldWidget.maxWidth;
}

// [child] held to the measure of the ApplianceScreen round it, centred as
// its body is; as it is outside one.
Widget _onMeasure(BuildContext context, Widget child) {
  final measure = _PageMeasure.of(context);
  if (measure == null) return child;
  return Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: measure),
      child: child,
    ),
  );
}
