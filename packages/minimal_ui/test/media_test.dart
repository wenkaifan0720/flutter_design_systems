/// A declared media slot's photograph: the bundled asset first, else the
/// remote link; a sheen while the linked photo is still being made, the
/// photo once it lands, the plain placeholder once it failed — and the same
/// slot as an ImageProvider (MinimalMediaSource.image).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// A 1 × 1 PNG: real bytes for the engine's decoder.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

const String _url = 'https://image.example/v1/photos/job/hero.jpg';

/// A bundle carrying exactly [assets] (each a 1 × 1 PNG) and, when given,
/// a remote manifest mapping slots to links.
class _Bundle extends CachingAssetBundle {
  _Bundle({this.assets = const {}, this.remote});

  final Set<String> assets;
  final Map<String, String>? remote;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{
        for (final asset in assets)
          asset: <Object>[
            <String, Object>{'asset': asset},
          ],
      })!;
    }
    if (key == 'assets/media/remote.json' && remote != null) {
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode({'slots': remote}))),
      );
    }
    if (assets.contains(key)) return ByteData.sublistView(_png);
    throw FlutterError('Unable to load asset: "$key".');
  }
}

/// Answers every request with the next of [answers] (the last repeats).
class _Client extends Fake implements HttpClient {
  _Client(this.answers);

  final List<int> answers;
  int requests = 0;

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final status = answers[requests.clamp(0, answers.length - 1)];
    requests += 1;
    return _Request(status);
  }
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.status);

  final int status;

  @override
  HttpHeaders get headers => _Headers();

  @override
  Future<HttpClientResponse> close() async =>
      _Response(status, status == 200 ? _png : const []);
}

class _Headers extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this.bytes);

  @override
  final int statusCode;
  final List<int> bytes;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(
  AssetBundle bundle,
  Widget child, {
  bool disableAnimations = false,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: navigator!,
    ),
  ),
  home: DefaultAssetBundle(
    bundle: bundle,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 200, height: 120, child: child),
    ),
  ),
);

const Widget _slot = MinimalMediaImage(
  slotId: 'hero',
  fallback: Text('placeholder'),
);

/// The pending sheen over the placeholder.
final Finder _sheen = find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_SheenPainter',
);

