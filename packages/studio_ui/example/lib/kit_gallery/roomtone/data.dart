/// Roomtone's sample library: a listener's shows and episodes, and the take
/// on the recorder. Every name is invented.
library;

/// A show the listener follows.
class RoomtoneShow {
  /// A show named [name] by [host].
  const RoomtoneShow({
    required this.id,
    required this.name,
    required this.host,
    required this.blurb,
  });

  /// Its id.
  final String id;

  /// Its name.
  final String name;

  /// Who makes it.
  final String host;

  /// What it is, in a line.
  final String blurb;
}

/// An episode of a show.
class RoomtoneEpisode {
  /// An episode of [show].
  const RoomtoneEpisode({
    required this.id,
    required this.show,
    required this.title,
    required this.published,
    required this.minutes,
    this.progress = 0,
    this.downloaded = false,
    this.notes = '',
    this.chapters = const [(0, 'Introductions')],
  });

  /// Its id.
  final String id;

  /// Its show.
  final RoomtoneShow show;

  /// Its title.
  final String title;

  /// When it came out, as the list says it.
  final String published;

  /// How long it runs.
  final int minutes;

  /// How far the listener got, 0 to 1.
  final double progress;

  /// Whether it is on the device.
  final bool downloaded;

  /// Its show notes.
  final String notes;

  /// Chapter start times in seconds and their titles, in playback order.
  final List<(int, String)> chapters;

  /// Whether it has been started and not finished.
  bool get started => progress > 0 && progress < 1;

  /// Whether it has not been played at all.
  bool get unplayed => progress == 0;

  /// Its length as a readout says it.
  String get length => roomtoneClock(minutes * 60);

  /// The minutes left of it (RoomtoneWords.timeLeft says them).
  int get minutesLeft => (minutes * (1 - progress)).round();
}

/// [value] with a true minus sign before it when it is below zero.
String roomtoneSigned(int value) => value < 0 ? '\u2212${-value}' : '$value';

/// [seconds] as a readout shows them: 1:04:09, or 4:09 under an hour.
String roomtoneClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// The shows.
const roomtoneShows = [
  RoomtoneShow(
    id: 'low-ceiling',
    name: 'Low Ceiling',
    host: 'Ines Okafor',
    blurb: 'Long conversations with people who make things by hand.',
  ),
  RoomtoneShow(
    id: 'field-notes',
    name: 'Field Notes',
    host: 'Tomas Reyna',
    blurb: 'Sound walks through one place, recorded at dawn.',
  ),
  RoomtoneShow(
    id: 'long-take',
    name: 'The Long Take',
    host: 'Priya Venn and Jo Haldane',
    blurb: 'Two friends, one film a week, no spoilers in the first half.',
  ),
  RoomtoneShow(
    id: 'small-rooms',
    name: 'Small Rooms',
    host: 'Ada Kestrel',
    blurb: 'Musicians play one song in a room no bigger than a kitchen.',
  ),
];

RoomtoneShow _show(String id) => roomtoneShows.firstWhere((s) => s.id == id);

/// The episodes, newest first.
final roomtoneEpisodes = [
  RoomtoneEpisode(
    id: 'lc-41',
    chapters: [
      (0, 'Introductions'),
      (312, 'The attic'),
      (1420, 'Thread and patience'),
      (2890, 'The drawer of offcuts'),
    ],
    show: _show('low-ceiling'),
    title: 'The bookbinder who keeps every offcut',
    published: 'Today',
    minutes: 64,
    progress: 0.42,
    downloaded: true,
    notes:
        'Marguerite has bound books in the same attic for thirty years. We '
        'talk about thread, patience, and the drawer of offcuts she has never '
        'once emptied.',
  ),
  RoomtoneEpisode(
    id: 'fn-18',
    chapters: [
      (0, 'Introductions'),
      (265, 'The north quay'),
      (774, 'The first engine'),
    ],
    show: _show('field-notes'),
    title: 'A harbour before the boats go out',
    published: 'Yesterday',
    minutes: 23,
    downloaded: true,
    notes:
        'Ropes, gulls and an engine that will not start. Recorded on the '
        'north quay between five and six in the morning.',
  ),
  RoomtoneEpisode(
    id: 'lt-102',
    chapters: [
      (0, 'Introductions'),
      (560, 'Family scenes'),
      (1675, 'After the interval'),
    ],
    show: _show('long-take'),
    title: 'A quiet film about a loud family',
    published: '12 Nov',
    minutes: 51,
    progress: 0.08,
    notes:
        'Priya loved it. Jo wanted twenty minutes fewer. The second half has '
        'spoilers: we say when.',
  ),
  RoomtoneEpisode(
    id: 'sr-7',
    chapters: [
      (0, 'Introductions'),
      (164, 'Four floors of echo'),
      (458, 'The stairwell take'),
      (818, 'Last notes'),
    ],
    show: _show('small-rooms'),
    title: 'Cello in a stairwell',
    published: '10 Nov',
    minutes: 17,
    progress: 1,
    downloaded: true,
    notes: 'One take, one microphone, four floors of echo.',
  ),
  RoomtoneEpisode(
    id: 'lc-40',
    chapters: [
      (0, 'Introductions'),
      (410, 'Setting the stone'),
      (1450, 'The Saturday queue'),
    ],
    show: _show('low-ceiling'),
    title: 'Sharpening knives for a whole street',
    published: '8 Nov',
    minutes: 58,
    notes:
        'Every Saturday Bram sets up a stone on a folding table and the '
        'street brings him its knives.',
  ),
  RoomtoneEpisode(
    id: 'fn-17',
    chapters: [
      (0, 'Introductions'),
      (242, 'The passing shower'),
      (793, 'When the rain stops'),
    ],
    show: _show('field-notes'),
    title: 'Rain on a tin roof, then none',
    published: '5 Nov',
    minutes: 19,
    progress: 0.65,
    notes: 'A shed at the end of an allotment, through one passing shower.',
  ),
  RoomtoneEpisode(
    id: 'lt-101',
    chapters: [
      (0, 'Introductions'),
      (425, 'A chase in silence'),
      (1753, 'Checking our phones'),
    ],
    show: _show('long-take'),
    title: 'The film with no music at all',
    published: '5 Nov',
    minutes: 47,
    downloaded: true,
    notes: 'What silence does to a chase, and why we both checked our phones.',
  ),
];

/// The episode the listener is in the middle of.
RoomtoneEpisode get roomtoneNowPlaying => roomtoneEpisodes.first;

/// The listener.
const roomtoneListener = (name: 'Mara Lind', email: 'mara@roomtone.example');

/// An address set to break after its @ rather than mid-word, when large
/// text leaves it no room on one line.
String roomtoneBreakable(String address) =>
    address.replaceFirst('@', '@\u200B');

/// A marker on the take being recorded.
typedef RoomtoneMarker = ({int seconds, String label});

/// The take on the recorder: its markers so far.
const roomtoneMarkers = <RoomtoneMarker>[
  (seconds: 12, label: 'Cold open'),
  (seconds: 194, label: 'Guest arrives'),
  (seconds: 431, label: 'Retake the question'),
];
