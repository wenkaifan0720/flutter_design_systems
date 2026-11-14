/// Media: the image over the design kit's media slot (Cody v2's media
/// tests, ported onto ExpressiveMedia: a bundled photo while the manifest is
/// pending, a late image, a pending placeholder, 202 retries, a terminal
/// miss), its corner and library-shape masks (a hero moment), and the
/// avatar's kinds, sizes, tones and semantics.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/list_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// A 1×1 PNG: a picture the engine decodes.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _ManifestBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(
    Uint8List.fromList(
      utf8.encode('{"slots":{"hero":"https://media.example/hero.jpg"}}'),
    ),
  );
}

class _OfflineBundle extends CachingAssetBundle {
  final manifest = Completer<String>();
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'assets/media/remote.json'
      ? manifest.future
      : super.loadString(key, cache: cache);
  @override
  Future<ByteData> load(String key) => key == 'assets/media/hero.jpg'
      ? Future.value(ByteData.sublistView(_png))
      : rootBundle.load(key);
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

/// [child] themed, in a text direction.
Widget _themed(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ExpressiveTheme(data: _theme, child: child),
);

Widget _app(AssetBundle bundle) => DefaultAssetBundle(
  bundle: bundle,
  child: _themed(
    const Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: ExpressiveMedia(
          slotId: 'hero',
          placeholder: Text('placeholder'),
        ),
      ),
    ),
  ),
);

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

  testWidgets(
    'a face pile reserves space for its remaining count at narrow widths',
    (tester) async {
      await tester.pumpWidget(
        _themed(
          const Center(
            child: SizedBox(
              width: 120,
              child: ExpressiveAvatarGroup(
                faces: [
                  ExpressiveFace('Ada Kim'),
                  ExpressiveFace('Noor Ali'),
                  ExpressiveFace('Sam Reed'),
                  ExpressiveFace('Jo Wu'),
                ],
                total: 9,
              ),
            ),
          ),
        ),
      );
      final count = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('+'),
      );
      expect(count, findsOneWidget);
      final pile = tester.getRect(find.byType(ExpressiveAvatarGroup));
      expect(pile.width, lessThanOrEqualTo(120));
      expect(pile.contains(tester.getRect(count).center), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('alignment reaches the slot picture', (tester) async {
    await tester.pumpWidget(
      _themed(
        const Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: ExpressiveMedia(
              slotId: 'missing',
              aspectRatio: 4 / 3,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<MediaSlotImage>(find.byType(MediaSlotImage)).alignment,
      Alignment.bottomCenter,
    );
  });

  group('Cody v2 media tests, on ExpressiveMedia', () {
    _mediaTest('bundled photos render while the optional manifest is pending', (
      tester,
    ) async {
      final bundle = _OfflineBundle();
      await tester.pumpWidget(_app(bundle));
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        final images = tester.widgetList<RawImage>(find.byType(RawImage));
        if (images.any((image) => image.image != null)) break;
      }
      await tester.pump();
      expect(bundle.manifest.isCompleted, isFalse);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(find.text('placeholder'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      bundle.manifest.complete('{"slots":{}}');
      await tester.pump();
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
        for (
          var i = 0;
          i < 50 && find.text('placeholder').evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pump();
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

    _mediaTest(
      '202 retries while mounted and disposal cancels future polling',
      (tester) async {
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
      },
    );

    _mediaTest(
      'a terminal missing image keeps its placeholder without polling',
      (tester) async {
        final client = _Client(() async => _Response(404));
        debugNetworkImageHttpClientProvider = () => client;
        await tester.pumpWidget(_app(_ManifestBundle()));
        await tester.pump();
        await tester.pump(const Duration(seconds: 30));
        expect(client.requests, 1);
        expect(find.text('placeholder'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ExpressiveMedia', () {
    testWidgets(
      'takes its ratio from the width, and is silent unless labelled',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _themed(
            const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: Column(
                  children: <Widget>[
                    ExpressiveMedia(
                      key: ValueKey<String>('wide'),
                      slotId: 'wide',
                      aspectRatio: 16 / 9,
                      corner: ExpressiveCorner.extraLarge,
                      semanticLabel: 'The harbour',
                    ),
                    ExpressiveMedia(
                      key: ValueKey<String>('free'),
                      slotId: 'free',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey<String>('wide'))),
          const Size(320, 180),
        );
        // Unbounded height: square.
        expect(
          tester.getSize(find.byKey(const ValueKey<String>('free'))),
          const Size(320, 320),
        );
        expect(find.bySemanticsLabel('The harbour'), findsOneWidget);
        expect(find.byType(ExpressiveImagePlaceholder), findsNWidgets(2));
        semantics.dispose();
      },
    );

    testWidgets('masks by the corner scale', (tester) async {
      await tester.pumpWidget(
        _themed(
          const Center(
            child: SizedBox(
              width: 200,
              child: ExpressiveMedia(
                slotId: 'x',
                aspectRatio: 1,
                corner: ExpressiveCorner.extraLarge,
              ),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipPath>(find.byType(ClipPath));
      final border = (clip.clipper! as ShapeBorderClipper).shape;
      expect(border, _theme.shapes.corner(ExpressiveCorner.extraLarge));
    });

    testWidgets('a shaped image is a hero moment', (tester) async {
      await tester.pumpWidget(
        _themed(
          const Center(
            child: SizedBox(
              width: 96,
              child: ExpressiveMedia.shaped(
                slotId: 'x',
                shape: ExpressiveMaterialShape.cookie9Sided,
              ),
            ),
          ),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('outside an ExpressiveHeroMoment'),
      );

      await tester.pumpWidget(
        _themed(
          const Center(
            child: ExpressiveHeroMoment(
              label: 'cover',
              child: SizedBox(
                width: 96,
                child: ExpressiveMedia.shaped(
                  slotId: 'x',
                  shape: ExpressiveMaterialShape.cookie9Sided,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final clip = tester.widget<ClipPath>(find.byType(ClipPath));
      expect(
        (clip.clipper! as ShapeBorderClipper).shape,
        const ExpressiveMaterialShapeBorder(
          ExpressiveMaterialShape.cookie9Sided,
        ),
      );
      expect(tester.getSize(find.byType(ExpressiveMedia)), const Size(96, 96));
    });

    test('a placeholder tone is stable per slot', () {
      for (final seed in <String>['hero', 'face-mara', 'album-tide']) {
        expect(ExpressiveMediaTone.of(seed), ExpressiveMediaTone.of(seed));
      }
      final tones = <ExpressiveMediaTone>{
        for (var i = 0; i < 30; i++) ExpressiveMediaTone.of('slot-$i'),
      };
      expect(tones, ExpressiveMediaTone.values.toSet());
    });
  });

  group('ExpressiveAvatar', () {
    test('initials are the first letters of the first two words', () {
      expect(ExpressiveAvatar.initialsOf('Mara Quist'), 'MQ');
      expect(ExpressiveAvatar.initialsOf('  ada  lovelace byron '), 'AL');
      expect(ExpressiveAvatar.initialsOf('Cher'), 'C');
      expect(ExpressiveAvatar.initialsOf(''), '');
    });

    testWidgets('m is Material\'s list avatar: 40dp primaryContainer circle, '
        'initials in titleMedium onPrimaryContainer', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _themed(
          const Center(
            child: ExpressiveAvatar(
              name: 'Mara Quist',
              tone: ExpressiveMediaTone.primary,
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ExpressiveAvatar)),
        Size.square(ListTokens.itemLeadingAvatarSize),
      );
      expect(ListTokens.itemLeadingAvatarSize, 40);
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(ExpressiveAvatar),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, _theme.colors.primaryContainer);
      final text = tester.widget<Text>(find.text('MQ'));
      expect(text.style!.color, _theme.colors.onPrimaryContainer);
      expect(text.style!.fontSize, _theme.type.titleMedium.fontSize);
      // Material's full corner on a square, held as a circle: a person
      // stays round in every corner family.
      final clip = tester.widget<ClipPath>(find.byType(ClipPath));
      expect((clip.clipper! as ShapeBorderClipper).shape, const CircleBorder());
      expect(find.bySemanticsLabel('Mara Quist'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('sizes, icon and empty-name kinds, and the pending photo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _themed(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final size in ExpressiveAvatarSize.values)
                  ExpressiveAvatar(
                    key: ValueKey<ExpressiveAvatarSize>(size),
                    name: 'Mara Quist',
                    size: size,
                  ),
                const ExpressiveAvatar(
                  name: 'Book club',
                  icon: ExpressiveSymbols.group,
                ),
                const ExpressiveAvatar(name: ''),
                const ExpressiveAvatar(name: 'Theo Park', slotId: 'face-theo'),
              ],
            ),
          ),
        ),
      );
      for (final (size, side) in <(ExpressiveAvatarSize, double)>[
        (ExpressiveAvatarSize.extraSmall, 24),
        (ExpressiveAvatarSize.small, 32),
        (ExpressiveAvatarSize.medium, 40),
        (ExpressiveAvatarSize.large, 56),
        (ExpressiveAvatarSize.extraLarge, 96),
      ]) {
        expect(
          tester.getSize(find.byKey(ValueKey<ExpressiveAvatarSize>(size))),
          Size.square(side),
        );
      }
      expect(find.byIcon(ExpressiveSymbols.group), findsOneWidget);
      expect(find.byIcon(ExpressiveSymbols.person), findsOneWidget);
      // The photo is pending (no bundled picture): the initials stand in.
      expect(find.text('TP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a row of compact avatars prints every name\'s initials at one '
        'size', (tester) async {
      // Compact density draws the 32dp avatar at 24dp, under its 14dp type:
      // the initials scale down, all by the scale the widest pair needs, so
      // a wide pair does not print smaller than its neighbours.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ExpressiveTheme(
            data: _theme.copyWith(density: ExpressiveDensity.compact),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final who in const ['Maya Okafor', 'Sam Reyes', 'You'])
                    ExpressiveAvatar(
                      name: who,
                      size: ExpressiveAvatarSize.small,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(ExpressiveAvatar).first),
        const Size.square(24),
      );
      final heights = [
        for (final initials in ['MO', 'SR', 'Y'])
          tester.getRect(find.text(initials)).height,
      ];
      expect(heights[0], lessThan(tester.getSize(find.text('MO')).height));
      expect(heights[1], moreOrLessEquals(heights[0], epsilon: 0.01));
      expect(heights[2], moreOrLessEquals(heights[0], epsilon: 0.01));
    });

    testWidgets('a shaped avatar is a hero moment', (tester) async {
      await tester.pumpWidget(
        _themed(
          const Center(
            child: ExpressiveAvatar(
              name: 'Ines Okafor',
              shape: ExpressiveMaterialShape.cookie12Sided,
            ),
          ),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('outside an ExpressiveHeroMoment'),
      );
    });
  });
}
