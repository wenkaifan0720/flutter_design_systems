/// The Flutter side of the Expressive oracle (CONTRACT §7; the capture
/// contract in `tools/expressive_oracle/README.md`): renders each oracle
/// scene key the way the Compose oracle renders it — same theme label,
/// brightness, crop, DPR 2.625, platform Android, real fonts — and writes
/// the same files (`<key>.png`, `<key>.json`, and for motion
/// `<key>.frames.json` + `<key>.frames/NNN.png`) for `compare`.
///
/// A scene group is one file, `test/oracle/scenes/<id>_scenes_test.dart`,
/// whose `main` hands its [OracleGroup] to [runOracleGroup]; `flutter test`
/// discovers the files, and no shared list names a group (wave decision E4).
/// See `test/oracle/README.md`.
///
/// Run by `bun run flutter` in `tools/expressive_oracle` with
/// `--dart-define`s ([OracleRun]); without `ORACLE_OUT` (as in the design
/// system's own `flutter test`) every scene is still built and measured in
/// `baseline` light, and nothing is written.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/color/baked_colors.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/themes/registry.g.dart';

/// The device pixel ratio every capture runs at: the oracle AVD's 420 dpi.
const double oracleDensity = 2.625;

/// The oracle AVD's window in physical pixels (a screen scene's crop).
const Size oracleWindowPx = Size(1080, 2400);

/// What a crop is held to (CONTRACT §7 "Pixels"): 1.5 % for a component,
/// 3 % for a screen.
enum OracleSceneKind { component, screen }

/// A motion recording, as the oracle scene of the same key records it:
/// [frames] frames stepped 16 ms apart, the bounds of [tags] in each, and
/// with [images] every frame's crop.
@immutable
class OracleMotion {
  const OracleMotion({
    required this.tags,
    this.frames = 60,
    this.images = false,
  });

  final List<String> tags;
  final int frames;
  final bool images;

  /// Frames are stepped exactly this far apart (CONTRACT §7).
  static const Duration frame = Duration(milliseconds: 16);
}

/// An input performed on the node tagged [tag] once the scene has settled,
/// held while it is captured (a motion scene records from that moment). The
/// oracle performs the same input on the same tag. Disabled and selected
/// are not inputs: a scene builds its component disabled or selected.
@immutable
sealed class OracleInteraction {
  const OracleInteraction(this.tag);

  final String tag;

  /// `press`, `focus` or `hover`: the scene file's `interaction.kind`.
  String get kind;
}

/// A finger down at the node's centre, never released while captured.
final class OraclePress extends OracleInteraction {
  const OraclePress(super.tag);

  @override
  String get kind => 'press';
}

/// Keyboard focus on the first focusable at or below the node, with focus
/// highlights in keyboard mode (Material draws focus only then).
final class OracleFocus extends OracleInteraction {
  const OracleFocus(super.tag);

  @override
  String get kind => 'focus';
}

/// A mouse pointer resting over the node's centre.
final class OracleHover extends OracleInteraction {
  const OracleHover(super.tag);

  @override
  String get kind => 'hover';
}

/// One oracle scene, keyed exactly as its Compose twin. [size] is the crop
/// in dp (the oracle's `size`; multiples of 8 dp); [build] is centred in it
/// over the theme's `surface`. A [OracleSceneKind.screen] scene ([screen])
/// is the whole 1080×2400 px window instead, edge to edge, its system-bar
/// insets in `MediaQuery.padding`/`viewPadding`. Every node to measure is
/// wrapped in an [OracleTag].
@immutable
class OracleScene {
  const OracleScene({
    required this.key,
    required this.size,
    required this.build,
    this.motion,
    this.interaction,
  }) : kind = OracleSceneKind.component;

  const OracleScene.screen({
    required this.key,
    required this.build,
    this.motion,
    this.interaction,
  }) : kind = OracleSceneKind.screen,
       size = Size.zero;

  final String key;
  final Size size;
  final OracleSceneKind kind;
  final OracleMotion? motion;
  final OracleInteraction? interaction;
  final WidgetBuilder build;

