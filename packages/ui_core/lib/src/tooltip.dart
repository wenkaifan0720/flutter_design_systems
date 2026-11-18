/// A tooltip, headless: a short message beside a control, shown while a
/// pointer rests on it, while it has the keyboard's focus, or after a long
/// press, and readable by a screen reader on the control itself. The look
/// paints the tip.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'haptics.dart';
import 'internal/placement.dart';
import 'motion.dart';

/// A tooltip of [message] for [child], painted by [tooltipBuilder].
///
/// It shows:
/// - when a pointer rests on [child] for [hoverDelay];
/// - at once when [child] takes the keyboard's focus (the focus a Tab
///   gives, not a tap's);
/// - after a long press of a finger or a stylus ([triggerMode]), with the
///   long press's haptic ([DesignHaptics.longPress]) when [enableFeedback],
///   and stays [touchDelay] after the finger lifts.
///
/// As WCAG 1.4.13 asks of content shown on hover or focus, the pointer may
/// move from [child] onto the tip and it stays (hoverable); Escape hides it
/// without moving the pointer or the focus, and goes no further when it hid
/// one (dismissible); and it stays until the pointer or the focus leaves
/// (persistent). A tap anywhere but on the tip hides it too.
///
/// One tooltip shows at a time, app-wide. While one shows, and for
/// [warmUpDuration] after it hid, the next shows at once: running the
/// pointer along a toolbar reads each control's tip without the wait. A
/// route pushed over [child] hides it.
///
/// A screen reader hears [message] as [child]'s tooltip, [child] and the
/// message one node; the tip itself is left out of the semantics tree, so
/// the words are not read twice. Put it round one control (a button, an
/// icon), as a tip belongs to one.
///
/// The tip fades in and out on an effects spring ([DesignMotionPolicy]):
/// under Reduce Motion, a short fade.
///
/// ```dart
/// DesignTooltip(message: 'Save the report', tooltipBuilder: (context, info) => Text('Save the report'), child: const Text('Save'))
/// ```
class DesignTooltip extends StatefulWidget {
  /// A tooltip of [message] for [child].
  const DesignTooltip({
    super.key,
    required this.message,
    required this.tooltipBuilder,
    required this.child,
    this.placement = defaultPlacement,
    this.hoverDelay = const Duration(milliseconds: 500),
    this.dismissDelay = const Duration(milliseconds: 100),
    this.touchDelay = const Duration(milliseconds: 1500),
    this.triggerMode = TooltipTriggerMode.longPress,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
  });

  /// What it says; a screen reader hears it as [child]'s tooltip. Empty: no
  /// tooltip at all.
  final String message;

  /// Paints the tip: [DesignOverlayInfo.side] is the side of [child] it
  /// took, [DesignOverlayInfo.animation] its presence (0 hidden, 1 shown),
  /// and [DesignOverlayInfo.surfaceRect] where it landed, for a tail that
  /// points at [child]. It never takes the focus.
  final DesignOverlaySurfaceBuilder tooltipBuilder;

  /// The control it describes.
  final Widget child;

  /// Where the tip goes: [defaultPlacement] by default. Wherever it goes,
  /// it keeps clear of the screen's edges, the on-screen keyboard and a
  /// [DesignOverlayPadding].
  final DesignOverlayPlacement placement;

  /// Above [child], centred on it, 4 px from it; below where there are
  /// fewer than 48 px above (two lines of a tip) and more below.
  static const DesignOverlayPlacement defaultPlacement = DesignOverlayPlacement(
    side: DesignOverlaySide.above,
    align: DesignOverlayAlign.center,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  /// How long a pointer rests on [child] before it shows; 500 ms by
  /// default. Within [warmUpDuration] of another tip, none.
  final Duration hoverDelay;

  /// How long it stays after the pointer leaves [child] and the tip; 100 ms
  /// by default, time to cross the gap between them.
  final Duration dismissDelay;

  /// How long it stays after a long press (or a tap, in
  /// [TooltipTriggerMode.tap]) lets go; 1.5 s by default.
  final Duration touchDelay;

  /// What a finger does to show it: [TooltipTriggerMode.longPress] (the
  /// default), [TooltipTriggerMode.tap], or [TooltipTriggerMode.manual]
  /// (nothing: the child's own long press keeps its meaning). A pointer's
  /// hover and the keyboard's focus show it in every mode.
  final TooltipTriggerMode triggerMode;

  /// Whether a long press that shows it plays [DesignHaptics.longPress];
  /// true by default.
  final bool enableFeedback;

  /// Whether a screen reader is left without [message]; false by default.
  /// True only where [child] already says it (its label is the message).
  final bool excludeFromSemantics;

  /// How long after a tip hid the next shows at once, with no
  /// [hoverDelay]: 300 ms.
  static const Duration warmUpDuration = Duration(milliseconds: 300);

  /// Hides the tip that shows, if one does; true when one did (Flutter's
  /// `Tooltip.dismissAllToolTips`).
  static bool dismissAll() {
    final shown = _DesignTooltipState._shown;
    if (shown == null) return false;
    shown._hide(dismissed: true);
    return true;
  }

  @override
  State<DesignTooltip> createState() => _DesignTooltipState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        ObjectFlagProperty<DesignOverlaySurfaceBuilder>.has(
          'tooltipBuilder',
          tooltipBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<DesignOverlayPlacement>(
          'placement',
          placement,
          defaultValue: defaultPlacement,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'hoverDelay',
          hoverDelay,
          defaultValue: const Duration(milliseconds: 500),
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'dismissDelay',
          dismissDelay,
          defaultValue: const Duration(milliseconds: 100),
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'touchDelay',
          touchDelay,
          defaultValue: const Duration(milliseconds: 1500),
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
          'enableFeedback',
          value: enableFeedback,
          ifFalse: 'no haptic',
        ),
      )
      ..add(
        FlagProperty(
          'excludeFromSemantics',
          value: excludeFromSemantics,
          ifTrue: 'excluded from semantics',
        ),
      );
  }
}

