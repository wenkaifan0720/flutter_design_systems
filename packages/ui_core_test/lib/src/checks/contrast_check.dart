part of '../alignment.dart';

/// Whether the words and icons a screen draws read on what is drawn under
/// them, at two levels: faults, which fail [DesignAlignmentReport.verify],
/// and findings under Material's bar, which it lists as advisories.
///
/// Material's bar is WCAG 2's: words at 4.5:1, large words (24 px, or
/// 18.66 px bold) and icons at 3:1 (1.4.3 and 1.4.11). Material's own
/// controls meet it in Material's own palettes, but for a disabled control.
/// Cupertino's do not, by its design: in its own palettes (measured on
/// `cupertino_ui` 1.1.7) its tint words read 4.01:1 on white, its
/// `secondaryLabel` words 3.43, a search field's placeholder 3.24, a tab
/// bar's inactive label 2.70, its list chevron 2.21, an orange icon 1.97
/// and a text field's placeholder 1.72 by day (2.23 by night). Words under
/// [wordsBar] (or a large word under [largeWordsBar]) and icons under
/// [iconsBar] are findings: what a look following Material leaves to fix,
/// which a Cupertino-like look may keep.
///
/// A fault is what neither Material nor Cupertino draws: words under
/// [wordsFloor] (2.6:1, below Cupertino's least, its tab bar's inactive
/// label at 2.70), an icon under [iconsFloor] (1.9:1, below its orange
/// icon's 1.97), and a text entry's hint or placeholder under [hintFloor]
/// (1.7:1, below its text field's placeholder at 1.72). A named palette
/// that a look's colour API lets fall there (a navy accent's words on a
/// night page) is one.
///
/// A disabled control's words and icon are left out, as WCAG leaves them:
/// its semantics say it is not enabled, or it is a control whose own focus
/// can't be taken (a disabled `CupertinoButton`, or `DropdownButton` arrow
/// and all). A button with no focus of its own (`CupertinoDialogAction`) is
/// read, as are words beside live controls under a focus that holds theirs. So are words no one sees (in a transparent colour or
/// opacity, off stage, clipped away, painted over), words drawn over a
/// ground of more than one colour (a picture, a gradient), whose ground no
/// one colour names, and words over a ground the boundary it reads holds
/// translucent. It reads the outermost repaint boundary drawing the words,
/// which in an app is the route's own: a dialog's surface there has no
/// page behind it, so a test that wraps its app in a `RepaintBoundary`
/// reads a dialog's words over the page it covers. Words in the very colour
/// of their ground read 1:1. A text field's typed text is not read. A run of separators alone (a "·"
/// between two dates, a breadcrumb's "/", a rule's "│") says no words and
/// is held as an icon is. Each run of words is read in its own
/// colour (its style's, through any opacity on the way) against the
/// commonest colour drawn under it, as the screen shows it: a list row's
/// own layer holds the words, not the page under them. It reads the drawn
/// pixels.
/// A test passes its tester's `runAsync`:
///
/// ```dart
/// final report = await const DesignContrastCheck(look: 'Gilt').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
@immutable
class DesignContrastCheck {
  /// A check for [look].
  const DesignContrastCheck({
    required this.look,
    this.wordsFloor = 2.6,
    this.iconsFloor = 1.9,
    this.hintFloor = 1.7,
    this.wordsBar = 4.5,
    this.largeWordsBar = 3,
    this.iconsBar = 3,
    this.pixelRatio = 3,
  }) : assert(
         wordsFloor <= wordsBar && wordsFloor <= largeWordsBar,
         'the words floor is at or under their bars',
       ),
       assert(
         iconsFloor <= iconsBar,
         'the icons floor is at or under their bar',
       ),
       assert(
         hintFloor <= wordsBar && hintFloor <= largeWordsBar,
         'the hint floor is at or under its bars',
       );

  /// The look's name, for messages.
  final String look;

  /// The least contrast words of any size keep: under it is a fault.
  final double wordsFloor;

  /// The least contrast an icon keeps: under it is a fault.
  final double iconsFloor;

  /// The least contrast a text entry's hint or placeholder keeps (words
  /// drawn where its typed text goes): under it is a fault.
  final double hintFloor;

