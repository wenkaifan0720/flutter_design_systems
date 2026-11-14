import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/well.dart';
import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../internal/styled.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../forms/forms.dart' show FrostedSelectOption;
import '../marks/marks.dart' show FrostedCheckbox;
import '../pressable/pressable.dart';
import '../progress/progress.dart';
import '../../internal/dim.dart';
import '../../internal/rest_ring.dart';
import '../../internal/cap.dart';

/// One choice of a [FrostedRadioGroup]: its [value], its [label], a quiet
/// [note] under it, and whether it can be chosen ([enabled]). Built by the
/// group it stands in.
///
/// ```dart
/// FrostedRadioGroup<String>(label: 'Plan', value: plan, onChanged: setPlan, options: const [FrostedRadio('free', 'Free'), FrostedRadio('pro', 'Pro', note: 'Billed yearly')])
/// ```
class FrostedRadio<T> extends StatelessWidget {
  /// A choice of [value], named [label].
  const FrostedRadio(
    this.value,
    this.label, {
    this.note,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// What choosing it sets.
  final T value;

  /// Its words.
  final String label;

  /// A line under the words.
  final String? note;

  /// Whether it can be chosen.
  final bool enabled;

  /// This choice's own style, over `FrostedThemeData.components.radio`:
  /// the mark's fill (selected when chosen), the dot's colour
  /// (foreground), the ring's colour or whole side, the mark's shape and
  /// the words' style, each per state.
  ///
  /// ```dart
  /// FrostedRadio(
  ///   'card',
  ///   'Card',
  ///   style: const FrostedStyle(
  ///     edge: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final group = _RadioScope.of<T>(context);
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final on = group.value == value;
    final live = enabled && group.onChanged != null;
    const d = 22.0;
    final layers = FrostedStyleLayers(style, t.components.radio);
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final shape = s.shape ?? const CircleBorder();
      final fill = s.fill;
      final mark = AnimatedContainer(
        duration: motion.fast,
        curve: motion.curve,
        width: d,
        height: d,
        decoration: ShapeDecoration(
          shape: shape.copyWith(
            side: on
                ? BorderSide.none
                : s.side ??
                      BorderSide(
                        color: s.edge ?? frostedRestRing(t),
                        width: 1.5,
                      ),
          ),
          gradient: on && fill == null ? t.colorScheme.buttonFill : null,
          color: fill ?? (on ? null : t.glass.fill),
        ),
        child: Center(
          child: AnimatedScale(
            scale: on ? 1 : 0,
            duration: motion.fast,
            curve: motion.curve,
            child: SizedBox.square(
              dimension: 8,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
                  color: s.foreground ?? t.colorScheme.onButton,
                ),
              ),
            ),
          ),
        ),
      );
      Widget row = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: FrostedBreakpoints.hitTargetOf(context),
        ),
        child: Row(
          spacing: FrostedSpacing.s12,
          children: [
            mark,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    frostedCapCentred(
                      Text(
                        label,
                        style: t.textTheme.titleMedium.merge(s.textStyle),
                      ),
                    ),
                    if (note case final note?)
                      Text(note, style: t.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      row = FrostedDim(off: !enabled, child: row);
      return row;
    }

    return FrostedPressable(
      onPressed: live ? () => group.onChanged!(value) : null,
      label: label,
      value: note,
      role: FrostedPressRole.control,
      checked: on,
      inMutuallyExclusiveGroup: true,
      radius: FrostedCorners.r12,
      builder: (context, states, _) => draw(states),
    );
  }
}

class _RadioScope<T> extends InheritedWidget {
  const _RadioScope({
    required this.value,
    required this.onChanged,
    required super.child,
  });

  final T? value;
  final ValueChanged<T>? onChanged;

