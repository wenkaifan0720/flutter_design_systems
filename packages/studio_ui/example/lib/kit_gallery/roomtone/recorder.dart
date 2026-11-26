/// Record: the take's clock in a readout window, the two channels' meters,
/// the input gain on a fader and the monitor level on a knob, the record key
/// with its red lamp, and the markers dropped so far.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'publish.dart';
import 'roomtone.dart';
import 'save_take_stub.dart'
    if (dart.library.io) 'save_take_io.dart'
    if (dart.library.js_interop) 'save_take_web.dart';
import 'take_audio.dart';

/// The recorder, [recording] at first when asked.
/// What the recorder asks as it opens.
enum RoomtoneRecorderAsk {
  /// Whether to discard the take.
  discard,

  /// How to export the take.
  export,
}

class RoomtoneRecorder extends StatefulWidget {
  /// The recorder.
  const RoomtoneRecorder({super.key, this.recording = false, this.asking});

  /// Whether the take is rolling as the screen opens.
  final bool recording;

  /// What it asks as it opens; null: nothing.
  final RoomtoneRecorderAsk? asking;

  @override
  State<RoomtoneRecorder> createState() => _RoomtoneRecorderState();
}

class _RoomtoneRecorderState extends State<RoomtoneRecorder>
    with SingleTickerProviderStateMixin {
  late bool _recording = widget.recording;
  int _seconds = 434;
  double _gain = 0.62;
  double _monitor = 0.5;
  double _left = 0.58;
  double _right = 0.52;
  double _peak = 0.71;
  final List<RoomtoneMarker> _markers = [...roomtoneMarkers];
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (_recording) _ticker.start();
    final asking = widget.asking;
    if (asking != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (asking) {
          case RoomtoneRecorderAsk.discard:
            _discard();
          case RoomtoneRecorderAsk.export:
            _export();
        }
      });
    }
  }

  Future<void> _export() async {
    // A sheet from the foot on a phone; on a desk the same panel stands as a
    // dialog over the rack, clear of its edges.
    final seconds = _seconds;
    final markers = List<RoomtoneMarker>.of(_markers);
    final format = roomtoneDesk(context)
        ? await showStudioDialog<TakeFormat>(
            context: context,
            builder: (context) => StudioDialog(
              title: 'Export take',
              content: _ExportSheet(seconds: seconds, inDialog: true),
            ),
          )
        : await showStudioBottomSheet<TakeFormat>(
            context: context,
            title: 'Export take',
            builder: (context) => _ExportSheet(seconds: seconds),
          );
    if (format == null || !mounted) return;
    try {
      final result = await saveTake(TakeAudio.render(seconds, format, markers));
      if (mounted) showStudioToast(context, result);
    } catch (_) {
      if (mounted) {
        showStudioToast(
          context,
          'Could not save the take. Try exporting again.',
        );
      }
    }
  }

  void _tick(Duration elapsed) {
    // Levels from the input while the take rolls: the meters move with it.
    final t = elapsed.inMilliseconds / 1000;
    setState(() {
      _left =
          (0.45 + 0.3 * math.sin(t * 7.3) * math.sin(t * 2.1)).clamp(0, 1) *
          _gain *
          1.4;
      _right =
          (0.42 + 0.3 * math.sin(t * 6.1 + 1) * math.sin(t * 1.7)).clamp(0, 1) *
          _gain *
          1.4;
      _left = _left.clamp(0, 1);
      _right = _right.clamp(0, 1);
      _peak = math.max(_peak * 0.995, math.max(_left, _right));
      if ((elapsed - _last).inSeconds >= 1) {
        _last = elapsed;
        _seconds++;
      }
    });
  }

  void _toggle() {
    setState(() => _recording = !_recording);
    if (_recording) {
      _last = Duration.zero;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _mark() {
    final marker = (seconds: _seconds, label: 'Marker ${_markers.length + 1}');
    setState(() => _markers.add(marker));
    showStudioToast(
      context,
      'Marker added at ${roomtoneClock(_seconds)}',
      actionLabel: 'Undo',
      onAction: () => setState(() => _markers.remove(marker)),
    );
  }

  Future<void> _discard() async {
    final discard = await showStudioDialog<bool>(
      context: context,
      // It asks before something is lost: an alert, which the scrim does
      // not close.
      isAlert: true,
      builder: (context) => StudioDialog(
        title: 'Discard this take?',
        content: Text(
          'The ${roomtoneClock(_seconds)} you recorded will be gone.',
        ),
        actions: [
          StudioButton('Keep', onPressed: () => Navigator.pop(context, false)),
          StudioButton.lit(
            'Discard',
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    if (_recording) _toggle();
    setState(() {
      _seconds = 0;
      _markers.clear();
    });
    showStudioToast(context, 'Take discarded');
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final clock = StudioDisplay(
      readout: true,
      padding: const EdgeInsets.all(StudioSpacing.regular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StudioLamp(on: _recording, color: c.danger),
              const SizedBox(width: StudioSpacing.small),
              Text(
                _recording ? 'Recording' : 'Paused',
                style: t.caption.copyWith(color: c.onReadoutMuted),
              ),
              const SizedBox(width: StudioSpacing.medium),
              Expanded(
                child: Text(
                  'Episode 13 · take 2',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(color: c.onReadoutMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.small),
          Semantics(
            label: 'Recorded ${roomtoneClock(_seconds)}',
            excludeSemantics: true,
            child: Text(
              roomtoneClock(_seconds),
              textAlign: TextAlign.center,
              style: t.readout.copyWith(
                fontSize: 48,
                height: 56 / 48,
                // Paused, the figures stand unlit in the window and the
                // meters rest: nothing is going to tape.
                color: _recording ? c.danger : c.onReadoutMuted,
                shadows: [
                  if (_recording)
                    Shadow(
                      color: c.danger.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: StudioSpacing.medium),
          for (final (name, level) in [('L', _left), ('R', _right)]) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: Text(
                    name,
                    style: t.caption.copyWith(color: c.onReadoutMuted),
                  ),
                ),
                Expanded(
                  child: StudioMeter(
                    level: _recording ? level : 0,
                    peak: _recording ? _peak : null,
                    semanticLabel: name == 'L' ? 'Left level' : 'Right level',
                  ),
                ),
              ],
            ),
            if (name == 'L') const SizedBox(height: StudioSpacing.small),
          ],
        ],
      ),
    );
    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioSectionHeader('Input'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Gain', style: t.label),
                      const Spacer(),
                      StudioReadout(
                        '${roomtoneSigned((-24 + _gain * 30).round())} dB',
                        minWidth: 72,
                        style: const TextStyle(fontSize: 15, height: 20 / 15),
                      ),
                    ],
                  ),
                  StudioFader(
                    value: _gain,
                    onChanged: (v) => setState(() => _gain = v),
                    semanticLabel: 'Input gain',
                    semanticFormatter: (v) => '${(-24 + v * 30).round()} dB',
                  ),
                ],
              ),
            ),
            const SizedBox(width: StudioSpacing.extraLarge),
            Column(
              children: [
                StudioKnob(
                  value: _monitor,
                  divisions: 10,
                  onChanged: (v) => setState(() => _monitor = v),
                  semanticLabel: 'Monitor level',
                ),
                Text(
                  'Monitor',
                  style: t.caption.copyWith(color: c.legendMuted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    // The deck's transport, under its display.
    final transport = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: StudioSpacing.regular,
      runSpacing: StudioSpacing.small,
      children: [
        // The keys either side stand one width, so the record key keeps the
        // display's centre.
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _sideKey),
          child: StudioButton(
            'Mark',
            icon: const Icon(LucideIcons.flag),
            onPressed: _mark,
          ),
        ),
        StudioTransportKey(
          icon: Icon(_recording ? LucideIcons.pause : LucideIcons.circle),
          tooltip: _recording ? 'Pause recording' : 'Record',
          record: true,
          lit: _recording,
          size: 76,
          onPressed: _toggle,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _sideKey),
          child: StudioButton(
            'Discard',
            isDestructiveAction: true,
            onPressed: _discard,
          ),
        ),
      ],
    );
    final markers = StudioListGroup(
      header: 'Markers',
      children: [
        for (final m in _markers.reversed)
          StudioListTile(
            leading: StudioReadout(
              roomtoneClock(m.seconds),
              minWidth: 64,
              style: const TextStyle(fontSize: 14, height: 18 / 14),
            ),
            title: m.label,
          ),
      ],
    );
    return RoomtonePage(
      title: 'Record',
      maxWidth: wide ? 1080 : StudioMetrics.readingWidth,
      actions: [
        StudioIconButton(
          icon: const Icon(LucideIcons.share),
          tooltip: 'Export take',
          onPressed: _seconds == 0 ? null : _export,
        ),
      ],
      bottom: StudioButton.lit(
        'Finish take',
        icon: const Icon(LucideIcons.check),
        onPressed: _seconds == 0
            ? null
            : () => RoomtoneFrame.of(context).push(const RoomtonePublishPage()),
      ),
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The display with its transport under it; beside them the
                  // input's controls over the markers.
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        clock,
                        const SizedBox(height: StudioSpacing.large),
                        transport,
                      ],
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.extraLarge),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [controls, roomtoneGroupGap, markers],
                    ),
                  ),
                ],
              ),
            ]
          : [
              clock,
              roomtoneGroupGap,
              controls,
              roomtoneGroupGap,
              transport,
              roomtoneGroupGap,
              markers,
            ],
    );
  }
}