  /// Material's bar for words: under it (and over the floor) is a finding.
  final double wordsBar;

  /// Material's bar for large words (24 px, or 18.66 px bold, at the text
  /// scale shown): under it is a finding.
  final double largeWordsBar;

  /// Material's bar for an icon: under it is a finding.
  final double iconsBar;

  /// The scale the screen is drawn at to read its pixels.
  final double pixelRatio;

  /// Checks every word and icon drawn under [context] (on screen, under a
  /// repaint boundary as every route is). A test passes its tester's
  /// `runAsync` (reading pixels takes real time); null reads them directly.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final shown = _shownIn(root);
    final off = _offWords(context);
    final entries = [
      for (final b in shown)
        if (b is RenderEditable) _global(b),
    ];
    final pixels = <RenderRepaintBoundary, DrawnPixels>{};
    final faults = <String>[];
    final findings = <String>[];
    final fallback = <String>[];
    for (final p in shown.whereType<RenderParagraph>()) {
      if (off.contains(p) || _disabledAbove(p)) continue;
      final boundary = _seenIn(p);
      if (boundary == null) continue;
      final drawn = pixels[boundary] ??= await DrawnPixels.read(
        boundary,
        pixelRatio,
        runAsync,
      );
      final global = _global(p);
      final hint = entries.any((e) {
        final both = e.intersect(global);
        return both.width > 0 &&
            both.height > 0 &&
            both.width * both.height >= global.width * global.height * 0.5;
      });
      for (final run in _ContrastRun.of(p, boundary, drawn)) {
        if (run.testFont) {
          fallback.add('"${run.text}"');
          continue;
        }
        final (floor, bar, what) = run.icon
            ? (iconsFloor, iconsBar, 'an icon')
            : run.separator
            ? (iconsFloor, iconsBar, 'a separator')
            : hint
            ? (hintFloor, run.large ? largeWordsBar : wordsBar, 'a hint')
            : (
                wordsFloor,
                run.large ? largeWordsBar : wordsBar,
                run.large ? 'large words' : 'words',
              );
        if (run.ratio >= bar) continue;
        final said =
            '$what ${run.icon ? '' : '"${run.text}" '}'
            '(${run.size.toStringAsFixed(1)} px): '
            '${_hex(run.ink)} on ${_hex(run.ground)} reads '
            '${_under(run.ratio)}:1';
        if (run.ratio < floor) {
          faults.add(
            '$said, under ${_ratio(floor)}, less than Material or Cupertino '
            'give ${run.icon || run.separator
                ? 'an icon'
                : hint
                ? 'a placeholder'
                : 'words outside a text entry'} '
            'in their own palettes',
          );
        } else {
          findings.add('$said, under Material\'s ${_ratio(bar)}');
        }
      }
    }
    if (fallback.isNotEmpty) {
      return DesignAlignmentReport(look, [_testFontProblem(fallback)]);
    }
    return DesignAlignmentReport(look, faults, advisories: findings);
  }

  /// Checks the screen `screen` gives in each of [palettes], by day and by
  /// night: [show] puts the look in a palette (null: the look's own) and a
  /// brightness and pumps it. One report, each line headed with its palette
  /// and brightness.
  ///
  /// ```dart
  /// final report = await const DesignContrastCheck(look: 'Gilt').sweep(
  ///   show: (palette, brightness) async {
  ///     // The look's own colour API takes the palette.
  ///     final theme = palette == null
  ///         ? GiltThemeData(brightness: brightness)
  ///         : GiltThemeData.from(
  ///             accent: palette.accent,
  ///             paper: palette.neutral,
  ///             brightness: brightness,
  ///           );
  ///     await tester.pumpWidget(
  ///       GiltApp(theme: theme, home: const SettingsScreen()),
  ///     );
  ///     await tester.pumpAndSettle();
  ///   },
  ///   screen: () => tester.element(find.byType(SettingsScreen)),
  ///   runAsync: tester.runAsync,
  /// );
  /// report.verify();
  /// ```
  Future<DesignAlignmentReport> sweep({
    required Future<void> Function(
      DesignPalette? palette,
      Brightness brightness,
    )
    show,
    required BuildContext Function() screen,
    Iterable<DesignPalette?> palettes = const [null, ...DesignPalette.briefs],
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
  }) async {
    final faults = <String>[];
    final findings = <String>[];
    for (final palette in palettes) {
      for (final brightness in Brightness.values) {
        await show(palette, brightness);
        final report = await check(screen(), runAsync: runAsync);
        final head =
            '${palette?.name ?? 'its own palette'}, '
            '${brightness == Brightness.dark ? 'night' : 'day'}: ';
        faults.addAll(report.problems.map((p) => '$head$p'));
        findings.addAll(report.advisories.map((a) => '$head$a'));
      }
    }
    return DesignAlignmentReport(look, faults, advisories: findings);
  }

  // A level as set: 3:1, 4.5:1, 2.65:1.
  static String _ratio(double r) =>
      '${r.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}:1';

  static String _hex(int rgb) =>
      '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  // Whether a control round [p] says it is not enabled.
  static bool _disabledAbove(RenderObject p) {
    for (RenderObject? up = p; up != null; up = up.parent) {
      if (up is RenderSemanticsAnnotations && up.properties.enabled == false) {
        return true;
      }
    }
    return false;
  }

  // The words of each control whose own focus can't be taken, read from
  // the widgets round them. The nearest focus round the words (but a
  // scope's) says, and it is a control's when a button's semantics stand
  // round it (a disabled CupertinoButton's FocusableActionDetector) or
  // round the words inside it (a disabled DropdownButton's InkWell, round
  // its selected item), no semantics boundary between, or else when it
  // holds a button's semantics and no other focus (the same InkWell, round
  // its arrow). A button with no focus of its own (a CupertinoDialogAction)
  // is live, as are words under a focus round a page's live controls.
  static Set<RenderObject> _offWords(BuildContext context) {
    final words = <(RenderObject, List<_Round>)>[];
    final round = <_Round>[];
    ({bool button, bool focus}) visit(Element e) {
      final w = e.widget;
      final said = switch (w) {
        Semantics() => _Round(
          button: w.properties.button ?? false,
          boundary: w.container || w.explicitChildNodes,
          focus: w.properties.focused == null ? null : true,
        ),
        FocusScope() => null,
        Focus(includeSemantics: true) => _Round(focus: w.canRequestFocus),
        _ => null,
      };
      if (said != null) round.add(said);
      if (e is RenderObjectElement && e.renderObject is RenderParagraph) {
        words.add((e.renderObject, [...round]));
      }
      var button = false, focus = false;
      e.visitChildren((child) {
        final inside = visit(child);
        button = button || inside.button;
        focus = focus || inside.focus;
      });
      if (said == null) return (button: button, focus: focus);
      round.removeLast();
      said
        ..holdsButton = button
        ..holdsFocus = focus;
      return (
        button: said.button || (button && !said.boundary),
        focus: focus || said.focus != null,
      );
    }

    visit(context as Element);
    return {
      for (final (p, path) in words)
        if (_offIn(path)) p,
    };
  }

  // Whether the nearest focus in [round] (the innermost last) can't be
  // taken and is a control's.
  static bool _offIn(List<_Round> round) {
    var inButton = false;
    for (var i = round.length - 1; i >= 0; i--) {
      final r = round[i];
      if (inButton && r.boundary) return false;
      if (r.button) inButton = true;
      final focus = r.focus;
      if (focus == null) continue;
      if (focus) return false;
      if (inButton) return true;
      for (var j = i - 1; j >= 0; j--) {
        if (round[j].button) return true;
        if (round[j].boundary) break;
      }
      return r.holdsButton && !r.holdsFocus;
    }
    return false;
  }

  // [ratio] to two places, never rounded up to a level it is under.
  static String _under(double ratio) =>
      ((ratio * 100).floor() / 100).toStringAsFixed(2);
}

