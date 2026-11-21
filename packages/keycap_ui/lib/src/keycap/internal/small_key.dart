/// A small key set inside a field's well (a clear key, a reveal key): an
/// alpha cap a little shorter than the field, with a glyph for a legend.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../cap.dart';
import '../theme.dart';

/// A small key with [icon], [semanticLabel] its name; [side] its height.
class KeycapSmallKey extends StatelessWidget {
  /// A small key.
  const KeycapSmallKey({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.side = 32,
    this.width,
    this.toggled,
    this.focusNode,
  });

  /// The glyph.
  final IconData icon;

  /// What the key does.
  final String semanticLabel;

  /// Called when pressed; null turns it off.
  final VoidCallback? onPressed;

  /// Its height.
  final double side;

  /// Its width; [side] when null.
  final double? width;

  /// Whether it is a toggle that is on (null: not a toggle).
  final bool? toggled;

  /// Its focus node.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: semanticLabel,
      // A button, selected while on, as `IconButton(isSelected:)`.
      semanticSelected: toggled,
      excludeSemantics: true,
      builder: (context, states, _) {
        final face = keycapKeyFace(
          theme,
          KeycapKind.alpha,
          states,
          radius: KeycapMetrics.smallKeyRadius,
        );
        return TapTargetPadding(
          child: SizedBox(
            height: side,
            width: width ?? side,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(side),
              child: Center(child: Icon(icon, size: 16, color: face.legend)),
            ),
          ),
        );
      },
    );
  }
}
