// Catalog and example illustrations; excluded from retro_desktop_ui by design.demoArt.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:retro_desktop_ui/retro_desktop_parts.dart';

/// Decorative desktop object used by the catalog examples.
enum RetroDesktopDeskMark {
  /// The disk illustration used only as example content.
  disk,

  /// The floppy illustration used only as example content.
  floppy,

  /// The bin illustration used only as example content.
  bin,
}

class _DeskArtPainter extends RetroDesktopPixelPainter {
  const _DeskArtPainter(this.c, this.mark);
  final RetroDesktopColors c;
  final RetroDesktopDeskMark mark;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    // The marks keep their own inks by night (law 6): light bodies, a near-black edge. In the night's greys they stood
    // as dark shapes on the dark desk, the bin almost gone.
    final c = this.c.dark
        ? this.c.copyWith(
            platinum: const Color(0xFFCCCCCC),
            platinumLight: const Color(0xFFDDDDDD),
            platinumDark: const Color(0xFFAAAAAA),
            bevelLight: const Color(0xFFF4F4F4),
            bevelDark: const Color(0xFF888888),
            outline: const Color(0xFF111111),
            control: const Color(0xFF111111),
            paper: const Color(0xFFFFFFFF),
          )
        : this.c;
    final canvas = px.canvas;
    final edge = c.dark ? c.control : c.outline;
    final u = s.width / 48;
    void box(double x, double y, double w, double h, Color color) =>
        px.fill(Rect.fromLTWH(x * u, y * u, w * u, h * u), color);
    void poly(List<Offset> points, Color color) => canvas.drawPath(
      Path()..addPolygon([for (final p in points) p * u], true),
      Paint()..color = color,
    );
    switch (mark) {
      case RetroDesktopDeskMark.disk:
        poly(const [
          Offset(5, 18),
          Offset(10, 11),
          Offset(38, 11),
          Offset(43, 18),
        ], edge);
        poly(const [
          Offset(7, 17),
          Offset(11, 12),
          Offset(37, 12),
          Offset(41, 17),
        ], c.platinum);
        box(5, 17, 38, 20, edge);
        box(6, 18, 36, 18, c.platinumLight);
        box(6, 18, 36, 1, c.bevelLight);
        box(6, 34, 36, 2, c.bevelDark);
        box(10, 28, 5, 2, c.highlight);
        box(26, 23, 12, 1, c.bevelDark);
        box(26, 26, 12, 1, c.bevelDark);
        box(26, 29, 12, 1, c.bevelDark);
        box(8, 37, 5, 2, edge);
        box(35, 37, 5, 2, edge);
      case RetroDesktopDeskMark.floppy:
        box(8, 5, 32, 38, edge);
        box(9, 6, 30, 36, c.platinumDark);
        box(9, 6, 30, 1, c.bevelLight);
        box(9, 40, 30, 2, c.bevelDark);
        box(14, 5, 20, 13, edge);
        box(15, 6, 18, 11, c.platinumLight);
        box(26, 8, 4, 7, edge);
        box(12, 23, 24, 15, edge);
        box(13, 24, 22, 13, c.paper);
        box(13, 24, 22, 3, c.highlight);
        box(15, 30, 16, 1, c.bevelDark);
        box(15, 33, 11, 1, c.bevelDark);
      case RetroDesktopDeskMark.bin:
        box(19, 5, 10, 4, edge);
        box(21, 6, 6, 3, c.platinumLight);
        box(9, 9, 30, 5, edge);
        box(10, 10, 28, 3, c.platinumLight);
        box(10, 10, 28, 1, c.bevelLight);
        poly(const [
          Offset(11, 14),
          Offset(37, 14),
          Offset(35, 44),
          Offset(13, 44),
        ], edge);
        poly(const [
          Offset(12, 15),
          Offset(36, 15),
          Offset(34, 43),
          Offset(14, 43),
        ], c.platinum);
        for (final x in [17.0, 23.0, 29.0]) {
          box(x, 18, 1, 22, c.bevelDark);
          box(x + 1, 18, 1, 22, c.bevelLight);
        }
    }
  }

  @override
  bool shouldRepaint(_DeskArtPainter o) => o.c != c || o.mark != mark;
}

/// A disk, a floppy or a bin, drawn on the grid: for a head inside a window, about 40 square.
///
/// ```dart
/// RetroDesktopDeskArt(RetroDesktopDeskMark.disk)
/// ```
class RetroDesktopDeskArt extends StatelessWidget {
  /// Creates a [RetroDesktopDeskArt].
  const RetroDesktopDeskArt(this.mark, {super.key, this.size = 48});