// A finger or a stylus: a mouse shows it by resting.
const Set<PointerDeviceKind> _touchKinds = {
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

class _DesignTooltipState extends State<DesignTooltip>
    with SingleTickerProviderStateMixin {
  // The tip that shows, app-wide; whether the next shows at once; and the
  // tooltip whose timer cools it (its own, so a tooltip disposed takes its
  // timer with it).
  static _DesignTooltipState? _shown;
  static bool _warm = false;
  static _DesignTooltipState? _warmFrom;

  final OverlayPortalController _portal = OverlayPortalController(
    debugLabel: 'DesignTooltip',
  );
  // Bounded: a tip's presence is an opacity, 0 to 1.
  late final AnimationController _presence = AnimationController(vsync: this);
  final DesignSurfaceRect _placed = DesignSurfaceRect();
  Timer? _showTimer;
  Timer? _hideTimer;
  Timer? _coolDown;
  // The child and its tip, kept as the semantics round them come and go.
  final GlobalKey _childKey = GlobalKey(debugLabel: 'DesignTooltip child');

  // What holds it up: a pointer on the child or on the tip, the keyboard's
  // focus in the child, a finger's long press until it lets go.
  bool _overChild = false;
  bool _overTip = false;
  bool _focused = false;
  bool _pressing = false;

  // Hidden by Escape, a tap or dismissAll: it stays hidden until what held
  // it up lets go (the pointer leaves, the focus moves).
  bool _dismissed = false;

  bool _routeCurrent = true;

  bool get _enabled => widget.message.isNotEmpty;

  bool get _isShown => identical(_shown, this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (!_routeCurrent && _isShown) _hide();
  }

  @override
  void didUpdateWidget(DesignTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _isShown) _hide();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (_isShown) {
      _shown = null;
      _warm = false;
      FocusManager.instance.removeEarlyKeyEventHandler(_escape);
    }
    if (identical(_warmFrom, this)) {
      _coolDown?.cancel();
      _warmFrom = null;
      _warm = false;
    }
    _presence.dispose();
    _placed.dispose();
    super.dispose();
  }

  // Warm for [DesignTooltip.warmUpDuration] from now, on this one's timer.
  void _coolDownFrom() {
    _warmFrom?._coolDown?.cancel();
    _warmFrom = this;
    _warm = true;
    _coolDown = Timer(DesignTooltip.warmUpDuration, () {
      _warm = false;
      _warmFrom = null;
    });
  }

  SpringDescription get _spring =>
      DesignMotionPolicy.of(context).effects(dampingRatio: 1, stiffness: 1600);

  void _show() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (!mounted || !_enabled || !_routeCurrent || _dismissed) return;
    if (_isShown) return;
    _shown?._hide();
    _shown = this;
    _warmFrom?._coolDown?.cancel();
    _warmFrom = null;
    _warm = true;
    FocusManager.instance.addEarlyKeyEventHandler(_escape);
    _portal.show();
    _presence.springTo(1, _spring);
  }

  void _hide({bool dismissed = false}) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (!_isShown) return;
    if (dismissed) _dismissed = true;
    _shown = null;
    _coolDownFrom();
    FocusManager.instance.removeEarlyKeyEventHandler(_escape);
    // Completes only when the fade-out ran to its end (a show before then
    // takes the controller over, and this never completes).
    _presence.springTo(0, _spring).whenComplete(() {
      if (mounted && !_isShown) _portal.hide();
    });
  }

  // Shows after [delay], or at once when warm.
  void _showAfter(Duration delay) {
    _hideTimer?.cancel();
    if (_isShown) return;
    if (_warm || delay == Duration.zero) {
      _show();
      return;
    }
    _showTimer?.cancel();
    _showTimer = Timer(delay, _show);
  }

  void _hideAfter(Duration delay) {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    if (delay == Duration.zero) {
      _hide();
    } else {
      _hideTimer = Timer(delay, _hide);
    }
  }

  // Nothing holds it up any more: it goes after [delay].
  void _letGo(Duration delay) {
    if (_overChild || _overTip || _focused || _pressing) return;
    _dismissed = false;
    if (_isShown) {
      _hideAfter(delay);
    } else {
      _showTimer?.cancel();
    }
  }

  // Escape, while it shows: hides it, and the key goes no further.
  KeyEventResult _escape(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !_isShown) {
      return KeyEventResult.ignored;
    }
    _hide(dismissed: true);
    return KeyEventResult.handled;
  }

  void _childEnter(PointerEnterEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    _overChild = true;
    _showAfter(widget.hoverDelay);
  }

  void _childExit(PointerExitEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    _overChild = false;
    _letGo(widget.dismissDelay);
  }

  void _tipEnter(PointerEnterEvent _) {
    _overTip = true;
    _hideTimer?.cancel();
  }

  void _tipExit(PointerExitEvent _) {
    _overTip = false;
    _letGo(widget.dismissDelay);
  }

  void _focusChanged(bool focused) {
    _focused =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_focused) {
      _show();
    } else {
      _letGo(Duration.zero);
    }
  }

  void _longPressStart(LongPressStartDetails _) {
    if (!_enabled) return;
    _pressing = true;
    _dismissed = false;
    if (widget.enableFeedback) DesignHaptics.of(context).longPress?.call();
    _show();
  }

  void _longPressEnd(LongPressEndDetails _) {
    _pressing = false;
    if (_isShown && !_overChild && !_focused) _hideAfter(widget.touchDelay);
  }

  void _tap() {
    if (!_enabled) return;
    _dismissed = false;
    _show();
    if (_isShown) _hideAfter(widget.touchDelay);
  }

  Widget _tip(BuildContext context, OverlayChildLayoutInfo layout) {
    final direction = Directionality.of(context);
    final anchor = MatrixUtils.transformRect(
      layout.childPaintTransform,
      Offset.zero & layout.childSize,
    );
    final placement = widget.placement;
    final bounds = designOverlayBounds(
      overlaySize: layout.overlaySize,
      view: _overlayView(context),
      padding: DesignOverlayPadding.of(context),
      margin: placement.margin,
    );
    final side = designResolveSide(anchor, bounds, placement, direction);
    final maxSize = designOverlayMaxSize(
      anchor,
      bounds,
      side,
      placement.gap,
      direction,
    );
    final info = DesignOverlayInfo(
      side: side,
      anchorRect: anchor,
      maxSize: maxSize,
      animation: _presence,
      close: _hide,
      surfaceRect: _placed,
    );
    Widget tip = ExcludeSemantics(child: widget.tooltipBuilder(context, info));
    tip = MouseRegion(onEnter: _tipEnter, onExit: _tipExit, child: tip);
    tip = TapRegion(onTapOutside: (_) => _hide(dismissed: true), child: tip);
    return ConstrainedBox(
      constraints: BoxConstraints.loose(layout.overlaySize),
      child: CustomSingleChildLayout(
        delegate: DesignOverlayLayout(
          anchor: anchor,
          bounds: bounds,
          side: side,
          placement: placement,
          textDirection: direction,
          maxSize: maxSize,
          placed: _placed,
        ),
        child: RepaintBoundary(child: tip),
      ),
    );
  }

  // The overlay's own view (the keyboard and the safe area as it has them),
  // with a dependency.
  MediaQueryData? _overlayView(BuildContext context) {
    final overlay = Overlay.maybeOf(context)?.context;
    final view = overlay?.getElementForInheritedWidgetOfExactType<MediaQuery>();
    if (view == null) return MediaQuery.maybeOf(context);
    context.dependOnInheritedElement(view);
    return (view.widget as MediaQuery).data;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    Widget child = widget.child;
    final mode = widget.triggerMode;
    child = GestureDetector(
      excludeFromSemantics: true,
      supportedDevices: _touchKinds,
      onLongPressStart: enabled && mode == TooltipTriggerMode.longPress
          ? _longPressStart
          : null,
      onLongPressEnd: enabled && mode == TooltipTriggerMode.longPress
          ? _longPressEnd
          : null,
      onTap: enabled && mode == TooltipTriggerMode.tap ? _tap : null,
      child: child,
    );
    child = MouseRegion(
      onEnter: enabled ? _childEnter : null,
      onExit: enabled ? _childExit : null,
      child: child,
    );
    child = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: enabled ? _focusChanged : null,
      child: child,
    );
    child = OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: _tip,
      child: child,
    );
    // Kept, with its state and the tip's, as the semantics round it come
    // and go.
    child = KeyedSubtree(key: _childKey, child: child);
    // The message joins the child's node: one control, one node.
    if (!enabled || widget.excludeFromSemantics) return child;
    return MergeSemantics(
      child: Semantics(tooltip: widget.message, child: child),
    );
  }
}
