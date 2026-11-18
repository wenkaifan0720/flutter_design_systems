/// Gloss's overlays: the dialog, the sheets (from the foot, from the side)
/// and the action sheet, raised porcelain panels set down over a dimmed
/// page, and the toast, a floating pearl capsule.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'internal/key_paint.dart';
import 'surface.dart';
import 'theme.dart';

/// One of a [GlossDialog]'s keys.
@immutable
class GlossDialogAction {
  /// A key reading [label].
  const GlossDialogAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  /// Its words.
  final String label;

  /// Called on a press; null turns it off.
  final VoidCallback? onPressed;

  /// Whether it is the dialog's one action: a gel key (ruby when
  /// [destructive]).
  final bool primary;

  /// Whether it destroys something.
  final bool destructive;
}

/// A Gloss dialog: a raised porcelain panel rounded 24, its [title], its
/// [content] and its keys at the foot's end, the confirm last. Its words
/// scroll under fixed keys when long; the keys stack, the confirm on top,
/// when they do not fit side by side (a narrow phone, large text). As it
/// opens, focus goes to the safe key (Keep, beside a Delete).
///
/// ```dart
/// GlossDialog(title: 'Delete this week’s plan?', content: const Text('The 7 dinners in it go back to your recipes.'), actions: [GlossDialogAction(label: 'Keep', onPressed: () {}), GlossDialogAction(label: 'Delete', onPressed: () {}, primary: true, destructive: true)])
/// ```
class GlossDialog extends StatelessWidget {
  /// A dialog titled [title].
  const GlossDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
  });

  /// What it asks.
  final String title;

  /// What it says.
  final Widget? content;

  /// Its keys, in reading order; the confirm last.
  final List<GlossDialogAction> actions;

  /// The widest it stands.
  static const double maxWidth = 440;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    // In its route a dialog stands a margin in from the screen's edges,
    // centred; shown at rest in a page it stands at its column's start with
    // no margin, as a card does. Either way it is as wide as it may be (up to
    // [maxWidth]), never shrunk to its words.
    final routed = ModalRoute.of(context) is DesignDialogRoute;
    // ui_core's dialog lays it out, focuses its safe key and stacks its
    // keys; Gloss paints the panel, the words and the keys.
    final dialog = DesignDialog(
      title: title,
      content: content == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: GlossSpacing.small),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(color: c.inkSecondary),
                child: content!,
              ),
            ),
      actions: [
        for (final a in actions)
          DesignDialogAction(
            label: a.label,
            onPressed: a.onPressed,
            isDefaultAction: a.primary,
            isDestructiveAction: a.destructive,
          ),
      ],
      insetPadding: routed
          ? const EdgeInsets.all(GlossSpacing.large)
          : EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: maxWidth),
      actionSpacing: GlossSpacing.small,
      stackedActionSpacing: GlossSpacing.small,
      titleBuilder: (context, title) =>
          Text(title, style: theme.textTheme.title),
      actionsBuilder: (context, details, child) => Padding(
        padding: const EdgeInsets.only(top: GlossSpacing.large),
        child: child,
      ),
      frameBuilder: (context, details, child) => GlossSurface(
        face: _panel(c),
        child: DesignKeylineRegion(
          label: 'Dialog',
          child: Padding(
            padding: const EdgeInsets.all(GlossSpacing.large),
            child: child,
          ),
        ),
      ),
      // A stacked key takes the panel's width.
      actionBuilder: (context, action, details) {
        final key = glossKeyPaint(
          context,
          details.states,
          kind: action.isDefaultAction ? GlossKeyKind.gel : GlossKeyKind.pearl,
          label: action.label,
          destructive: action.isDestructiveAction,
        );
        return details.stacked
            ? SizedBox(width: double.infinity, child: key)
            : key;
      },
    );
    if (routed) return dialog;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: dialog,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length));
  }
}