  /// An identifying glyph or caller-supplied widget.
  final RetroDesktopDeskMark mark;

  /// The size of the visible face; minimum interactive reach is retained.
  final double size;
  @override
  Widget build(BuildContext context) => retroDesktopOwnSize(
    width: size,
    height: size,
    child: RetroDesktopPixelPaint(
      painter: _DeskArtPainter(RetroDesktopTheme.of(context).colors, mark),
    ),
  );
}

/// Marks on the desktop itself: a disk, a floppy and a bin, each with its name, in the rail at a desktop's end with the last
/// at the rail's foot. They carry no data: use them for the app's own places or leave them out. On a phone they show only
/// on a page that says `whole`.
///
/// ```dart
/// RetroDesktopDeskMarks(marks: const [(RetroDesktopDeskMark.disk, 'Studio'), (RetroDesktopDeskMark.bin, 'Bin')])
/// ```
class RetroDesktopDeskMarks extends StatelessWidget {
  /// Creates a [RetroDesktopDeskMarks].
  const RetroDesktopDeskMarks({super.key, required this.marks});

  /// The decorative desktop marks in display order.
  final List<(RetroDesktopDeskMark, String)> marks;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget one((RetroDesktopDeskMark, String) m) => SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RetroDesktopDeskArt(m.$1),
          const SizedBox(height: 4),
          // The label's plate takes the family's control shape, as a
          // file's name does.
          DecoratedBox(
            decoration: ShapeDecoration(
              color: c.markLabel,
              shape: t.shapes.small.copyWith(side: BorderSide.none),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                m.$2,
                style: t.type.text(12, 15, weight: FontWeight.w600),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    if (!t.desk) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 22,
          runSpacing: 10,
          children: [for (final m in marks) one(m)],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) => Column(
        mainAxisSize: box.hasBoundedHeight
            ? MainAxisSize.max
            : MainAxisSize.min,
        mainAxisAlignment: marks.length > 1 && box.hasBoundedHeight
            ? MainAxisAlignment.start
            : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0 && i < marks.length - 1) const SizedBox(height: 20),
            if (i > 0 && i == marks.length - 1)
              box.hasBoundedHeight
                  ? const Spacer()
                  : const SizedBox(height: 20),
            one(marks[i]),
          ],
        ],
      ),
    );
  }
}

class _FolderPainter extends RetroDesktopPixelPainter {
  const _FolderPainter(this.c, this.selected);
  final RetroDesktopColors c;
  final bool selected;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final line = c.dark ? c.shade : c.outline;
    final back = selected ? c.highlightDark : c.highlightMid;
    final front = selected ? c.highlight : c.highlightContainer;
    final tab = Path()
      ..addPolygon(const [
        Offset(3.5, 5.5),
        Offset(19.5, 5.5),
        Offset(23.5, 9.5),
        Offset(52.5, 9.5),
        Offset(52.5, 40.5),
        Offset(3.5, 40.5),
      ], true);
    canvas.drawPath(tab, Paint()..color = back);
    // A pixel wide, as the body's frame: a hairline stayed one device pixel when the art was drawn large.
    canvas.drawPath(
      tab,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = false
        ..color = line,
    );
    px.fill(const Rect.fromLTWH(3, 14, 50, 27), line);
    px.fill(const Rect.fromLTWH(4, 15, 48, 25), front);
    if (!selected) px.fill(const Rect.fromLTWH(4, 15, 48, 1), c.bevelLight);
    px.fill(const Rect.fromLTWH(4, 38, 48, 2), back);
  }

  @override
  bool shouldRepaint(_FolderPainter o) => o.c != c || o.selected != selected;
}

/// How a file's page is drawn: lines of text, a short letter with a total, a table, a plan, a sound.
enum RetroDesktopFileArt {
  /// The text displayed by this part.
  text,

  /// The letter illustration used only as example content.
  letter,

  /// The table illustration used only as example content.
  table,

  /// The plan illustration used only as example content.
  plan,

  /// The sound illustration used only as example content.
  sound,
}