/// A palette a person names in a brief: an [accent] and, when they name
/// one, the [neutral] ground it stands on. [briefs] are the five people
/// name most, which [DesignContrastCheck.sweep] tries by default.
@immutable
class DesignPalette {
  /// A palette called [name].
  const DesignPalette(this.name, {required this.accent, this.neutral});

  /// Navy on white.
  static const navy = DesignPalette(
    'navy + white',
    accent: Color(0xFF1F3A68),
    neutral: Color(0xFFFFFFFF),
  );

  /// Green on white.
  static const green = DesignPalette(
    'green + white',
    accent: Color(0xFF2E7D32),
    neutral: Color(0xFFFFFFFF),
  );

  /// Gold on black.
  static const blackAndGold = DesignPalette(
    'black + gold',
    accent: Color(0xFFC9A227),
    neutral: Color(0xFF111111),
  );

  /// Purple, with no ground named.
  static const purple = DesignPalette('purple', accent: Color(0xFF6D28D9));

  /// A pastel blush on cream.
  static const pastel = DesignPalette(
    'pastel + cream',
    accent: Color(0xFFF4A7B9),
    neutral: Color(0xFFFFF4EC),
  );

  /// The five palettes people name most in a brief: blue or navy with
  /// white, green with white, black with gold, purple, and a pastel.
  static const briefs = [navy, green, blackAndGold, purple, pastel];

