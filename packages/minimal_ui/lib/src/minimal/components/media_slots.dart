import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A declared media slot's photograph as an [ImageProvider], for the APIs
/// that take one rather than a slot id (a kit's `image:`, a section's
/// `picture:`, a sample's `image: (name) => …`), so no page loads
/// `assets/media/` by hand.
///
/// It resolves as [MinimalMedia.media] does: the bundled `assets/media/<slot>.jpg`
/// first, else the durable link `assets/media/remote.json` maps the slot to.
/// A link whose photo is still being made is asked again until the photo
/// lands; one that failed (404), never lands within 15 minutes, or a slot
/// with neither ends as an image error, so the taker paints its own
/// placeholder.
///
/// ```dart
/// Image(image: MinimalMediaSource.image('hero-bakery'), fit: BoxFit.cover)
/// ```
abstract final class MinimalMediaSource {
  /// The photograph of the declared media slot [slotId].
  static ImageProvider image(String slotId) => _SlotImage(slotId);

  /// Reads a picture value that is no plain slot id: an app's own
  /// reference to a photo it stored, one on this device, a link. A record's
  /// picture field holds a slot id or such a reference; [MinimalMedia.media]
  /// and `MinimalAvatar(media:)` ask this for every value they are given.
  /// Its answer names the slot the value stands for, or the image that
  /// draws it; an answer with neither draws the placeholder, and null (or
  /// no reader) takes the value as a slot id. The app sets it once.
  ///
  /// ```dart
  /// MinimalMediaSource.reference = (context, value) => value.startsWith('https:') ? (slot: null, image: NetworkImage(value)) : null
  /// ```
  static MinimalMediaReference? Function(BuildContext context, String value)?
  reference;
}

/// What [MinimalMediaSource.reference] reads a picture value as: the declared
/// [slot] it stands for, or the [image] that draws it.
typedef MinimalMediaReference = ({String? slot, ImageProvider? image});

/// Trusted image delivery for one declared media slot, shared by
/// [MinimalMedia.media] and [MinimalAvatar]'s `media:`: the bundled
/// `assets/media/<slot>.jpg` first, else the durable link
/// `assets/media/remote.json` maps the slot to. While a linked photo is
/// still being made, [fallback] stands in under a slow sheen; the photo
/// replaces it when it lands. A slot with neither, or a link that failed
/// (404) or never landed within 15 minutes, shows [fallback] plain. A
/// pending image never delays layout, first paint or publication.
///
/// ```dart
/// MinimalMediaImage(slotId: 'face-hanna', fallback: initials)
/// ```
class MinimalMediaImage extends StatefulWidget {
  /// The photograph of the media slot [slotId], or [fallback] until it
  /// resolves.
  const MinimalMediaImage({
    super.key,
    required this.slotId,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  /// The declared media slot it shows.
  final String slotId;

  /// What shows while the slot has no photograph.
  final Widget fallback;

  /// How the photograph fills its box.
  final BoxFit fit;

  @override
  State<MinimalMediaImage> createState() => _MinimalMediaImageState();
}

class _MinimalMediaImageState extends State<MinimalMediaImage> {
  AssetBundle? _bundle;

  /// Where the slot's photo comes from; null while that is being read.
  _Source? _source;

  /// Bumped by every new resolution, so a stale one lands nowhere.
  int _ticket = 0;

  /// The value as [MinimalMediaSource.reference] reads it; null for a plain
  /// slot
  /// id.
  MinimalMediaReference? _read() =>
      MinimalMediaSource.reference?.call(context, widget.slotId);

  /// The slot the widget names: its slot id, or the slot a reference stands
  /// for (a slot with words of its own).
  String get _slot => _read()?.slot ?? widget.slotId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _resolve();
    }
  }