/// A raised porcelain panel: a dialog's, a sheet's.
GlossFace _panel(GlossColors c, {double radius = GlossMetrics.panelRadius}) =>
    GlossFace.porcelain(c, radius: radius).copyWith(
      top: c.brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF343A41),
      middle: c.brightness == Brightness.light
          ? const Color(0xFFF7F8FA)
          : const Color(0xFF2B3036),
      bottom: c.brightness == Brightness.light
          ? const Color(0xFFF1F3F5)
          : const Color(0xFF272B31),
      lift: 1,
    );

/// Shows the dialog [builder] makes over a dimmed page: it rises from 96%
/// of its size on Gloss's panel spring and fades in. Escape or Back closes
/// it, and a press on the page round it when [barrierDismissible] (null: a
/// dialog yes, an alert no). An [isAlert] dialog asks for an answer: a
/// screen reader hears an alert.
///
/// ```dart
/// showGlossDialog<bool>(context: context, isAlert: true, builder: (context) => const GlossDialog(title: 'Delete?'))
/// ```
Future<T?> showGlossDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isAlert = false,
  bool? barrierDismissible,
}) {
  final theme = GlossTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignDialogRoute<T>(
      isAlert: isAlert,
      barrierDismissible: barrierDismissible,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim, 320),
      dampingRatio: GlossMotion.panelDamping,
      stiffness: _riseStiffness(320),
      closeDampingRatio: _fallDamping,
      closeStiffness: _fallStiffness(320),
      builder: (context, details) => GlossTheme(
        data: theme,
        child: _Rise(
          animation: details.animation,
          ms: 320,
          scaleFrom: 0.96,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

/// Damping of the closing spring shared by dialogs and sheets.
const double _fallDamping = 1.02;

/// The stiffness of a fall over [ms] milliseconds, as the dialog's 320 falls
/// at 640 (a spring's time goes as one over the root of its stiffness).
double _fallStiffness(int ms) => 640 * (320 / ms) * (320 / ms);

/// Adapts the panel's opening spring to the route duration.
double _riseStiffness(int ms) {
  final scale = _PanelCurve._span * 1000 / ms;
  return GlossMotion.panelStiffness * scale * scale;
}

/// The fall itself at the dialog's time: from rest at 1 toward 0. Every
/// route's fall is this one, run faster or slower to its own time.
final SpringSimulation _fall = SpringSimulation(
  SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: _fallStiffness(320),
    ratio: _fallDamping,
  ),
  1,
  0,
  0,
);

/// Converts a closing spring's position to the opacity animation's clock.
double _fallClock(double p) {
  const time = 0.32;
  if (p >= 1) return 1;
  if (p <= _fall.x(time)) return 0;
  var lo = 0.0;
  var hi = time;
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (_fall.x(mid) > p) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return 1 - (lo + hi) / 2 / time;
}

/// How much of a dialog or a sheet shows on its way in, at [clock] of its
/// route's time ([_Arrival]): eased out over the first half, as before
/// ui_core ran the routes.
double _arriving(double clock) =>
    Curves.easeOut.transform((clock / 0.5).clamp(0.0, 1.0));

/// How much of a dialog or a sheet shows at presence [t] once in (dragged):
/// eased out by nine tenths of the way; going ([closing]), eased in on the
/// fall's clock.
double _shown(double t, {required bool closing}) {
  final p = t.clamp(0.0, 1.0);
  return closing
      ? Curves.easeIn.transform(_fallClock(p))
      : Curves.easeOut.transform((p / 0.9).clamp(0.0, 1.0));
}

/// A sheet fading as it slides, coming ([_arriving] over its route's [ms])
/// and going ([_shown]).
class _Fade extends StatelessWidget {
  const _Fade({required this.animation, required this.ms, required this.child});

  final Animation<double> animation;
  final int ms;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Arrival(
    animation: animation,
    ms: ms,
    child: child,
    builder: (context, clock, child) => Opacity(
      opacity: clock != null
          ? _arriving(clock)
          : _shown(
              animation.value,
              closing: animation.status == AnimationStatus.reverse,
            ),
      child: child,
    ),
  );
}

/// A dialog rising on its route's spring presence (0 gone, 1 open): it
/// fades as [_shown] and grows from [scaleFrom].
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.ms,
    required this.child,
    required this.scaleFrom,
  });

  final Animation<double> animation;
  final int ms;
  final Widget child;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) => _Arrival(
    animation: animation,
    ms: ms,
    child: child,
    builder: (context, clock, child) {
      final t = animation.value;
      return Opacity(
        opacity: clock != null
            ? _arriving(clock)
            : _shown(t, closing: animation.status == AnimationStatus.reverse),
        child: Transform.scale(
          scale: scaleFrom + (1 - scaleFrom) * t,
          child: child,
        ),
      );
    },
  );
}