  /// The palette's name, for messages.
  final String name;

  /// Its accent.
  final Color accent;

  /// Its neutral ground, or null when none is named.
  final Color? neutral;

  @override
  bool operator ==(Object other) =>
      other is DesignPalette &&
      other.name == name &&
      other.accent == accent &&
      other.neutral == neutral;

  @override
  int get hashCode => Object.hash(name, accent, neutral);

  @override
  String toString() => 'DesignPalette($name)';
}

// The marks that part words and say none themselves: dots, bullets, bars,
// slashes, dashes and the box rules a terminal draws, and spaces.
final Set<int> _separators = {for (final c in ' \u{a0}·•∙‧|│┃/\\—–-'.runes) c};

// One run of words (one style) of a paragraph, as drawn: its ink, the
// ground under it and the contrast between.
class _ContrastRun {
  _ContrastRun._({
    required this.text,
    required this.icon,
    required this.separator,
    required this.large,
    required this.size,
    required this.ink,
    required this.ground,
    required this.ratio,
    this.testFont = false,
  });

  final String text;
  final bool icon;

  // Separators alone (a "·", a "/", a "│"), which say no words.
  final bool separator;
  final bool large;
  final double size;
  final int ink;
  final int ground;
  final double ratio;
  final bool testFont;

  // The runs of [p] drawn in [boundary] ([drawn]) that can be read: shown,
  // in one colour, over a ground of one colour.
  static List<_ContrastRun> of(
    RenderParagraph p,
    RenderRepaintBoundary boundary,
    DrawnPixels drawn,
  ) {
    // What paints it: the opacity on the way (up to the boundary, whose
    // pixels are the screen as seen) and the clips round it.
    var alpha = 1.0;
    Rect? clip;
    RenderObject child = p;
    for (var up = p.parent; up != null; up = up.parent) {
      if (identical(child, boundary)) break;
      switch (up) {
        case RenderOpacity(:final opacity):
          alpha *= opacity;
        case RenderAnimatedOpacity(:final opacity):
          alpha *= opacity.value;
      }
      if (up.describeApproximatePaintClip(child) case final r?) {
        final inBoundary = MatrixUtils.transformRect(
          up.getTransformTo(boundary),
          r,
        );
        clip = clip == null ? inBoundary : clip.intersect(inBoundary);
      }
      child = up;
    }
    if (alpha <= 0.01) return const [];
    final toBoundary = p.getTransformTo(boundary);
    final screen = Offset.zero & boundary.size;
    final runs = <_ContrastRun>[];
    var offset = 0;
    void walk(InlineSpan span, TextStyle? inherited) {
      final style = inherited == null
          ? span.style
          : inherited.merge(span.style);
      if (span is PlaceholderSpan) {
        offset += 1;
        return;
      }
      if (span is! TextSpan) return;
      final text = span.text;
      if (text != null && text.isNotEmpty) {
        final start = offset;
        offset += text.length;
        final run = _read(
          p,
          drawn,
          text,
          style,
          alpha,
          start,
          offset,
          toBoundary,
          clip == null ? screen : clip.intersect(screen),
        );
        if (run != null) runs.add(run);
      }
      for (final c in span.children ?? const <InlineSpan>[]) {
        walk(c, style);
      }
    }

    walk(p.text, null);
    return runs;
  }