  /// The key's first segment: its group's id.
  String get group => key.split('/').first;

  static final RegExp keyPattern = RegExp(
    r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*(?:/[a-z0-9]+(?:-[a-z0-9]+)*)+$',
  );
}

/// One scene group: [id] is the first segment of every one of its keys,
/// the same id as the Compose group (`scenes/<Name>Scenes.kt`) and the
/// stem of its file (`<id with _>_scenes_test.dart`).
///
/// [frame] wraps each scene in what its components need above them (for
/// components, the Expressive host, once it exists); the harness itself
/// provides only the media query, the text direction and the theme scope.
@immutable
class OracleGroup {
  const OracleGroup({required this.id, required this.scenes, this.frame});

  final String id;
  final List<OracleScene> scenes;
  final Widget Function(BuildContext context, Widget scene)? frame;
}

/// Measures the node below it for the capture: its bounds in dp relative
/// to the crop and, when [shape] is given, the radii that shape resolves
/// to on those bounds. [tag] must be unique in its scene and spelled as the
/// oracle's `Modifier.testTag`. Place it directly around the widget whose
/// render box is measured (a text's `RichText`, a container's box): it adds
/// no render object of its own.
class OracleTag extends StatelessWidget {
  const OracleTag(
    this.tag, {
    required this.child,
    this.shape,
    this.drawn = false,
    super.key,
  });

  final String tag;
  final ShapeBorder? shape;
  final Widget child;

  /// Measure the drawn component inside its minimum interactive size, not
  /// the 48dp target: for a twin whose semantics sit inside Compose's
  /// `minimumInteractiveComponentSize` (`IconButton` applies its clickable
  /// inside it, so its testTag reports the 40dp container; `Slider` and
  /// `Checkbox` report the grown target).
  final bool drawn;

  @override
  Widget build(BuildContext context) => child;
}

/// What a harness run captures, from `--dart-define`s:
/// - `ORACLE_OUT`: where captures go (`<out>/<label>/<brightness>/<key>.*`);
///   unset = measure only, write nothing;
/// - `ORACLE_THEMES`: theme labels, comma-separated (`baseline`, `bloom`,
///   `bloom.c1`; default the contract's `baseline,bloom,bloom.c1`, or
///   `baseline` when measuring only);
/// - `ORACLE_BRIGHTNESS`: `light`, `dark` or both (default both, or light
///   when measuring only);
/// - `ORACLE_SCENES`: key globs, comma-separated, `*` any run (default all).
@immutable
class OracleRun {
  const OracleRun({
    required this.out,
    required this.themes,
    required this.brightnesses,
    required this.scenes,
  });

  factory OracleRun.fromEnvironment() {
    const out = String.fromEnvironment('ORACLE_OUT');
    const themes = String.fromEnvironment('ORACLE_THEMES');
    const brightness = String.fromEnvironment('ORACLE_BRIGHTNESS');
    const scenes = String.fromEnvironment('ORACLE_SCENES');
    List<String> list(String value) => <String>[
      for (final item in value.split(','))
        if (item.trim().isNotEmpty) item.trim(),
    ];
    final capturing = out.isNotEmpty;
    return OracleRun(
      out: capturing ? out : null,
      themes: themes.isNotEmpty
          ? list(themes)
          : capturing
          ? const <String>['baseline', 'bloom', 'bloom.c1']
          : const <String>['baseline'],
      brightnesses: [
        for (final b
            in brightness.isNotEmpty
                ? list(brightness)
                : capturing
                ? const <String>['light', 'dark']
                : const <String>['light'])
          switch (b) {
            'light' => Brightness.light,
            'dark' => Brightness.dark,
            _ => throw ArgumentError.value(b, 'ORACLE_BRIGHTNESS'),
          },
      ],
      scenes: [
        for (final glob in list(scenes))
          RegExp('^${glob.split('*').map(RegExp.escape).join('.*')}\$'),
      ],
    );
  }