/// A curve shaped like Gloss's panel spring, settling without a bounce a
/// person would see.
class _PanelCurve extends Curve {
  const _PanelCurve();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: GlossMotion.panelStiffness,
      ratio: GlossMotion.panelDamping,
    ),
    0,
    1,
    0,
  );

  static final double _span = () {
    var t = 0.0;
    while (t < 3) {
      if ((_spring.x(t) - 1).abs() < 0.001 && _spring.dx(t).abs() < 0.01) {
        return t;
      }
      t += 0.005;
    }
    return 3.0;
  }();

  @override
  double transformInternal(double t) => _spring.x(t * _span);
}

/// A whole page raised as a sheet ([GlossSheetPage.fullScreen]) rising from
/// [from] (a share of its own size) on a curve shaped like the panel spring.
class _Arrive extends StatefulWidget {
  const _Arrive({
    required this.animation,
    required this.child,
    required this.from,
  });

  final Animation<double> animation;
  final Widget child;
  final Offset from;

  @override
  State<_Arrive> createState() => _ArriveState();
}

class _ArriveState extends State<_Arrive> {
  late CurvedAnimation _moved = _curve();
  late CurvedAnimation _faded = _fade();

  CurvedAnimation _curve() => CurvedAnimation(
    parent: widget.animation,
    curve: const _PanelCurve(),
    reverseCurve: Curves.easeInCubic,
  );

  CurvedAnimation _fade() => CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );

  @override
  void didUpdateWidget(_Arrive old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _moved.dispose();
      _faded.dispose();
      _moved = _curve();
      _faded = _fade();
    }
  }

  @override
  void dispose() {
    _moved.dispose();
    _faded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) return FadeTransition(opacity: _faded, child: widget.child);
    return FadeTransition(
      opacity: _faded,
      child: AnimatedBuilder(
        animation: _moved,
        child: widget.child,
        builder: (context, child) {
          final t = _moved.value;
          return FractionalTranslation(
            translation: widget.from * (1 - t),
            child: child,
          );
        },
      ),
    );
  }
}