bool _decoded(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .any((image) => image.image != null);

/// Pumps the fake clock and lets the engine's decoder and the manifest
/// reads run outside it, until [done] holds or 50 rounds pass.
Future<void> _settle(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pump();
}

/// Lets the bundle's manifest reads land.
Future<void> _read(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

/// Shows [provider] the way a kit's picture does, with its own placeholder.
Widget _picture(ImageProvider provider) => Image(
  image: provider,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stack) => const Text('failed'),
);

/// A widget test that leaves the network image client as it found it.
void _mediaTest(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}

void main() {
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    MinimalMediaSource.reference = null;
  });

  _mediaTest('a reference reader names a slot, draws an image, or neither', (
    tester,
  ) async {
    final bundle = _Bundle(assets: {'assets/media/hero.jpg'});
    MinimalMediaSource.reference = (context, value) => switch (value) {
      'ref:hero' => (slot: 'hero', image: null),
      'ref:drawn' => (
        slot: null,
        image: const AssetImage('assets/media/hero.jpg'),
      ),
      'ref:none' => (slot: null, image: null),
      _ => null,
    };
    Widget shown(String value) =>
        MinimalMediaImage(slotId: value, fallback: const Text('placeholder'));
    // A value the reader takes for a slot draws that slot's photo.
    await tester.pumpWidget(_host(bundle, shown('ref:hero')));
    await _settle(tester, () => _decoded(tester));
    expect(_decoded(tester), isTrue);
    // An image the reader answers with draws in its place.
    await tester.pumpWidget(_host(bundle, shown('ref:drawn')));
    await _settle(tester, () => _decoded(tester));
    expect(_decoded(tester), isTrue);
    expect(find.text('placeholder'), findsNothing);
    // An answer with neither draws the placeholder; no answer, the value as a slot id.
    await tester.pumpWidget(_host(bundle, shown('ref:none')));
    await tester.pump();
    expect(find.text('placeholder'), findsOneWidget);
    await tester.pumpWidget(_host(bundle, shown('missing')));
    await _settle(tester, () => find.text('placeholder').evaluate().isNotEmpty);
    expect(find.text('placeholder'), findsOneWidget);
    await tester.pumpWidget(_host(bundle, const SizedBox()));
  });

  _mediaTest('a bundled photo wins over a remote link, with no request', (
    tester,
  ) async {
    final client = _Client([200]);
    debugNetworkImageHttpClientProvider = () => client;
    final bundle = _Bundle(
      assets: {'assets/media/hero.jpg'},
      remote: {'hero': _url},
    );
    await tester.pumpWidget(_host(bundle, _slot));
    await _settle(tester, () => _decoded(tester));
    expect(_decoded(tester), isTrue);
    expect(find.text('placeholder'), findsNothing);
    expect(_sheen, findsNothing);
    expect(client.requests, 0);
    // A bundled photo never shimmers, even before its first frame.
    await tester.pumpWidget(_host(bundle, const SizedBox()));
    PaintingBinding.instance.imageCache.clear();
    await tester.pumpWidget(_host(bundle, _slot));
    expect(_sheen, findsNothing);
    await tester.pumpWidget(_host(bundle, const SizedBox()));
  });

  _mediaTest('a photo still being made shimmers, then appears', (tester) async {
    final client = _Client([202, 202, 200]);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_host(_Bundle(remote: {'hero': _url}), _slot));
    await _read(tester);
    expect(client.requests, 1);
    expect(find.text('placeholder'), findsOneWidget);
    expect(_sheen, findsOneWidget);
    // The sheen moves.
    final before = tester.widget<CustomPaint>(_sheen).painter as dynamic;
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester.widget<CustomPaint>(_sheen).painter as dynamic;
    expect(after.progress, isNot(before.progress));
    // Asked again after 2 s, and again: the third answer is the photo.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    expect(client.requests, 2);
    expect(_sheen, findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await _settle(tester, () => _decoded(tester));
    expect(client.requests, 3);
    expect(_decoded(tester), isTrue);
    expect(find.text('placeholder'), findsNothing);
    expect(_sheen, findsNothing);
    await tester.pumpWidget(_host(_Bundle(), const SizedBox()));
    expect(tester.takeException(), isNull);
  });

  _mediaTest('the sheen is finite sweeps with a still rest between', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () => _Client([202]);
    await tester.pumpWidget(_host(_Bundle(remote: {'hero': _url}), _slot));
    await _read(tester);
    double progress() =>
        (tester.widget<CustomPaint>(_sheen).painter as dynamic).progress
            as double;
    // One sweep: it ends with the band off the box.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(progress(), 1.0);
    // The rest: no frame asked for, so a capture settles here.
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(progress(), 1.0);
    // Then the next sweep.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(progress(), inExclusiveRange(0.0, 1.0));
    await tester.pumpWidget(_host(_Bundle(), const SizedBox()));
  });

  _mediaTest('a failed photo (404) shows the plain placeholder and stops', (
    tester,
  ) async {
    final client = _Client([202, 404]);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_host(_Bundle(remote: {'hero': _url}), _slot));
    await _read(tester);
    expect(_sheen, findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 2);
    expect(find.text('placeholder'), findsOneWidget);
    expect(_sheen, findsNothing);
    await tester.pump(const Duration(minutes: 1));
    expect(client.requests, 2);
    expect(tester.takeException(), isNull);
  });

  _mediaTest('a photo that never lands gives up after 15 minutes', (
    tester,
  ) async {
    final client = _Client([202]);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(
      _host(_Bundle(remote: {'hero': _url}), _slot, disableAnimations: true),
    );
    await _read(tester);
    for (var i = 0; i < 460 && _sheen.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    }
    expect(_sheen, findsNothing);
    expect(find.text('placeholder'), findsOneWidget);
    expect(client.requests, 451);
    expect(tester.takeException(), isNull);
  });

  _mediaTest('leaving the page stops the asking', (tester) async {
    final client = _Client([202]);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_host(_Bundle(remote: {'hero': _url}), _slot));
    await _read(tester);
    expect(client.requests, 1);
    await tester.pumpWidget(_host(_Bundle(), const SizedBox()));
    await tester.pump(const Duration(minutes: 1));
    expect(client.requests, 1);
    expect(tester.takeException(), isNull);
  });

  _mediaTest('under reduced motion the sheen stands still', (tester) async {
    debugNetworkImageHttpClientProvider = () => _Client([202]);
    await tester.pumpWidget(
      _host(_Bundle(remote: {'hero': _url}), _slot, disableAnimations: true),
    );
    await _read(tester);
    expect(_sheen, findsOneWidget);
    final before = tester.widget<CustomPaint>(_sheen).painter as dynamic;
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester.widget<CustomPaint>(_sheen).painter as dynamic;
    expect(after.progress, before.progress);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(_host(_Bundle(), const SizedBox()));
  });

  _mediaTest('a slot with neither a photo nor a link stays plain', (
    tester,
  ) async {
    final client = _Client([200]);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_host(_Bundle(), _slot));
    await _read(tester);
    expect(find.text('placeholder'), findsOneWidget);
    expect(_sheen, findsNothing);
    expect(client.requests, 0);
    expect(tester.takeException(), isNull);
  });

  group('MinimalMediaSource.image', () {
    test('names its slot and compares by it', () {
      expect(
        MinimalMediaSource.image('hero'),
        MinimalMediaSource.image('hero'),
      );
      expect(
        MinimalMediaSource.image('hero'),
        isNot(MinimalMediaSource.image('dish')),
      );
    });

    _mediaTest('a bundled photo', (tester) async {
      await tester.pumpWidget(
        _host(
          _Bundle(assets: {'assets/media/hero.jpg'}, remote: {'hero': _url}),
          _picture(MinimalMediaSource.image('hero')),
        ),
      );
      await _settle(tester, () => _decoded(tester));
      expect(_decoded(tester), isTrue);
    });

    _mediaTest('a linked photo lands after being made', (tester) async {
      final client = _Client([202, 200]);
      debugNetworkImageHttpClientProvider = () => client;
      await tester.pumpWidget(
        _host(
          _Bundle(remote: {'hero': _url}),
          _picture(MinimalMediaSource.image('hero')),
        ),
      );
      await _read(tester);
      expect(client.requests, 1);
      expect(_decoded(tester), isFalse);
      expect(find.text('failed'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester, () => _decoded(tester));
      expect(client.requests, 2);
      expect(_decoded(tester), isTrue);
      await tester.pumpWidget(_host(_Bundle(), const SizedBox()));
    });

    _mediaTest('a failed link and a missing slot error for the taker', (
      tester,
    ) async {
      debugNetworkImageHttpClientProvider = () => _Client([404]);
      await tester.pumpWidget(
        _host(
          _Bundle(remote: {'hero': _url}),
          Column(
            children: [
              Expanded(child: _picture(MinimalMediaSource.image('hero'))),
              Expanded(child: _picture(MinimalMediaSource.image('missing'))),
            ],
          ),
        ),
      );
      await _read(tester);
      await tester.pump();
      expect(find.text('failed'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
