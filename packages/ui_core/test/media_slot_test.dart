import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/host.dart';

/// A 1 × 1 PNG: real bytes for the engine's decoder.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// A bundle whose remote manifest maps `hero` to a URL.
class _ManifestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(
      utf8.encode('{"slots":{"hero":"https://media.example/hero.jpg"}}'),
    ),
  );
}

/// A bundle whose remote manifest maps `hero` and `dawn` to URLs.
class _TwoSlotBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(
      utf8.encode(
        '{"slots":{"hero":"https://media.example/hero.jpg",'
        '"dawn":"https://media.example/dawn.jpg"}}',
      ),
    ),
  );
}

/// A bundle carrying `hero` as a bundled photo, whose remote manifest is
/// still loading until the test completes it.
class _OfflineBundle extends CachingAssetBundle {
  final manifest = Completer<String>();

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == MediaSlot.remoteManifest
      ? manifest.future
      : super.loadString(key, cache: cache);

  @override
  Future<ByteData> load(String key) => key == MediaSlot.assetPath('hero')
      ? Future.value(ByteData.sublistView(_png))
      : rootBundle.load(key);
}

/// A bundle with no remote manifest until [publish] adds one.
class _LateManifestBundle extends CachingAssetBundle {
  String? published;
  int reads = 0;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads += 1;
    final value = published;
    if (value == null) throw FlutterError('no $key');
    return value;
  }

  @override
  Future<ByteData> load(String key) => throw FlutterError('no $key');
}

class _Client extends Fake implements HttpClient {
  _Client(this.respond);
  final Future<HttpClientResponse> Function() respond;
  int requests = 0;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests += 1;
    return _Request(respond);
  }
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.respond);
  final Future<HttpClientResponse> Function() respond;
  @override
  Future<HttpClientResponse> close() => respond();
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, [this.bytes = const []]);
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

Widget _app(
  AssetBundle bundle, {
  String slotId = 'hero',
  AlignmentGeometry alignment = Alignment.center,
}) => DefaultAssetBundle(
  bundle: bundle,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 100,
      height: 100,
      child: MediaSlotImage(
        slotId: slotId,
        alignment: alignment,
        fallback: const Text('placeholder'),
      ),
    ),
  ),
);

/// Pumps the fake clock and lets the engine's decoder run outside it until
/// [done] holds or 50 rounds pass.
Future<void> _settleImages(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  await tester.pump();
}

bool _decoded(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .any((image) => image.image != null);

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
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('a slot names its bundled photo and the remote manifest', () {
    expect(MediaSlot.assetPath('face-hanna'), 'assets/media/face-hanna.jpg');
    expect(MediaSlot.remoteManifest, 'assets/media/remote.json');
  });

  test(
    'the remote map reads once per bundle; a miss is not remembered',
    () async {
      final bundle = _LateManifestBundle();
      expect(await MediaSlot.remoteUrls(bundle), isEmpty);
      bundle.published = '{"slots":{"hero":"https://media.example/hero.jpg"}}';
      expect(await MediaSlot.remoteUrls(bundle), <String, String>{
        'hero': 'https://media.example/hero.jpg',
      });
      expect(await MediaSlot.remoteUrls(bundle), hasLength(1));
      expect(bundle.reads, 2);
    },
  );

  _mediaTest('bundled photos render while the optional manifest is pending', (
    tester,
  ) async {
    final bundle = _OfflineBundle();
    await tester.pumpWidget(_app(bundle));
    // Pending its first frame, the photo shows the placeholder.
    expect(find.text('placeholder'), findsOneWidget);
    await _settleImages(tester, () => _decoded(tester));
    expect(bundle.manifest.isCompleted, isFalse);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.text('placeholder'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    bundle.manifest.complete('{"slots":{}}');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  _mediaTest('the picture sits where alignment says', (tester) async {
    final bundle = _OfflineBundle();
    await tester.pumpWidget(_app(bundle, alignment: Alignment.bottomCenter));
    await _settleImages(tester, () => _decoded(tester));
    expect(
      tester.widget<RawImage>(find.byType(RawImage)).alignment,
      Alignment.bottomCenter,
    );
    await tester.pumpWidget(const SizedBox());
    bundle.manifest.complete('{"slots":{}}');
    await tester.pump();
  });

  _mediaTest('a slot with no bundled photo keeps its placeholder', (
    tester,
  ) async {
    final bundle = _OfflineBundle();
    await tester.pumpWidget(_app(bundle, slotId: 'missing'));
    await _settleImages(tester, () => false);
    expect(find.text('placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  _mediaTest(
    'a late image replaces the placeholder without rebuilding the app',
    (tester) async {
      final response = Completer<HttpClientResponse>();
      final client = _Client(() => response.future);
      debugNetworkImageHttpClientProvider = () => client;
      await tester.pumpWidget(_app(_ManifestBundle()));
      await tester.pump();
      expect(find.text('placeholder'), findsOneWidget);
      response.complete(_Response(200, _png));
      // Network completion belongs to the fake clock; the engine's PNG
      // decoder completes outside it. Pump both without waiting for a
      // fake-zone future from runAsync (which would prevent that future's
      // continuation running).
      await _settleImages(
        tester,
        () => find.text('placeholder').evaluate().isEmpty,
      );
      expect(find.text('placeholder'), findsNothing);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(client.requests, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  _mediaTest(
    'a pending image paints its placeholder without waiting for the request',
    (tester) async {
      final response = Completer<HttpClientResponse>();
      final client = _Client(() => response.future);
      debugNetworkImageHttpClientProvider = () => client;
      await tester.pumpWidget(_app(_ManifestBundle()));
      await tester.pump();
      expect(find.text('placeholder'), findsOneWidget);
      expect(client.requests, 1);
      await tester.pumpWidget(const SizedBox());
      response.complete(_Response(404));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  _mediaTest('202 retries while mounted and disposal cancels future polling', (
    tester,
  ) async {
    final client = _Client(() async => _Response(202));
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_app(_ManifestBundle()));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 1);
    expect(find.text('placeholder'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
    expect(client.requests, 2);
    expect(tester.takeException(), isNull);
  });

  _mediaTest('a new slot drops the old slot\'s retry and starts its own', (
    tester,
  ) async {
    final client = _Client(() async => _Response(202));
    debugNetworkImageHttpClientProvider = () => client;
    final bundle = _TwoSlotBundle();
    await tester.pumpWidget(_app(bundle));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 1);
    // A second into hero's two-second wait, the slot changes.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_app(bundle, slotId: 'dawn'));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 2);
    // Hero's retry would have fired by now; it was cancelled.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(client.requests, 2);
    // Dawn's own first retry, two seconds after its start.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    expect(client.requests, 3);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  _mediaTest('a terminal missing image keeps its placeholder without polling', (
    tester,
  ) async {
    final client = _Client(() async => _Response(404));
    debugNetworkImageHttpClientProvider = () => client;
    await tester.pumpWidget(_app(_ManifestBundle()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(client.requests, 1);
    expect(find.text('placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
