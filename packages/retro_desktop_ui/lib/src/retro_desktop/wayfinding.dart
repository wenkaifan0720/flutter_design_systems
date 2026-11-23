import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'acts.dart';
import 'behavior.dart' show RetroDesktopMotion;
import 'component_themes.dart';
import 'controls.dart';
import 'glyphs.dart';
import 'internal/caps.dart';
import 'internal/face.dart';
import 'layout.dart';
import 'localizations.dart';
import 'pixels.dart';
import 'press.dart';
import 'theme.dart';
import 'tokens.dart';

/// One place in a [RetroDesktopBreadcrumb] trail.
@immutable
class RetroDesktopBreadcrumbItem {
  /// Creates a [RetroDesktopBreadcrumbItem].
  const RetroDesktopBreadcrumbItem(this.label, {this.onPressed});

  /// The place's name.
  final String label;

  /// Goes to this place; null leaves it as words.
  final VoidCallback? onPressed;
}

/// The trail of folders above the current page, as the Finder's path bar
/// reads: quiet names joined by small triangles, the last one the page you
/// are on. A place with [RetroDesktopBreadcrumbItem.onPressed] is a link.
///
/// ```dart
/// RetroDesktopBreadcrumb(items: [RetroDesktopBreadcrumbItem('Everything', onPressed: () {}), RetroDesktopBreadcrumbItem('Letters')])
/// ```
class RetroDesktopBreadcrumb extends StatelessWidget {
  /// Creates a [RetroDesktopBreadcrumb].
  const RetroDesktopBreadcrumb({super.key, required this.items, this.label});

  /// The places, outermost first; the last is the current page.
  final List<RetroDesktopBreadcrumbItem> items;