class _FilePainter extends RetroDesktopPixelPainter {
  const _FilePainter(this.c, this.art, this.selected);
  final RetroDesktopColors c;
  final RetroDesktopFileArt art;
  final bool selected;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    canvas.save();
    canvas.translate(2, 1);
    final line = c.dark ? c.control : c.outline;
    final page = Path()
      ..addPolygon(const [
        Offset(4.5, 1.5),
        Offset(27.5, 1.5),
        Offset(35.5, 9.5),
        Offset(35.5, 48.5),
        Offset(4.5, 48.5),
      ], true);
    canvas.drawPath(
      page,
      Paint()..color = selected ? c.highlightContainer : c.iconPage,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = line;
    canvas.drawPath(page, stroke);
    final fold = Path()
      ..addPolygon(const [
        Offset(27.5, 1.5),
        Offset(27.5, 9.5),
        Offset(35.5, 9.5),
      ], true);
    canvas.drawPath(fold, Paint()..color = c.iconFold);
    canvas.drawPath(fold, stroke);
    void rect(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    final lo = c.iconLine;
    void lines(List<double> ys, {double last = 16}) {
      for (var i = 0; i < ys.length; i++) {
        rect(9, ys[i], i == ys.length - 1 ? last : 22, 2, lo);
      }
    }

    switch (art) {
      case RetroDesktopFileArt.text:
        lines(const [15, 19, 23, 27, 31, 35]);
      case RetroDesktopFileArt.letter:
        lines(const [15, 19, 23]);
        rect(9, 30, 22, 1, lo);
        rect(21, 33, 10, 3, c.text);
      case RetroDesktopFileArt.table:
        rect(9, 13, 22, 24, lo);
        rect(10, 14, 20, 22, c.iconPage);
        rect(16, 14, 1, 22, lo);
        rect(23, 14, 1, 22, lo);
        rect(10, 14, 20, 4, c.iconFold);
        rect(10, 18, 20, 1, lo);
        rect(10, 24, 20, 1, lo);
        rect(10, 30, 20, 1, lo);
      case RetroDesktopFileArt.plan:
        rect(8, 16, 24, 3, c.text);
        rect(10, 19, 3, 16, c.text);
        rect(27, 19, 3, 16, c.text);
        rect(14, 26, 12, 2, lo);
        rect(10, 16, 3, 3, c.highlight);
        rect(27, 16, 3, 3, c.highlight);
      case RetroDesktopFileArt.sound:
        const heights = [2.0, 5.0, 8.0, 4.0, 10.0, 6.0, 3.0, 7.0];
        for (var i = 0; i < heights.length; i++) {
          rect(9.0 + i * 3, 25 - heights[i], 2, 2 * heights[i], c.text);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FilePainter o) =>
      o.c != c || o.art != art || o.selected != selected;
}

/// What `RetroDesktopObjectArt` draws: a folder, a file's page of each `RetroDesktopFileArt`, a disk, a floppy or a bin.
enum RetroDesktopObject {
  /// The folder illustration used only as example content.
  folder,

  /// The text displayed by this part.
  text,

  /// The letter illustration used only as example content.
  letter,

  /// The table illustration used only as example content.
  table,

  /// The plan illustration used only as example content.
  plan,

  /// The sound illustration used only as example content.
  sound,

  /// The disk illustration used only as example content.
  disk,

  /// The floppy illustration used only as example content.
  floppy,

  /// The bin illustration used only as example content.
  bin,
}

/// One of the look's own objects drawn large, in the middle of the room it is given: for a piece with no picture of its
/// own, so a shelf of them reads as things and not as missing pictures. Its pixels grow by whole device pixels, as far as
/// [fill] of the room allows, so they stay square and sharp. `RetroDesktopPictureCard(art:)` stands one in its picture.
///
/// ```dart
/// RetroDesktopObjectArt(RetroDesktopObject.folder)
/// ```
class RetroDesktopObjectArt extends StatelessWidget {
  /// Creates a [RetroDesktopObjectArt].
  const RetroDesktopObjectArt(this.object, {super.key, this.fill = .8});

  /// The caller-supplied object displayed in the hero.
  final RetroDesktopObject object;

  /// The share of the room's shorter side it may take.
  final double fill;
  @override
  Widget build(BuildContext context) {
    final c = RetroDesktopTheme.of(context).colors;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final (Size natural, Widget art) = switch (object) {
      RetroDesktopObject.folder => (
        const Size(56, 44),
        RetroDesktopPixelPaint(painter: _FolderPainter(c, false)),
      ),
      RetroDesktopObject.disk => (
        const Size(48, 48),
        const RetroDesktopDeskArt(RetroDesktopDeskMark.disk),
      ),
      RetroDesktopObject.floppy => (
        const Size(48, 48),
        const RetroDesktopDeskArt(RetroDesktopDeskMark.floppy),
      ),
      RetroDesktopObject.bin => (
        const Size(48, 48),
        const RetroDesktopDeskArt(RetroDesktopDeskMark.bin),
      ),
      final file => (
        const Size(44, 52),
        RetroDesktopPixelPaint(
          painter: _FilePainter(
            c,
            RetroDesktopFileArt.values.byName(file.name),
            false,
          ),
        ),
      ),
    };
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, room) {
          var k = 1.0;
          if (room.hasBoundedWidth && room.hasBoundedHeight) {
            final most =
                fill *
                math.min(
                  room.maxWidth / natural.width,
                  room.maxHeight / natural.height,
                );
            k = most * dpr >= 1 ? (most * dpr).floorToDouble() / dpr : most;
          }
          return Center(
            child: SizedBox(
              width: natural.width * k,
              height: natural.height * k,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox.fromSize(size: natural, child: art),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A catalog folder illustration. A library folder grid accepts any widget.
///
/// ```dart
/// RetroDesktopFolderArt(selected: true)
/// ```
class RetroDesktopFolderArt extends StatelessWidget {
  /// Creates a [RetroDesktopFolderArt].
  const RetroDesktopFolderArt({super.key, this.selected = false, this.icon});

  /// Whether the part represents the current selection.
  final bool selected;

  /// The glyph shown with the content.
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = RetroDesktopTheme.of(context).colors;
    return retroDesktopOwnSize(
      width: 56,
      height: 44,
      child: RetroDesktopPixelPaint(
        painter: _FolderPainter(c, selected),
        child: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 20, top: 19),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? c.onHighlight
                        : (c.dark ? c.text : c.highlightDark),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A catalog document illustration. A library file grid accepts any widget.
///
/// ```dart
/// RetroDesktopFilePageArt(kind: RetroDesktopFileArt.text)
/// ```
class RetroDesktopFilePageArt extends StatelessWidget {
  /// Creates a [RetroDesktopFilePageArt].
  const RetroDesktopFilePageArt({
    super.key,
    this.kind = RetroDesktopFileArt.text,
    this.selected = false,
  });

  /// The visual category used to draw this item.
  final RetroDesktopFileArt kind;

  /// Whether the part represents the current selection.
  final bool selected;
  @override
  Widget build(BuildContext context) => retroDesktopOwnSize(
    width: 44,
    height: 52,
    child: RetroDesktopPixelPaint(
      painter: _FilePainter(
        RetroDesktopTheme.of(context).colors,
        kind,
        selected,
      ),
    ),
  );
}

const _towerShape = [
  '....#....',
  '...###...',
  '..#####..',
  '..LLLLL..',
  '..LLLLL..',
  '.#######.',
  '..WWWWW..',
  '..WWWWW..',
  '..#####..',
  '..#####..',
  '..WWWWW..',
  '..WWWWW..',
  '.#######.',
  '.#######.',
  '.WWWWWWW.',
  '.WWWWWWW.',
];
const _rockShape = [
  '.....#########.....',
  '...#############...',
  '.#################.',
  '###################',
];

/// A decorative lighthouse for a catalog picture slot; it plots no data.
///
/// ```dart
/// RetroDesktopBeaconArt()
/// ```
class RetroDesktopBeaconArt extends StatelessWidget {
  /// Creates a [RetroDesktopBeaconArt].
  const RetroDesktopBeaconArt({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _BeaconPainter(RetroDesktopTheme.of(context).colors),
    ),
  );
}

class _BeaconPainter extends CustomPainter {
  const _BeaconPainter(this.colors);
  final RetroDesktopColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width / 25, size.height / 24);
    final x = size.width - 13 * unit, y = size.height - 23 * unit;
    canvas.drawPath(
      Path()..addPolygon([
        Offset(x, y + 4 * unit),
        Offset(0, y),
        Offset(0, y + 10 * unit),
      ], true),
      Paint()..color = colors.highlightMid.withValues(alpha: .5),
    );
    void sprite(
      List<String> rows,
      double cx,
      double top,
      Map<String, Color> palette,
    ) {
      final left = cx - rows.first.length * unit / 2;
      for (var row = 0; row < rows.length; row++) {
        for (var col = 0; col < rows[row].length; col++) {
          final color = palette[rows[row][col]];
          if (color != null) {
            canvas.drawRect(
              Rect.fromLTWH(left + col * unit, top + row * unit, unit, unit),
              Paint()..color = color,
            );
          }
        }
      }
    }

    sprite(_rockShape, x, y + 16 * unit, {'#': colors.illustration.skyLine});
    sprite(_towerShape, x, y, {
      '#': colors.illustration.skyLine,
      'W': colors.illustration.tower,
      'L': colors.highlight,
    });
  }

  @override
  bool shouldRepaint(_BeaconPainter old) => old.colors != colors;
}
