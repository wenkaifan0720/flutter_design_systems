/// Semantic inks kept separate from the comic's dramatic accent.
library;

import 'package:flutter/widgets.dart';

import 'theme.dart' show comicLightTones, comicDarkTones;

/// Meaning expressed by both an ink and a distinct mark.
enum ComicTone {
  /// Information.
  info,

  /// A successful result.
  success,

  /// Something needs attention.
  warning,

  /// A destructive action or error.
  danger,
}

/// Four semantic inks, each legible on the current panel ground.
@immutable
class ComicTones {
  /// Creates semantic inks.
  const ComicTones({
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Information ink.
  final Color info;

  /// Success ink.
  final Color success;

  /// Warning ink.
  final Color warning;

  /// Danger ink.
  final Color danger;

  /// Inks for light newsprint.
  static const light = comicLightTones;

  /// Inks for dark panels.
  static const dark = comicDarkTones;

  /// The ink corresponding to a meaning.
  Color of(ComicTone tone) => switch (tone) {
    ComicTone.info => info,
    ComicTone.success => success,
    ComicTone.warning => warning,
    ComicTone.danger => danger,
  };

  /// Changes only the supplied inks.
  ComicTones copyWith({
    Color? info,
    Color? success,
    Color? warning,
    Color? danger,
  }) => ComicTones(
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
  );

  /// Blends all four inks.
  static ComicTones lerp(ComicTones a, ComicTones b, double t) => ComicTones(
    info: Color.lerp(a.info, b.info, t)!,
    success: Color.lerp(a.success, b.success, t)!,
    warning: Color.lerp(a.warning, b.warning, t)!,
    danger: Color.lerp(a.danger, b.danger, t)!,
  );
  @override
  bool operator ==(Object other) =>
      other is ComicTones &&
      other.info == info &&
      other.success == success &&
      other.warning == warning &&
      other.danger == danger;
  @override
  int get hashCode => Object.hash(info, success, warning, danger);
}
