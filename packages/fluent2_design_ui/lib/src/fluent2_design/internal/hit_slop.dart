import 'package:flutter/widgets.dart';

import '../components/pressable/pressable.dart' show Fluent2FocusRing;
import '../theme.dart';

/// Aligns a labelled choice with the text in its column. The focus ring
/// follows the label and indicator, even when the pointer target fills a row.
class Fluent2HangRoom extends StatelessWidget {
  /// The leading indicator's padding hangs in the gutter. When [focused]
  /// is supplied, the ring follows the face. Set [labelFirst] when the
  /// label already starts on the column's keyline.
  const Fluent2HangRoom({
    required this.child,
    this._focused,
    this._labelFirst = false,
    super.key,
  });

  /// The control.
  final Widget child;

  final bool? _focused;
  final bool _labelFirst;

  @override
  Widget build(BuildContext context) {
    final start = Directionality.maybeOf(context) == TextDirection.rtl
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final offset = Offset(_labelFirst ? 0 : start.x * Fluent2Spacing.s, 0);
    if (_focused == null) {
      return Transform.translate(offset: offset, child: child);
    }
    return Align(
      alignment: start,
      widthFactor: 1,
      heightFactor: 1,
      child: Transform.translate(
        offset: offset,
        child: Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            child,
            if (_focused)
              PositionedDirectional(
                start: _labelFirst ? -Fluent2Spacing.s : 0,
                end: 0,
                top: 0,
                bottom: 0,
                child: const IgnorePointer(child: Fluent2FocusRing()),
              ),
          ],
        ),
      ),
    );
  }
}
