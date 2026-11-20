/// What a render asks of Minimal's gallery, on the web: a browser asks
/// nothing through the environment, so every page demo reads left to
/// right.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// Which way a page demo reads: always left to right on the web.
TextDirection get templateDirection => TextDirection.ltr;

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Anchor createElement(String tag);
}

extension type _Anchor(JSObject _) implements JSObject {
  external set href(String url);
  external set download(String filename);
  external void click();
}

/// Starts a browser download during the user's export gesture.
Future<void> exportHabitsCsv(String csv, String filename) async {
  final link = _document.createElement('a');
  link
    ..download = filename
    ..href = Uri.dataFromString(
      csv,
      mimeType: 'text/csv',
      encoding: utf8,
    ).toString()
    ..click();
}
