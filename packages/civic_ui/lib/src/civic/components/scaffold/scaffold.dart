import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../internal/fit_words.dart';
import '../../internal/frame_scope.dart';
import '../../theme.dart';
import '../../internal/underline.dart';

/// A page of a service, on the theme's ground: the [topBar] across the top,
/// the places ([navigationBar] along the bottom on a phone and down the
/// start as a rail from [CivicLayout.medium] wide, [sideNavigation] down
/// the start from [CivicLayout.expanded] wide), the [body] in between. A service's flow (the question pages) gives neither:
/// one thing per page, and the way out is the bar's back control (in an
/// app) or the back link (on the site). In a wide window the side
/// navigation's places start where a page with none starts its column,
/// under the bar's words, so the bar stands still from page to page.
///
/// While the keyboard is up the body stands above it and the places' bar
/// stands aside, so a page's action ([CivicPageBody.action]) stays in reach.
///
/// With [skipLinkLabel] the first thing a keyboard reaches is a skip link,
/// hidden until it has the focus, that jumps past the bar and the places to
/// the body.
///
/// ```dart
/// CivicScaffold(
///   topBar: const CivicTopBar(title: 'Brindlemere parking permits'),
///   skipLinkLabel: 'Skip to main content',
///   body: CivicPageBody(title: 'Your applications', children: rows),
/// )
/// ```
class CivicScaffold extends StatefulWidget {
  /// A page.
  const CivicScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.navigationBar,
    this.sideNavigation,
    this.skipLinkLabel,
  });

  /// The page's own content.
  final Widget body;

  /// The band across the top: a [CivicTopBar].
  final Widget? topBar;

  /// An app's places ([CivicLayout.isApp]): a [CivicNavigationBar], along
  /// the bottom on a phone, down the start as a rail from
  /// [CivicLayout.medium] wide.
  final Widget? navigationBar;

  /// The places down the start, from [CivicLayout.expanded] wide: a
  /// [CivicSideNavigation].
  final Widget? sideNavigation;

  /// The skip link's words, in the reader's language; null shows none.
  final String? skipLinkLabel;

  @override
  State<CivicScaffold> createState() => _CivicScaffoldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('skipLinkLabel', skipLinkLabel, defaultValue: null),
    );
  }
}

