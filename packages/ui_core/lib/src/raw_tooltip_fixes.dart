/// What Flutter's [RawTooltip] lacks for a look's tooltip, until Flutter has
/// it: showing on the keyboard's focus, and telling the tip which side of
/// the control it took.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'anchored_overlay.dart';
import 'internal/focus_visible.dart';
import 'internal/placement.dart';

/// Shows the tooltip round it while its child has the keyboard's focus, as
/// it shows while a pointer rests on the child.
///
/// Flutter's [RawTooltip] (and so a `Tooltip`) shows on a pointer's hover
/// and a finger's press, never on the keyboard's focus
/// (flutter/flutter#196554). Put this as the tooltip's child, round the
/// control: when the control takes the keys' focus (a Tab, not a tap), the
/// tip shows at once; when the focus leaves, the tip it showed goes, and a
/// Tab from one tipped control to the next shows the next one's. Escape hides
/// it (a hovered tip too, from Flutter 3.50).
///
/// Put the [RawTooltip] in a [MergeSemantics]. [RawTooltip] says its
/// `semanticsTooltip` on a [Semantics] round the control, and a control with
/// a node of its own (a button, a link) leaves it outside that node, so a
/// screen reader hears the tip apart from the control. Merged, the tip is on
/// the control's own node, as `DesignTooltip`, which merged its own, said it.
///
/// ```dart
/// RawTooltip(semanticsTooltip: 'Save the report', tooltipBuilder: (context, animation) => const Text('Save the report'), child: RawTooltipFocusFix(child: Focus(child: const Text('Save'))))
/// ```
// Remove it when ui_core's Flutter floor is a stable release whose RawTooltip
// shows on focus (flutter/flutter#196554).
class RawTooltipFocusFix extends StatefulWidget {
  /// Shows the tooltip round [child] while [child] has the keys' focus.
  const RawTooltipFocusFix({super.key, required this.child});

  /// The control the tooltip describes.
  final Widget child;

  @override
  State<RawTooltipFocusFix> createState() => _RawTooltipFocusFixState();
}

class _RawTooltipFocusFixState extends State<RawTooltipFocusFix> {
  // Whether the tip shows because of the focus here: only then does the
  // focus leaving hide it (a pointer may hold it up otherwise).
  bool _shown = false;

  // Whether the control has the focus, as last told.
  bool _focused = false;

  // Flutter 3.47's RawTooltip does not hide on Escape (3.50's does, flutter
  // #192966 and #193192), so this does while the tip it showed shows.
  KeyEventResult _escape(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !_shown) {
      return KeyEventResult.ignored;
    }
    _hide();
    return RawTooltip.dismissAllToolTips()
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  void _hide() {
    _shown = false;
    FocusManager.instance.removeEarlyKeyEventHandler(_escape);
  }

  void _focusChanged(bool focused) {
    _focused = focused;
    if (focused) {
      // Shown once the whole focus change is told: on a Tab from one tipped
      // control to the next, the control gaining the focus hears it first,
      // and the one losing it then dismisses every tip (RawTooltip hides no
      // single one), the next one's with it.
      scheduleMicrotask(_show);
    } else if (_shown) {
      _hide();
      RawTooltip.dismissAllToolTips();
    }
  }

  void _show() {
    // The keys' focus shows the tip; a pointer's does not (a dialog a click
    // opened, its safe action focused), as for :focus-visible.
    if (!mounted || !_focused || _shown || !DesignFocusVisible.shown) return;
    final tooltip = context.findAncestorStateOfType<RawTooltipState>();
    if (tooltip != null && tooltip.ensureTooltipVisible()) {
      _shown = true;
      FocusManager.instance.addEarlyKeyEventHandler(_escape);
    }
  }

  @override
  void dispose() {
    if (_shown) _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onFocusChange: _focusChanged,
    child: widget.child,
  );
}