/// Shows a sheet [builder] fills: on a phone a porcelain panel rising from
/// the foot, its top rounded 24 with a grip pressed into it; from 600 px a
/// panel 560 wide set down over the page's foot. A drag down on the panel,
/// a press on the dimmed page or Escape closes it.
///
/// ```dart
/// showGlossSheet<void>(context: context, title: 'Filters', builder: (context) => const Text('Vegetarian'))
/// ```
Future<T?> showGlossSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  WidgetBuilder? footerBuilder,
}) {
  final theme = GlossTheme.of(context);
  final words = DesignLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      barrierLabel: words.modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim, 380),
      semanticLabel: title,
      builder: (context, details) => GlossTheme(
        data: theme,
        child: _Fade(
          animation: details.animation,
          ms: 380,
          child: _TapBeside(
            close: details.close,
            child: _Sheet(
              title: title,
              builder: builder,
              footer: footerBuilder,
              scrollController: details.scrollController,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Gloss's scrim under a dialog or a sheet, as [DesignBarrierBuilder]: it
/// darkens on its route's own clock as it arrives (eased over [ms], as it did
/// before ui_core ran the routes, [_Arrival]), follows the panel when it is
/// dragged (ease-in on its presence), and lifts on the fall's clock as it
/// goes ([_fallClock]).
DesignBarrierBuilder _scrim(Color color, int ms) =>
    (context, animation) => _Arrival(
      animation: animation,
      ms: ms,
      builder: (context, clock, _) {
        final share = clock != null
            ? Curves.ease.transform(clock)
            : animation.status == AnimationStatus.reverse
            ? Curves.ease.transform(_fallClock(animation.value))
            : Curves.easeIn.transform(animation.value);
        return ColoredBox(
          color: color.withValues(alpha: color.a * share),
          child: const SizedBox.expand(),
        );
      },
    );

/// The clock Gloss's routes ran on before ui_core: linear over the route's
/// time ([ms]) from the push. While the route arrives [builder] gets the
/// share of that time gone; once it is in, dragged or sent back, null (the
/// route's presence rules).
class _Arrival extends StatefulWidget {
  const _Arrival({
    required this.animation,
    required this.ms,
    required this.builder,
    this.child,
  });

  final Animation<double> animation;
  final int ms;
  final Widget Function(BuildContext context, double? clock, Widget? child)
  builder;
  final Widget? child;

  @override
  State<_Arrival> createState() => _ArrivalState();
}

class _ArrivalState extends State<_Arrival>
    with SingleTickerProviderStateMixin {
  // The frame the route set out in (its spring took its first step in it),
  // while it is on its way in.
  Duration? _start;
  Ticker? _frames;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_status);
    if (widget.animation.status == AnimationStatus.forward) {
      _start = SchedulerBinding.instance.currentFrameTimeStamp;
      _frames = createTicker(_tick)..start();
    }
  }

  @override
  void didUpdateWidget(_Arrival old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      old.animation.removeStatusListener(_status);
      widget.animation.addStatusListener(_status);
    }
  }

  double? get _clock {
    final start = _start;
    if (start == null) return null;
    final gone =
        (SchedulerBinding.instance.currentFrameTimeStamp - start)
            .inMicroseconds /
        (widget.ms * 1000);
    return gone < 1 ? gone : null;
  }

  // Frames on to the end of the route's time, after its spring has settled.
  void _tick(Duration _) {
    if (_clock == null) {
      _start = null;
      _frames!.stop();
    }
    setState(() {});
  }

  // Sent back on its way in, it leaves on its presence.
  void _status(AnimationStatus status) {
    if (status == AnimationStatus.reverse && _start != null) {
      _start = null;
      _frames!.stop();
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_status);
    _frames?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    child: widget.child,
    builder: (context, child) => widget.builder(context, _clock, child),
  );
}

/// A sheet's route: ui_core's bottom sheet on Gloss's panel spring. A tap on
/// the scrim above or beside the sheet closes it; a screen reader closes it
/// with its close bead, Escape or Back (and the sheet's own dismiss), so the
/// scrim, which runs on under the sheet, is not a node of its own that would
/// outline the sheet's controls too.
class _SheetRoute<T> extends DesignBottomSheetRoute<T> {
  _SheetRoute({
    super.settings,
    required super.builder,
    required String super.barrierLabel,
    required super.barrierBuilder,
    super.semanticLabel,
    super.snapSizes,
    int ms = 380,
  }) : super(
         dampingRatio: GlossMotion.panelDamping,
         stiffness: _riseStiffness(ms),
         closeDampingRatio: _fallDamping,
         closeStiffness: _fallStiffness(ms),
       );

  @override
  bool get semanticsDismissible => false;
}

/// A sheet narrower than the screen (framed on a desk, an action sheet): a
/// tap on the dimmed page beside it closes it, as one above it does.
class _TapBeside extends StatelessWidget {
  const _TapBeside({required this.close, required this.child});

  final VoidCallback close;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: close,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: child,
      ),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.builder,
    required this.scrollController,
    this.footer,
  });

  final String? title;
  final WidgetBuilder builder;
  final WidgetBuilder? footer;

  // The route's: a drag on the words at their top moves the sheet.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final framed = size.width >= 600;
    // Edge to edge on a phone, the sheet's words stand on the page margin;
    // framed, inset by the panel's own.
    final side = framed
        ? GlossSpacing.large
        : GlossSpacing.pageMargin(size.width);
    final words = DesignLocalizations.of(context);
    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The grip: a short slot pressed into the panel's top. The whole
        // panel drags (the route's); its close bead closes it for keys and
        // screen readers.
        Padding(
          padding: const EdgeInsets.only(
            top: GlossSpacing.small,
            bottom: GlossSpacing.tight,
          ),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 6,
              child: GlossSurface(face: GlossFace.well(c)),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: side),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      header: true,
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.title,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: framed ? GlossSpacing.regular : side,
                ),
                child: GlossIconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: words.closeButtonLabel,
                  icon: const Icon(LucideIcons.x, size: 18),
                  style: const GlossStyle(
                    minimumSize: WidgetStatePropertyAll(Size(32, 32)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              side,
              GlossSpacing.small,
              side,
              footer != null
                  ? GlossSpacing.regular
                  : GlossSpacing.large + (framed ? 0 : pad.bottom),
            ),
            child: DesignKeylineRegion(
              label: title ?? 'Sheet',
              child: DefaultTextStyle.merge(
                style: theme.textTheme.body,
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              GlossSpacing.small,
              side,
              GlossSpacing.large + (framed ? 0 : pad.bottom),
            ),
            child: Builder(builder: footer!),
          ),
      ],
    );
    // A phone's panel runs a corner's height past the screen's foot, so only
    // its top corners show.
    final sheet = GlossSurface(
      face: _panel(c),
      child: framed
          ? panel
          : Padding(
              padding: const EdgeInsets.only(bottom: GlossMetrics.panelRadius),
              child: panel,
            ),
    );
    // The route names it for a screen reader (its title).
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: framed ? 560 : double.infinity,
        maxHeight: size.height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: framed ? GlossSpacing.large : 0,
          left: framed ? GlossSpacing.large : 0,
          right: framed ? GlossSpacing.large : 0,
        ),
        child: framed
            ? sheet
            : Transform.translate(
                offset: const Offset(0, GlossMetrics.panelRadius),
                child: sheet,
              ),
      ),
    );
  }
}

