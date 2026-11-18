import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show UniqueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:studio_ui_example/gallery_pages.dart';
import 'package:studio_ui_example/kit_gallery/roomtone/data.dart';
import 'package:studio_ui_example/kit_gallery/roomtone/episode.dart';
import 'package:studio_ui_example/kit_gallery/roomtone/roomtone.dart';
import 'package:studio_ui_example/kit_gallery/roomtone/take_audio.dart';

void main() {
  setUpAll(studioLoadFonts);

  Future<void> open(
    WidgetTester t,
    RoomtoneApp app, {
    double width = 1440,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(app);
    await t.pumpAndSettle();
  }

  Finder transport(String tooltip) => find.byWidgetPredicate(
    (w) => w is StudioTransportKey && w.tooltip == tooltip,
  );
  Future<void> press(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder.first);
    await t.tap(finder.first);
    await t.pumpAndSettle();
  }

  test('every episode has named chapters within its running time', () {
    for (final episode in roomtoneEpisodes) {
      expect(episode.chapters.first.$1, 0);
      var previous = -1;
      for (final (time, title) in episode.chapters) {
        expect(time, greaterThan(previous));
        expect(time, lessThan(episode.minutes * 60));
        expect(title, isNotEmpty);
        previous = time;
      }
    }
  });

  test('export carries the selected format, duration, bitrate and markers', () {
    const markers = [
      (seconds: 1, label: 'Opening'),
      (seconds: 2, label: 'Second'),
    ];
    final wav = TakeAudio.render(4, (
      name: 'WAV',
      kbps: 192,
      chapters: true,
    ), markers);
    final wave = latin1.decode(wav.header);
    expect(wave.startsWith('RIFF'), isTrue);
    expect(wave, contains('cue '));
    expect(wave, contains('Opening'));
    expect(
      ByteData.sublistView(wav.header).getUint32(4, Endian.little) + 8,
      wav.header.length + wav.repeats * wav.block.length + wav.tail.length,
    );
    expect(wav.repeats * wav.block.length + wav.tail.length, 4 * 48000 * 2 * 3);
    expect(wav.block.any((b) => b != 0), isTrue);
    for (final kbps in [96, 128, 192, 256, 320]) {
      final mp3 = TakeAudio.render(3, (
        name: 'MP3',
        kbps: kbps,
        chapters: true,
      ), markers);
      final tag = latin1.decode(mp3.header);
      expect(tag, startsWith('ID3'));
      expect(tag, contains('CHAP'));
      expect(tag, contains('CTOC'));
      expect(mp3.block.take(2), [0xff, 0xfb]);
      expect(
        mp3.repeats * mp3.block.length + mp3.tail.length,
        3 * kbps * 1000 ~/ 8,
      );
    }
    expect(
      TakeAudio.render(2, (
        name: 'MP3',
        kbps: 128,
        chapters: false,
      ), markers).header,
      isEmpty,
    );
    expect(
      latin1.decode(
        TakeAudio.render(2, (
          name: 'WAV',
          kbps: 128,
          chapters: false,
        ), markers).header,
      ),
      isNot(contains('cue ')),
    );
  });

  testWidgets(
    'running player advances, pauses, and seeks to the selected chapter',
    (t) async {
      await open(t, const RoomtoneApp(initialPlace: RoomtonePlace.library));
      expect(find.text('26:53'), findsOneWidget);
      await t.tap(transport('Play'));
      await t.pump();
      await t.pump(const Duration(seconds: 4));
      expect(find.text('26:57'), findsOneWidget);
      await t.tap(transport('Pause'));
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 2));
      expect(find.text('26:57'), findsOneWidget);
      await press(t, find.text('Cello in a stairwell').first);
      await press(t, find.text('Chapters'));
      await press(t, find.text('Introductions'));
      expect(
        find.byWidgetPredicate(
          (w) => w is StudioReadout && w.semanticsLabel == 'Played 0:00',
        ),
        findsOneWidget,
      );
      expect(
        t
            .widget<StudioListTile>(
              find.ancestor(
                of: find.text('Introductions'),
                matching: find.byType(StudioListTile),
              ),
            )
            .selected,
        isTrue,
      );
      await press(t, find.text('Four floors of echo'));
      expect(
        find.byWidgetPredicate(
          (w) => w is StudioReadout && w.semanticsLabel == 'Played 2:44',
        ),
        findsOneWidget,
      );
      expect(
        t
            .widget<StudioListTile>(
              find.ancestor(
                of: find.text('Four floors of echo'),
                matching: find.byType(StudioListTile),
              ),
            )
            .selected,
        isTrue,
      );
      await press(t, find.text('2×'));
      await t.ensureVisible(transport('Play'));
      await t.tap(transport('Play'));
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      expect(
        find.byWidgetPredicate(
          (w) => w is StudioReadout && w.semanticsLabel == 'Played 2:48',
        ),
        findsOneWidget,
      );
      await t.tap(transport('Pause'));
      await t.pumpAndSettle();
    },
  );

  testWidgets('shared URL identifies the episode and opens it on a phone', (
    t,
  ) async {
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? written;
    binding.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        written = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => binding.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await open(
      t,
      const RoomtoneApp(
        initialPlace: RoomtonePlace.library,
        initialScene: RoomtoneScene.episode,
        initialEpisodeId: 'sr-7',
      ),
      width: 390,
    );
    expect(find.byType(RoomtoneEpisodePage), findsOneWidget);
    expect(find.text('Cello in a stairwell'), findsOneWidget);
    await press(
      t,
      find.byWidgetPredicate(
        (w) => w is StudioIconButton && w.tooltip == 'Share',
      ),
    );
    expect(
      Uri.parse(Uri.parse(written!).fragment).queryParameters['id'],
      'sr-7',
    );
    expect(find.text('Link copied'), findsOneWidget);
  });

  testWidgets(
    'scheduling agrees across the badge, date, and retry notification',
    (t) async {
      await open(
        t,
        const RoomtoneApp(
          initialPlace: RoomtonePlace.record,
          initialScene: RoomtoneScene.publish,
        ),
      );
      await press(t, find.text('On a day'));
      await press(t, find.text('Schedule episode'));
      await press(t, find.text('Try again'));
      expect(find.text('On air'), findsNothing);
      expect(find.text('Scheduled'), findsNWidgets(2));
      expect(find.textContaining('November 19, 2026'), findsWidgets);
      expect(find.textContaining('9:00'), findsWidgets);
    },
  );

  testWidgets('signed-out account stays hidden after changing destinations', (
    t,
  ) async {
    await open(t, const RoomtoneApp(initialPlace: RoomtonePlace.settings));
    await press(t, find.text('Sign out'));
    expect(find.text('Mara Lind'), findsNothing);
    expect(find.textContaining('mara@'), findsNothing);
    await press(t, find.text('Library'));
    expect(find.text('Sign in to Roomtone'), findsOneWidget);
    await press(t, find.text('Settings'));
    expect(find.text('Sign out'), findsNothing);
    await press(t, find.text('Use the Roomtone demo account'));
    expect(find.text('Mara Lind'), findsWidgets);
  });

  testWidgets('English descriptions end with their full stop in RTL', (
    t,
  ) async {
    final parts = [
      for (final page in galleryPages) (title: page.title, build: page.build),
    ];
    void endsRight(String text) {
      final words = t.renderObject<RenderParagraph>(find.text(text).first);
      expect(words.textDirection, TextDirection.ltr, reason: text);
      expect(words.textAlign, TextAlign.right, reason: text);
    }

    await open(
      t,
      RoomtoneApp(
        initialDirection: TextDirection.rtl,
        parts: parts,
        initialPart: galleryPages.indexWhere((p) => p.id == 'pickers'),
      ),
      width: 390,
    );
    endsRight(
      'A display window that opens a calendar under glass; the chosen day '
      'sits in a slot, today has a lamp.',
    );
    // A fresh app: the first one's state would keep it on the pickers page.
    await open(
      t,
      RoomtoneApp(
        key: UniqueKey(),
        initialDirection: TextDirection.rtl,
        parts: parts,
      ),
      width: 390,
    );
    endsRight('An app as a well-made piece of studio gear.');
  });
}
