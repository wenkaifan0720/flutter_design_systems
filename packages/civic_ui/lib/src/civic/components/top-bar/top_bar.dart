import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../internal/underline.dart';
import '../../internal/frame_scope.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';

/// The band across the top of every page: the [title] in bold white on a
/// deep band of the action's hue (a navy for Civic's blue), an [emblem]
/// before it, [actions] at its end, the action colour's rule under it (by
/// night its deeper edge). On the site it says whose service this is and
/// nothing more; the page's own heading says where the reader is. In an
/// app ([CivicLayout.isApp]) it is the app's own bar: on an inner page the
/// way back ([leading], [autoLeading]) and the page's place as its title,
/// the large heading in the page.
///
/// [onTitlePressed] makes the title a link home. The band is as deep in
/// light and dark, so the service reads as itself in both.
///
/// Reads [CivicStyle]'s fill (the band), foreground (the title and the
/// glyphs on it), edge (the rule under it) and textStyle (the title): its
/// `style:`, then [CivicThemeData.topBarStyle]. Keep the title at 7:1 on
/// the band.
///
/// ```dart
/// CivicTopBar(
///   title: 'Brindlemere parking permits',
///   onTitlePressed: () => router.go('/'),
///   actions: [CivicIconButton(icon: LucideIcons.user, semanticLabel: 'Your account', onPressed: openAccount)],
/// )
/// ```
class CivicTopBar extends StatelessWidget {
  /// The band.
  const CivicTopBar({
    super.key,
    required this.title,
    this.emblem,
    this.leading,
    this.actions = const [],
    this.onTitlePressed,
    this.style,
  });

  /// The service's name.
  final String title;

  /// A mark before the title: the body's own, never a borrowed one.
  final Widget? emblem;

  /// What stands before everything: a menu button.
  final Widget? leading;

  /// Buttons at the end.
  final List<Widget> actions;

  /// Called by a press on the title; null leaves it words.
  final VoidCallback? onTitlePressed;

  /// The band's height, under the safe area, its rule aside.
  static const double height = CivicChromeMetrics.topBar;

  /// Overrides for this bar's look.
  final CivicStyle? style;

  /// The rule under the band.
  static const double ruleHeight = CivicChromeMetrics.topBarRule;

  /// The band's colour in [t]: the action's hue, deep (a navy for Civic's
  /// blue), in light and dark.
  static Color bandOf(CivicThemeData t) {
    final hsl = HSLColor.fromColor(t.isDark ? t.actionEdge : t.action);
    return hsl
        .withLightness(t.isDark ? 0.08 : 0.15)
        .withSaturation((hsl.saturation * 0.85).clamp(0, 1))
        .toColor();
  }

  /// The words' colour on the band.
  static Color onBandOf(CivicThemeData t) =>
      t.isDark ? t.textPrimary : t.background;

  /// The way out the route at [context] earns, for [leading]: back (a
  /// chevron that points the way back in either reading direction) on a
  /// page pushed over another, close on a task raised over the app
  /// ([RoutePresentation.sheet]), nothing on an app's first page. Each says
  /// its name in the reader's language; [key] goes on the control.
  ///
  /// ```dart
  /// CivicTopBar(title: 'Your permit', leading: CivicTopBar.autoLeading(context))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) {
    final words = DesignLocalizations.of(context);
    void leave() => Navigator.maybePop(context);
    return switch (RoutePresentation.of(context)) {
      RoutePresentation.root => null,
      RoutePresentation.pushed => backButton(
        context,
        key: key,
        onPressed: leave,
      ),
      RoutePresentation.sheet => CivicIconButton(
        key: key,
        icon: LucideIcons.x,
        semanticLabel: words.closeButtonLabel,
        onPressed: leave,
      ),
    };
  }

  /// The way back, for [leading] on an app's inner page whose way back is
  /// not the navigator's (a page of a flow that goes to its step before): a
  /// chevron pointing the way back in either reading direction, saying
  /// "Back" in the reader's language; [onPressed] goes back.
  ///
  /// ```dart
  /// CivicTopBar(
  ///   title: 'Apply for a permit',
  ///   leading: CivicTopBar.backButton(context, onPressed: goBack),
  /// )
  /// ```
  static Widget backButton(
    BuildContext context, {
    required VoidCallback onPressed,
    Key? key,
  }) => Transform.flip(
    // The face is the same either way round; the chevron turns.
    flipX: Directionality.of(context) == TextDirection.rtl,
    child: CivicIconButton(
      key: key,
      icon: LucideIcons.chevronLeft,
      semanticLabel: DesignLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.topBarStyle], const {});
    final band = so.fill ?? bandOf(t);
    final onBand = so.foreground ?? onBandOf(t);
    final heading = text.headingS.merge(so.textStyle);
    final top = MediaQuery.paddingOf(context).top;
    final mark = emblem;
    final lead = leading;
    final name = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s12,
      children: [
        if (mark != null)
          IconTheme.merge(
            data: IconThemeData(color: onBand, size: 28),
            child: mark,
          ),
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: heading.copyWith(color: onBand),
          ),
        ),
      ],
    );
    final press = onTitlePressed;
    final titleWidget = press == null
        ? Semantics(header: false, child: name)
        : DesignPressable(
            onPressed: press,
            link: true,
            button: false,
            mouseCursor: SystemMouseCursors.click,
            builder: (context, states, _) => CivicSpringValue(
              value: states.contains(WidgetState.focused) ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              builder: (context, focus, _) => CustomPaint(
                painter: CivicFacePainter(
                  fill: t.focus.withValues(alpha: 0),
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: focus,
                  focusColor: t.focus,
                  barColor: t.focusBar,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: CivicSpacing.s8,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: Color.lerp(onBand, t.onFocus, focus),
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: Color.lerp(onBand, t.onFocus, focus),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: CivicSpacing.s12,
                        children: [
                          if (mark != null)
                            IconTheme.merge(
                              data: const IconThemeData(size: 28),
                              child: mark,
                            ),
                          Flexible(
                            // A pointer over the way home, or a press on
                            // it, underlines it, as a link answers.
                            child: CivicUnderlined(
                              style: heading.copyWith(
                                color: Color.lerp(onBand, t.onFocus, focus),
                                decoration:
                                    states.contains(WidgetState.hovered) ||
                                        states.contains(WidgetState.pressed)
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationThickness: 3,
                                decorationColor: Color.lerp(
                                  onBand,
                                  t.onFocus,
                                  focus,
                                ),
                              ),
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
    // The bar's words start in line with the side navigation's places, or
    // with the centred page frame's start when there is none.
    final width = MediaQuery.sizeOf(context).width;
    final margin = CivicFrameScope.startOf(context, width);
    final endMargin = CivicFrameScope.endOf(context, width);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: band,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: top,
                start: lead == null ? margin : margin - CivicSpacing.s12,
                end: actions.isEmpty ? endMargin : endMargin - CivicSpacing.s12,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: height),
                child: IconTheme.merge(
                  data: IconThemeData(color: onBand),
                  child: Row(
                    spacing: CivicSpacing.s8,
                    children: [
                      ?lead,
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: titleWidget,
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: ruleHeight,
              // By night the action colour is a light one: the rule takes
              // its deeper edge, so it frames the band and doesn't outshine
              // the page.
              child: ColoredBox(
                color: so.edge ?? (t.isDark ? t.actionEdge : t.action),
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
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length))
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onTitlePressed', onTitlePressed),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