class _CivicScaffoldState extends State<CivicScaffold> {
  final FocusNode _main = FocusNode(
    debugLabel: 'CivicScaffold main',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _main.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final width = MediaQuery.sizeOf(context).width;
    final wide = !CivicLayout.isApp(width);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final places = widget.navigationBar;
    final rail = !wide && width >= CivicLayout.medium && places != null
        ? CivicRailScope(child: places)
        : null;
    final side =
        (wide ? widget.sideNavigation : null) ??
        (rail == null
            ? null
            : MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: rail,
              ));
    final bottom = wide || rail != null || keyboard > 0 ? null : places;
    final top = widget.topBar;
    final skip = widget.skipLinkLabel;
    Widget main = Focus(
      focusNode: _main,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: widget.body,
      ),
    );
    if (bottom != null || keyboard > 0) {
      // The body's foot clears the bar, or the keyboard.
      main = MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: main,
        ),
      );
    }
    if (keyboard > 0) {
      main = Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: main,
      );
    }
    if (top != null) {
      main = MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: main,
      );
    }
    final column = CivicFrameScope(
      // Beside its own side navigation, or inside a frame's that stands one.
      besideNavigation:
          side != null || CivicFrameScope.besideNavigationOf(context),
      barOverNavigation: side != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?top,
          Expanded(
            child: side == null
                ? main
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The places start under the bar's words, where the
                      // centred frame starts.
                      if (rail != null)
                        side
                      else
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: CivicLayout.navigationOffset(width),
                          ),
                          child: side,
                        ),
                      Expanded(child: main),
                    ],
                  ),
          ),
          ?bottom,
        ],
      ),
    );
    return ColoredBox(
      color: t.ground,
      child: DefaultTextStyle(
        style: context.civicText.body,
        child: skip == null
            ? column
            : Stack(
                children: [
                  // The skip link comes first in reading and focus order,
                  // and stands over the bar only while it has the focus.
                  Positioned.fill(child: column),
                  PositionedDirectional(
                    top: MediaQuery.paddingOf(context).top,
                    start: 0,
                    child: _SkipLink(
                      label: skip,
                      onPressed: () {
                        _main.requestFocus();
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SkipLink extends StatefulWidget {
  const _SkipLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_SkipLink> createState() => _SkipLinkState();
}

class _SkipLinkState extends State<_SkipLink> {
  final _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    // Hidden until it has the focus, but always in a screen reader's reach
    // (its node and its action stay), and never in the way of a pointer: a
    // tap where it hides goes to what it covers, the bar's title.
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: _states,
      builder: (context, states, child) => _PassPointer(
        passes: !states.contains(WidgetState.focused),
        child: child,
      ),
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(-1),
        child: DesignPressable(
          onPressed: widget.onPressed,
          link: true,
          button: false,
          semanticLabel: widget.label,
          excludeSemantics: true,
          mouseCursor: SystemMouseCursors.click,
          statesController: _states,
          builder: (context, states, _) => CivicSpringValue(
            value: states.contains(WidgetState.focused) ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => Opacity(
              opacity: focus.clamp(0.0, 1.0),
              alwaysIncludeSemantics: true,
              child: CustomPaint(
                painter: CivicFacePainter(
                  fill: t.focus,
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: 1,
                  focusColor: t.focus,
                  barColor: t.focusBar,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CivicSpacing.s20,
                    CivicSpacing.s12,
                    CivicSpacing.s20,
                    CivicSpacing.s16,
                  ),
                  child: CivicUnderlined(
                    style: text.label.copyWith(
                      color: t.onFocus,
                      decoration: TextDecoration.underline,
                      decorationColor: t.onFocus,
                    ),
                    child: Text(widget.label),
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

/// Lets a pointer through [child] while [passes]; its semantics stay as
/// they are (an IgnorePointer would block a screen reader's actions too).
class _PassPointer extends SingleChildRenderObjectWidget {
  const _PassPointer({required this.passes, super.child});

  final bool passes;

  @override
  _RenderPassPointer createRenderObject(BuildContext context) =>
      _RenderPassPointer(passes);

  @override
  void updateRenderObject(BuildContext context, _RenderPassPointer object) {
    object.passes = passes;
  }
}

class _RenderPassPointer extends RenderProxyBox {
  _RenderPassPointer(this.passes);

  bool passes;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !passes && super.hitTest(result, position: position);
}

/// A page's content in its reading column: [backLink] first, then the
/// [errorSummary] when a send found problems, then a [caption] (Question 2
/// of 5, the section's name) over the [title] (the page's heading), then
/// [children], with the page's margins and at most [maxWidth] wide (the
/// reading width: short lines read faster), scrolled when it is long. With
/// no side navigation beside it, the column starts where a centred
/// [CivicLayout.pageWidth] frame starts in a wide window, in line with the
/// top bar's words. The heading sets at most half as large again at a
/// large text size, so its longest word still fits the column.
///
/// A question page gives no [title]: its question is the heading
/// (`isPageHeading` on the field).
///
/// In an app from [CivicLayout.medium] wide (a tablet) the column stands on
/// a centred measure.
///
/// The page's one [action] (Continue, Start now) stays in reach: in an
/// app-sized window ([CivicLayout.isApp]) it stands at the page's foot, on
/// the card's face over a hairline, while the page scrolls under it (and
/// over the keyboard while it is up); on the site it follows the
/// [children]. In an app the way back is the top bar's
/// ([CivicTopBar.leading]); give [backLink] on the site.
///
/// ```dart
/// CivicPageBody(
///   backLink: CivicBackLink(onPressed: () => Navigator.of(context).maybePop()),
///   caption: 'Question 2 of 5',
///   action: CivicButton(onPressed: apply, child: const Text('Continue')),
///   children: [question],
/// )
/// ```
class CivicPageBody extends StatelessWidget {
  /// A page's content.
  const CivicPageBody({
    super.key,
    required this.children,
    this.backLink,
    this.errorSummary,
    this.caption,
    this.title,
    this.action,
    this.maxWidth = CivicLayout.readingWidth,
    this.controller,
  });

  /// The content, top to bottom.
  final List<Widget> children;

  /// The way back, above everything.
  final Widget? backLink;

  /// A [CivicErrorSummary], under the way back and over the caption and the
  /// heading, where a reader looks first.
  final Widget? errorSummary;

  /// Words over the heading: where in the service the reader is.
  final String? caption;

  /// The page's heading.
  final String? title;

  /// The page's one action: kept at the foot in an app, after [children] on
  /// the site.
  final Widget? action;

  /// The widest the column stands.
  final double maxWidth;

  /// The scroll's controller; the body's own when null.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final width = MediaQuery.sizeOf(context).width;
    final margin = CivicLayout.marginFor(width);
    final insets = MediaQuery.paddingOf(context);
    final back = backLink;
    final problems = errorSummary;
    final head = title;
    final over = caption;
    final act = action;
    final app = CivicLayout.isApp(width);
    final start = CivicFrameScope.besideNavigationOf(context)
        ? margin
        : CivicLayout.frameInset(width);
    final end = CivicFrameScope.endOf(context, width);
    // A pointer's back link is a shorter target than a finger's: the room
    // its target loses goes round it, so its words stand as far from the
    // bar and the heading on a desk as on a phone.
    final room = math.max(
      0.0,
      (DesignTapTargets.of(context).touch.height -
              DesignTapTargets.of(context).floorOn().height) /
          2,
    );
    final foot = act != null && app;
    // A tablet's app page stands its column on a centred measure, not down
    // the start of a stretched phone's.
    final centred = app && width >= CivicLayout.medium;
    final scroll = SingleChildScrollView(
      controller: controller,
      padding: EdgeInsetsDirectional.fromSTEB(
        start,
        back == null ? CivicSpacing.s32 : CivicSpacing.s12 + room,
        // The page ends where the frame ends, under the bar's actions.
        end,
        foot ? CivicSpacing.s32 : CivicSpacing.s64 + insets.bottom,
      ),
      child: Align(
        alignment: centred
            ? Alignment.topCenter
            : AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (back != null) ...[
                Align(alignment: AlignmentDirectional.centerStart, child: back),
                SizedBox(height: CivicSpacing.s24 + room),
              ],
              if (problems != null) ...[
                problems,
                const SizedBox(height: CivicSpacing.s32),
              ],
              if (over != null) ...[
                Text(
                  over,
                  style: text.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: CivicSpacing.s4),
              ],
              if (head != null) ...[
                Semantics(
                  header: true,
                  child: CivicFitWords(head, style: text.headingXL),
                ),
                const SizedBox(height: CivicSpacing.s24),
              ],
              ...children,
              if (act != null && !app) ...[
                const SizedBox(height: CivicSpacing.s32),
                Align(alignment: AlignmentDirectional.centerStart, child: act),
              ],
            ],
          ),
        ),
      ),
    );
    if (!foot) return scroll;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: scroll),
        // The action's foot: the card's face over a hairline, the action in
        // the page's column.
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.background,
            border: Border(top: BorderSide(color: t.rule)),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              start,
              CivicSpacing.s12,
              end,
              CivicSpacing.s12 + insets.bottom,
            ),
            child: Align(
              alignment: centred
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                // On a centred measure the action starts where the
                // column's words do.
                child: centred
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: act,
                      )
                    : act,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('caption', caption, defaultValue: null))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(DoubleProperty('maxWidth', maxWidth));
  }
}
