import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/menu_row.dart';
import '../../internal/paint.dart';
import '../../theme.dart';

/// A short [message] naming [child] (most often a [CivicIconButton]'s
/// glyph): an ink plate with the page's colour for its words (by night the
/// light plate with dark words), shown while a pointer rests on [child],
/// at once when the keyboard reaches it, and after a long press: Flutter's
/// [RawTooltip], Civic's painting.
///
/// It names; it never holds what the reader must know (a tip is missed on a
/// phone and by many readers): what the page needs said, it says in words
/// of its own. A screen reader hears [message] on [child] itself.
///
/// The plate rises on Civic's spring from the side it opens on (a quick
/// fade under Reduce Motion). Escape hides it; the pointer may cross onto it and it
/// stays.
///
/// Reads [CivicStyle]'s fill (the plate), foreground, padding and
/// textStyle (the words): its `style:`, then [CivicThemeData.tooltipStyle].
///
/// ```dart
/// CivicTooltip(
///   message: 'Print this page',
///   child: CivicIconButton(icon: LucideIcons.printer, semanticLabel: 'Print this page', onPressed: () {}),
/// )
/// ```
class CivicTooltip extends StatelessWidget {
  /// A tooltip of [message] for [child].
  const CivicTooltip({
    super.key,
    required this.message,
    required this.child,
    this.side = RawPopoverSide.above,
    this.triggerMode = TooltipTriggerMode.longPress,
    this.excludeFromSemantics = false,
    this.style,
  });

  /// What it says. Empty: no tooltip.
  final String message;

  /// The control it names.
  final Widget child;

  /// The side of [child] it prefers: above by default, below where there is
  /// no room.
  final RawPopoverSide side;

  /// What a finger does to show it: a long press by default.
  final TooltipTriggerMode triggerMode;

  /// Whether a screen reader is left without [message]: only where [child]
  /// already says it (its label is the message).
  final bool excludeFromSemantics;

  /// Overrides for this tooltip's look.
  final CivicStyle? style;

  /// The widest a tip stands before its words wrap.
  static const double maxWidth = 280;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    // Over no Overlay (a toast shown above the app's Navigator) there is
    // nowhere to float the tip: the child keeps its words for a reader.
    if (Overlay.maybeOf(context) == null) {
      if (excludeFromSemantics) return child;
      return MergeSemantics(
        child: Semantics(tooltip: message, child: child),
      );
    }
    return MergeSemantics(
      child: RawTooltipPlacement(
        placement: RawPopoverPlacement(
          side: side,
          align: RawPopoverAlign.center,
          gap: CivicSpacing.s4,
          preferredExtent: 48,
          matchAnchorWidth: false,
          maxWidth: maxWidth,
        ),
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: excludeFromSemantics ? null : message,
          hoverDelay: const Duration(milliseconds: 500),
          triggerMode: triggerMode,
          positionDelegate: positionDelegate,
          animationStyle: _TipSpring.life,
          tooltipBuilder: (context, animation) => ExcludeSemantics(
            child: _TipSpring(
              showing: animation,
              builder: (context, presence) => _plate(context, presence),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  Widget _plate(BuildContext context, Animation<double> presence) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.tooltipStyle], const {});
    final plate = so.fill ?? t.textPrimary;
    return civicRise(
      animation: presence,
      fromAbove: RawTooltipPlacement.sideOf(context) == RawPopoverSide.below,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: plate,
            borderRadius: BorderRadius.circular(CivicMetrics.corner),
          ),
          child: Padding(
            padding:
                so.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(
                  horizontal: CivicSpacing.s12,
                  vertical: CivicSpacing.s8,
                ),
            child: Text(
              message,
              style: text.bodySmall
                  .merge(so.textStyle)
                  .copyWith(color: so.foreground ?? t.background),
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
      ..add(StringProperty('message', message))
      ..add(
        EnumProperty<RawPopoverSide>(
          'side',
          side,
          defaultValue: RawPopoverSide.above,
        ),
      )
      ..add(
        EnumProperty<TooltipTriggerMode>(
          'triggerMode',
          triggerMode,
          defaultValue: TooltipTriggerMode.longPress,
        ),
      )
      ..add(
        FlagProperty(
          'excludeFromSemantics',
          value: excludeFromSemantics,
          ifTrue: 'excludeFromSemantics',
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A tip's presence on ui_core's effects spring, following [RawTooltip]'s
/// animation: up as it starts forward, down as it starts back.
class _TipSpring extends StatefulWidget {
  const _TipSpring({required this.showing, required this.builder});

  /// How long the [RawTooltip] keeps a hidden tip in the overlay: longer
  /// than the spring takes to settle (about 230 ms).
  static const AnimationStyle life = AnimationStyle(
    duration: Duration(milliseconds: 150),
    reverseDuration: Duration(milliseconds: 300),
  );

  final Animation<double> showing;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipSpring> createState() => _TipSpringState();
}

class _TipSpringState extends State<_TipSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(vsync: this);
  bool? _shown;

  @override
  void initState() {
    super.initState();
    widget.showing.addStatusListener(_follow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow(widget.showing.status);
  }

  @override
  void didUpdateWidget(_TipSpring old) {
    super.didUpdateWidget(old);
    if (old.showing != widget.showing) {
      old.showing.removeStatusListener(_follow);
      widget.showing.addStatusListener(_follow);
      _follow(widget.showing.status);
    }
  }

  @override
  void dispose() {
    widget.showing.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final shown = status.isForwardOrCompleted;
    if (shown == _shown) return;
    _shown = shown;
    _presence.springTo(
      shown ? 1 : 0,
      DesignMotionPolicy.of(context).effects(dampingRatio: 1, stiffness: 1600),
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _presence);
}
