/// Jotter's Share and export: who can open a note, its link, and the note
/// written out as a file. A page pushed over the editor on a phone; a side
/// sheet beside it from 600.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';

/// The page holding [JotterShare], below 600 wide.
class JotterSharePage extends StatelessWidget {
  /// Share and export for note [noteId].
  const JotterSharePage({super.key, required this.noteId});

  /// The note.
  final String noteId;

  @override
  Widget build(BuildContext context) => JotterPage(
    title: 'Share and export',
    children: [JotterShare(noteId: noteId)],
  );
}

/// Opens Share and export for note [id]: a side sheet from 600, a page
/// below.
void showJotterShare(BuildContext context, String id) {
  final frame = JotterFrame.of(context);
  if (frame.wide) {
    showKeycapSideSheet<void>(
      context: context,
      title: 'Share and export',
      width: 400,
      builder: (_) => JotterShare(noteId: id, inSheet: true),
    );
  } else {
    frame.push(JotterSharePage(noteId: id));
  }
}

/// Who can open the note, its link, and its export.
class JotterShare extends StatefulWidget {
  /// Share and export for note [noteId].
  const JotterShare({super.key, required this.noteId, this.inSheet = false});

  /// The note.
  final String noteId;

  /// Whether it stands in a side sheet (narrow, so its fields stack).
  final bool inSheet;

  @override
  State<JotterShare> createState() => _JotterShareState();
}

typedef _Person = ({String name, String email, bool edits});

class _JotterShareState extends State<JotterShare> {
  final _invite = TextEditingController();
  final _people = <_Person>[
    (name: 'Sam Lee', email: 'sam.lee@example.com', edits: true),
    (name: 'Ines Duarte', email: 'ines@example.com', edits: false),
  ];
  bool _link = true;
  String _format = 'pdf';
  bool _exporting = false;
  String? _inviteError;

  @override
  void dispose() {
    _invite.dispose();
    super.dispose();
  }

  void _send() {
    final email = _invite.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(
        () => _inviteError =
            'Enter an email address, like '
            'name@example.com',
      );
      return;
    }
    final name = email.split('@').first.replaceAll('.', ' ');
    setState(() {
      _people.add((name: name, email: email, edits: false));
      _inviteError = null;
      _invite.clear();
    });
    showKeycapToast(context, 'Invited $email to view');
  }

  Future<void> _role(int i) async {
    final p = _people[i];
    await showKeycapActionSheet(
      context: context,
      title: p.name,
      actions: [
        KeycapSheetAction(
          'Can edit',
          icon: LucideIcons.pencil,
          onPressed: () => setState(
            () => _people[i] = (name: p.name, email: p.email, edits: true),
          ),
        ),
        KeycapSheetAction(
          'Can view',
          icon: LucideIcons.eye,
          onPressed: () => setState(
            () => _people[i] = (name: p.name, email: p.email, edits: false),
          ),
        ),
        KeycapSheetAction(
          'Remove access',
          destructive: true,
          onPressed: () => setState(() => _people.removeAt(i)),
        ),
      ],
    );
  }

  Future<void> _export(JotterNote note) async {
    setState(() => _exporting = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _exporting = false);
    final kind = switch (_format) {
      'pdf' => 'PDF',
      'md' => 'Markdown',
      _ => 'plain text',
    };
    showKeycapToast(context, 'Exported “${note.title}” as $kind');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final frame = JotterFrame.of(context);
    final note = frame.note(widget.noteId);
    final stack = widget.inSheet || MediaQuery.sizeOf(context).width < 600;
    final link = 'jotter.example/n/${note.id}-7f3k';
    final invite = KeycapTextField(
      controller: _invite,
      label: 'Invite by email',
      hint: 'name@example.com',
      error: _inviteError,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.email],
      onSubmitted: (_) => _send(),
    );
    final inviteKey = KeycapButton(
      onPressed: _send,
      child: const Text('Invite'),
    );
    final people = KeycapListGroup(
      header: 'People with access',
      children: [
        KeycapListTile(
          leading: ExcludeSemantics(
            child: KeycapAvatar(name: jotterWriter.name, size: 36),
          ),
          title: '${jotterWriter.name} (you)',
          subtitle: jotterWriter.email,
          trailingText: 'Owner',
        ),
        for (final (i, p) in _people.indexed)
          KeycapListTile(
            leading: ExcludeSemantics(
              child: KeycapAvatar(name: p.name, size: 36),
            ),
            title: p.name,
            subtitle: p.email,
            value: p.edits ? 'Can edit' : 'Can view',
            onTap: () => _role(i),
          ),
      ],
    );
    final linkGroup = KeycapListGroup(
      header: 'Link',
      footer: _link
          ? 'Anyone with the link can read this note. They can’t edit it.'
          : 'Only the people above can open this note.',
      children: [
        KeycapSwitchListTile(
          leading: const Icon(LucideIcons.link),
          title: 'Share with a link',
          value: _link,
          onChanged: (v) => setState(() => _link = v),
        ),
        // One row, one target: the whole row copies the link (a key inside
        // a row that does nothing would leave most of the row dead).
        if (_link)
          KeycapListTile(
            leading: const Icon(LucideIcons.copy),
            title: 'Copy link',
            subtitle: link,
            showChevron: false,
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'https://$link'));
              showKeycapToast(context, 'Link copied');
            },
          ),
      ],
    );
    final export = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KeycapSectionHeader('Export'),
        KeycapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeycapSelect<String>(
                label: 'Format',
                value: _format,
                items: const [
                  KeycapSelectItem(value: 'pdf', label: 'PDF'),
                  KeycapSelectItem(value: 'md', label: 'Markdown'),
                  KeycapSelectItem(value: 'txt', label: 'Plain text'),
                ],
                onChanged: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: KeycapSpacing.regular),
              Text(
                '${note.title} · ${note.words} '
                'words${_format == 'pdf' ? ' · A4, Rubik' : ''}',
                style: theme.textTheme.secondary,
              ),
              const SizedBox(height: KeycapSpacing.large),
              if (_exporting) ...[
                const KeycapProgressBar(semanticLabel: 'Exporting'),
                const SizedBox(height: KeycapSpacing.regular),
              ],
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KeycapButton.accent(
                  icon: const Icon(LucideIcons.download),
                  onPressed: _exporting ? null : () => _export(note),
                  child: const Text('Export'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stack) ...[
          invite,
          const SizedBox(height: KeycapSpacing.small),
          Align(alignment: AlignmentDirectional.centerEnd, child: inviteKey),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: invite),
              const SizedBox(width: KeycapSpacing.small),
              inviteKey,
            ],
          ),
        const SizedBox(height: KeycapSpacing.large),
        people,
        jotterGroupGap,
        linkGroup,
        jotterGroupGap,
        export,
      ],
    );
  }
}