  static _RadioScope<T> of<T>(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioScope<T>>();
    assert(scope != null, 'A FrostedRadio stands in a FrostedRadioGroup.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_RadioScope<T> old) =>
      old.value != value || old.onChanged != onChanged;
}

/// One choice of several, all in view: [options] down the column, each a
/// round mark before its words (the chosen one's mark the ink act with a
/// white dot), the whole row its target. The page owns [value]; a null
/// [onChanged] leaves them inert. A screen reader hears [label] over a
/// group of radio buttons, each checked or not; Tab enters the group and
/// the arrow keys move along it.
///
/// ```dart
/// FrostedRadioGroup<String>(label: 'Delivery', value: speed, onChanged: (v) => setState(() => speed = v), options: const [FrostedRadio('standard', 'Standard', note: '3 to 5 days'), FrostedRadio('express', 'Express', note: 'Tomorrow')])
/// ```
class FrostedRadioGroup<T> extends StatelessWidget {
  /// The [options], [value] chosen.
  const FrostedRadioGroup({
    required this.options,
    required this.label,
    this.value,
    this.onChanged,
    this.error,
    super.key,
  });

  /// The choices, in order.
  final List<FrostedRadio<T>> options;

  /// The chosen value; null when none is.
  final T? value;

  /// Called with the value chosen.
  final ValueChanged<T>? onChanged;

  /// The group's name, printed over it and spoken.
  final String label;

  /// What is wrong with the choice, under it in the over ink.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        child: _RadioScope<T>(
          value: value,
          onChanged: onChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  label,
                  style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
                ),
              ),
              const SizedBox(height: FrostedSpacing.s4),
              ...options,
              if (error case final error?)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: t.textTheme.bodySmall.c(t.colorScheme.over),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chip: a short choice, filter, act or entry on the 32 glass capsule in
/// its hairline (the filter chips'), its [icon] before its [label]; while
/// [selected], the ink act with its word in white. With [onDeleted] it
/// carries a close at its end, its own target, read as [deleteLabel] (the
/// localized "Remove" and the label by default). Without [onPressed] it
/// states; with it, it acts (and with [selected], toggles). Its target is
/// 44, 48 under a finger.
///
/// ```dart
/// FrostedChip('Vegetarian', selected: veg, onPressed: () => setState(() => veg = !veg))
/// ```
///
/// ```dart
/// FrostedChip('ines@park.studio', icon: FrostedGlyphs.email, onDeleted: () => remove(email))
/// ```
class FrostedChip extends StatelessWidget {
  /// A chip saying [label].
  const FrostedChip(
    this.label, {
    this.onPressed,
    this.selected,
    this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.isEnabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Its words.
  final String label;

  /// What a press does; null for a chip that only states.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether it stands chosen; null for a chip that is not a choice.
  final bool? selected;

  /// Removes it; null draws no close.
  final VoidCallback? onDeleted;

  /// The close's spoken name.
  final String? deleteLabel;

  /// A glyph before the words.
  final IconData? icon;

  /// Whether it takes presses.
  final bool isEnabled;

  /// This chip's own style, over `FrostedThemeData.components.chip`: its
  /// fill, foreground, edge or side (drawn in place of the hairline ring),
  /// overlay, shape, padding, minimum size, text style and icon size, each
  /// per state (selected while [selected] is true).
  ///
  /// ```dart
  /// FrostedChip(
  ///   'Vegetarian',
  ///   selected: veg,
  ///   onPressed: toggle,
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(8)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final on = selected ?? false;
    final close = onDeleted;
    final words = FrostedLocalizations.of(context);
    final layers = FrostedStyleLayers(style, t.components.chip);
    // Large text grows the pill by its words' extra line, as a button's: at
    // 200% the words filled a 32 pill to its rim (self-review round 5).
    final h = frostedGrownHeight(
      context,
      t.density.height(FrostedChromeMetrics.filterChip),
      t.textTheme.labelSmall,
    );
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final cut = s.cut(FrostedCorners.full);
      final ink =
          s.foreground ??
          (on ? t.colorScheme.onButton : t.colorScheme.textPrimary);
      final fill = s.fill;
      final side = s.side;
      final (edge, edges) = side == null
          ? (s.edge, EdgeInsets.all(FrostedStrokes.regular))
          : s.edgeOf(null, FrostedStrokes.regular);
      final inset = t.density.padding(
        EdgeInsetsDirectional.only(
          start: FrostedChromeMetrics.filterChipInset + (icon == null ? 2 : 0),
          end: close == null ? FrostedChromeMetrics.filterChipInset + 2 : 4,
        ).resolve(Directionality.of(context)),
      );
      Widget face = AnimatedSwitcher(
        duration: motion.fast,
        child: SizedBox(
          key: ValueKey(on),
          height: h,
          child: FrostedFace(
            material: on ? FrostedMaterial.paint : FrostedMaterial.pane,
            radius: BorderRadius.circular(
              FrostedStyleLayers.radiusOf(cut, h, h / 2),
            ),
            shape: cut,
            color: fill,
            gradients: on && fill == null
                ? [t.colorScheme.buttonFill]
                : const <Gradient>[],
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: on ? t.colorScheme.buttonSheen : null,
            ring: on || edge != null
                ? null
                : frostedLitEdge(t, t.colorScheme.border),
            shadows: on ? t.shadows.button : const <BoxShadow>[],
            padding: s.padding?.resolve(Directionality.of(context)) ?? inset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedSpacing.s4,
              children: [
                if (icon case final icon?)
                  Icon(icon, size: s.iconSize ?? 14, color: ink),
                frostedCapCentred(
                  Text(
                    label,
                    maxLines: 1,
                    style: s.words(
                      on
                          ? t.textTheme.labelSmall.semibold.c(ink)
                          : t.textTheme.labelSmall.c(ink),
                    ),
                  ),
                ),
                if (close != null)
                  FrostedHitSlop(
                    child: FrostedPressable(
                      onPressed: isEnabled ? close : null,
                      label: deleteLabel ?? '${words.remove} $label',
                      radius: 12,
                      child: SizedBox.square(
                        dimension: 24,
                        child: Icon(
                          FrostedGlyphs.close,
                          size: s.iconSize ?? 14,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      face = s.least(face);
      face = FrostedDim(off: !isEnabled, child: face);
      return face;
    }

    if (onPressed == null) {
      return Semantics(
        label: label,
        selected: selected,
        explicitChildNodes: close != null,
        excludeSemantics: close == null,
        child: draw({
          if (!isEnabled) WidgetState.disabled,
          if (on) WidgetState.selected,
        }),
      );
    }
    final cut = layers.cut(FrostedCorners.full);
    return FrostedHitSlop(
      child: FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: isEnabled ? onPressed : null,
        label: label,
        selected: selected,
        excludeChild: close == null,
        radius: FrostedStyleLayers.radiusOf(cut, h, h / 2),
        shape: cut,
        builder: (context, states, _) => draw(states),
      ),
    );
  }
}

/// A score out of [max] stars: each star drawn in the signature band when
/// it is reached (half a star with [allowHalf]), a ring of the strong
/// hairline when it is not. With [onChanged] a press or a drag along the
/// row sets it and the arrow keys step it; without, it only states. Read
/// aloud as [label] and "3 of 5".
///
/// ```dart
/// FrostedRating(value: stars, label: 'Your rating', onChanged: (v) => setState(() => stars = v))
/// ```
///
/// ```dart
/// FrostedRating(value: 4.5, label: 'Average', allowHalf: true, size: 16)
/// ```
class FrostedRating extends StatelessWidget {
  /// [value] stars of [max].
  const FrostedRating({
    required this.value,
    required this.label,
    this.onChanged,
    this.max = 5,
    this.allowHalf = false,
    this.size = 28,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(value >= 0 && value <= max);

  /// The score.
  final double value;

  /// What a screen reader calls it.
  final String label;

  /// Called with the score set; null leaves it stating.
  final ValueChanged<double>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// How many stars.
  final int max;

  /// Whether a score may end in half a star.
  final bool allowHalf;

  /// A star's size.
  final double size;

  double _snap(double v) {
    final step = allowHalf ? .5 : 1.0;
    return ((v / step).ceil() * step).clamp(step, max.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final live = onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final step = allowHalf ? .5 : 1.0;
    final gap = size * .2;
    final up = !live || value >= max
        ? null
        : () => onChanged!(math.min(max.toDouble(), value + step));
    final down = !live || value <= step
        ? null
        : () => onChanged!(math.max(step, value - step));
    final toward = rtl ? down : up;
    final away = rtl ? up : down;
    String spoken(double v) =>
        words.rating(v == v.roundToDouble() ? v.round() : v, max);
    double at(double dx, double width) {
      final x = rtl ? width - dx : dx;
      return _snap(x / (size + gap) + (allowHalf ? 0 : .0001));
    }

    Widget stars = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        for (var i = 0; i < max; i++)
          CustomPaint(
            size: Size.square(size),
            painter: _StarPainter(
              fill: (value - i).clamp(0.0, 1.0),
              band: t.hues.iris.band,
              ring: frostedRestRing(t),
              rtl: rtl,
            ),
          ),
      ],
    );
    if (live) {
      // The builder runs later, when `stars` has become what it builds.
      final drawn = stars;
      stars = LayoutBuilder(
        builder: (context, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final w = (context.findRenderObject()! as RenderBox).size.width;
            onChanged!(at(d.localPosition.dx, w));
          },
          onHorizontalDragUpdate: (d) {
            final w = (context.findRenderObject()! as RenderBox).size.width;
            onChanged!(at(d.localPosition.dx, w));
          },
          child: MouseRegion(cursor: SystemMouseCursors.click, child: drawn),
        ),
      );
      stars = FrostedKeyFocus(
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: true,
        radius: FrostedSpacing.s6,
        keys: {
          LogicalKeyboardKey.arrowRight: ?toward,
          LogicalKeyboardKey.arrowLeft: ?away,
          LogicalKeyboardKey.arrowUp: ?up,
          LogicalKeyboardKey.arrowDown: ?down,
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: FrostedBreakpoints.hitTargetOf(context),
          ),
          // At the line's start, as the read-only stars stand, when the
          // page stretches it; as tall as the touch target, never the page.
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: stars,
          ),
        ),
      );
    }
    return Semantics(
      label: label,
      enabled: live ? true : null,
      value: spoken(value),
      increasedValue: up == null ? null : spoken(value + step),
      decreasedValue: down == null ? null : spoken(value - step),
      onIncrease: up,
      onDecrease: down,
      excludeSemantics: true,
      child: stars,
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fill,
    required this.band,
    required this.ring,
    required this.rtl,
  });

  /// How much of the star is reached, 0 to 1.
  final double fill;
  final Gradient band;
  final Color ring;
  final bool rtl;

  static Path _star(Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * .48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size);
    final rect = Offset.zero & size;
    if (fill < 1) {
      canvas.drawPath(
        path,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (fill <= 0) return;
    canvas.save();
    final w = size.width * fill;
    canvas.clipRect(
      rtl
          ? Rect.fromLTWH(size.width - w, 0, w, size.height)
          : Rect.fromLTWH(0, 0, w, size.height),
    );
    canvas.drawPath(path, Paint()..shader = band.createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill ||
      old.band != band ||
      old.ring != ring ||
      old.rtl != rtl;
}

/// A file of a [FrostedFileUpload]: its [name], its size in [bytes], how
/// far its upload has gone ([progress], null once done), and what went
/// wrong ([error]).
@immutable
class FrostedUploadFile {
  /// A file named [name].
  const FrostedUploadFile(this.name, {this.bytes, this.progress, this.error});

  /// Its name.
  final String name;

  /// Its size.
  final int? bytes;

  /// How far it has gone up, 0 to 1; null when it is up.
  final double? progress;

  /// What went wrong with it.
  final String? error;

  /// Its size as a person reads it: 820 KB, 2.4 MB.
  String? get size {
    final b = bytes;
    if (b == null) return null;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      other is FrostedUploadFile &&
      other.name == name &&
      other.bytes == bytes &&
      other.progress == progress &&
      other.error == error;

  @override
  int get hashCode => Object.hash(name, bytes, progress, error);
}

/// Where files are given: a glass well with the upload glyph, the glass
/// Choose a file and the invitation to drop one, then the [files] given so
/// far, each its name and size with its upload's progress and a remove. The
/// package picks no files itself: [onPressed] opens the app's picker, and an
/// app that takes drops sets [dragging] while one is over it (the well's
/// rim brightens and glows by day, takes the accent by night, as a field
/// holding focus does; with an [error] it warms to the over hue). Read
/// aloud as [label].
///
/// ```dart
/// FrostedFileUpload(label: 'Attachments', hint: 'PDF or images, up to 10 MB', onPressed: pick, files: files, onRemoved: (f) => setState(() => files.remove(f)))
/// ```
class FrostedFileUpload extends StatelessWidget {
  /// A place for files, called [label].
  const FrostedFileUpload({
    required this.label,
    this.onPressed,
    this.files = const [],
    this.onRemoved,
    this.hint,
    this.dragging = false,
    this.error,
    super.key,
  });

  /// What the files are for, printed over the well and spoken.
  final String label;

  /// Opens the app's file picker; null makes it inert.
  final VoidCallback? onPressed;

  /// The files given so far.
  final List<FrostedUploadFile> files;

  /// Removes a file; null draws no remove.
  final ValueChanged<FrostedUploadFile>? onRemoved;

  /// What it takes ("PDF or images, up to 10 MB").
  final String? hint;

  /// Whether a dragged file is over it.
  final bool dragging;

  /// What is wrong, under it in the over ink.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final well = FrostedWell(
      radius: FrostedCorners.r18,
      focused: dragging,
      error: error != null,
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.s20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s10,
            children: [
              Icon(
                FrostedGlyphs.upload,
                size: 24,
                color: t.colorScheme.textSecondary,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: FrostedSpacing.s8,
                runSpacing: FrostedSpacing.s6,
                children: [
                  FrostedButton.glass(
                    words.chooseFile,
                    size: FrostedButtonSize.small,
                    onPressed: onPressed,
                  ),
                  Text(words.dropFile, style: t.textTheme.bodySmall),
                ],
              ),
              if (hint case final hint?)
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.s8,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
            ),
          ),
          well,
          for (final file in files)
            _FileRow(
              file: file,
              onRemoved: onRemoved == null ? null : () => onRemoved!(file),
            ),
          if (error case final error?)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: t.textTheme.bodySmall.c(t.colorScheme.over),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemoved});

  final FrostedUploadFile file;
  final VoidCallback? onRemoved;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final progress = file.progress;
    return FrostedFace(
      material: FrostedMaterial.pane,
      radius: BorderRadius.circular(FrostedCorners.r12),
      ring: frostedLitEdge(t, t.colorScheme.border),
      padding: const EdgeInsetsDirectional.fromSTEB(
        14,
        10,
        6,
        10,
      ).resolve(Directionality.of(context)),
      child: Row(
        spacing: FrostedSpacing.s10,
        children: [
          Icon(FrostedGlyphs.file, size: 18, color: t.colorScheme.textTertiary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s4,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleMedium,
                ),
                if (file.error case final error?)
                  Text(
                    error,
                    style: t.textTheme.bodySmall.c(t.colorScheme.over),
                  )
                else if (progress != null)
                  FrostedLinearProgressIndicator(
                    value: progress,
                    label: file.name,
                    minHeight: 4,
                  )
                else if (file.size case final size?)
                  Text(size, style: t.textTheme.bodySmall),
              ],
            ),
          ),
          if (onRemoved case final remove?)
            FrostedHitSlop(
              child: FrostedPressable(
                onPressed: remove,
                label: '${words.remove} ${file.name}',
                radius: 14,
                child: SizedBox.square(
                  dimension: 28,
                  child: Icon(
                    FrostedGlyphs.close,
                    size: 16,
                    color: t.colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check row and choices
// ---------------------------------------------------------------------------

/// A checkbox with its words as one row (Material's `CheckboxListTile`):
/// the [label] in the body over a quiet [note], the check at the row's end,
/// at least 52 tall; a press anywhere on the row turns it. Read aloud as
/// one checkbox named [label]. [tristate] lets it go round through mixed
/// (a null [value]); a null [onChanged] leaves it faded and inert.
///
/// ```dart
/// FrostedCheckRow(label: 'Email me a receipt', note: 'Sent to the address on file', value: receipt, onChanged: (v) => setState(() => receipt = v ?? false))
/// ```
class FrostedCheckRow extends StatelessWidget {
  /// A row named [label], checked by [value].
  const FrostedCheckRow({
    required this.label,
    required this.value,
    this.note,
    this.onChanged,
    this.enabled = true,
    this.tristate = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(tristate || value != null, 'Only a tristate check is mixed.');

  /// The row's words.
  final String label;

  /// A quiet line under them.
  final String? note;

  /// Whether it is checked; null is mixed.
  final bool? value;

  /// Hands over the next state; null leaves the row inert.
  final ValueChanged<bool?>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether a row that can change may change now: false paints it disabled.
  final bool enabled;

  /// Whether a press goes round through mixed.
  final bool tristate;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => tristate ? false : true,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final change = enabled ? onChanged : null;
    final words = note;
    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s6),
        child: Row(
          spacing: FrostedSpacing.s12,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(label, style: t.textTheme.titleMedium),
                  if (words != null) Text(words, style: t.textTheme.bodyMedium),
                ],
              ),
            ),
            // The check is the row's picture: the row is the control.
            ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: FrostedCheckbox(
                    value: value,
                    label: label,
                    tristate: tristate,
                    onChanged: change == null ? null : (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    row = FrostedDim(off: !enabled, child: row);
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: change == null ? null : () => change(_next),
      label: words == null ? label : '$label, $words',
      role: FrostedPressRole.control,
      checked: value ?? false,
      excludeChild: true,
      radius: FrostedCorners.r10,
      child: row,
    );
  }
}

/// One value of a few, as a run of chips (tiles of Material's
/// `ChoiceChip`): each option a [FrostedChip], the chosen one lit, wrapping
/// onto a new line when the row runs out, 8 apart. A screen reader hears a
/// group named [label] of buttons, the chosen one selected. A null
/// [onChanged] leaves them inert; a disabled option stands faded.
///
/// ```dart
/// FrostedChoices<String>(label: 'Size', options: const [FrostedSelectOption('s', 'Small'), FrostedSelectOption('m', 'Medium'), FrostedSelectOption('l', 'Large')], value: size, onChanged: (v) => setState(() => size = v))
/// ```
class FrostedChoices<T> extends StatelessWidget {
  /// Chips over [options], [value] lit.
  const FrostedChoices({
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    super.key,
  });

  /// The choices, in reading order.
  final List<FrostedSelectOption<T>> options;

  /// The chosen value; null lights none.
  final T? value;

  /// Hands over the value pressed.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the group.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        child: Wrap(
          spacing: FrostedSpacing.s8,
          runSpacing: FrostedSpacing.s8,
          children: [
            for (final o in options)
              FrostedChip(
                o.label,
                selected: o.value == value,
                isEnabled: o.enabled && change != null,
                onPressed: change == null ? null : () => change(o.value),
              ),
          ],
        ),
      ),
    );
  }
}