  final String? out;
  final List<String> themes;
  final List<Brightness> brightnesses;
  final List<RegExp> scenes;

  bool selects(String key) =>
      scenes.isEmpty || scenes.any((glob) => glob.hasMatch(key));
}

/// A theme label (`bloom`, `bloom.c1`) as the Expressive theme it paints:
/// the preset at its own contrast, or its colours baked at `c<level>`.
ExpressiveThemeData oracleTheme(String label, Brightness brightness) {
  final match = RegExp(r'^([a-z0-9]+(?:-[a-z0-9]+)*)(?:\.c(0|0\.5|1))?$')
      .firstMatch(label);
  if (match == null) {
    throw ArgumentError.value(label, 'label', 'not <id> or <id>.c<level>');
  }
  final id = match.group(1)!;
  final preset = ExpressiveThemeData.preset(id, brightness);
  final level = match.group(2);
  if (level == null) return preset;
  final baked = expressiveBakedThemes[id]!;
  final contrast = double.parse(level);
  if (contrast == baked.contrast) return preset;
  return ExpressiveThemeData(
    id: preset.id,
    brightness: brightness,
    expression: preset.expression,
    colors: expressiveResolveColors(baked, brightness, contrast: contrast),
    type: preset.type,
    shapes: preset.shapes,
    motion: preset.motion,
  );
}

bool _fontsLoaded = false;

/// Loads the fonts the module bundles, so text renders in Roboto Flex and
/// symbols in Material Symbols — never flutter_test's square test font.
Future<void> loadOracleFonts() async {
  if (_fontsLoaded) return;
  for (final (family, asset) in const [
    ('RobotoFlex', 'assets/fonts/RobotoFlex.ttf'),
    ('MaterialSymbolsRounded', 'assets/fonts/MaterialSymbolsRounded.ttf'),
  ]) {
    // Under the name the styles ask for: the package's, once it is one.
    await (FontLoader(
      expressiveFontFamily(family),
    )..addFont(rootBundle.load(asset))).load();
  }
  _fontsLoaded = true;
}

/// Declares one test per scene × theme label × brightness of [group] that
/// [OracleRun.fromEnvironment] selects, each rendering and measuring the
/// scene and, when capturing, writing its files.
void runOracleGroup(OracleGroup group) {
  final run = OracleRun.fromEnvironment();
  setUpAll(loadOracleFonts);

  test('${group.id}: keys are well formed, unique and in the group', () {
    final keys = group.scenes.map((s) => s.key).toList();
    expect(keys.toSet().length, keys.length, reason: 'duplicate keys');
    for (final scene in group.scenes) {
      expect(OracleScene.keyPattern.hasMatch(scene.key), isTrue);
      expect(scene.group, group.id, reason: scene.key);
      if (scene.kind == OracleSceneKind.component) {
        for (final side in [scene.size.width, scene.size.height]) {
          expect(side > 0 && side % 8 == 0, isTrue, reason: scene.key);
        }
      }
    }
  });

  for (final scene in group.scenes.where((s) => run.selects(s.key))) {
    for (final label in run.themes) {
      for (final brightness in run.brightnesses) {
        testWidgets(
          '${scene.key}@$label@${brightness.name}',
          (tester) => _capture(tester, run, group, scene, label, brightness),
          variant: TargetPlatformVariant.only(TargetPlatform.android),
        );
      }
    }
  }
}

final GlobalKey _crop = GlobalKey(debugLabel: 'oracle crop');

