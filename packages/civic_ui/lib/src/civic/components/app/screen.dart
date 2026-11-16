import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../../internal/frame_scope.dart';
import '../../theme.dart';
import '../scaffold/scaffold.dart';

/// A page of an app: the [topBar] across the top, then the [body] in the
/// page's reading column (at most 640 wide, short lines read faster),
/// scrolled when it is long, its foot clear of the device's edge and of
/// whatever a frame stands under it ([ShellInsets]).
///
/// [scroll] false hands the body the room to scroll itself; [fullBleed]
/// drops the column and its margins, for a body that draws to the page's
/// edges (a map, a picture). With [skipLinkLabel] the first thing a
/// keyboard reaches is a link past the bar to the body ([CivicScaffold]).
///
/// ```dart
/// CivicScreen(
///   topBar: CivicTopBar(
///     title: 'Your permit',
///     leading: CivicTopBar.autoLeading(context),
///   ),
///   body: Column(
///     crossAxisAlignment: CrossAxisAlignment.stretch,
///     children: [Text('Your permit', style: context.civicText.headingXL)],
///   ),
/// )
/// ```
class CivicScreen extends StatelessWidget {
  /// A page of [body].
  const CivicScreen({
    super.key,
    required this.body,
    this.topBar,
    this.scroll = true,
    this.fullBleed = false,
    this.skipLinkLabel,
  });

  /// The page's content.
  final Widget body;

  /// The band across the top: a [CivicTopBar]; null draws none.
  final Widget? topBar;

  /// Whether the page scrolls the body (false: the body scrolls itself).
  final bool scroll;

  /// Whether the body stands edge to edge, without the reading column.
  final bool fullBleed;

  /// The skip link's words, in the reader's language; null shows none.
  final String? skipLinkLabel;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final margin = CivicLayout.marginFor(width);
    // The column starts in line with the top bar's words: at the margin
    // beside the places, where a centred frame starts without them.
    final start = CivicFrameScope.besideNavigationOf(context)
        ? margin
        : CivicLayout.frameInset(width);
    // And ends where the frame ends: the bar's actions' line.
    final end = CivicFrameScope.endOf(context, width);
    final bar = topBar;
    // Under a bar the page starts at the bar's foot; with none, under the
    // device's top edge.
    final top = bar == null ? insets.top : 0.0;
    final foot = math.max(insets.bottom, ShellInsets.of(context));
    Widget column(Widget child) => Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CivicLayout.readingWidth),
        child: child,
      ),
    );
    final Widget content = fullBleed
        ? Padding(
            padding: EdgeInsets.only(top: top, bottom: ShellInsets.of(context)),
            child: body,
          )
        : scroll
        ? SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              start,
              top + CivicSpacing.s32,
              end,
              foot + CivicSpacing.s64,
            ),
            child: column(body),
          )
        : Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              start,
              top + CivicSpacing.s32,
              end,
              foot,
            ),
            child: column(body),
          );
    final page = CivicScaffold(
      topBar: bar,
      skipLinkLabel: skipLinkLabel,
      body: content,
    );
    // The bar's band is ink by day and by night: the status bar over it
    // takes light glyphs.
    return bar == null
        ? page
        : AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: page,
          );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('scroll', value: scroll, ifFalse: 'body scrolls'))
      ..add(FlagProperty('fullBleed', value: fullBleed, ifTrue: 'full bleed'))
      ..add(StringProperty('skipLinkLabel', skipLinkLabel, defaultValue: null));
  }
}