/// The router's page for a route raised as a sheet: its screen on a glazed
/// panel risen from the bottom edge, a grip pressed into its top, edge to
/// edge on a phone and framed, 560 wide, from 600. It stands at most 88%
/// of the screen tall, or as tall as its content when [drawer];
/// [fullScreen] raises a whole page instead. Its screen reads the route as
/// a sheet ([RoutePresentation.sheet]), so the bar's way out is a close. A
/// tap on the scrim above it, Escape or Back closes it. A go_router route's
/// `pageBuilder` returns it with the route's `state.pageKey`.
///
/// ```dart
/// GlossSheetPage<void>(key: state.pageKey, child: const AddRecipePage())
/// ```
class GlossSheetPage<T> extends Page<T> {
  /// A sheet of [child].
  const GlossSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The sheet's screen, usually a `GlossScreen`.
  final Widget child;

  /// Whether it stands as tall as its content rather than 88% of the
  /// screen.
  final bool drawer;

  /// Whether it is raised as a whole page rather than a sheet.
  final bool fullScreen;

  @override
  Route<T> createRoute(BuildContext context) {
    final theme = GlossTheme.of(context);
    // The page as it stands now: a router that updates the page in place
    // hands the route the new one.
    Widget current(BuildContext context) {
      final page = ModalRoute.of(context)?.settings;
      return page is GlossSheetPage ? page.child : child;
    }

    Widget scoped(Widget child) => GlossTheme(
      data: theme,
      child: RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: child,
      ),
    );
    if (fullScreen) {
      return PageRouteBuilder<T>(
        settings: this,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, _) => scoped(
          ColoredBox(color: theme.colors.page, child: current(context)),
        ),
        transitionsBuilder: (context, animation, _, child) => _Arrive(
          animation: animation,
          from: const Offset(0, 1),
          child: child,
        ),
      );
    }
    // A drawer stands at its content's height; a sheet rests at 88% of
    // the screen, its screen scrolling in it.
    return _SheetRoute<T>(
      settings: this,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim, 300),
      snapSizes: drawer ? null : const [0.88],
      ms: 300,
      builder: (context, details) => scoped(
        _Fade(
          animation: details.animation,
          ms: 300,
          child: _TapBeside(
            close: details.close,
            child: _PageSheet(
              drawer: drawer,
              child: Builder(builder: current),
            ),
          ),
        ),
      ),
    );
  }
}

