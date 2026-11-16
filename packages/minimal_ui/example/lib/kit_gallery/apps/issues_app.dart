/// The package example's Issues app: the issue tracker of the team that
/// builds the bakery's till, as a whole app in the window. My issues (on a
/// laptop the open issue beside the list) and the Inbox of what changed on
/// them; a row opens its issue.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../demos/screen_issues.dart';
import '../kit_words.dart';
import 'app_frame.dart';

/// The tracker, standing in the window, [gallery] its way out.
class KitIssuesApp extends StatelessWidget {
  const KitIssuesApp({super.key, required this.gallery, this.screen});

  final KitGalleryLink? gallery;

  /// The screen it opens at, one of [screens]; null opens My issues.
  final String? screen;

  /// My issues (on a laptop, the first beside them); an issue's page.
  static const screens = ['my-issues', 'issue'];

  @override
  Widget build(BuildContext context) => KitApp(
    name: ar('Tracker', 'المتتبّع'),
    gallery: gallery,
    destinations: [
      (
        item: MinimalNavItem(LucideIcons.circleUser, ar('My issues', 'مهامي')),
        root: (context) => KitListAndDetail(
          initial: 'ENG-142',
          opened: screen == 'issue',
          list: (open, onOpen) => KitIssuesPage(
            open: open,
            onOpen: onOpen,
            leading: KitApp.leading(context),
          ),
          detail: (id, parent) => KitIssuePage(id: id, parent: parent),
          parent: ar('My issues', 'مهامي'),
          listWidth: 480,
        ),
      ),
      (
        item: MinimalNavItem(LucideIcons.inbox, ar('Inbox', 'الوارد')),
        root: (context) => KitListAndDetail(
          initial: 'ENG-157',
          list: (open, onOpen) => _Inbox(open: open, onOpen: onOpen),
          detail: (id, parent) => KitIssuePage(id: id, parent: parent),
          parent: ar('Inbox', 'الوارد'),
          listWidth: 480,
        ),
      ),
    ],
  );
}

/// What happened on my issues, newest first: who, what, on which issue.
typedef _Note = ({String who, String what, String issue, String when});

List<_Note> get _notes => [
  (
    who: ar('Oskar Lind', 'عمر الخطيب'),
    what: ar('assigned you', 'أسند إليك مهمة'),
    issue: 'ENG-157',
    when: ar('9 min', '9 د'),
  ),
  (
    who: ar('Ines Duarte', 'هالة منصور'),
    what: ar(
      'commented: “Seen it twice on the Lund till”',
      'علّقت: «رأيتها مرتين على صندوق لوند»',
    ),
    issue: 'ENG-142',
    when: ar('42 min', '42 د'),
  ),
  (
    who: ar('Tom Alves', 'طارق عيسى'),
    what: ar('moved to In progress', 'نقل مهمة إلى «قيد التنفيذ»'),
    issue: 'ENG-138',
    when: ar('2 h', '2 س'),
  ),
  (
    who: ar('Hanna Berg', 'هند البرغوثي'),
    what: ar('raised the priority to Medium', 'رفعت الأولوية إلى «متوسطة»'),
    issue: 'ENG-149',
    when: ar('3 h', '3 س'),
  ),
  (
    who: ar('Liv Sande', 'لينا سعادة'),
    what: ar('mentioned you', 'أشارت إليك'),
    issue: 'ENG-121',
    when: ar('Yesterday', 'أمس'),
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
      title: ar('Inbox', 'الوارد'),
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
