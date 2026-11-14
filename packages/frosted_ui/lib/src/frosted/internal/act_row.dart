import 'package:flutter/widgets.dart';

import '../components/button/button.dart';

/// The sizes an act shows, smallest first.
enum FrostedActSize {
  /// A tile head's or a line's small pill.
  small,

  /// The ordinary button.
  regular,

  /// The wide act of a sheet's or a dialog's foot (48, the larger word).
  wide,
}

/// An act of the look's own, other than a [FrostedButton], that stands in a
/// row of acts: the size it asks for. Plumbing of the components.
abstract interface class FrostedSizedAct {
  /// The size this act asks for on its own.
  FrostedActSize get actSize;
}

/// One row of acts (a sheet's foot, a dialog's pair, a [FrostedButtonRow]):
/// every act in it shows the size the largest of them asks for, so the row
/// shows one top and one bottom whatever each act's variant. A variant
/// differs in its fill, never in the size it shows. Plumbing of the
/// components; pages place a [FrostedButtonRow].
class FrostedActRow extends InheritedWidget {
  /// Every act under [child] shows at least [size].
  const FrostedActRow({required this.size, required super.child, super.key});

  /// The size the row's acts show.
  final FrostedActSize size;

  /// The row's size above [context]; null outside a row.
  static FrostedActSize? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FrostedActRow>()?.size;

  /// The size [act] asks for on its own.
  static FrostedActSize ask(Widget act) => switch (act) {
    FrostedButton(size: FrostedButtonSize.small) => FrostedActSize.small,
    FrostedButton(expand: true) => FrostedActSize.wide,
    FrostedButton() => FrostedActSize.regular,
    FrostedSizedAct(:final actSize) => actSize,
    _ => FrostedActSize.small,
  };

  /// [acts], each standing at the size the largest of them asks for.
  static List<Widget> wrap(List<Widget> acts) {
    var size = FrostedActSize.small;
    for (final act in acts) {
      final asked = ask(act);
      if (asked.index > size.index) size = asked;
    }
    return [for (final act in acts) FrostedActRow(size: size, child: act)];
  }

  /// What [asked] shows in the row above [context]: the larger of the two.
  static FrostedActSize shown(BuildContext context, FrostedActSize asked) {
    final row = of(context);
    return row == null || row.index <= asked.index ? asked : row;
  }

  @override
  bool updateShouldNotify(FrostedActRow oldWidget) => oldWidget.size != size;
}
