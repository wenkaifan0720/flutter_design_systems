import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:ui_core/ui_core.dart' show RawTapTargets;
import 'package:web/web.dart' as web;

import 'generated/studies.dart' as studies;

void runStudy(String look) {
  setUrlStrategy(null);
  WidgetsFlutterBinding.ensureInitialized();
  final launch = StintLaunch.fromUri(Uri.base);
  final fragment = Uri.tryParse(Uri.base.fragment);
  final host = _Host({
    ...Uri.base.queryParameters,
    ...?fragment?.queryParameters,
  });
  runApp(_Study(look: look, launch: launch, host: host));
}

/// What the documentation page changes beside the app's own settings: two
/// preferences a device would pass in, and two overlays drawn over the app.
///
/// The platform is not among them: a release build reads it once from the
/// browser (Flutter's override throws outside debug builds), so the app
/// always adapts to the visitor's own.
///
/// The page sends {type: 'stint-options', params} with any of theme (day,
/// night), scale (1 to 2), lang (en, ar, ja, de), density (standard,
/// compact), accent (one of the edition's palettes, by id), motion (reduce,
/// full), bold, targets and reader (1, 0); the app answers each change, its
/// own Settings page's included, with {type: 'stint-settings', params} in
/// the same words, and with palettes: the edition's, the look's own first,
/// each {id, name, swatch}, which the page's accent menu lists.
class _Host extends ChangeNotifier {
  _Host(Map<String, String> p)
    : reduceMotion = _flag(p['motion'], on: 'reduce', off: 'full'),
      bold = _flag(p['bold']),
      targets = p['targets'] == '1',
      reader = p['reader'] == '1';

  /// Null: the device's own preference.
  bool? reduceMotion, bold;
  bool targets, reader;

  static bool? _flag(String? value, {String on = '1', String off = '0'}) =>
      value == on ? true : (value == off ? false : null);

