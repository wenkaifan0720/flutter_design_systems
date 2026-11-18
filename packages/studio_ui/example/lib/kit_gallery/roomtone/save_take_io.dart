import 'dart:io';

import 'take_audio.dart';

/// Saves the sample to Downloads, or a private export directory on a device
/// where Downloads is unavailable. Returns its location to the recorder.
Future<String> saveTake(TakeAudio take) async {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  final candidates = [
    if (home != null) Directory('$home/Downloads'),
    if (home != null) Directory('$home/Documents'),
  ];
  Directory? parent;
  for (final dir in candidates) {
    if (await dir.exists()) {
      parent = dir;
      break;
    }
  }
  final folder = await (parent ?? Directory.systemTemp).createTemp('Roomtone-');
  final file = File('${folder.path}/${take.filename}');
  final output = file.openWrite();
  try {
    output.add(take.header);
    for (var i = 0; i < take.repeats; i++) {
      output.add(take.block);
      if (i % 10 == 9) await output.flush();
    }
    output.add(take.tail);
    await output.flush();
  } finally {
    await output.close();
  }
  return 'Saved to ${file.path}';
}
