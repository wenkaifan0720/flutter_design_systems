import 'dart:async';
import 'dart:js_interop';

import 'take_audio.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, _BlobOptions options);
}

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

@JS('URL.createObjectURL')
external String _objectUrl(_Blob data);
@JS('URL.revokeObjectURL')
external void _revoke(String url);
@JS('document.createElement')
external _Anchor _createElement(String tag);

extension type _Anchor._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
}

/// Starts a browser download while the export button's user gesture is active.
Future<String> saveTake(TakeAudio take) async {
  final block = take.block.toJS;
  final parts = <JSAny>[
    take.header.toJS,
    ...List.filled(take.repeats, block),
    take.tail.toJS,
  ];
  final url = _objectUrl(_Blob(parts.toJS, _BlobOptions(type: take.mime)));
  try {
    _createElement('a')
      ..href = url
      ..download = take.filename
      ..click();
  } finally {
    // Give the browser time to read the object after accepting the download.
    Timer(const Duration(seconds: 30), () => _revoke(url));
  }
  return 'Download started: ${take.filename}';
}