  void apply(Map<String, String> p) {
    var changed = false;
    if (p.containsKey('motion')) {
      reduceMotion = _flag(p['motion'], on: 'reduce', off: 'full');
      changed = true;
    }
    if (p.containsKey('bold')) {
      bold = _flag(p['bold']);
      changed = true;
    }
    if (p['targets'] case final v?) {
      targets = v == '1';
      changed = true;
    }
    if (p['reader'] case final v?) {
      reader = v == '1';
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// The settings in effect, in the page's words.
  Map<String, String> effective(StintSettings s) {
    final device = WidgetsBinding.instance.platformDispatcher;
    final night = switch (s.appearance) {
      Appearance.day => false,
      Appearance.night => true,
      Appearance.system => device.platformBrightness == Brightness.dark,
    };
    final features = device.accessibilityFeatures;
    return {
      'theme': night ? 'night' : 'day',
      'scale': '${s.scale ?? device.textScaleFactor}',
      'lang': s.language.name,
      'density': s.compact ? 'compact' : 'standard',
      'accent': s.palette?.id ?? s.accent ?? 'look',
      'motion': (reduceMotion ?? features.disableAnimations)
          ? 'reduce'
          : 'full',
      'bold': (bold ?? features.boldText) ? '1' : '0',
      'targets': targets ? '1' : '0',
      'reader': reader ? '1' : '0',
      // What reaches the controls here and its floor, against which the
      // tap-target overlay judges them, and the touch floor beside it.
      'input': RawTapTargets.fallback.inputOn().name,
      'floor': '${RawTapTargets.fallback.floorOn().width.round()}',
      'touchFloor': '${RawTapTargets.fallback.touch.width.round()}',
    };
  }

  /// The edition's palettes in the page's words: each id, name and swatch
  /// (#rrggbb).
  static List<Map<String, String>> palettes(StintSettings s) => [
    for (final p in s.palettes)
      {
        'id': p.id,
        'name': p.name,
        'swatch':
            '#${(p.swatch.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}',
      },
  ];
}

class _Study extends StatefulWidget {
  const _Study({required this.look, required this.launch, required this.host});
  final String look;
  final StintLaunch launch;
  final _Host host;

  @override
  State<_Study> createState() => _StudyState();
}

class _StudyState extends State<_Study> {
  final _semantics = SemanticsBinding.instance.ensureSemantics();
  late final _settings = StintSettings(widget.launch);
  late Future<Widget?> _app = _open();
  late final JSFunction _listener = _receive.toJS;
  var _posting = false;

  Future<Widget?> _open() {
    final app = studies.openStudy(
      widget.look,
      widget.launch.sharing(_settings),
    );
    app.then((_) => _post(), onError: (_) {});
    return app;
  }

  @override
  void initState() {
    super.initState();
    web.window.addEventListener('message', _listener);
    _settings.addListener(_post);
    widget.host.addListener(_post);
    PaintingBinding.instance.systemFonts.addListener(_fontsArrived);
  }

  /// Japanese draws with a fallback font fetched on first use. Text already
  /// laid out takes it on its own, but a builder that measured a word
  /// before it arrived ("does 15時間45分 fit?") chose with the wrong width,
  /// so every part of the app builds again, keeping its state.
  void _fontsArrived() {
    void again(Element element) {
      element.markNeedsBuild();
      element.visitChildren(again);
    }

    if (mounted) (context as Element).visitChildren(again);
    if (!_settling && _settings.language == StintLanguage.ja) {
      _settle?.cancel();
      _settle = Timer(const Duration(milliseconds: 500), _settleFonts);
    }
  }

  /// The engine fetches Japanese in a dozen pieces and lays text out again
  /// as each lands, yet now and then a word keeps an empty box until the
  /// next layout (a window resize clears it). Half a second after the last
  /// piece, the app takes the fonts once more, as the engine announces them.
  Timer? _settle;
  var _settling = false;

  Future<void> _settleFonts() async {
    _settling = true;
    final done = Completer<void>();
    ui.channelBuffers.push(
      SystemChannels.system.name,
      SystemChannels.system.codec.encodeMessage(const {'type': 'fontsChange'}),
      (_) => done.complete(),
    );
    await done.future;
    _settling = false;
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    _settings.removeListener(_post);
    widget.host.removeListener(_post);
    PaintingBinding.instance.systemFonts.removeListener(_fontsArrived);
    _settle?.cancel();
    _semantics.dispose();
    super.dispose();
  }

  void _receive(web.MessageEvent event) {
    if (event.origin != web.window.location.origin) return;
    final data = event.data.dartify();
    if (data is! Map || data['type'] != 'stint-options') return;
    final params = data['params'];
    if (params is! Map) return;
    final p = <String, String>{
      for (final MapEntry(:key, :value) in params.entries)
        if (key is String && (value is String || value is num)) key: '$value',
    };
    final scale = double.tryParse(p['scale'] ?? '');
    final language = StintLanguage.values.asNameMap()[p['lang']];
    final theme = switch (p['theme']) {
      'day' => Appearance.day,
      'night' => Appearance.night,
      _ => null,
    };
    final density = switch (p['density']) {
      'compact' => true,
      'standard' => false,
      _ => null,
    };
    // An id the edition doesn't offer keeps the look's own colours.
    final accent = p['accent'];
    if (theme != null ||
        language != null ||
        density != null ||
        accent != null ||
        (scale != null && scale.isFinite)) {
      _settings.update(() {
        if (theme != null) _settings.appearance = theme;
        if (language != null) _settings.language = language;
        if (density != null) _settings.compact = density;
        if (accent != null) _settings.accent = accent;
        if (scale != null && scale.isFinite) {
          _settings.scale = scale.clamp(1, 2).toDouble();
        }
      });
    }
    widget.host.apply(p);
    // A change the app already had still answers, so the page's buttons
    // always show what is in effect.
    _post();
  }

  /// Tells the page the settings in effect, once per batch of changes.
  void _post() {
    if (_posting) return;
    _posting = true;
    scheduleMicrotask(() {
      _posting = false;
      web.window.parent?.postMessage(
        {
          'type': 'stint-settings',
          'params': widget.host.effective(_settings),
          'palettes': _Host.palettes(_settings),
        }.jsify(),
        web.window.location.origin.toJS,
      );
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget?>(
    future: _app,
    builder: (context, snapshot) {
      if (snapshot.data case final app?) {
        return _Frame(host: widget.host, child: app);
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Text(
              'Opening Stint…',
              style: TextStyle(color: Color(0xff53565b), fontSize: 16),
            ),
          ),
        );
      }
      return MaterialApp(
        title: 'Stint',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.hasError
                      ? 'Stint could not open.'
                      : 'This edition of Stint is unavailable.',
                ),
                if (snapshot.hasError)
                  TextButton(
                    onPressed: () => setState(() => _app = _open()),
                    child: const Text('Try again'),
                  ),
                TextButton(
                  onPressed: () => web.window.location.assign('../stint/'),
                  child: const Text('Explore Stint editions'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The app with the host's preferences passed in as a device would (the
/// apps never make a MediaQuery of their own, so theirs reads this one), and
/// the overlays over it.
class _Frame extends StatelessWidget {
  const _Frame({required this.host, required this.child});
  final _Host host;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: host,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: host.reduceMotion ?? media.disableAnimations,
          boldText: host.bold ?? media.boldText,
        ),
        child: Stack(
          alignment: Alignment.topLeft,
          fit: StackFit.expand,
          children: [
            child,
            if (host.targets || host.reader)
              _Overlay(targets: host.targets, reader: host.reader),
          ],
        ),
      );
    },
  );
}

/// Draws what the semantics tree holds over the app: each control's tap
/// area against the floor, or what a screen reader announces for each
/// stop. It reads the tree the app already builds and changes nothing.
class _Overlay extends StatefulWidget {
  const _Overlay({required this.targets, required this.reader});
  final bool targets, reader;

  @override
  State<_Overlay> createState() => _OverlayState();
}

class _OverlayState extends State<_Overlay> {
  SemanticsOwner? _owner;
  final _version = ValueNotifier(0);

  void _changed() => _version.value++;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  void _attach() {
    final owner = View.pipelineOwnerOf(context).semanticsOwner;
    if (owner == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attach();
      });
      return;
    }
    if (owner == _owner) return;
    _owner?.removeListener(_changed);
    _owner = owner..addListener(_changed);
    _changed();
  }

  @override
  void dispose() {
    _owner?.removeListener(_changed);
    _version.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: CustomPaint(
        painter: _SemanticsPainter(
          owner: _owner,
          version: _version,
          ratio: View.of(context).devicePixelRatio,
          floor: RawTapTargets.fallback.floorOn().width,
          targets: widget.targets,
          reader: widget.reader,
        ),
      ),
    ),
  );
}

class _Stop {
  _Stop(this.node, this.data, this.rect, this.clip);
  final SemanticsNode node;
  final SemanticsData data;
  final Rect rect;

