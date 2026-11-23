import 'package:flutter/widgets.dart';

/// Whether the list a field opens shows: a combobox's or a tag input's text
/// input reads it as its expanded state.
class ComicListOpen extends InheritedWidget {
  /// Tells the field in [child] whether its list shows.
  const ComicListOpen({super.key, required this.open, required super.child});

  /// Whether the list shows.
  final bool open;

  /// The state above [context], or null where no list is.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComicListOpen>()?.open;

  @override
  bool updateShouldNotify(ComicListOpen oldWidget) => oldWidget.open != open;
}
