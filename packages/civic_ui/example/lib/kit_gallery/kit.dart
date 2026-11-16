/// Shared host for the Civic gallery's demo screens.
///
/// Every demo renders inside the environment a Civic page gets live: a
/// MaterialApp with Civic's theme (the preset in theme.dart's [kitPreset])
/// and its toaster above the navigator, in the brightness the demo is
/// given, under a [CivicScaffold] with the service's top bar and the
/// demo's sections in a reading column.
///
/// Demos import ONLY the Civic barrel, this file, Flutter and the packages
/// Civic depends on.
library;

import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import 'gallery_words.dart';
import 'theme.dart';

/// The theme a demo is drawn in.
CivicThemeData kitTheme(Brightness brightness) =>
    CivicThemeData.preset(kitPreset, brightness);

/// The app every demo stands in: Civic's theme and toaster over the
/// navigator, [home] its one page.
Widget kitApp({
  required Brightness brightness,
  required Widget home,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: civicPageTransitions,
    ),
  ),
  locale: direction == TextDirection.rtl
      ? const Locale('ar')
      : const Locale('en'),
  localizationsDelegates: galleryDelegates,
  supportedLocales: DesignLocalizations.supportedLocales,
  color: kitTheme(brightness).action,
  builder: (context, child) => CivicTheme(
    data: kitTheme(brightness),
    child: CivicToaster(child: child ?? const SizedBox.shrink()),
  ),
  home: home,
);

/// A demo screen: the service's top bar over a reading column titled
/// [title], [intro] under the title, then [sections], one per variant or
/// state.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  String? intro,
  List<Widget> sections = const [],
  double maxWidth = CivicLayout.readingWidth,
}) => kitApp(
  brightness: brightness,
  home: CivicScaffold(
    topBar: const CivicTopBar(title: 'Civic', emblem: KitEmblem()),
    body: CivicPageBody(
      title: title,
      maxWidth: maxWidth,
      children: [
        if (intro != null) ...[
          Text(intro),
          const SizedBox(height: CivicSpacing.s32),
        ],
        for (final section in sections) ...[
          section,
          const SizedBox(height: CivicSpacing.s48),
        ],
      ],
    ),
  ),
);

/// A section of a demo: a heading, a line on what it shows, then [children]
/// down the column.
class KitSection extends StatelessWidget {
  /// A section titled [title].
  const KitSection({
    super.key,
    required this.title,
    required this.children,
    this.caption,
    this.spacing = CivicSpacing.s16,
  });

  /// The heading.
  final String title;

  /// What it shows.
  final String? caption;

  /// The specimens.
  final List<Widget> children;

  /// The space between them.
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      CivicSectionHeader(title: title),
      if (caption != null) ...[
        Text(caption!, style: context.civicText.caption),
        const SizedBox(height: CivicSpacing.s16),
      ],
      for (final (i, child) in children.indexed) ...[
        if (i > 0) SizedBox(height: spacing),
        child,
      ],
    ],
  );
}

/// Shows the focus a keyboard gives [builder]'s part, without a keyboard:
/// the part takes the states controller this holds, focused.
class KitFocused extends StatefulWidget {
  /// A part drawn focused.
  const KitFocused({super.key, required this.builder});

  /// Builds the part with the controller.
  final Widget Function(WidgetStatesController controller) builder;

  @override
  State<KitFocused> createState() => _KitFocusedState();
}

class _KitFocusedState extends State<KitFocused> {
  final WidgetStatesController _controller = WidgetStatesController({
    WidgetState.focused,
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// The invented city's emblem: a square with a gate in it, drawn, never a
/// borrowed crest.
class KitEmblem extends StatelessWidget {
  /// The emblem.
  const KitEmblem({super.key, this.size = 28});

  /// Its side.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? context.civicTheme.textPrimary;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _EmblemPainter(color),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  _EmblemPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1;
    final r = Rect.fromLTWH(s * 0.05, s * 0.05, s * 0.9, s * 0.9);
    canvas.drawRect(r, stroke);
    // A gate: an arch over two posts.
    final fill = Paint()..color = color;
    final w = s * 0.5;
    final left = (s - w) / 2;
    final top = s * 0.3;
    final path = Path()
      ..moveTo(left, s * 0.82)
      ..lineTo(left, top + w / 2)
      ..arcToPoint(
        Offset(left + w, top + w / 2),
        radius: Radius.circular(w / 2),
      )
      ..lineTo(left + w, s * 0.82)
      ..lineTo(left + w * 0.72, s * 0.82)
      ..lineTo(left + w * 0.72, top + w / 2)
      ..arcToPoint(
        Offset(left + w * 0.28, top + w / 2),
        radius: Radius.circular(w * 0.22),
        clockwise: false,
      )
      ..lineTo(left + w * 0.28, s * 0.82)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(_EmblemPainter old) => old.color != color;
}
