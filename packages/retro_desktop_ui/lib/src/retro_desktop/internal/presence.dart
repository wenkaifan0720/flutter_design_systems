// A raised panel's presence in the look's own time. ui_core runs an anchored overlay's presence on a spring (0 to 1
// as it opens, 1 to 0 as it closes, critically damped, about a quarter second) and keeps the panel until that spring
// settles. Faded on it, a menu came in over a quarter second and lingered as long after its item was chosen, where the
// look raises and lowers at once (RetroDesktopMotion's raise and leave, zero by default), as the period's menus did.
import 'package:flutter/widgets.dart';

import '../behavior.dart' show RetroDesktopMotion;

/// [child], a panel ui_core raises on [animation], whole from its first frame while it opens or stands, and gone (no
/// paint, no hit, no semantics; its size kept) from the first frame its spring falls. A motion with a [RetroDesktopMotion.raise]
/// fades it in on the spring; one with a [RetroDesktopMotion.leave] fades it out; Reduce Motion makes both instant.
class RetroDesktopPresence extends StatefulWidget {
  /// Shows [child] on [animation].
  const RetroDesktopPresence({
    super.key,
    required this.animation,
    required this.child,
  });

  /// ui_core's presence: 0 to 1 as the panel opens, 1 to 0 as it closes.
  final Animation<double> animation;

  /// The panel.
  final Widget child;

  @override
  State<RetroDesktopPresence> createState() => _RetroDesktopPresenceState();
}

class _RetroDesktopPresenceState extends State<RetroDesktopPresence> {
  late double _last = widget.animation.value;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_moved);
  }

  @override
  void didUpdateWidget(RetroDesktopPresence old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      old.animation.removeListener(_moved);
      widget.animation.addListener(_moved);
      _last = widget.animation.value;
      _leaving = false;
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_moved);
    super.dispose();
  }

  // The spring rises as the panel opens (or opens again mid-close) and falls only as it closes; critically damped,
  // it never turns back on its own.
  void _moved() {
    final value = widget.animation.value;
    final leaving = value < _last
        ? true
        : value > _last
        ? false
        : _leaving;
    _last = value;
    if (leaving != _leaving) setState(() => _leaving = leaving);
  }

  @override
  Widget build(BuildContext context) {
    final motion = RetroDesktopMotion.of(context);
    final fades = _leaving
        ? motion.leave != Duration.zero
        : motion.raise != Duration.zero;
    final gone = _leaving && !fades;
    // Gone keeps its size (ui_core sizes the panel by its intrinsic width; an Offstage one measured 0, and its rows
    // overflowed a 20-pixel panel while the spring ran out).
    return IgnorePointer(
      ignoring: gone,
      child: ExcludeSemantics(
        excluding: gone,
        child: FadeTransition(
          opacity: gone
              ? kAlwaysDismissedAnimation
              : fades
              ? widget.animation.drive(const _Clamp())
              : kAlwaysCompleteAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

// The spring's value as an opacity (an underdamped one passes 1).
class _Clamp extends Animatable<double> {
  const _Clamp();

  @override
  double transform(double t) => t.clamp(0.0, 1.0);
}
