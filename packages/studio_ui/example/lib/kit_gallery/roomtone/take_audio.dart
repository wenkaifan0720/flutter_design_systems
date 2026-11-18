import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'data.dart';
import 'reference_frames.dart';

/// Export settings for Roomtone's built-in reference recording.
typedef TakeFormat = ({String name, int kbps, bool chapters});

/// The recorder uses a quiet 250 Hz reference signal. The repeated three-second
/// block keeps a full-length stereo WAV inexpensive to assemble and save.
class TakeAudio {
  TakeAudio._(this.header, this.block, this.repeats, this.tail, this.extension);

  final Uint8List header;
  final Uint8List block;
  final int repeats;
  final Uint8List tail;
  final String extension;

  String get filename => 'roomtone-take.$extension';
  String get mime => extension == 'wav' ? 'audio/wav' : 'audio/mpeg';

  factory TakeAudio.render(
    int seconds,
    TakeFormat format,
    List<RoomtoneMarker> markers,
  ) {
    final chapters = format.chapters
        ? markers
              .where(
                (marker) => marker.seconds >= 0 && marker.seconds < seconds,
              )
              .toList()
        : <RoomtoneMarker>[];
    if (format.name == 'MP3') {
      // MPEG-1 Layer III at 48 kHz has 1,152 samples (24 ms) per frame.
      final frame = base64Decode(roomtoneReferenceFrames[format.kbps]!);
      final block = _repeat(frame, 125);
      final frames = (seconds * 1000 / 24).round();
      return TakeAudio._(
        _id3Chapters(chapters, seconds),
        block,
        frames ~/ 125,
        Uint8List.sublistView(block, 0, frames % 125 * frame.length),
        'mp3',
      );
    }
    const hz = 48000, channels = 2, bytesPerSample = 3;
    const sampleBytes = channels * bytesPerSample;
    final cycle = Uint8List(hz ~/ 250 * sampleBytes);
    for (var i = 0; i < hz ~/ 250; i++) {
      final sample = (math.sin(2 * math.pi * 250 * i / hz) * 327680).round();
      for (var ch = 0; ch < channels; ch++) {
        final off = i * sampleBytes + ch * bytesPerSample;
        for (var b = 0; b < bytesPerSample; b++) {
          cycle[off + b] = (sample >> (8 * b)) & 255;
        }
      }
    }
    final block = _repeat(cycle, 250 * 3);
    final dataBytes = seconds * hz * sampleBytes;
    if (dataBytes > 0xffffffff - 65536) {
      throw const FormatException('This take exceeds the WAV file size limit.');
    }
    final formatChunk = _chunk('fmt ', [
      ..._int(1, 2),
      ..._int(channels, 2),
      ..._int(hz),
      ..._int(hz * sampleBytes),
      ..._int(sampleBytes, 2),
      ..._int(24, 2),
    ]);
    final metadata = <int>[];
    if (chapters.isNotEmpty) {
      final cues = BytesBuilder()..add(_int(chapters.length));
      final labels = BytesBuilder()..add(ascii.encode('adtl'));
      for (var i = 0; i < chapters.length; i++) {
        final offset = chapters[i].seconds * hz;
        cues.add([
          ..._int(i + 1),
          ..._int(offset),
          ...ascii.encode('data'),
          ..._int(0),
          ..._int(0),
          ..._int(offset),
        ]);
        labels.add(
          _chunk('labl', [
            ..._int(i + 1),
            ...utf8.encode(chapters[i].label),
            0,
          ]),
        );
      }
      metadata.addAll(_chunk('cue ', cues.takeBytes()));
      metadata.addAll(_chunk('LIST', labels.takeBytes()));
    }
    final body = [
      ...ascii.encode('WAVE'),
      ...formatChunk,
      ...metadata,
      ...ascii.encode('data'),
      ..._int(dataBytes),
    ];
    final header = Uint8List.fromList([
      ...ascii.encode('RIFF'),
      ..._int(body.length + dataBytes),
      ...body,
    ]);
    return TakeAudio._(
      header,
      block,
      seconds ~/ 3,
      Uint8List.sublistView(block, 0, (seconds % 3) * hz * sampleBytes),
      'wav',
    );
  }
}

Uint8List _repeat(Uint8List source, int count) {
  final result = Uint8List(source.length * count);
  if (count == 0) return result;
  result.setAll(0, source);
  var used = source.length;
  while (used < result.length) {
    final n = math.min(used, result.length - used);
    result.setRange(used, used + n, result);
    used += n;
  }
  return result;
}

List<int> _int(int value, [int width = 4, Endian order = Endian.little]) {
  final data = ByteData(width);
  if (width == 2) {
    data.setUint16(0, value, order);
  } else {
    data.setUint32(0, value, order);
  }
  return data.buffer.asUint8List();
}

List<int> _chunk(String name, List<int> bytes) => [
  ...ascii.encode(name),
  ..._int(bytes.length),
  ...bytes,
  if (bytes.length.isOdd) 0,
];

Uint8List _id3Chapters(List<RoomtoneMarker> chapters, int seconds) {
  if (chapters.isEmpty) return Uint8List(0);
  List<int> frame(String id, List<int> data) => [
    ...ascii.encode(id),
    ..._int(data.length, 4, Endian.big),
    0,
    0,
    ...data,
  ];
  final frames = BytesBuilder();
  for (var i = 0; i < chapters.length; i++) {
    final end = i + 1 < chapters.length ? chapters[i + 1].seconds : seconds;
    final title = chapters[i].label.codeUnits;
    frames.add(
      frame('CHAP', [
        ...ascii.encode('ch$i'),
        0,
        ..._int(chapters[i].seconds * 1000, 4, Endian.big),
        ..._int(end * 1000, 4, Endian.big),
        ...List.filled(8, 255),
        ...frame('TIT2', [
          1,
          0xff,
          0xfe,
          for (final unit in title) ..._int(unit, 2),
        ]),
      ]),
    );
  }
  if (chapters.length <= 255) {
    frames.add(
      frame('CTOC', [
        ...ascii.encode('toc'),
        0,
        3,
        chapters.length,
        for (var i = 0; i < chapters.length; i++) ...[
          ...ascii.encode('ch$i'),
          0,
        ],
      ]),
    );
  }
  final data = frames.takeBytes();
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    for (final shift in [21, 14, 7, 0]) (data.length >> shift) & 127,
    ...data,
  ]);
}
