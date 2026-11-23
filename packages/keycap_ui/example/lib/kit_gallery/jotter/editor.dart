/// Jotter's editor: the note on the floor of a well, a row of formatting
/// keys over it (at a phone's foot, under the thumb), its word count.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';
import 'share.dart';

/// The editor pushed over a place, below 1024 wide.
class JotterEditorPage extends StatelessWidget {
  /// The editor for note [noteId].
  const JotterEditorPage({super.key, required this.noteId});

  /// The note.
  final String noteId;

  @override
  Widget build(BuildContext context) => _Editor(noteId: noteId, pane: false);
}

/// The editor beside the notes list, from 1024 wide.
class JotterEditorPane extends StatelessWidget {
  /// The editor for note [noteId].
  const JotterEditorPane({super.key, required this.noteId});

  /// The note.
  final String noteId;

  @override
  Widget build(BuildContext context) => _Editor(noteId: noteId, pane: true);
}

class _Editor extends StatefulWidget {
  const _Editor({required this.noteId, required this.pane});

  final String noteId;
  final bool pane;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final JotterNote _start = JotterFrame.of(context).note(widget.noteId);
  late final _title = TextEditingController(text: _start.title);
  late final _body = TextEditingController(text: _start.body);
  final _focus = FocusNode(debugLabel: 'note');
  final _on = <String>{};

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    JotterFrame.of(context)
        .rewrite(widget.noteId, title: _title.text, body: _body.text);
    setState(() {});
  }

  int get _words => '${_title.text} ${_body.text}'
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final c = theme.colors;
    final frame = JotterFrame.of(context);
    final note = frame.notes.where((n) => n.id == widget.noteId).firstOrNull;
    if (note == null) return const SizedBox();
    final folder = jotterFolder(note.folder);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600;
    const bar = WidgetStatePropertyAll(Size.square(KeycapAppBar.keySide));
    final actions = [
      KeycapIconButton(
        icon: const Icon(LucideIcons.share2),
        semanticLabel: 'Share and export',
        onPressed: () => showJotterShare(context, note.id),
        style: const KeycapStyle(minimumSize: bar),
      ),
      KeycapIconButton(
        icon: const Icon(LucideIcons.folderInput),
        semanticLabel: 'Move to folder',
        onPressed: () => frame.askMove(context, note.id),
        style: const KeycapStyle(minimumSize: bar),
      ),
      KeycapIconButton(
        icon: const Icon(LucideIcons.trash2),
        semanticLabel: 'Delete note',
        onPressed: () => frame.askDelete(context, note.id),
        style: KeycapStyle(
          minimumSize: bar,
          foreground: WidgetStatePropertyAll(c.dangerInk),
        ),
      ),
    ];
    final keys = <({String id, IconData icon, String label})>[
      (id: 'bold', icon: LucideIcons.bold, label: 'Bold'),
      (id: 'italic', icon: LucideIcons.italic, label: 'Italic'),
      (id: 'heading', icon: LucideIcons.heading, label: 'Heading'),
      (id: 'list', icon: LucideIcons.list, label: 'Bulleted list'),
      (id: 'checklist', icon: LucideIcons.listChecks, label: 'Checklist'),
      (id: 'quote', icon: LucideIcons.quote, label: 'Quote'),
    ];
    Widget key(({String id, IconData icon, String label}) k) =>
        KeycapIconButton(
          icon: Icon(k.icon),
          semanticLabel: k.label,
          isSelected: _on.contains(k.id),
          onPressed: () => setState(() {
            if (!_on.remove(k.id)) _on.add(k.id);
          }),
        );
    final count = Text('$_words words · Saved', style: theme.textTheme.figure);
    final formatRow = KeycapToolbar(
      semanticLabel: 'Formatting',
      trailing: count,
      children: [for (final k in keys) key(k)],
    );
    final size = switch (JotterPrefs.of(context).textSize) {
      'Small' => 15.0,
      'Large' => 18.0,
      _ => 16.0,
    };
    final words = theme.textTheme.body.copyWith(fontSize: size, height: 1.6);
    final well = Focus(
      focusNode: _focus,
      skipTraversal: true,
      canRequestFocus: false,
      child: KeycapWell(
        page: true,
        rim: _focus.hasFocus ? c.focus.withValues(alpha: 0.6) : null,
        rimWidth: 1,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The title's line takes a finger's 44 high.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: TextField(
                  controller: _title,
                  onChanged: (_) => _save(),
                  style: theme.textTheme.title,
                  cursorColor: c.accent.top,
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Title',
                    hintStyle: theme.textTheme.title.copyWith(
                      color: c.inkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KeycapSpacing.tight),
              // The page of the notebook reaches the foot of the window and
              // scrolls its own words.
              Expanded(
                child: TextField(
                  controller: _body,
                  onChanged: (_) => _save(),
                  style: words,
                  cursorColor: c.accent.top,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  spellCheckConfiguration: null,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Start writing',
                    hintStyle: words.copyWith(color: c.inkMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final meta = Text(
      '${folder.name} · ${note.edited}',
      style: theme.textTheme.secondary,
    );
    return KeycapScreen(
      topBar: KeycapAppBar(
        title: note.title.isEmpty ? 'New note' : folder.name,
        onBack: widget.pane ? null : () => Navigator.of(context).maybePop(),
        actions: actions,
      ),
      maxWidth: KeycapMetrics.readingWidth + 80,
      scroll: false,
      footer: phone ? formatRow : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!phone) ...[
            formatRow,
            const SizedBox(height: KeycapSpacing.regular),
          ],
          Expanded(child: well),
          const SizedBox(height: KeycapSpacing.medium),
          // The count stands at the line's end, or under the folder and
          // time when both don't fit (a large text size).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: KeycapSpacing.medium,
            runSpacing: KeycapSpacing.tight,
            children: [meta, if (phone) count],
          ),
        ],
      ),
    );
  }
}
