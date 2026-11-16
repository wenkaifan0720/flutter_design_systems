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

  /// The field: [up] while its list shows; [mark] goes round the list.
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