/// A [GlossSheetPage]'s panel: the glaze, the grip, and the screen under
/// it, framed as [showGlossSheet]'s.
class _PageSheet extends StatelessWidget {
  const _PageSheet({required this.drawer, required this.child});

  final bool drawer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final size = MediaQuery.sizeOf(context);
    final framed = size.width >= GlossMetrics.railBreakpoint;
    final panel = Column(
      mainAxisSize: drawer ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The grip: a short slot pressed into the panel's top. The whole
        // panel drags (the route's); its close bead closes it for keys and
        // screen readers.
        Padding(
          padding: const EdgeInsets.only(
            top: GlossSpacing.small,
            bottom: GlossSpacing.tight,
          ),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 6,
              child: GlossSurface(face: GlossFace.well(c)),
            ),
          ),
        ),
        if (drawer) Flexible(child: child) else Expanded(child: child),
      ],
    );
    // A phone's panel runs a corner's height past the screen's foot, so only
    // its top corners show.
    final sheet = GlossSurface(
      face: _panel(c),
      child: framed
          ? panel
          : Padding(
              padding: const EdgeInsets.only(bottom: GlossMetrics.panelRadius),
              child: panel,
            ),
    );
    final body = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: framed ? 560 : double.infinity,
        maxHeight: size.height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: framed ? GlossSpacing.large : 0,
          left: framed ? GlossSpacing.large : 0,
          right: framed ? GlossSpacing.large : 0,
        ),
        child: framed
            ? sheet
            : Transform.translate(
                offset: const Offset(0, GlossMetrics.panelRadius),
                child: sheet,
              ),
      ),
    );
    return body;
  }
}

/// Shows a side sheet [builder] fills: a porcelain panel the page's height
/// sliding in from the reading end (or [edge]), rounded on its inner side,
/// its [title] and a close bead at the top. A drag toward its edge, a press
/// on the dimmed page or Escape closes it.
///
/// ```dart
/// showGlossSideSheet<void>(context: context, title: 'Filters', builder: (context) => const Text('Vegetarian'))
/// ```
Future<T?> showGlossSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  WidgetBuilder? footerBuilder,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = 380,
}) {
  final theme = GlossTheme.of(context);
  final words = DesignLocalizations.of(context);
  // Over the whole window (a sidebar included), as a sheet and a dialog are.
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierBuilder: _scrim(theme.colors.scrim, 340),
      barrierLabel: words.modalBarrierDismissLabel,
      semanticLabel: title,
      // The panel's own spring (M3 eased it in over 340 ms, a curve no
      // spring from rest follows); its scrim on that clock, its fall over
      // 340 ms.
      dampingRatio: GlossMotion.panelDamping,
      stiffness: GlossMotion.panelStiffness,
      closeDampingRatio: _fallDamping,
      closeStiffness: _fallStiffness(340),
      builder: (context, sheet) => GlossTheme(
        data: theme,
        child: _SidePanel(
          info: sheet,
          title: title,
          builder: builder,
          footer: footerBuilder,
        ),
      ),
    ),
  );
}