// How to export the take: the format, its quality, the markers as chapters.
class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.seconds, this.inDialog = false});

  final int seconds;

  // In a desk's dialog: a Cancel key beside Export, at the end.
  final bool inDialog;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  String _format = 'MP3';
  double _quality = 0.5;
  bool _chapters = true;

  int get _kbps => const [96, 128, 192, 256, 320][(_quality * 4).round()];
  TakeFormat get _settings => (name: _format, kbps: _kbps, chapters: _chapters);

  String get _rate => _format == 'WAV' ? '48 kHz, 24 bit' : '$_kbps kbps';

  @override
  Widget build(BuildContext context) {
    final theme = context.studioTheme;
    final c = theme.colors;
    final mb = _format == 'WAV'
        ? widget.seconds * 0.288
        : widget.seconds * _kbps / 8000;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSegmentedButton<String>(
          semanticLabel: 'Format',
          expand: true,
          segments: const [
            StudioSegment(value: 'MP3', label: 'MP3'),
            StudioSegment(value: 'WAV', label: 'WAV'),
          ],
          value: _format,
          onChanged: (v) => setState(() => _format = v),
        ),
        const SizedBox(height: StudioSpacing.large),
        Row(
          children: [
            Expanded(
              child: Text(
                'Quality',
                style: theme.textTheme.body.copyWith(color: c.legend),
              ),
            ),
            StudioReadout(_rate, minWidth: 128),
          ],
        ),
        const SizedBox(height: StudioSpacing.small),
        StudioFader(
          value: _quality,
          divisions: 4,
          onChanged: _format == 'WAV'
              ? null
              : (v) => setState(() => _quality = v),
          semanticLabel: 'Quality',
          semanticFormatter: (_) => _rate,
        ),
        const SizedBox(height: StudioSpacing.regular),
        StudioListGroup(
          children: [
            StudioListTile.toggle(
              title: 'Markers as chapters',
              value: _chapters,
              onChanged: (v) => setState(() => _chapters = v),
            ),
          ],
        ),
        const SizedBox(height: StudioSpacing.regular),
        Text(
          'Reference tone · ${roomtoneClock(widget.seconds)} · About ${mb.toStringAsFixed(1)} MB',
          style: theme.textTheme.secondary.copyWith(color: c.legendMuted),
        ),
        const SizedBox(height: StudioSpacing.large),
        if (widget.inDialog)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StudioButton(
                'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: StudioSpacing.small),
              StudioButton.lit(
                'Export',
                icon: const Icon(LucideIcons.download),
                onPressed: () => Navigator.of(context).pop(_settings),
              ),
            ],
          )
        else
          StudioButton.lit(
            'Export',
            icon: const Icon(LucideIcons.download),
            onPressed: () => Navigator.of(context).pop(_settings),
          ),
      ],
    );
  }
}

// The width of the keys either side of the record key: the wider of Mark and
// Discard at the reader's usual size.
const double _sideKey = 100;