  /// The trail's accessible name; defaults to the localized "Breadcrumbs".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The places behind in the secondary ink; where you are in the words' own, so the trail ends on it.
    final quiet = t.textTheme.caption.copyWith(color: c.textSecondary);
    final here = t.textTheme.caption.copyWith(
      color: c.text,
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      container: true,
      label: label ?? RetroDesktopLocalizations.of(context).breadcrumbs,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: RetroDesktopSpacing.s6,
        runSpacing: RetroDesktopSpacing.s2,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              ExcludeSemantics(
                child: RetroDesktopTriangleMark(
                  rtl ? AxisDirection.left : AxisDirection.right,
                  size: 8,
                ),
              ),
            if (i == items.length - 1 || items[i].onPressed == null)
              Semantics(
                selected: i == items.length - 1,
                child: Text(
                  items[i].label,
                  style: i == items.length - 1 ? here : quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              RetroDesktopPressable(
                label: items[i].label,
                link: true,
                button: false,
                onPressed: items[i].onPressed,
                // A crumb's words on its trail's line: the first on the
                // column's edge.
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: RetroDesktopSpacing.px,
                  ),
                  child: Text(
                    items[i].label,
                    style: quiet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopBreadcrumbItem>('items', items))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// Page numbers between a back and a next arrow, the current page lit. Long
/// runs fold into an ellipsis around the first, the last and the pages beside
/// the current one, so the pager stays one line on a phone.
///
/// ```dart
/// RetroDesktopPagination(count: 12, page: 3, onChanged: (_) {})
/// ```
class RetroDesktopPagination extends StatelessWidget {
  /// Creates a [RetroDesktopPagination].
  const RetroDesktopPagination({
    super.key,
    required this.count,
    required this.page,
    this.onChanged,
    this.label,
    this.style,
  }) : assert(count > 0),
       assert(page >= 0 && page < count);

  /// How many pages there are.
  final int count;

  /// The current page, from zero.
  final int page;

  /// Reports the page chosen; null shows the pager without acting.
  final ValueChanged<int>? onChanged;

  /// The pager's accessible name; defaults to the localized "Pages".
  final String? label;

  /// Overrides the page buttons' component theme.
  final RetroDesktopStyle? style;

  /// The pages shown, with null where a run of pages folds. [most] is how
  /// many places the row has for numbers and folds: under seven only the
  /// first, the current and the last page stay.
  static List<int?> shown(int count, int page, {int most = 7}) {
    if (count <= most) return [for (var i = 0; i < count; i++) i];
    final keep = most < 7
        ? <int>{0, page, count - 1}.toList()
        : <int>{
            0,
            count - 1,
            page,
            if (page > 0) page - 1,
            if (page < count - 1) page + 1,
            if (page <= 2) ...[1, 2, 3],
            if (page >= count - 3) ...[count - 4, count - 3, count - 2],
          }.toList();
    keep.sort();
    final out = <int?>[];
    for (final i in keep) {
      if (out.isNotEmpty && out.last != null && i - out.last! > 1) {
        out.add(null);
      }
      out.add(i);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = RetroDesktopLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final live = onChanged != null;
    // Every place is a full touch target; the pager stays one line, folding
    // more pages away as the width shrinks.
    const gap = 2.0;
    return Semantics(
      container: true,
      label: label ?? words.pages,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The arrows show a page number's height: its 20 px line, not
          // their 18 px glyph, inside the same padding and rim; arrows and
          // numbers a whole number of pixels tall, so each stands centred in
          // its reach on whole pixels at one top (at compact density the
          // fractional height left the arrows 0.3 px higher).
          final figure = t.textTheme.figure;
          final cell =
              (MediaQuery.textScalerOf(context).scale(figure.fontSize ?? 14) *
                          (figure.height ?? 1.2) +
                      2 * 4 * t.density.vertical +
                      2 * retroDesktopFaceRim(t))
                  .ceilToDouble();
          // A place is a whole reach, or the arrows' square where that is wider (51 at twice the text size).
          final place = math.max(48.0, cell);
          // Places that fit with the gaps between them, less the two arrows.
          final room = constraints.hasBoundedWidth
              ? ((constraints.maxWidth + gap) / (place + gap)).floor() - 2
              : count;
          final compact = room < 5 && count > room;
          final arrow = RetroDesktopStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(cell)),
          );
          // Each place a button of its own, a little apart: side by side their outlines doubled into a 2 px seam.
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              RetroDesktopIconButton(
                rtl
                    ? RetroDesktopGlyphs.chevronRight
                    : RetroDesktopGlyphs.chevronLeft,
                label: RawWidgetsLocalizations.of(context).previousPageTooltip,
                size: RetroDesktopButtonSize.small,
                style: arrow,
                onPressed: live && page > 0 ? () => onChanged!(page - 1) : null,
              ),
              if (compact)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RetroDesktopSpacing.s4,
                    ),
                    child: Text(
                      '${words.formatInteger(page + 1)}/${words.formatInteger(count)}',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: t.textTheme.figure.copyWith(color: t.colors.text),
                    ),
                  ),
                )
              else
                for (final i in shown(count, page, most: room < 7 ? 5 : 7))
                  if (i == null)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 20,
                        child: Text(
                          '…',
                          textAlign: TextAlign.center,
                          style: t.textTheme.body.copyWith(
                            color: t.colors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    RetroDesktopPressable(
                      label: words.pageOf(i + 1, count),
                      selected: i == page,
                      onPressed: live ? () => onChanged!(i) : null,
                      builder: (context, states) => ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 32,
                          minHeight: cell,
                        ),
                        child: retroDesktopFace(
                          states: states,
                          // In Chisel a page is a raised button as the arrows
                          // beside it are, its box its face: as a control its
                          // bevel stood 2 px inside the arrows' top and foot.
                          // Platinum keeps a segment's outline.
                          scale: t.chisel
                              ? RetroDesktopFaceScale.button
                              : RetroDesktopFaceScale.control,
                          component: t.segmentedButtonTheme,
                          style: style,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: RetroDesktopCaps(
                            style: t.textTheme.figure,
                            Text(
                              words.formatInteger(i + 1),
                              textAlign: TextAlign.center,
                              style: t.textTheme.figure.copyWith(
                                color: states.contains(WidgetState.selected)
                                    ? t.colors.onHighlight
                                    : t.colors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              RetroDesktopIconButton(
                rtl
                    ? RetroDesktopGlyphs.chevronLeft
                    : RetroDesktopGlyphs.chevronRight,
                label: RawWidgetsLocalizations.of(context).nextPageTooltip,
                size: RetroDesktopButtonSize.small,
                style: arrow,
                onPressed: live && page < count - 1
                    ? () => onChanged!(page + 1)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('page', page))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// A row of pixel stars: filled up to the value, outlined after it. ui_core's [RawRating] carries it: one tab stop,
/// the arrows a star at a time, Home or 0 none, End all, a digit that many; a drag sweeps across; a screen reader hears
/// a slider it can step. A tap on the stars already given clears them, as before. [onChanged] null shows a still
/// reading, a compact row for a review or a product. [enabled] false keeps the stars at their chosen size and spacing,
/// dimmed, and takes no input. The filled stars take the highlight: they are the chosen value. The pointer resting on
/// them lights nothing, as on the period's desktop.
///
/// ```dart
/// RetroDesktopRating(label: 'Your rating', value: 4, onChanged: (_) {})
/// ```
class RetroDesktopRating extends StatefulWidget {
  /// Creates a [RetroDesktopRating].
  const RetroDesktopRating({
    super.key,
    required this.label,
    required this.value,
    this.max = 5,
    this.onChanged,
    this.enabled = true,
  }) : assert(max > 0),
       assert(value >= 0 && value <= max);

  /// Whether a rating that takes input ([onChanged] set) accepts it now; when
  /// false it is drawn as it would be, dimmed.
  final bool enabled;

  /// The rating's accessible name.
  final String label;

  /// The stars given, whole numbers when chosen; a reading may be fractional.
  final double value;

  /// The most stars.
  final int max;

  /// Reports the stars chosen; null shows a still reading.
  final ValueChanged<int>? onChanged;

  @override
  State<RetroDesktopRating> createState() => _RatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(StringProperty('label', label))
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('max', max, defaultValue: 5))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged));
  }
}

class _RatingState extends State<RetroDesktopRating> {
  final _focus = FocusNode(debugLabel: 'rating');
  List<GlobalKey> _stars = const [];
  // The star a pointer went down on, from 1, while it is down; and where.
  int? _held;
  Offset? _downAt;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // The star under [global], from 1; null, none.
  int? _starAt(Offset global) {
    for (var i = 0; i < _stars.length; i++) {
      final box = _stars[i].currentContext?.findRenderObject();
      if (box is RenderBox &&
          box.hasSize &&
          (Offset.zero & box.size).contains(box.globalToLocal(global))) {
        return i + 1;
      }
    }
    return null;
  }

  bool get _takes => widget.onChanged != null && widget.enabled;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final w = widget;
    final words = RetroDesktopLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final still = w.onChanged == null;
    final chosen = w.value.round();
    if (_stars.length != w.max) {
      _stars = [for (var i = 0; i < w.max; i++) GlobalKey()];
    }
    Widget star(RawRatingItemDetails item) {
      // The value's own fill: a hovering pointer's preview lights nothing.
      final share = item.isPreview
          ? (w.value - item.index).clamp(0.0, 1.0)
          : item.fill;
      // Held, a star shows its press as the appearance's buttons do: Platinum's body darkens; Chisel's greys and
      // sinks a pixel down and right.
      final held = _held == item.index + 1;
      final face = retroDesktopOwnSize(
        width: _starSide,
        height: _starSide,
        child: RetroDesktopPixelPaint(
          painter: _StarPainter(
            share: share,
            // A given star darkens under the press as an empty one does.
            fill: held && !t.chisel
                ? Color.alphaBlend(c.text.withValues(alpha: .3), c.highlight)
                : c.highlight,
            line: c.textSecondary,
            rtl: rtl,
            body: !held
                ? null
                : t.chisel
                ? retroDesktopChiselHeldBox(c)
                : (c.brightness == Brightness.dark
                      ? c.platinumLight
                      : c.platinumDark),
            sink: held && t.chisel ? 1 : 0,
          ),
        ),
      );
      if (still) {
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: item.index == 0 ? 0 : RetroDesktopSpacing.s2,
          ),
          child: face,
        );
      }
      // Each star keeps its full touch target; disabled, it dims in place.
      return KeyedSubtree(
        key: _stars[item.index],
        child: RetroDesktopReach(
          child: AnimatedOpacity(
            duration: RetroDesktopMotion.of(context).state,
            curve: RetroDesktopMotion.of(context).standard,
            opacity: item.states.contains(WidgetState.disabled) ? .5 : 1,
            child: Padding(
              padding: const EdgeInsets.all(RetroDesktopSpacing.px),
              child: face,
            ),
          ),
        ),
      );
    }

    final rating = RawRating(
      value: still ? w.value : chosen.toDouble(),
      itemCount: w.max,
      readOnly: still,
      onChanged: _takes ? (value) => w.onChanged!(value.round()) : null,
      semanticLabel: w.label,
      semanticFormatterCallback: (value) => words.ratingOf(value, w.max),
      focusNode: _focus,
      // In a slot narrower than the stars the row scales down: ui_core reads a pointer along one line. In a wider one
      // it stands at the start, as the look's rows do.
      layoutBuilder: (context, items) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: still
            ? Row(mainAxisSize: MainAxisSize.min, children: items)
            : Stack(
                // The ring stands outside the stars where their reach is no wider than they are (a desk's).
                clipBehavior: Clip.none,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: items),
                  Positioned.fill(child: _ring(t, items.length)),
                ],
              ),
      ),
      itemBuilder: (context, item) => star(item),
    );
    if (still) return rating;
    // A press on a star: held while down, and on the stars already given, clearing them (ui_core leaves the value as it
    // is). Heard beside ui_core's own gestures, not against them.
    return Listener(
      onPointerDown: (event) {
        if (!_takes) return;
        _downAt = event.position;
        setState(() => _held = _starAt(event.position));
      },
      onPointerMove: (event) {
        final from = _downAt;
        if (_held == null || from == null) return;
        if ((event.position - from).distance > kTouchSlop) {
          setState(() => _held = null);
        }
      },
      onPointerUp: (event) {
        final held = _held;
        if (held == null) return;
        setState(() => _held = null);
        if (_takes && held == chosen && _starAt(event.position) == held) {
          w.onChanged!(0);
        }
      },
      onPointerCancel: (_) => setState(() => _held = null),
      child: rating,
    );
  }

  // The keys' ring round the row (one tab stop), on the stars' own faces, not their reach: each star stands on the
  // middle of a reach as wide and tall as a pointer or a finger needs, so the ring keeps clear of that room.
  Widget _ring(RetroDesktopThemeData t, int count) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, room) {
        const face = _starSide + 2 * RetroDesktopSpacing.px;
        final across = count == 0 ? 0.0 : (room.maxWidth / count - face) / 2;
        final down = (room.maxHeight - face) / 2;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: math.max(0, across),
            vertical: math.max(0, down),
          ),
          child: ListenableBuilder(
            listenable: _focus,
            builder: (context, _) => RetroDesktopHighlight(
              shape: t.shapes.small,
              focused: _focus.hasFocus,
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    ),
  );
}