  static _ContrastRun? _read(
    RenderParagraph p,
    DrawnPixels drawn,
    String text,
    TextStyle? style,
    double alpha,
    int start,
    int end,
    Matrix4 toBoundary,
    Rect clip,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _emoji(trimmed)) return null;
    if (style?.foreground?.shader != null) return null;
    final colour =
        style?.foreground?.color ?? style?.color ?? const Color(0xFF000000);
    // Words in a transparent colour (room kept for them) no one sees.
    if (colour.a * alpha <= 0.01) return null;
    final boxes = p.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
    if (boxes.isEmpty) return null;
    var rect = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      rect = rect.expandToInclude(b.toRect());
    }
    rect = MatrixUtils.transformRect(toBoundary, rect).intersect(clip);
    if (rect.width < 1 || rect.height < 1) return null;
    final px = _Px(drawn, rect);
    final first = px.commonest();
    if (first == null) return null;
    var ink = _blend(first.colour, colour, alpha);
    // Words whose box is all their own colour: in the very colour of the
    // ground going on round them they read 1:1; in the test's own font,
    // which fills each letter's box, the ground round them is another.
    final filled = first.share >= 0.95 && _Px._apart(ink, first.colour) <= 6;
    final boxed =
        filled && px.ringShare(first.colour, (3 * drawn.ratio).round()) < 0.5;
    final same = filled && !boxed;
    final ground = filled ? first : (px.commonest(away: ink) ?? first);
    // A ground the boundary holds translucent (a dialog's surface, read
    // without the page behind it) is no one colour anyone sees.
    if (ground.alpha < 250) return null;
    ink = _blend(ground.colour, colour, alpha);
    // Its own colour, apart from the ground's, where it stands: none when
    // something is painted over it.
    final seen = filled ? first.share : px.share(ink, apartFrom: ground.colour);
    if (!filled && seen < 0.004) return null;
    final ratio = _contrast(ink, ground.colour);
    final icon = isIconGlyph(trimmed) || _iconFont(style?.fontFamily);
    // The test's own font draws each letter as a solid box.
    final testFont =
        !icon && trimmed.length >= 3 && (boxed || (!same && seen >= 0.5));
    if (boxed && !testFont) return null;
    // A ground of more than one colour: a picture, a gradient.
    if (!testFont && ground.share < 0.6) return null;
    final size = p.textScaler.scale(style?.fontSize ?? 14);
    final bold = (style?.fontWeight ?? FontWeight.normal).value >= 700;
    return _ContrastRun._(
      text: trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed,
      icon: icon,
      separator: !icon && trimmed.runes.every(_separators.contains),
      large: size >= 24 || (size >= 18.66 && bold),
      size: size,
      ink: ink,
      ground: ground.colour,
      ratio: ratio,
      testFont: testFont,
    );
  }

  static bool _iconFont(String? family) {
    final f = (family ?? '').toLowerCase();
    return f.contains('icon') ||
        f.contains('lucide') ||
        f.contains('symbols') ||
        f.contains('phosphor');
  }

  static bool _emoji(String text) => text.runes.any(
    (r) => (r >= 0x1F000 && r <= 0x1FAFF) || (r >= 0x2600 && r <= 0x27BF),
  );

  // [colour] at [alpha] over [ground] (0xRRGGBB).
  static int _blend(int ground, Color colour, double alpha) {
    final a = (colour.a * alpha).clamp(0.0, 1.0);
    int mix(int g, double c) => (g + ((c * 255).round() - g) * a).round();
    return mix(ground >> 16 & 0xFF, colour.r) << 16 |
        mix(ground >> 8 & 0xFF, colour.g) << 8 |
        mix(ground & 0xFF, colour.b);
  }

  static double _contrast(int a, int b) {
    double lum(int c) {
      double lin(int v) {
        final s = v / 255;
        return s <= 0.04045
            ? s / 12.92
            : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
      }

      return 0.2126 * lin(c >> 16 & 0xFF) +
          0.7152 * lin(c >> 8 & 0xFF) +
          0.0722 * lin(c & 0xFF);
    }

    final x = lum(a), y = lum(b);
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }
}