  @override
  void didUpdateWidget(MinimalMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slotId != widget.slotId) _resolve();
  }

  void _resolve() {
    final bundle = _bundle!;
    final slotId = _slot;
    final ticket = ++_ticket;
    // A photo the bundle is known to carry starts in this frame.
    _source = _knownSource(bundle, slotId);
    if (_source != null) return;
    _sourceOf(bundle, slotId).then((source) {
      if (mounted && ticket == _ticket) setState(() => _source = source);
    });
  }

  @override
  Widget build(BuildContext context) {
    // A picture the app took or stored (no slot): through MinimalMediaSource.reference.
    final reference = _read();
    if (reference != null && reference.slot == null) {
      final image = reference.image;
      if (image == null) return widget.fallback;
      return Image(
        key: ValueKey(widget.slotId),
        image: image,
        fit: widget.fit,
        frameBuilder: (context, child, frame, synchronouslyLoaded) =>
            frame == null && !synchronouslyLoaded
            ? _Sheen(child: widget.fallback)
            : child,
        errorBuilder: (context, error, stack) => widget.fallback,
      );
    }
    final source = _source;
    // Still reading where it comes from: start the bundled photo at once,
    // as an offline render needs no extra frame. A slot the bundle does not
    // carry shows the placeholder until the read lands.
    if (source == null) return _asset(_assetPath(_slot));
    final url = source.url;
    if (url != null) {
      return Image(
        // Its own element: an Image keeps the error of the provider before.
        key: ValueKey(url),
        image: _PendingNetworkImage(url),
        fit: widget.fit,
        // Pending: the placeholder under the sheen, until the photo lands.
        frameBuilder: (context, child, frame, synchronouslyLoaded) =>
            frame == null ? _Sheen(child: widget.fallback) : child,
        // Failed for good: the placeholder, plain.
        errorBuilder: (context, error, stack) => widget.fallback,
      );
    }
    final asset = source.asset;
    return asset == null ? widget.fallback : _asset(asset);
  }

  /// The bundled photo at [path], the placeholder until its first frame.
  Widget _asset(String path) => Image.asset(
    path,
    fit: widget.fit,
    frameBuilder: (context, child, frame, synchronouslyLoaded) =>
        frame == null && !synchronouslyLoaded ? widget.fallback : child,
    errorBuilder: (context, error, stack) => widget.fallback,
  );
}

/// The pending sign over a placeholder: a soft band of light that sweeps
/// across it corner to corner in one finite [_sweepTime], rests [_restTime]
/// and sweeps again. Never a repeating animation: a capture (App Preview's
/// headless frames, a page check) runs a finite animation to its end, where
/// the band is off and the placeholder plain, and settles in the rest; a
/// looping one would hold every capture to its budget. Under reduced motion
/// and the test kill-switch it does not run: the placeholder stands plain.
class _Sheen extends StatefulWidget {
  const _Sheen({required this.child});