// A star's side, in logical pixels: eleven cells of two.
const double _starSide = 22;

// An eleven-cell star on the device's grid, two pixels a cell: filled to
// [share] from the start edge in the highlight, outlined in the ink.
class _StarPainter extends RetroDesktopPixelPainter {
  const _StarPainter({
    required this.share,
    required this.fill,
    required this.line,
    required this.rtl,
    this.body,
    this.sink = 0,
  });
  final double share;
  final Color fill, line;
  final bool rtl;

  /// The unlit body's colour while held; null leaves it open.
  final Color? body;

  /// How far a held star sinks, down and right.
  final double sink;

  static const _rows = [
    '.....#.....',
    '.....#.....',
    '....###....',
    '....###....',
    '###########',
    '.#########.',
    '..#######..',
    '..#######..',
    '..###.###..',
    '.##.....##.',
    '.#.......#.',
  ];

  static bool _on(int x, int y) =>
      y >= 0 && y < 11 && x >= 0 && x < 11 && _rows[y][x] == '#';

  @override
  void paint(RetroDesktopPixelGrid px, Size size) {
    final cell = math.min(size.width, size.height) / 11;
    final ox = (size.width - cell * 11) / 2 + sink;
    final oy = (size.height - cell * 11) / 2 + sink;
    final edge = 11 * share;
    for (var y = 0; y < 11; y++) {
      for (var x = 0; x < 11; x++) {
        if (!_on(x, y)) continue;
        final rim =
            !_on(x - 1, y) ||
            !_on(x + 1, y) ||
            !_on(x, y - 1) ||
            !_on(x, y + 1);
        final from = rtl ? 10 - x : x;
        final lit = from < edge;
        if (!rim && !lit && body == null) continue;
        px.fill(
          Rect.fromLTWH(ox + x * cell, oy + y * cell, cell, cell),
          rim ? line : (lit ? fill : body!),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.share != share ||
      old.fill != fill ||
      old.line != line ||
      old.rtl != rtl ||
      old.body != body ||
      old.sink != sink;
}

/// A sunken well that takes files: drop them on it, or choose them with its
/// button. It lights while something is held over it ([active]: the app's
/// drop listener sets it), and lists what was taken with a way to remove each.
///
/// ```dart
/// RetroDesktopFileUpload(label: 'Attachments', onChoose: () {}, files: const ['notes.txt'])
/// ```
class RetroDesktopFileUpload extends StatelessWidget {
  /// Creates a [RetroDesktopFileUpload].
  const RetroDesktopFileUpload({
    super.key,
    required this.label,
    this.hint,
    this.onChoose,
    this.active = false,
    this.files = const [],
    this.onRemove,
    this.style,
  });

  /// What the files are for; also the well's accessible name.
  final String label;

  /// A line under the invitation (kinds and sizes taken).
  final String? hint;

  /// Opens the system's file chooser; null hides the button.
  final VoidCallback? onChoose;

  /// Whether something is held over the well.
  final bool active;

  /// The names of the files taken so far.
  final List<String> files;

  /// Removes the file at an index; null leaves the list fixed.
  final ValueChanged<int>? onRemove;

  /// Overrides the well's component theme.
  final RetroDesktopStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final words = RetroDesktopLocalizations.of(context);
    return Semantics(
      container: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          retroDesktopFace(
            states: {if (active) WidgetState.selected},
            component: t.wellTheme.over(
              RetroDesktopStyle(
                fill: WidgetStatePropertyAll(
                  active ? c.highlightContainer : c.paper,
                ),
                foreground: WidgetStatePropertyAll(c.text),
                edge: WidgetStatePropertyAll(
                  active ? c.highlight : c.textTertiary,
                ),
              ),
            ),
            style: style,
            scale: RetroDesktopFaceScale.surface,
            // A sunken well with a solid line: a dotted one is the look's focus mark.
            sunken: true,
            padding: const EdgeInsets.fromLTRB(
              RetroDesktopSpacing.s16,
              RetroDesktopSpacing.s18,
              RetroDesktopSpacing.s16,
              RetroDesktopSpacing.s18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RetroDesktopGlyphs.upload,
                  size: 28,
                  color: active ? c.highlight : c.textSecondary,
                ),
                const SizedBox(height: RetroDesktopSpacing.s8),
                Text(
                  words.dropFiles,
                  textAlign: TextAlign.center,
                  style: t.textTheme.row,
                ),
                if (hint != null) ...[
                  const SizedBox(height: RetroDesktopSpacing.s2),
                  Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: t.textTheme.meta,
                  ),
                ],
                if (onChoose != null) ...[
                  const SizedBox(height: RetroDesktopSpacing.s12),
                  RetroDesktopButton(
                    words.chooseFiles,
                    size: RetroDesktopButtonSize.small,
                    onPressed: onChoose,
                  ),
                ],
              ],
            ),
          ),
          for (var i = 0; i < files.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: RetroDesktopSpacing.s6),
              child: Row(
                children: [
                  Icon(
                    RetroDesktopGlyphs.fileText,
                    size: 16,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: RetroDesktopSpacing.s8),
                  Expanded(
                    child: Text(
                      files[i],
                      style: t.textTheme.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onRemove != null)
                    RetroDesktopIconButton(
                      RetroDesktopGlyphs.x,
                      label: '${words.removeFile} ${files[i]}',
                      size: RetroDesktopButtonSize.small,
                      onPressed: () => onRemove!(i),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onChoose', onChoose))
      ..add(FlagProperty('active', value: active, ifTrue: 'active'))
      ..add(IterableProperty<String>('files', files, defaultValue: const []))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onRemove', onRemove))
      ..add(
        DiagnosticsProperty<RetroDesktopStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}