/// The side sheet's route: as the sheet's, its barrier is no node of its own
/// for a screen reader (it would outline the whole window, past what a tap
/// reaches); the panel's close bead and Escape close it.
class _SideSheetRoute<T> extends DesignSideSheetRoute<T> {
  _SideSheetRoute({
    required super.builder,
    super.edge,
    super.width,
    super.barrierBuilder,
    super.barrierLabel,
    super.semanticLabel,
    super.dampingRatio,
    super.stiffness,
    super.closeDampingRatio,
    super.closeStiffness,
  });

  @override
  bool get semanticsDismissible => false;
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.info,
    required this.title,
    required this.builder,
    required this.footer,
  });

  final DesignSheetInfo info;
  final String? title;
  final WidgetBuilder builder;
  final WidgetBuilder? footer;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final pad = MediaQuery.paddingOf(context);
    // It runs the window's whole height, so its corners are square: a
    // rounded one would show the window's own top bar through it.
    final face = _panel(c).copyWith(corners: BorderRadius.zero);
    return GlossSurface(
      face: face,
      child: Padding(
        padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: GlossSpacing.large,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Semantics(
                          header: true,
                          child: Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.title,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: GlossSpacing.regular,
                    ),
                    child: GlossIconButton(
                      onPressed: info.close,
                      tooltip: words.closeButtonLabel,
                      icon: const Icon(LucideIcons.x, size: 18),
                      style: const GlossStyle(
                        minimumSize: WidgetStatePropertyAll(Size(32, 32)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  GlossSpacing.large,
                  GlossSpacing.tight,
                  GlossSpacing.large,
                  GlossSpacing.large,
                ),
                child: DesignKeylineRegion(
                  label: title ?? 'Side sheet',
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.body,
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GlossSpacing.large,
                  GlossSpacing.small,
                  GlossSpacing.large,
                  GlossSpacing.large,
                ),
                child: Builder(builder: footer!),
              ),
          ],
        ),
      ),
    );
  }
}

/// One of an action sheet's keys.
@immutable
class GlossSheetAction<T> {
  /// A key reading [label] that closes the sheet with [value].
  const GlossSheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructiveAction = false,
    this.enabled = true,
  });

  /// Its words.
  final String label;

  /// What the sheet closes with when it is pressed.
  final T value;

  /// Its glyph.
  final IconData? icon;

  /// Whether it destroys something: danger ink.
  final bool isDestructiveAction;

  /// Whether it can be pressed.
  final bool enabled;
}

