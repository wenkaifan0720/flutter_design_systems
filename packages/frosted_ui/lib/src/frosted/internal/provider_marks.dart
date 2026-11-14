import 'package:flutter/widgets.dart';

/// A sign-in provider's mark, drawn from path data so it costs the app no
/// asset and draws the same on every platform: Google's four-colour "G"
/// (its sign-in branding assets) and the Apple logo in one colour, the
/// label's. Plumbing of the sign-in button; pages never place one.
class FrostedProviderMark extends StatelessWidget {
  /// Creates a [FrostedProviderMark].
  const FrostedProviderMark(
    this.provider, {
    required this.color,
    this.size = 20,
    super.key,
  });

  /// `apple` or `google`.
  final String provider;

  /// A one-colour mark's ink.
  final Color color;

  /// The mark's square.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(provider, color)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.provider, this.color);

  final String provider;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas
      ..save()
      ..translate((size.width - side) / 2, (size.height - side) / 2);
    if (provider == 'google') {
      // 48 units; the G fills its square, as it does on Google's button.
      canvas.scale(side / 48);
      for (final (fill, path) in _google) {
        canvas.drawPath(path, Paint()..color = fill);
      }
    } else {
      // 814 by 1000 units: fit the height, centre the width.
      final scale = side / 1000;
      canvas
        ..translate((side - 814 * scale) / 2, 0)
        ..scale(scale)
        ..drawPath(_apple, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.provider != provider || old.color != color;
}

/// Google's "G", 48 × 48 units: each colour's path (Google's sign-in
/// branding assets).
final List<(Color, Path)> _google = [
  (
    const Color(0xFFEA4335),
    _path(
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
      '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ),
  ),
  (
    const Color(0xFF4285F4),
    _path(
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
      '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
  ),
  (
    const Color(0xFFFBBC05),
    _path(
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
      'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
  ),
  (
    const Color(0xFF34A853),
    _path(
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
      '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
    ),
  ),
];

/// The Apple logo, 814 × 1000 units (media_corpus logos/svg/apple.svg).
final Path _apple = _path(
  'M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 '
  '202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5'
  '-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 '
  '790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 '
  '162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234'
  '-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9'
  '-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 '
  '1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z',
);

/// One command letter or one number of an SVG path's data.
final RegExp _token = RegExp(
  r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
);

/// An SVG path's data as a [Path]: the commands the marks use (move, line,
/// horizontal, vertical, cubic, smooth cubic, close), absolute or relative,
/// with repeated parameter groups.
Path _path(String data) {
  final path = Path();
  final tokens = _token.allMatches(data).map((m) => m.group(0)!).toList();
  var i = 0;
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  var cx = 0.0, cy = 0.0; // the last cubic's second control point
  var command = '';
  double next() => double.parse(tokens[i++]);
  bool number() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!number()) command = tokens[i++];
    final relative = command == command.toLowerCase();
    final ox = relative ? x : 0.0, oy = relative ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        path.moveTo(x, y);
        startX = cx = x;
        startY = cy = y;
        // Further pairs after a move are lines.
        command = relative ? 'l' : 'L';
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'H':
        x = ox + next();
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'V':
        y = oy + next();
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'S':
        final x1 = 2 * x - cx, y1 = 2 * y - cy;
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x2;
        cy = y2;
      case 'Z':
        path.close();
        x = cx = startX;
        y = cy = startY;
      default:
        throw FormatException('unsupported path command $command');
    }
  }
  return path;
}