/// Places a [RawTooltip]'s tip as ui_core places a popover, and tells the
/// tip which side of the control it took, for a tail that points at it.
///
/// [builder] builds the tooltip with the `positionDelegate` given. Flutter's
/// [RawTooltip] gives its `tooltipBuilder` only the animation, so the tip
/// reads the side with [RawTooltipPlacement.sideOf]: null until the tip has
/// been laid out once, then the side it took, a frame after it moved.
/// Wherever it goes, the tip keeps clear of the screen's edges, the
/// on-screen keyboard and a [RawPopoverPadding].
///
/// ```dart
/// RawTooltipPlacement(builder: (context, positionDelegate) => RawTooltip(semanticsTooltip: 'Save the report', positionDelegate: positionDelegate, tooltipBuilder: (context, animation) => Text('Save the report, ${RawTooltipPlacement.sideOf(context)}'), child: const Text('Save')))
/// ```
// Remove it when ui_core's Flutter floor is a stable release whose RawTooltip
// tells its tooltipBuilder where the tip went (no issue filed yet).
class RawTooltipPlacement extends StatefulWidget {
  /// Places the tip of the tooltip [builder] builds by [placement].
  const RawTooltipPlacement({
    super.key,
    this.placement = defaultPlacement,
    required this.builder,
  });

  /// Where the tip goes: [defaultPlacement] by default.
  final RawPopoverPlacement placement;

  /// Above the control, centred on it, 4 px from it; below where there are
  /// fewer than 48 px above (two lines of a tip) and more below.
  static const RawPopoverPlacement defaultPlacement = RawPopoverPlacement(
    side: RawPopoverSide.above,
    align: RawPopoverAlign.center,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  /// Builds the [RawTooltip], with `positionDelegate` as its own.
  final Widget Function(
    BuildContext context,
    TooltipPositionDelegate positionDelegate,
  )
  builder;

  /// The side of the control the tip at [context] took, from inside a
  /// [RawTooltipPlacement]'s tooltip: null before it was laid out. [context]
  /// builds again when it changes.
  static RawPopoverSide? sideOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TipSide>()?.notifier?.value;

  @override
  State<RawTooltipPlacement> createState() => _RawTooltipPlacementState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<RawPopoverPlacement>(
        'placement',
        placement,
        defaultValue: defaultPlacement,
      ),
    );
  }
}

class _RawTooltipPlacementState extends State<RawTooltipPlacement> {
  final ValueNotifier<RawPopoverSide?> _side = ValueNotifier(null);
  TextDirection _direction = TextDirection.ltr;
  MediaQueryData? _view;
  EdgeInsets _padding = EdgeInsets.zero;

  @override
  void dispose() {
    _side.dispose();
    super.dispose();
  }

  // RawTooltip lays its tip out in the overlay less the on-screen keyboard,
  // and gives [position] the tip's target (the control's centre) and size in
  // the overlay's coordinates.
  Offset _position(TooltipPositionContext tip) {
    final placement = widget.placement;
    final anchor = Rect.fromCenter(
      center: tip.target,
      width: tip.targetSize.width,
      height: tip.targetSize.height,
    );
    final bounds = designOverlayBounds(
      overlaySize: tip.overlaySize,
      view: _view?.removeViewInsets(removeBottom: true),
      padding: _padding,
      margin: placement.margin,
    );
    final side = designResolveSide(anchor, bounds, placement, _direction);
    final layout = DesignOverlayLayout(
      anchor: anchor,
      bounds: bounds,
      side: side,
      placement: placement,
      textDirection: _direction,
      maxSize: designOverlayMaxSize(
        anchor,
        bounds,
        side,
        placement.gap,
        _direction,
      ),
    );
    if (_side.value != side) {
      // Told after the frame that laid it out: the tip builds again then.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _side.value = side;
      }, debugLabel: 'RawTooltipPlacement.side');
      SchedulerBinding.instance.ensureVisualUpdate();
    }
    return layout.getPositionForChild(tip.overlaySize, tip.tooltipSize);
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
    _direction = Directionality.of(context);
    _view = _overlayView(context);
    _padding = RawPopoverPadding.of(context);
    return _TipSide(
      notifier: _side,
      child: Builder(builder: (context) => widget.builder(context, _position)),
    );
  }
}

class _TipSide extends InheritedNotifier<ValueNotifier<RawPopoverSide?>> {
  const _TipSide({required super.notifier, required super.child});
}
