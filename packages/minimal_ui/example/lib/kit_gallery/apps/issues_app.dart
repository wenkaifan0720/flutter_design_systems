/// The package example's Issues app: the issue tracker of the team that
/// builds the bakery's till, as a whole app in the window. My issues (on a
/// laptop the open issue beside the list) and the Inbox of what changed on
/// them; a row opens its issue.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../demos/screen_issues.dart';
import 'app_frame.dart';

/// The tracker, standing in the window, [gallery] its way out.
class KitIssuesApp extends StatelessWidget {
  const KitIssuesApp({super.key, required this.gallery});

  final KitGalleryLink? gallery;

  @override
  Widget build(BuildContext context) => KitApp(
    name: 'Tracker',
    gallery: gallery,
    destinations: [
      (
        item: const MinimalNavItem(LucideIcons.circleUser, 'My issues'),
        root: (context) => KitListAndDetail(
          initial: 'ENG-142',
          list: (open, onOpen) => KitIssuesPage(
            open: open,
            onOpen: onOpen,
            leading: KitApp.leading(context),
          ),
          detail: (id, parent) => KitIssuePage(id: id, parent: parent),
          parent: 'My issues',
          listWidth: 480,
        ),
      ),
      (
        item: const MinimalNavItem(LucideIcons.inbox, 'Inbox'),
        root: (context) => KitListAndDetail(
          initial: 'ENG-157',
          list: (open, onOpen) => _Inbox(open: open, onOpen: onOpen),
          detail: (id, parent) => KitIssuePage(id: id, parent: parent),
          parent: 'Inbox',
          listWidth: 480,
        ),
      ),
    ],
  );
}

/// What happened on my issues, newest first: who, what, on which issue.
typedef _Note = ({String who, String what, String issue, String when});

const List<_Note> _notes = [
  (who: 'Oskar Lind', what: 'assigned you', issue: 'ENG-157', when: '9 min'),
  (
    who: 'Ines Duarte',
    what: 'commented: "Seen it twice on the Lund till"',
    issue: 'ENG-142',
    when: '42 min',
  ),
  (
    who: 'Tom Alves',
    what: 'moved to In progress',
    issue: 'ENG-138',
    when: '2 h',
  ),
  (
    who: 'Hanna Berg',
    what: 'raised the priority to Medium',
    issue: 'ENG-149',
    when: '3 h',
  ),
  (
    who: 'Liv Sande',
    what: 'mentioned you',
    issue: 'ENG-121',
    when: 'Yesterday',
  ),
];

class _Inbox extends StatelessWidget {
  const _Inbox({required this.open, required this.onOpen});

  final String? open;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(
      leading: KitApp.leading(context),
      title: 'Inbox',
      subtitle: '${_notes.length}',
    ),
    padding: EdgeInsets.zero,
    body: MinimalListSection(
      children: [
        for (final note in _notes)
          MinimalListTile(
            leading: MinimalAvatar(note.who, size: 32),
            title: '${note.who} ${note.what}',
            subtitle: '${note.issue} · ${kitIssueTitle(note.issue)}',
            meta: note.when,
            selected: note.issue == open ? true : null,
            onTap: () => onOpen(note.issue),
          ),
      ],
    ),
  );
}
