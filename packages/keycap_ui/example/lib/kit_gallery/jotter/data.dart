/// Jotter's notes, folders and the writer they belong to: one believable
/// notebook whose counts agree with each other.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A folder of notes.
@immutable
class JotterFolder {
  /// A folder.
  const JotterFolder(this.id, this.name, this.icon);

  /// Its id.
  final String id;

  /// Its name.
  final String name;

  /// Its glyph.
  final IconData icon;
}

/// The writer's folders.
const jotterFolders = [
  JotterFolder('inbox', 'Inbox', LucideIcons.inbox),
  JotterFolder('work', 'Work', LucideIcons.briefcase),
  JotterFolder('garden', 'Garden', LucideIcons.sprout),
  JotterFolder('reading', 'Reading', LucideIcons.bookOpen),
  JotterFolder('kitchen', 'Kitchen', LucideIcons.cookingPot),
];

/// The folder [id].
JotterFolder jotterFolder(String id) =>
    jotterFolders.firstWhere((f) => f.id == id);

/// A note.
@immutable
class JotterNote {
  /// A note.
  const JotterNote({
    required this.id,
    required this.title,
    required this.body,
    required this.folder,
    required this.edited,
    required this.editedShort,
    this.pinned = false,
    this.draft = false,
    this.tags = const [],
  });

  /// Its id.
  final String id;

  /// Its title.
  final String title;

  /// Its words.
  final String body;

  /// The folder it is in.
  final String folder;

  /// When it was last edited, in words.
  final String edited;

  /// The same, short, for a row's end.
  final String editedShort;

  /// Whether it is pinned to Home.
  final bool pinned;

  /// Whether it is still a draft.
  final bool draft;

  /// Its tags.
  final List<String> tags;

  /// Its first line of words, for a row.
  String get excerpt =>
      body.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');

  /// How many words it has.
  int get words =>
      '$title $body'.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// A copy in [folder].
  JotterNote movedTo(String folder) => JotterNote(
    id: id,
    title: title,
    body: body,
    folder: folder,
    edited: 'Just now',
    editedShort: 'Now',
    pinned: pinned,
    draft: draft,
    tags: tags,
  );

  /// A copy with new words.
  JotterNote rewritten({String? title, String? body}) => JotterNote(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    folder: folder,
    edited: 'Just now',
    editedShort: 'Now',
    pinned: pinned,
    draft: draft,
    tags: tags,
  );
}

/// The writer.
const jotterWriter = (
  name: 'Mira Okafor',
  email: 'mira.okafor@example.com',
  plan: 'Personal, synced on 2 devices',
);

/// The notebook, newest first.
const jotterNotes = [
  JotterNote(
    id: 'talk',
    title: 'Talk for the allotment society',
    body:
        'Start with the frost of 3 November and what it took: the dahlias, '
        'the last of the beans, nothing in the cold frame.\n\n'
        'Then the case for a shared seed library. Twelve plots already swap '
        'by hand; a shelf in the shed and a sign-out sheet would make it a '
        'habit.\n\n'
        'Close on the spring work day: Saturday 14 March, ten until one.',
    folder: 'garden',
    edited: 'Edited 10 minutes ago',
    editedShort: '10 min',
    pinned: true,
    draft: true,
    tags: ['talks', 'allotment'],
  ),
  JotterNote(
    id: 'standup',
    title: 'Monday stand-up',
    body:
        'Search results ship behind the flag on Wednesday.\n'
        'Ines takes the export bug; Theo pairs on the sync retry.\n'
        'Ask about the design review moving to Thursday.',
    folder: 'work',
    edited: 'Edited today at 09:40',
    editedShort: '09:40',
    tags: ['meetings'],
  ),
  JotterNote(
    id: 'soup',
    title: 'Roast squash soup',
    body:
        'One squash, two onions, a thumb of ginger, a litre of stock.\n'
        'Roast the squash at 200° for 40 minutes before it goes in.\n'
        'Finish with lime and toasted seeds.',
    folder: 'kitchen',
    edited: 'Edited yesterday',
    editedShort: 'Yesterday',
    tags: ['recipes'],
  ),
  JotterNote(
    id: 'river',
    title: 'The River Notebook, chapters 4 to 6',
    body:
        'The map in chapter 4 is the one from the frontispiece, redrawn.\n'
        'Chapter 5 changes narrator without saying so; read it twice.\n'
        'Quote for the reading group: "a river is a long argument with a '
        'hill."',
    folder: 'reading',
    edited: 'Edited Monday',
    editedShort: 'Mon',
    tags: ['book club'],
  ),
  JotterNote(
    id: 'quotes',
    title: 'Ask for quotes on the shed roof',
    body:
        'Felt, not tiles. Three quotes before the end of the month.\n'
        'Measure again: 2.4 by 1.8 metres.',
    folder: 'inbox',
    edited: 'Edited 12 Nov',
    editedShort: '12 Nov',
  ),
  JotterNote(
    id: 'retro',
    title: 'Retro: the October release',
    body:
        'What went well: the beta group, the changelog, no rollback.\n'
        'What to change: freeze copy a week earlier; one owner for '
        'screenshots.',
    folder: 'work',
    edited: 'Edited 10 Nov',
    editedShort: '10 Nov',
    tags: ['meetings'],
  ),
  JotterNote(
    id: 'bulbs',
    title: 'Bulbs to order',
    body:
        'Thirty narcissus for the long border, twenty alliums, a tray of '
        'snowdrops in the green for February.',
    folder: 'garden',
    edited: 'Edited 7 Nov',
    editedShort: '7 Nov',
    tags: ['allotment'],
  ),
  JotterNote(
    id: 'bread',
    title: 'Weekend loaf',
    body:
        '500 g flour, 350 g water, 10 g salt, 100 g starter.\n'
        'Fold four times, an hour apart; shape and rest overnight.',
    folder: 'kitchen',
    edited: 'Edited 2 Nov',
    editedShort: '2 Nov',
    tags: ['recipes'],
  ),
];

/// How many of [notes] are in folder [id].
int jotterCount(List<JotterNote> notes, String id) =>
    notes.where((n) => n.folder == id).length;