  final Widget child;

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  static const Duration _sweepTime = Duration(milliseconds: 1400);
  static const Duration _restTime = Duration(milliseconds: 700);

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: _sweepTime,
  )..addStatusListener(_swept);

  /// The rest between sweeps: a real-time timer, not an animation.
  Timer? _rest;
  bool _still = false;

  void _swept(AnimationStatus status) {
    if (status != AnimationStatus.completed || _still) return;
    _rest?.cancel();
    _rest = Timer(_restTime, () {
      _rest = null;
      if (mounted && !_still) _sweep.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = context.minimalStill;
    if (_still) {
      _rest?.cancel();
      _rest = null;
      _sweep
        ..stop()
        ..value = 0;
    } else if (!_sweep.isAnimating && _rest == null) {
      _sweep.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rest?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final glow = t.isLightAppearance
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.5)
        : t.foreground.withValues(alpha: 0.08);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) => CustomPaint(
                painter: _SheenPainter(
                  Curves.easeInOut.transform(_sweep.value),
                  glow,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One band of [glow], perpendicular to the box's diagonal, [progress] of
/// the way from beyond its top-left corner to beyond its bottom-right one:
/// off the box at 0 and at 1.
class _SheenPainter extends CustomPainter {
  const _SheenPainter(this.progress, this.glow);

  final double progress;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final diagonal = size.bottomRight(Offset.zero);
    final length = diagonal.distance;
    final along = diagonal / length;
    final half = math.max(length * 0.22, 24.0);
    final centre = along * (-half + progress * (length + 2 * half));
    final clear = glow.withValues(alpha: 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          centre - along * half,
          centre + along * half,
          [clear, glow, clear],
          const [0, 0.5, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter oldDelegate) =>
      progress != oldDelegate.progress || glow != oldDelegate.glow;
}

/// Where a slot's photo comes from: a bundled [asset], a remote [url], or
/// (both null) nowhere.
typedef _Source = ({String? asset, String? url});

String _assetPath(String slotId) => 'assets/media/$slotId.jpg';

/// The assets a bundle carries, once its manifest has been read: kept
/// synchronously, so every bundled photo after the first starts in its
/// first frame. A bundle's manifest does not change while it is mounted.
final _bundledAssets = Expando<Set<String>>();
final _bundledLoads = Expando<Future<Set<String>?>>();

/// [bundle]'s assets, or null when its manifest cannot be read (then tried
/// again next time rather than the miss retained).
Future<Set<String>?> _bundled(AssetBundle bundle) {
  return _bundledLoads[bundle] ??= () async {
    try {
      final assets = (await AssetManifest.loadFromAssetBundle(bundle))
          .listAssets()
          .toSet();
      _bundledAssets[bundle] = assets;
      return assets;
    } catch (_) {
      _bundledLoads[bundle] = null;
      return null;
    }
  }();
}

final _manifests = Expando<Future<Map<String, String>>>();

/// The slot → link map [bundle] carries in `assets/media/remote.json`, read
/// once per bundle. None (a bundled or offline app) reads as empty and is
/// not remembered, so a live-preview rebuild that adds remote media is seen.
Future<Map<String, String>> _remoteUrls(AssetBundle bundle) {
  return _manifests[bundle] ??= () async {
    try {
      final value = jsonDecode(
        await bundle.loadString('assets/media/remote.json'),
      );
      final slots =
          (value as Map<String, dynamic>)['slots'] as Map<String, dynamic>;
      return slots.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      _manifests[bundle] = null;
      return <String, String>{};
    }
  }();
}

/// [slotId]'s source when it can be told without waiting: a photo [bundle]
/// is known to carry.
_Source? _knownSource(AssetBundle bundle, String slotId) {
  final path = _assetPath(slotId);
  return (_bundledAssets[bundle]?.contains(path) ?? false)
      ? (asset: path, url: null)
      : null;
}

/// [slotId]'s source in [bundle]: its bundled photo first, else its remote
/// link, else none. A bundle whose manifest cannot be read cannot rule its
/// photo out, so an unlinked slot then tries the asset.
Future<_Source> _sourceOf(AssetBundle bundle, String slotId) async {
  final path = _assetPath(slotId);
  final assets = await _bundled(bundle);
  if (assets != null && assets.contains(path)) return (asset: path, url: null);
  final url = (await _remoteUrls(bundle))[slotId];
  if (url != null) return (asset: null, url: url);
  return (asset: assets == null ? path : null, url: null);
}

/// Hands on the frames of the image it follows, and stops following when
/// its last listener leaves.
abstract class _Relay extends ImageStreamCompleter {
  _Relay() {
    addOnLastListenerRemovedCallback(stop);
  }

  bool stopped = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  /// Follows [provider]'s frames; its error goes to [onError].
  void follow(
    ImageProvider provider,
    ImageConfiguration configuration,
    void Function(Object error, StackTrace? stack) onError,
  ) {
    final stream = provider.resolve(configuration);
    final listener = ImageStreamListener(
      (image, synchronousCall) => setImage(image),
      onChunk: reportImageChunkEvent,
      onError: (error, stack) {
        detach();
        // Never inside addListener: a taker that has not listened yet
        // would leave the error unheard and reported.
        scheduleMicrotask(() => onError(error, stack));
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void detach() {
    final stream = _stream, listener = _listener;
    _stream = null;
    _listener = null;
    if (stream != null && listener != null) stream.removeListener(listener);
  }

  void stop() {
    stopped = true;
    detach();
  }
}

/// A media slot as an image: see [MinimalMediaSource.image].
@immutable
final class _SlotImage extends ImageProvider<_SlotKey> {
  const _SlotImage(this.slotId);

  final String slotId;

  @override
  Future<_SlotKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(
        _SlotKey(slotId, configuration.bundle ?? rootBundle, configuration),
      );

  // Never cached itself (the photo it lands on is, as an asset or a
  // network image), so a pending link is asked only while someone shows it.
  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    _SlotKey key,
    ImageErrorListener handleError,
  ) {
    if (stream.completer == null) stream.setCompleter(_SlotRelay(key));
  }

  @override
  bool operator ==(Object other) =>
      other is _SlotImage && other.slotId == slotId;

  @override
  int get hashCode => slotId.hashCode;

  @override
  String toString() => "MinimalMediaSource.image('$slotId')";
}

@immutable
final class _SlotKey {
  const _SlotKey(this.slotId, this.bundle, this.configuration);

  final String slotId;
  final AssetBundle bundle;
  final ImageConfiguration configuration;

  @override
  bool operator ==(Object other) =>
      other is _SlotKey &&
      other.slotId == slotId &&
      identical(other.bundle, bundle);

  @override
  int get hashCode => Object.hash(slotId, bundle);
}

final class _SlotRelay extends _Relay {
  _SlotRelay(this.key) {
    final known = _knownSource(key.bundle, key.slotId);
    if (known != null) {
      _land(known);
    } else {
      _sourceOf(key.bundle, key.slotId).then((source) {
        if (!stopped) _land(source);
      });
    }
  }

  final _SlotKey key;

  void _land(_Source source) {
    final url = source.url, asset = source.asset;
    final ImageProvider? provider = url != null
        ? _PendingNetworkImage(url)
        : asset != null
        ? AssetImage(asset, bundle: key.bundle)
        : null;
    if (provider == null) {
      reportError(
        exception: FlutterError(
          'Media slot "${key.slotId}" has no bundled photo and no remote link.',
        ),
        silent: true,
      );
      return;
    }
    follow(
      provider,
      key.configuration,
      (error, stack) => reportError(exception: error, stack: stack),
    );
  }
}

/// A generated photo's durable link, asked again while it answers that the
/// photo is still being made (202) or fails for a passing reason, until the
/// photo lands. A 404 (it failed) or 15 minutes of asking end it as an
/// error. Never cached itself (the photo is, under its [NetworkImage]), so
/// the asking ends with its last taker.
@immutable
final class _PendingNetworkImage extends ImageProvider<_PendingNetworkImage> {
  const _PendingNetworkImage(this.url);

  final String url;

  @override
  Future<_PendingNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    _PendingNetworkImage key,
    ImageErrorListener handleError,
  ) {
    if (stream.completer == null) {
      stream.setCompleter(_Asking(url, configuration));
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _PendingNetworkImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

final class _Asking extends _Relay {
  _Asking(this.url, this.configuration) {
    _ask();
  }

  final String url;
  final ImageConfiguration configuration;
  Timer? _again;
  int _attempt = 0;

  /// The time spent waiting between asks: a sum of the waits, not a clock.
  Duration _waited = Duration.zero;

  static const Duration _patience = Duration(minutes: 15);

  void _ask() => follow(NetworkImage(url), configuration, _missed);

  void _missed(Object error, StackTrace? stack) {
    if (stopped) return;
    final status = error is NetworkImageLoadException ? error.statusCode : null;
    // Still being made: ask again at the pace the link asks for. Anything
    // else passing: back off, from 2 s to 10 s.
    final wait = status == 202
        ? const Duration(seconds: 2)
        : Duration(seconds: (_attempt + 2).clamp(2, 10));
    if (status == 404 || _waited + wait > _patience) {
      reportError(exception: error, stack: stack);
      return;
    }
    _attempt += 1;
    _waited += wait;
    _again = Timer(wait, () async {
      _again = null;
      // A failed network image may stay cached (on the web it does).
      await NetworkImage(url).evict();
      if (!stopped) _ask();
    });
  }

  @override
  void stop() {
    _again?.cancel();
    _again = null;
    super.stop();
  }
}
