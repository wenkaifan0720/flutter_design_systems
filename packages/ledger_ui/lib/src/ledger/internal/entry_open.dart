import 'package:flutter/widgets.dart';

/// Whether the list a text entry opens stands open, for the entry under it
/// to say on its own node (expanded, or collapsed): a combobox's field
/// builder sets it from its field's `isOpen`. Outside one an entry says
/// neither. Plumbing of the components.
class LedgerEntryOpen extends InheritedWidget {
  /// Marks the entry under [child] as opening a list that is [open].
  const LedgerEntryOpen({required this.open, required super.child, super.key});

  /// Whether the entry's list stands open.
  final bool open;

  /// Whether the list of the entry at [context] stands open; null where
  /// the entry opens none.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerEntryOpen>()?.open;

  @override
  bool updateShouldNotify(LedgerEntryOpen oldWidget) => open != oldWidget.open;
}
