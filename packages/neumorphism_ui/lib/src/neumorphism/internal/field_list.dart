// A field's own open list (a select's, a combobox's, a multi-select's): it stands clear of its field, and while it is
// up the field rests, the list showing where the keys are (the user's review, 11-18: a risen field's shadow landed on
// the panel it opened, a smudge where the two met).
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// How far a field's open list stands from the field, on whichever side it opens: clear of the field's face, so the
/// panel's own relief never meets the field's.
const double neumorphicFieldListGap = 8;

/// Over a field whose own list is open ([open]): its focus leaves its well at rest depth.
class NeumorphicFieldListOpen extends InheritedWidget {
  /// Marks [child]'s field as having its list open, or not.
  const NeumorphicFieldListOpen({
    super.key,
    required this.open,
    required super.child,
  });

  /// Whether the field's own list is up.
  final bool open;

  /// Whether the field at [context] has its own list up.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<NeumorphicFieldListOpen>()
          ?.open ??
      false;

  @override
  bool updateShouldNotify(NeumorphicFieldListOpen oldWidget) =>
      open != oldWidget.open;
}

/// A field that opens a list of its own: [builder] builds it with [list], through which the list's surface goes. The
/// surface then stands [neumorphicFieldListGap] clear of the field, and the field under this reads
/// [NeumorphicFieldListOpen] while a surface is up (counted, so a list replacing its loading row stays open).
class NeumorphicFieldListOwner extends StatefulWidget {
  /// A field built by [builder].
  const NeumorphicFieldListOwner({super.key, required this.builder});

  /// The field, given whether its list is up and the wrap for its list's surface.
  final Widget Function(
    BuildContext context,
    bool open,
    Widget Function(Widget surface) list,
  )
  builder;

  @override
  State<NeumorphicFieldListOwner> createState() =>
      _NeumorphicFieldListOwnerState();
}

class _NeumorphicFieldListOwnerState extends State<NeumorphicFieldListOwner> {
  var _lists = 0;
  var _open = false;

  // A surface comes and goes while the tree builds; the field follows once the frame is done.
  void _count(int by) {
    _lists += by;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open != _lists > 0) setState(() => _open = _lists > 0);
    });
  }

  Widget _list(Widget surface) => _Surface(
    count: _count,
    // On both sides, as the list opens below the field or above it; the side it does not open on is empty room.
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: neumorphicFieldListGap),
      child: surface,
    ),
  );

  @override
  Widget build(BuildContext context) => NeumorphicFieldListOpen(
    open: _open,
    child: widget.builder(context, _open, _list),
  );
}

class _Surface extends StatefulWidget {
  const _Surface({required this.count, required this.child});

  final void Function(int by) count;
  final Widget child;

  @override
  State<_Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<_Surface> {
  late final void Function(int by) _count = widget.count;

  @override
  void initState() {
    super.initState();
    _count(1);
  }

  @override
  void dispose() {
    _count(-1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