  /// Whether the rect meets the clip of a scrolling list or a panel, so its
  /// size there is not the control's own.
  final bool clip;

  bool get actionable =>
      data.hasAction(SemanticsAction.tap) ||
      data.hasAction(SemanticsAction.longPress) ||
      data.hasAction(SemanticsAction.increase) ||
      data.hasAction(SemanticsAction.decrease) ||
      data.flagsCollection.isTextField ||
      data.flagsCollection.isSlider;

  /// What a screen reader says at this stop: its name, then its role, then
  /// its state, as VoiceOver and TalkBack order them.
  String? get announcement {
    final f = data.flagsCollection;
    final role = f.isTextField
        ? 'text field'
        : f.isSlider
        ? 'slider'
        : f.isToggled != Tristate.none
        ? 'switch'
        : f.isChecked != CheckedState.none
        ? (f.isInMutuallyExclusiveGroup ? 'radio button' : 'checkbox')
        : f.isLink
        ? 'link'
        : f.isButton
        ? 'button'
        : f.isHeader
        ? 'heading'
        : f.isImage
        ? 'image'
        : switch (data.role) {
            SemanticsRole.none => null,
            final r => r.name.replaceAllMapped(
              RegExp('[A-Z]'),
              (m) => ' ${m[0]!.toLowerCase()}',
            ),
          };
    final state = [
      if (f.isChecked == CheckedState.isTrue) 'checked',
      if (f.isChecked == CheckedState.isFalse) 'not checked',
      if (f.isChecked == CheckedState.mixed) 'mixed',
      if (f.isToggled == Tristate.isTrue) 'on',
      if (f.isToggled == Tristate.isFalse) 'off',
      if (f.isSelected == Tristate.isTrue) 'selected',
      if (f.isExpanded == Tristate.isTrue) 'expanded',
      if (f.isExpanded == Tristate.isFalse) 'collapsed',
      if (f.isRequired == Tristate.isTrue) 'required',
      if (f.isEnabled == Tristate.isFalse) 'dimmed',
    ];
    final name = [
      data.label,
      if (!f.isObscured) data.value,
    ].where((s) => s.trim().isNotEmpty).join(', ');
    // A container with no name (a table's rows and cells, a list) is not a
    // stop a screen reader dwells on; a control or a landmark is.
    if (name.isEmpty &&
        (role == null ||
            const {
              'table',
              'row',
              'cell',
              'column header',
              'list',
              'list item',
              'region',
              'complementary',
              'content info',
            }.contains(role))) {
      return null;
    }
    return [
      if (name.isNotEmpty) name.replaceAll('\n', ' '),
      ?role,
      ...state,
    ].join(', ');
  }
}

class _SemanticsPainter extends CustomPainter {
  _SemanticsPainter({
    required this.owner,
    required Listenable version,
    required this.ratio,
    required this.floor,
    required this.targets,
    required this.reader,
  }) : super(repaint: version);