Future<void> _capture(
  WidgetTester tester,
  OracleRun run,
  OracleGroup group,
  OracleScene scene,
  String label,
  Brightness brightness,
) async {
  final theme = oracleTheme(label, brightness);
  final screen = scene.kind == OracleSceneKind.screen;
  tester.view
    ..devicePixelRatio = oracleDensity
    // A component scene's crop sits in the whole window, where the oracle's
    // does (oracleCropOrigin): the window is what the shadow light hangs
    // over and what MediaQuery reports, as on the device.
    ..physicalSize = oracleWindowPx;
  final insets = screen ? oracleScreenInsets : EdgeInsets.zero;
  if (screen) {
    tester.view
      ..padding = FakeViewPadding(
        left: insets.left * oracleDensity,
        top: insets.top * oracleDensity,
        right: insets.right * oracleDensity,
        bottom: insets.bottom * oracleDensity,
      )
      ..viewPadding = FakeViewPadding(
        left: insets.left * oracleDensity,
        top: insets.top * oracleDensity,
        right: insets.right * oracleDensity,
        bottom: insets.bottom * oracleDensity,
      );
  }
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = 1;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  // Material's shadows render as shadows here, as on the device. The
  // binding checks the flag is back (to its own default: on under
  // flutter_test, off on a device) before tear-downs run.
  final disabledShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await _render(tester, run, group, scene, label, brightness, theme);
  } finally {
    debugDisableShadows = disabledShadows;
  }
}

