import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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

  /// What stands before everything: the way back ([autoLeading]) or a menu
  /// button. As a [CivicScaffold]'s band from [CivicLayout.expanded] wide it
  /// hangs in the gutter before the words, at most the gutter wide, so the
  /// words keep the page's column line as a page is pushed.
  final Widget? leading;

  /// Buttons at the end.
  final List<Widget> actions;

  /// Called by a press on the title; null leaves it words.
  final VoidCallback? onTitlePressed;

  /// Minimum height of the band, excluding its bottom rule and the safe area.
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
    final words = RawWidgetsLocalizations.of(context);
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
        tooltip: words.closeButtonLabel,
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
      semanticLabel: RawWidgetsLocalizations.of(context).backButtonTooltip,
      tooltip: RawWidgetsLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.topBarStyle], const {});
    final band = so.fill ?? bandOf(t);
    final onBand = so.foreground ?? onBandOf(t);
    final heading = text.headingS.merge(so.textStyle);
    final top = MediaQuery.paddingOf(context).top;
    final inset = civicHeaderInset(context, heading);
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
          child: Text(title, style: heading.copyWith(color: onBand)),
        ),
      ],
    );
    final press = onTitlePressed;
    final titleWidget = press == null
        ? Semantics(header: false, child: name)
        : RawButton(
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
                              child: Text(title),
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
    // with the centred page frame's start when there is none. As a
    // scaffold's top band the bar spans the window; anywhere else (in the
    // page, a pane, a sheet or a gallery's section narrower than the window)
    // it stands alone and centres that frame on its own width.
    final window = MediaQuery.sizeOf(context).width;
    final margin = CivicFrameScope.startOf(context, window);
    final endMargin = CivicFrameScope.endOf(context, window);
    final framed = CivicBarSlot.of(context);
    // From a desktop's width the way back (the leading control) hangs in the
    // gutter before the words, at most the gutter wide (the least of them
    // holds the 40 touch floor): the words keep the page's column line as a
    // page is pushed and popped. In an app's window, and in a bar standing
    // alone, it stands before them.
    final hang =
        lead != null &&
        framed &&
        !CivicLayout.isApp(window) &&
        margin >= CivicSpacing.s40;
    EdgeInsetsDirectional insets(double width) {
      final own = CivicLayout.frameInset(math.min(width, window));
      final start = framed ? margin : own;
      final end = framed ? endMargin : own;
      return EdgeInsetsDirectional.only(
        top: top,
        // A hung control's gutter is the row's start.
        start: lead == null
            ? start
            : hang
            ? 0
            : start - CivicSpacing.s12,
        end: actions.isEmpty ? end : end - CivicSpacing.s12,
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: band,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WidthPadding(
              window: window,
              insets: insets,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: height),
                child: IconTheme.merge(
                  data: IconThemeData(color: onBand),
                  child: Row(
                    children: [
                      if (lead != null)
                        if (hang)
                          // The gutter, the control at its end: at most
                          // the gutter wide.
                          SizedBox(
                            width: margin,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: lead,
                            ),
                          )
                        else ...[
                          lead,
                          const SizedBox(width: CivicSpacing.s8),
                        ],
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: press == null
                                  ? inset
                                  : inset - CivicSpacing.s8,
                            ),
                            child: titleWidget,
                          ),
                        ),
                      ),
                      for (final action in actions) ...[
                        const SizedBox(width: CivicSpacing.s8),
                        action,
                      ],
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

/// Pads [child] by the [insets] its own width gives: the window's, [window],
/// while its width is unbounded, and to measure its least and most width.
class _WidthPadding extends SingleChildRenderObjectWidget {
  const _WidthPadding({
    required this.window,
    required this.insets,
    required super.child,
  });

  final double window;
  final EdgeInsetsDirectional Function(double width) insets;

  @override
  _RenderWidthPadding createRenderObject(BuildContext context) =>
      _RenderWidthPadding(window, insets, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWidthPadding renderObject,
  ) => renderObject
    ..window = window
    ..insets = insets
    ..textDirection = Directionality.of(context);
}

class _RenderWidthPadding extends RenderShiftedBox {
  _RenderWidthPadding(this._window, this._insets, this._textDirection)
    : super(null);

  double _window;
  set window(double value) {
    if (value == _window) return;
    _window = value;
    markNeedsLayout();
  }

  EdgeInsetsDirectional Function(double width) _insets;
  set insets(EdgeInsetsDirectional Function(double width) value) {
    _insets = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  EdgeInsets _at(double width) =>
      _insets(width.isFinite ? width : _window).resolve(_textDirection);

  @override
  double computeMinIntrinsicWidth(double height) {
    final p = _at(_window);
    return p.horizontal +
        (child?.getMinIntrinsicWidth(math.max(0, height - p.vertical)) ?? 0);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final p = _at(_window);
    return p.horizontal +
        (child?.getMaxIntrinsicWidth(math.max(0, height - p.vertical)) ?? 0);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final p = _at(width);
    return p.vertical +
        (child?.getMinIntrinsicHeight(math.max(0, width - p.horizontal)) ?? 0);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final p = _at(width);
    return p.vertical +
        (child?.getMaxIntrinsicHeight(math.max(0, width - p.horizontal)) ?? 0);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final p = _at(constraints.maxWidth);
    final inner = child?.getDryLayout(constraints.deflate(p)) ?? Size.zero;
    return constraints.constrain(
      Size(inner.width + p.horizontal, inner.height + p.vertical),
    );
  }

  @override
  void performLayout() {
    final p = _at(constraints.maxWidth);
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(p.horizontal, p.vertical));
      return;
    }
    c.layout(constraints.deflate(p), parentUsesSize: true);
    (c.parentData! as BoxParentData).offset = Offset(p.left, p.top);
    size = constraints.constrain(
      Size(c.size.width + p.horizontal, c.size.height + p.vertical),
    );
  }
}
