/// A line that comes and goes under a field (its error, its help): it grows
/// open as it fades in, and fades out before it closes, so what stands under
/// the field moves with it and never jumps. Under Reduce Motion it cuts.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Reveals [child] under a field; a new [id] fades the old words out and
/// the new in.
class Fluent2MessageReveal extends StatelessWidget {
  /// Reveals [child], known by [id].
  const Fluent2MessageReveal({
    super.key,
    required this.id,
    required this.child,
  });

  /// What the line says: a new one fades over the old.
  final Object? id;

  /// The line, or an empty box when there is none.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Still (Reduce Motion), the line is there or not at once.
    if (rawReduceMotionOf(context)) {
      return KeyedSubtree(key: ValueKey<Object?>(id), child: child);
    }
    final duration = Fluent2Motion.normal;
    return AnimatedSize(
      duration: duration,
      curve: Fluent2Motion.decelerateMid,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Fluent2Motion.decelerateMid,
        switchOutCurve: Fluent2Motion.decelerateMid,
        // The words going leave the screen reader's tree at once.
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.topStart,
          children: [
            for (final going in previous) ExcludeSemantics(child: going),
            ?current,
          ],
        ),
        child: KeyedSubtree(key: ValueKey<Object?>(id), child: child),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('id', id, defaultValue: null));
  }
}