/// Shows an action sheet: a few things to do with what was pressed, as
/// pearl keys stacked on a porcelain panel rising from the foot, a cancel
/// key apart under them. It closes with the pressed key's value, or null.
///
/// ```dart
/// showGlossActionSheet<String>(context: context, title: 'Lemon risotto', actions: const [GlossSheetAction(label: 'Add to week', value: 'add'), GlossSheetAction(label: 'Delete', value: 'delete', isDestructiveAction: true)])
/// ```
Future<T?> showGlossActionSheet<T>({
  required BuildContext context,
  required List<GlossSheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
}) {
  final theme = GlossTheme.of(context);
  final words = DesignLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      barrierLabel: words.modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim, 340),
      semanticLabel: title,
      ms: 340,
      builder: (context, details) => GlossTheme(
        data: theme,
        child: _Fade(
          animation: details.animation,
          ms: 340,
          child: _TapBeside(
            close: details.close,
            child: _ActionSheet<T>(
              title: title,
              message: message,
              actions: actions,
              cancelLabel: cancelLabel ?? words.cancelButtonLabel,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ActionSheet<T> extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.message,
    required this.actions,
    required this.cancelLabel,
  });

  final String? title;
  final String? message;
  final List<GlossSheetAction<T>> actions;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final pad = MediaQuery.paddingOf(context);
    final navigator = Navigator.of(context);
    // The route names it for a screen reader (its title).
    return Semantics(
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            GlossSpacing.small,
            0,
            GlossSpacing.small,
            GlossSpacing.small + pad.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlossSurface(
                face: _panel(c),
                child: Padding(
                  padding: const EdgeInsets.all(GlossSpacing.regular),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null)
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.label.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      if (message != null) ...[
                        const SizedBox(height: GlossSpacing.tight),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.secondary,
                        ),
                      ],
                      if (title != null || message != null)
                        const SizedBox(height: GlossSpacing.regular),
                      for (final (i, a) in actions.indexed) ...[
                        if (i > 0) const SizedBox(height: GlossSpacing.small),
                        GlossButton(
                          a.label,
                          icon: a.icon == null ? null : Icon(a.icon),
                          isDestructiveAction: a.isDestructiveAction,
                          onPressed: a.enabled
                              ? () => navigator.pop<T>(a.value)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GlossSpacing.small),
              GlossSurface(
                face: _panel(c),
                child: Padding(
                  padding: const EdgeInsets.all(GlossSpacing.small),
                  child: GlossButton.text(
                    cancelLabel,
                    onPressed: () => navigator.pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where Gloss's toasts float: put it once under [GlossTheme], above the
/// navigator, and call [showGlossToast].
///
/// ```dart
/// GlossToaster(child: child)
/// ```
class GlossToaster extends StatelessWidget {
  /// Toasts over [child].
  const GlossToaster({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) => DesignToaster(
    dampingRatio: GlossMotion.panelDamping,
    stiffness: GlossMotion.panelStiffness,
    constraints: const BoxConstraints(maxWidth: 480),
    padding: const EdgeInsets.fromLTRB(
      GlossSpacing.regular,
      GlossSpacing.regular,
      GlossSpacing.regular,
      GlossSpacing.large,
    ),
    toastBuilder: (context, details) => _Toast(details),
    child: child,
  );
}

class _Toast extends StatelessWidget {
  const _Toast(this.details);

  final DesignToastDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final words = DesignLocalizations.of(context);
    final opacity = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    final face = GlossFace.pearl(c, radius: 26).copyWith(
      lens: c.brightness == Brightness.light ? 0.55 : 0.2,
      focus: glossFocusOf(c, focused: details.focused),
    );
    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: details.animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - details.animation.value) * 16),
          child: child,
        ),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: GlossSurface(
            face: face,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: GlossSpacing.large - 4,
                  end: GlossSpacing.small - 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: GlossSpacing.medium,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.title != null)
                              Text(t.title!, style: theme.textTheme.label),
                            Text(
                              t.message,
                              style: theme.textTheme.body.copyWith(
                                fontSize: 15,
                                height: 20 / 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (t.actionLabel != null && details.runAction != null) ...[
                      const SizedBox(width: GlossSpacing.small),
                      GlossButton.text(
                        t.actionLabel!,
                        onPressed: details.runAction,
                      ),
                      const SizedBox(width: GlossSpacing.tight),
                    ],
                    GlossIconButton.plain(
                      onPressed: details.dismiss,
                      tooltip: words.closeButtonLabel,
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
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

/// Shows [message] in a toast at the foot of the screen for [duration]
/// (null keeps it until closed), with an [actionLabel] key that runs
/// [onAction].
///
/// ```dart
/// showGlossToast(context, 'Added to Thursday', actionLabel: 'Undo')
/// ```
DesignToastHandle showGlossToast(
  BuildContext context,
  String message, {
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration = const Duration(seconds: 4),
}) => DesignToaster.of(context).show(
  DesignToast(
    message: message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  ),
);
