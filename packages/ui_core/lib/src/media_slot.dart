/// The one media-slot resolver: how a declared slot id becomes a picture.
///
/// A slot resolves to the bundled `assets/media/<slotId>.jpg`, or to the
/// durable URL the host-authored `assets/media/remote.json` maps it to
/// (`{"slots": {"<slotId>": "https://…"}}`). Pending images paint the
/// caller's placeholder, retry while mounted and settle without a new app
/// build; a screen never fetches a picture itself. A look's photo and
/// avatar components draw their placeholder and pass it to
/// [MediaSlotImage]; this file draws nothing else. A bundled photo also
/// shows the placeholder until its first frame decodes, as a remote one
/// always has.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

/// Where a slot's picture comes from.
abstract final class MediaSlot {
  /// The host-authored map from slot id to durable URL. Optional: a
  /// bundled or offline app carries none.
  static const String remoteManifest = 'assets/media/remote.json';

  /// The bundled picture for [slotId].
  static String assetPath(String slotId) => 'assets/media/$slotId.jpg';

  static final Expando<Future<Map<String, String>>> _remotes =
      Expando<Future<Map<String, String>>>();

  /// The slot → URL map [bundle] carries in [remoteManifest], read once per
  /// bundle. A missing or unreadable manifest reads as empty and is not
  /// remembered, so a live-preview rebuild that adds remote media is seen.
  static Future<Map<String, String>> remoteUrls(AssetBundle bundle) {
    return _remotes[bundle] ??= () async {
      try {
        final value = jsonDecode(await bundle.loadString(remoteManifest));
        final slots =
            (value as Map<String, dynamic>)['slots'] as Map<String, dynamic>;
        return slots.map((key, value) => MapEntry(key, value as String));
      } catch (_) {
        // Bundled/offline apps need no remote manifest. Do not retain a
        // miss across a live-preview rebuild that introduces remote media.
        _remotes[bundle] = null;
        return <String, String>{};
      }
    }();
  }
}

/// Trusted image delivery for one declared media slot, shared by a
/// system's photo and avatar components. [fallback] stands in while the
/// picture is pending and whenever it misses, so a pending image never
/// delays layout, first paint or publication.
///
/// A bundled picture starts at once, even while the optional remote
/// manifest is still loading. A remote one that fails retries while
/// mounted — after 2 s, then one second longer each time up to 10 s, for
/// at most 15 minutes — except a 404, which is terminal; disposal cancels
/// any pending retry.
///
/// ```dart
/// const MediaSlotImage(slotId: 'hero', fallback: ColoredBox(color: Color(0xFFDDDDDD)))
/// ```
class MediaSlotImage extends StatefulWidget {
  /// Creates a [MediaSlotImage].
  const MediaSlotImage({
    required this.slotId,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  /// The declared slot id.
  final String slotId;

  /// What stands in while the picture is pending or missing: the system's
  /// deterministic placeholder.
  final Widget fallback;

  /// How the picture fills its box.
  final BoxFit fit;

  /// Where the picture sits in its box when [fit] crops it (a subject low
  /// in the frame pinned `bottomCenter`).
  final AlignmentGeometry alignment;

  @override
  State<MediaSlotImage> createState() => _MediaSlotImageState();
}

class _MediaSlotImageState extends State<MediaSlotImage> {
  AssetBundle? _bundle;
  Future<Map<String, String>>? _source;
  Timer? _retry;
  int _attempt = 0;
  DateTime _started = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _source = MediaSlot.remoteUrls(bundle);
    }
  }

  @override
  void didUpdateWidget(MediaSlotImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slotId != widget.slotId) {
      _retry?.cancel();
      _retry = null;
      _attempt = 0;
      _started = DateTime.now();
    }
  }

  void _retryLater(String url, Object error) {
    if (error is NetworkImageLoadException && error.statusCode == 404) return;
    if (_retry != null || DateTime.now().difference(_started).inMinutes >= 15) {
      return;
    }
    _retry = Timer(Duration(seconds: (_attempt + 2).clamp(2, 10)), () async {
      await NetworkImage(url).evict();
      if (!mounted) return;
      _retry = null;
      setState(() => _attempt += 1);
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _source,
      builder: (context, snapshot) {
        // Start bundled images immediately, including while the optional
        // remote manifest is loading: offline rendering needs no extra
        // frame, and the fallback stands in until the first frame decodes.
        final url = snapshot.data?[widget.slotId];
        if (url == null) {
          return Image.asset(
            MediaSlot.assetPath(widget.slotId),
            fit: widget.fit,
            alignment: widget.alignment,
            frameBuilder: (context, child, frame, synchronouslyLoaded) =>
                frame == null && !synchronouslyLoaded ? widget.fallback : child,
            errorBuilder: (context, error, stack) => widget.fallback,
          );
        }
        return Image.network(
          url,
          key: ValueKey('$url:$_attempt'),
          fit: widget.fit,
          alignment: widget.alignment,
          frameBuilder: (context, child, frame, synchronouslyLoaded) =>
              frame == null ? widget.fallback : child,
          errorBuilder: (context, error, stack) {
            _retryLater(url, error);
            return widget.fallback;
          },
        );
      },
    );
  }
}
