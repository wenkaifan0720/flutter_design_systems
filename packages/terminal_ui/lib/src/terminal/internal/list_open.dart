/// Whether the list a field opens is up: the field then stands on the
/// list's raised ground, so the field and its list read as one block on the
/// same cells.
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// What a press on a field that opens a list does ([anchor] null: an off
/// field, nothing): the field takes the focus first, as a select does, so
/// the list, once closed (Escape, a choice), gives the focus back to the
/// field and not to whatever had it before the press. The focus moves at
/// the end of the press's turn; the list opens after it, so it knows where
/// to give it back. Pressed while it has the focus (Return, Space, Down) or
/// open, it opens or closes at once.
VoidCallback? termOpener(FocusNode field, DesignOverlayAnchor? anchor) {
  if (anchor == null) return null;
  return () {
    final menu = anchor.controller;
    if (field.hasPrimaryFocus || menu.isOpen || !field.canRequestFocus) {
      anchor.toggle();
      return;
    }
    field.requestFocus();
    scheduleMicrotask(() {
      if (!menu.isOpen) anchor.open();
    });
  };
}

/// Tells the field frames under it ([open]) that their list is up.
class TermListOpen extends InheritedWidget {
  /// Marks the fields under [child] open while [open].
  const TermListOpen({super.key, required this.open, required super.child});

  /// Whether the field's list is up.
  final bool open;

  /// Whether the list of the field at [context] is up.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TermListOpen>()?.open ?? false;

  @override
  bool updateShouldNotify(TermListOpen oldWidget) => open != oldWidget.open;
}

/// Calls [onChanged] with true once [child], a field's list, is built and
/// with false once it is gone: for a list whose host says nothing of its
/// being open (a combobox's). Each call waits for the frame to end, as the
/// list mounts and unmounts while the tree is being built; the field checks
/// it is still there.
class TermListOpenMark extends StatefulWidget {
  /// Reports [child] showing to [onChanged].
  const TermListOpenMark({
    super.key,
    required this.onChanged,
    required this.child,
  });

  /// What the field hears.
  final ValueChanged<bool> onChanged;

  /// The list.
  final Widget child;

  @override
  State<TermListOpenMark> createState() => _TermListOpenMarkState();
}

class _TermListOpenMarkState extends State<TermListOpenMark> {
  @override
  void initState() {
    super.initState();
    _tell(true);
  }

  @override
  void dispose() {
    _tell(false);
    super.dispose();
  }

  void _tell(bool value) {
    final onChanged = widget.onChanged;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => onChanged(value))
      ..ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Builds a field whose host says nothing of its list being open: [builder]
/// gets whether the list is up, and `mark`, to put round the list it hands
/// the host.
class TermListUp extends StatefulWidget {
  /// A field built by [builder].
  const TermListUp({super.key, required this.builder});

  /// The field: `up` while its list shows; `mark` goes round the list.
  final Widget Function(
    BuildContext context,
    bool up,
    Widget Function(Widget list) mark,
  )
  builder;

  @override
  State<TermListUp> createState() => _TermListUpState();
}

class _TermListUpState extends State<TermListUp> {
  // Lists showing: an old one can go in the frame a new one comes.
  var _lists = 0;

  void _changed(bool shown) {
    if (!mounted) return;
    setState(() => _lists = (_lists + (shown ? 1 : -1)).clamp(0, 1 << 20));
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _lists > 0,
    (list) => TermListOpenMark(onChanged: _changed, child: list),
  );
}

/// Which side of its field a combobox's list opens on. ui_core's anchored
/// lists (a select's, a menu's) move over their anchor when the room under
/// it is less than they want and the room over it is more; its combobox
/// opens on the side it is told and stays there, so near the foot of the
/// screen its list was held to the sliver left under the field. This keeps
/// the anchored lists' rule for it: [builder] is told whether the list goes
/// `above`, read from where the field stood whenever its words or its focus
/// change (what opens the list), and puts `watch` round the field.
class TermListSide extends StatefulWidget {
  /// A field built by [builder], whose list wants [wanted] of room.
  const TermListSide({super.key, required this.wanted, required this.builder});

  /// The room the list wants under the field before it goes over it.
  final double wanted;

  /// The field: `above` while its list opens over it; `watch` goes round
  /// the words' input, with its controller and its focus.
  final Widget Function(
    BuildContext context,
    bool above,
    Widget Function(
      TextEditingController controller,
      FocusNode focusNode,
      Widget field,
    )
    watch,
  )
  builder;

  @override
  State<TermListSide> createState() => _TermListSideState();
}

class _TermListSideState extends State<TermListSide> {
  var _above = false;
  var _safe = EdgeInsets.zero;

  // Reads the room on each side of the field as it last stood.
  void _place() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _place());
      return;
    }
    final box = context.findRenderObject();
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    if (overlay is! RenderBox || !overlay.hasSize) return;
    final top = box.localToGlobal(Offset.zero, ancestor: overlay).dy;
    final over = top - _safe.top;
    final under = overlay.size.height - _safe.bottom - (top + box.size.height);
    final above = under < widget.wanted && over > under;
    if (above != _above) setState(() => _above = above);
  }

  @override
  Widget build(BuildContext context) {
    // The keyboard and the screen's own edges take room from both sides,
    // as they do from the list.
    final media = MediaQuery.maybeOf(context);
    _safe = media == null
        ? EdgeInsets.zero
        : EdgeInsets.only(
            top: media.padding.top,
            bottom: media.padding.bottom + media.viewInsets.bottom,
          );
    return widget.builder(
      context,
      _above,
      (controller, focusNode, field) => _ListSideWatch(
        controller: controller,
        focusNode: focusNode,
        onChanged: _place,
        child: field,
      ),
    );
  }
}

// Calls [onChanged] when the words or the focus change.
class _ListSideWatch extends StatefulWidget {
  const _ListSideWatch({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.child,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final Widget child;

  @override
  State<_ListSideWatch> createState() => _ListSideWatchState();
}

class _ListSideWatchState extends State<_ListSideWatch> {
  void _changed() => widget.onChanged();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(_ListSideWatch old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