Future<void> _render(
  WidgetTester tester,
  OracleRun run,
  OracleGroup group,
  OracleScene scene,
  String label,
  Brightness brightness,
  ExpressiveThemeData theme,
) async {
  final screen = scene.kind == OracleSceneKind.screen;
  final crop = screen ? oracleWindowPx / oracleDensity : scene.size;
  final insets = screen ? oracleScreenInsets : EdgeInsets.zero;

  final surface = theme.colors.surface;
  Widget content = Builder(builder: scene.build);
  if (!screen) {
    content = CustomSingleChildLayout(
      delegate: const _PixelCenter(),
      child: content,
    );
  }
  final frame = group.frame;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view).copyWith(
        textScaler: TextScaler.noScaling,
        platformBrightness: brightness,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ExpressiveTheme(
          data: theme,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: screen ? 0 : oracleCropOrigin.dx,
                top: screen ? 0 : oracleCropOrigin.dy,
              ),
              child: RepaintBoundary(
                key: _crop,
                child: ColoredBox(
                  color: surface,
                  child: SizedBox.fromSize(
                    size: crop,
                    child: frame == null
                        ? content
                        : Builder(
                            builder: (context) => frame(context, content),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  final motion = scene.motion;
  if (motion == null) await tester.pumpAndSettle();
  final release = await _perform(
    tester,
    scene.interaction,
    settle: motion == null,
  );

  final bounds = _measure(tester, scene.key);
  for (final b in bounds) {
    final inside =
        b.left >= -1e-6 &&
        b.top >= -1e-6 &&
        b.left + b.width <= crop.width + 1e-6 &&
        b.top + b.height <= crop.height + 1e-6;
    expect(
      inside,
      isTrue,
      reason: '${scene.key}: ${b.tag} is outside its crop',
    );
  }

  final out = run.out;
  final base = out == null
      ? null
      : '$out/$label/${brightness.name}/${scene.key}';
  if (base != null) {
    await _writePng(tester, '$base.png');
    _writeJson('$base.json', <String, Object?>{
      'key': scene.key,
      'theme': label,
      'brightness': brightness.name,
      'platform': 'android',
      'kind': scene.kind.name,
      'density': oracleDensity,
      'size': {
        'width': _Bounds._round(crop.width),
        'height': _Bounds._round(crop.height),
      },
      'bounds': [for (final b in bounds) b.toJson()],
      if (scene.interaction case final interaction?)
        'interaction': {'kind': interaction.kind, 'tag': interaction.tag},
      if (screen)
        'insets': {
          'top': insets.top,
          'right': insets.right,
          'bottom': insets.bottom,
          'left': insets.left,
        },
    });
  }

  if (motion != null) {
    final frames = <Map<String, Object?>>[];
    if (base != null && motion.images) {
      final dir = Directory('$base.frames');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
    }
    for (var index = 0; index < motion.frames; index++) {
      if (index > 0) await tester.pump(OracleMotion.frame);
      final tagged = _measure(
        tester,
        scene.key,
      ).where((b) => motion.tags.contains(b.tag)).toList();
      final missing = motion.tags.toSet().difference({
        for (final b in tagged) b.tag,
      });
      expect(missing, isEmpty, reason: '${scene.key} frame $index');
      frames.add({
        'index': index,
        'timeMs': index * OracleMotion.frame.inMilliseconds,
        'bounds': [for (final b in tagged) b.toJson()],
      });
      if (base != null && motion.images) {
        await _writePng(
          tester,
          '$base.frames/${index.toString().padLeft(3, '0')}.png',
        );
      }
    }
    if (base != null) {
      _writeJson('$base.frames.json', <String, Object?>{
        'key': scene.key,
        'density': oracleDensity,
        'frameMs': OracleMotion.frame.inMilliseconds,
        'tags': motion.tags,
        'images': motion.images,
        'frames': frames,
      });
    }
  }

  await release();
  // Let whatever the scene started finish, so no timer outlives the test.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

/// Centres the scene's content the way the oracle's `Box(contentAlignment
/// = Alignment.Center)` does: Compose places a child at a whole device
/// pixel (`Alignment.align` rounds the centred offset with `roundToInt`, in
/// px), so its content starts on the pixel grid. Flutter's [Center] would
/// leave it at a fractional pixel, which blurs every edge against the
/// oracle's.
class _PixelCenter extends SingleChildLayoutDelegate {
  const _PixelCenter();

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double snap(double free) =>
        (free * oracleDensity / 2).roundToDouble() / oracleDensity;
    return Offset(
      snap(size.width - childSize.width),
      snap(size.height - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_PixelCenter oldDelegate) => false;
}

/// The insets the oracle AVD's window reports to an app, in dp, as every
/// screen capture records them (`insets`): the system bars joined with the
/// display cutout, which is what Compose's chrome pads by
/// (`systemBarsForVisualComponents` = `systemBars ∪ displayCutout`) and what
/// Flutter's Android embedding reports as `MediaQuery.padding`. On this AVD
/// the cutout (132 px) is taller than the status bar (74 px); gesture
/// navigation's handle is 63 px at the bottom. `compare` holds each screen
/// capture's recorded insets to these.
const EdgeInsets oracleScreenInsets = EdgeInsets.fromLTRB(
  0,
  132 / oracleDensity,
  0,
  63 / oracleDensity,
);

/// Where a component scene's crop sits in the window, in dp: the oracle
/// frames it in `Box(Modifier.safeDrawingPadding())` (Scene.kt
/// `SceneFrame`), below the display cutout (132 px on this AVD, the
/// larger of the cutout and the 74 px status bar) and at the left edge.
const Offset oracleCropOrigin = Offset(0, 132 / oracleDensity);

/// Performs [interaction] and returns what releases it.
Future<Future<void> Function()> _perform(
  WidgetTester tester,
  OracleInteraction? interaction, {
  required bool settle,
}) async {
  Future<void> none() async {}
  if (interaction == null) return none;
  final target = _tagFinder(interaction.tag);
  expect(target, findsOneWidget, reason: 'interaction on ${interaction.tag}');
  Future<void> Function() release = none;
  switch (interaction) {
    case OraclePress():
      final gesture = await tester.startGesture(tester.getCenter(target));
      release = () async {
        await gesture.up();
      };
    case OracleHover():
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(target));
      release = () async {
        await gesture.removePointer();
      };
    case OracleFocus():
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final focus = find.descendant(
        of: target,
        matching: find.byType(Focus),
        matchRoot: true,
      );
      expect(focus, findsWidgets, reason: 'nothing focusable at the tag');
      // Focus.of from below the Focus's own inherited scope (its child)
      // finds that Focus's node.
      Element? scope;
      tester.element(focus.first).visitChildren((e) => scope ??= e);
      Element? below;
      scope!.visitChildren((e) => below ??= e);
      Focus.of(below!).requestFocus();
      release = () async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        FocusManager.instance.primaryFocus?.unfocus();
      };
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A motion scene records the response from here. The oracle's
    // `waitForIdle` with its clock paused recomposes and lays out but
    // delivers no frame time, so an animation the input started gets its
    // first frame (elapsed 0) at the first 16 ms step. Build and lay out the
    // same way, without a frame's transient callbacks: a ticker the input
    // started (directly or while rebuilding) first ticks at frame 1, as in
    // Compose, rather than one frame early.
    // ignore: invalid_use_of_protected_member
    tester.binding.drawFrame();
  }
  return release;
}

Finder _tagFinder(String tag) =>
    find.byWidgetPredicate((w) => w is OracleTag && w.tag == tag);

/// A measured node, in dp relative to the crop.
@immutable
class _Bounds {
  const _Bounds(
    this.tag,
    this.kind,
    this.left,
    this.top,
    this.width,
    this.height,
    this.corners,
  );

  final String tag;
  final String kind;
  final double left, top, width, height;
  final List<double>? corners;

  static double _round(double v) => (v * 10000).roundToDouble() / 10000;

  Map<String, Object?> toJson() => {
    'tag': tag,
    'kind': kind,
    'left': _round(left),
    'top': _round(top),
    'width': _round(width),
    'height': _round(height),
    if (corners case final c?) 'corners': [for (final r in c) _round(r)],
  };
}

/// [box]'s drawn component ([OracleTag.drawn]): its semantics bounds, looked
/// up through the proxies a component wraps itself in (merge semantics,
/// annotations) to the minimum interactive size, which reports the
/// component it grows.
Rect _drawnBounds(RenderBox box) {
  RenderObject node = box;
  while (node is RenderProxyBox) {
    final child = node.child;
    if (child == null || !child.hasSize || child.size != box.size) break;
    node = child;
  }
  final inner = node as RenderBox;
  return inner.semanticBounds != Offset.zero & inner.size
      ? inner.semanticBounds
      : box.semanticBounds;
}

List<_Bounds> _measure(WidgetTester tester, String key) {
  final root = tester.renderObject<RenderBox>(find.byKey(_crop));
  final out = <_Bounds>[];
  for (final element
      in find.byWidgetPredicate((w) => w is OracleTag).evaluate()) {
    final tag = element.widget as OracleTag;
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) {
      fail('$key: ${tag.tag} has no laid-out box');
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: root);
    // Compose's testTag reports the semantics node's bounds, which a
    // component may grow past its layout (IncreaseVerticalSemanticsBounds on
    // progress); RenderBox.semanticBounds is the same, and defaults to the
    // layout box.
    final rect = (tag.drawn ? _drawnBounds(box) : box.semanticBounds).shift(
      origin,
    );
    out.add(
      _Bounds(
        tag.tag,
        box is RenderParagraph ? 'text' : 'box',
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        _corners(tag.shape, Offset.zero & box.size),
      ),
    );
  }
  final tags = out.map((b) => b.tag).toList();
  expect(tags.toSet().length, tags.length, reason: '$key: duplicate tags');
  return out;
}

/// [shape]'s radii on [rect] (clockwise from top-left), when it has radii.
List<double>? _corners(ShapeBorder? shape, Rect rect) {
  final BorderRadius? radii = switch (shape) {
    null => null,
    ExpressiveCornerBorder() => shape.radiiOn(rect),
    RoundedRectangleBorder(:final borderRadius) => borderRadius.resolve(
      TextDirection.ltr,
    ),
    StadiumBorder() ||
    CircleBorder() => BorderRadius.circular(rect.shortestSide / 2),
    _ => null,
  };
  if (radii == null) return null;
  final limit = rect.shortestSide / 2;
  double r(Radius radius) => radius.x < limit ? radius.x : limit;
  return [
    r(radii.topLeft),
    r(radii.topRight),
    r(radii.bottomRight),
    r(radii.bottomLeft),
  ];
}

Future<void> _writePng(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_crop),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: oracleDensity);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void _writeJson(String path, Map<String, Object?> json) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}