// The outermost repaint boundary drawn in the last frame that draws [node]:
// the screen as seen, with what lies under [node]'s own layer (a list draws
// each row in a layer of its own, which holds its words but not the page
// under them).
RenderRepaintBoundary? _seenIn(RenderObject node) {
  RenderRepaintBoundary? seen;
  for (RenderObject? up = node; up != null; up = up.parent) {
    if (up is RenderRepaintBoundary && DrawnPixels.inFrame(up)) seen = up;
  }
  return seen;
}

// The drawn pixels inside a rect (logical, in the boundary), as 0xRRGGBB.
class _Px {
  _Px(this.drawn, Rect rect)
    : left = (rect.left * drawn.ratio).floor().clamp(0, drawn.width),
      top = (rect.top * drawn.ratio).floor().clamp(0, drawn.height),
      right = (rect.right * drawn.ratio).ceil().clamp(0, drawn.width),
      bottom = (rect.bottom * drawn.ratio).ceil().clamp(0, drawn.height);

  final DrawnPixels drawn;
  final int left, top, right, bottom;

  int _at(int x, int y) =>
      drawn.bytes.getUint32((y * drawn.width + x) * 4) >> 8;

  int _alphaAt(int x, int y) =>
      drawn.bytes.getUint8((y * drawn.width + x) * 4 + 3);

  static int _apart(int a, int b) => math.max(
    ((a >> 16 & 0xFF) - (b >> 16 & 0xFF)).abs(),
    math.max(
      ((a >> 8 & 0xFF) - (b >> 8 & 0xFF)).abs(),
      ((a & 0xFF) - (b & 0xFF)).abs(),
    ),
  );

  // The commonest colour (in buckets of 8 levels a channel): the commonest
  // exact colour in the commonest bucket, with the share of the pixels read
  // the bucket holds and its mean alpha; pixels within 6 levels of [away]
  // are not read.
  ({int colour, double share, int alpha})? commonest({int? away}) {
    final counts = <int, List<int>>{};
    final colours = <int, Map<int, int>>{};
    var all = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final c = _at(x, y);
        if (away != null && _apart(c, away) <= 6) continue;
        all++;
        final k =
            (c >> 19 & 0x1F) << 10 | (c >> 11 & 0x1F) << 5 | (c >> 3 & 0x1F);
        final e = counts.putIfAbsent(k, () => [0, 0]);
        e[0]++;
        e[1] += _alphaAt(x, y);
        final exact = colours[k] ??= <int, int>{};
        exact[c] = (exact[c] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final key = counts.keys.reduce(
      (a, b) => counts[a]![0] >= counts[b]![0] ? a : b,
    );
    final n = counts[key]![0];
    final exact = colours[key]!.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return (colour: exact.key, share: n / all, alpha: counts[key]![1] ~/ n);
  }

  // The share of the pixels in a ring [by] pixels wide round these within
  // 6 levels of [colour] (1 with no ring, at the drawn pixels' edge).
  double ringShare(int colour, int by) {
    var near = 0, all = 0;
    final l = math.max(0, left - by), t = math.max(0, top - by);
    final r = math.min(drawn.width, right + by);
    final b = math.min(drawn.height, bottom + by);
    for (var y = t; y < b; y++) {
      for (var x = l; x < r; x++) {
        if (x >= left && x < right && y >= top && y < bottom) continue;
        all++;
        if (_apart(_at(x, y), colour) <= 6) near++;
      }
    }
    return all == 0 ? 1 : near / all;
  }

  // The share of the pixels within 6 levels of [colour] and more than 6
  // from [apartFrom].
  double share(int colour, {required int apartFrom}) {
    var near = 0, all = 0;
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        all++;
        final c = _at(x, y);
        if (_apart(c, colour) <= 6 && _apart(c, apartFrom) > 6) near++;
      }
    }
    return all == 0 ? 0 : near / all;
  }
}

// A widget round some words, as the check reads it for a control's focus:
// a button's semantics, a semantics boundary, or a focus and whether it can
// be taken, with what it holds.
class _Round {
  _Round({this.button = false, this.boundary = false, this.focus});

  final bool button;
  final bool boundary;
  // Null where the widget says nothing of focus.
  final bool? focus;
  // A button's semantics inside, no boundary between; another focus inside.
  bool holdsButton = false;
  bool holdsFocus = false;
}