  final SemanticsOwner? owner;
  final double ratio, floor;
  final bool targets, reader;

  static const _pass = Color(0xff13803a);
  static const _fail = Color(0xffd0242f);
  static const _unjudged = Color(0xff6b7280);
  static const _stop = Color(0xff5a46d6);

  List<_Stop> _stops() {
    final stops = <_Stop>[];
    void visit(SemanticsNode node, Matrix4 parent) {
      final transform = node.transform;
      final m = transform == null ? parent : parent.multiplied(transform);
      final data = node.getSemanticsData();
      if (!node.isInvisible && !data.flagsCollection.isHidden) {
        final clip = node.parentPaintClipRect;
        final r = node.rect;
        final clipped =
            clip != null &&
            ((r.left - clip.left).abs() < 0.5 ||
                (r.top - clip.top).abs() < 0.5 ||
                (r.right - clip.right).abs() < 0.5 ||
                (r.bottom - clip.bottom).abs() < 0.5);
        stops.add(_Stop(node, data, MatrixUtils.transformRect(m, r), clipped));
      }
      if (!node.mergeAllDescendantsIntoThisNode) {
        node.visitChildren((child) {
          visit(child, m);
          return true;
        });
      }
    }

    if (owner?.rootSemanticsNode case final root?) {
      visit(root, Matrix4.diagonal3Values(1 / ratio, 1 / ratio, 1));
    }
    return stops;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stops = _stops();
    final taken = <Rect>[];
    if (reader) {
      final announced = [
        for (final s in stops)
          if (s.announcement case final a?) (s, a),
      ];
      // Controls first, then the smallest: their words matter most where
      // labels would overlap.
      announced.sort((a, b) {
        if (a.$1.actionable != b.$1.actionable) {
          return a.$1.actionable ? -1 : 1;
        }
        return (a.$1.rect.width * a.$1.rect.height).compareTo(
          b.$1.rect.width * b.$1.rect.height,
        );
      });
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _stop;
      for (final (s, _) in announced) {
        canvas.drawRect(s.rect.deflate(0.75), outline);
      }
      for (final (s, words) in announced) {
        _chip(canvas, size, s.rect, words, _stop, taken, top: true);
      }
    }
    if (targets) {
      for (final s in stops) {
        if (!s.actionable || s.rect.isEmpty) continue;
        final w = s.rect.width, h = s.rect.height;
        final meets = w >= floor - 0.5 && h >= floor - 0.5;
        final color = meets ? _pass : (s.clip ? _unjudged : _fail);
        canvas.drawRect(
          s.rect,
          Paint()..color = color.withValues(alpha: meets ? 0.1 : 0.22),
        );
        canvas.drawRect(
          s.rect.deflate(1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color,
        );
        _chip(
          canvas,
          size,
          s.rect,
          '${w.round()}×${h.round()}',
          color,
          taken,
          top: false,
        );
      }
    }
  }

  /// A label at the top start (or bottom end) of [rect], moved down past
  /// labels already drawn; dropped when no place is free.
  void _chip(
    Canvas canvas,
    Size size,
    Rect rect,
    String text,
    Color color,
    List<Rect> taken, {
    required bool top,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xffffffff),
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: rect.width.clamp(48, 260).toDouble() - 8);
    final chip = Size(painter.width + 8, painter.height + 4);
    for (var i = 0; i < 4; i++) {
      final origin = top
          ? Offset(rect.left, rect.top + i * chip.height)
          : Offset(
              rect.right - chip.width,
              rect.bottom - chip.height - i * chip.height,
            );
      final box = (origin & chip).shift(
        Offset(
          origin.dx + chip.width > size.width
              ? size.width - origin.dx - chip.width
              : (origin.dx < 0 ? -origin.dx : 0),
          origin.dy < 0 ? -origin.dy : 0,
        ),
      );
      if (taken.any((t) => t.overlaps(box))) continue;
      taken.add(box);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.94),
      );
      painter.paint(canvas, box.topLeft + const Offset(4, 2));
      break;
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(_SemanticsPainter old) =>
      old.owner != owner ||
      old.ratio != ratio ||
      old.floor != floor ||
      old.targets != targets ||
      old.reader != reader;
}
