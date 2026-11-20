/// Jotter's Search: every note's title, words and tags, searched as you
/// type; the notes that match, or what to try when none does.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';

/// The search page, pushed over Notes.
class JotterSearchPage extends StatefulWidget {
  /// Search, opened on [initialQuery].
  const JotterSearchPage({super.key, this.initialQuery = ''});

  /// What it searches for at first.
  final String initialQuery;

  @override
  State<JotterSearchPage> createState() => _JotterSearchPageState();
}

class _JotterSearchPageState extends State<JotterSearchPage> {
  late final _query = TextEditingController(text: widget.initialQuery)
    ..addListener(() => setState(() {}));
  final _field = FocusNode(debugLabel: 'search');
  String _where = 'all';

  @override
  void dispose() {
    _query.dispose();
    _field.dispose();
    super.dispose();
  }

  /// The words of [n] around the first place [q] is found, or its excerpt.
  String _snippet(JotterNote n, String q) {
    final body = n.body.replaceAll('\n', ' ');
    final at = body.toLowerCase().indexOf(q);
    if (at < 0) return n.excerpt;
    // From the start of a word a few words back, to the end of a word.
    var from = (at - 28).clamp(0, body.length);
    if (from > 0) {
      final space = body.indexOf(' ', from);
      from = space < 0 || space >= at ? from : space + 1;
    }
    var to = (at + q.length + 56).clamp(0, body.length);
    if (to < body.length) {
      final space = body.lastIndexOf(' ', to);
      to = space <= at + q.length ? to : space;
    }
    return '${from > 0 ? '…' : ''}${body.substring(from, to).trim()}'
        '${to < body.length ? '…' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final frame = JotterFrame.of(context);
    final theme = context.keycapTheme;
    final q = _query.text.trim().toLowerCase();
    bool hits(JotterNote n) => switch (_where) {
      'titles' => n.title.toLowerCase().contains(q),
      _ =>
        n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q) ||
            n.tags.any((t) => t.toLowerCase().contains(q)),
    };
    final found = q.isEmpty
        ? const <JotterNote>[]
        : [
            for (final n in frame.notes)
              if (hits(n)) n,
          ];
    final Widget results;
    if (q.isEmpty) {
      results = KeycapListGroup(
        header: 'Tags',
        children: [
          for (final tag in {for (final n in frame.notes) ...n.tags})
            KeycapListTile(
              leading: const Icon(LucideIcons.hash),
              title: tag,
              onTap: () => _query.text = tag,
            ),
        ],
      );
    } else if (found.isEmpty) {
      results = Padding(
        padding: const EdgeInsets.symmetric(vertical: KeycapSpacing.large),
        child: KeycapEmptyState(
          icon: LucideIcons.searchX,
          title: 'No notes match “${_query.text.trim()}”',
          message: _where == 'titles'
              ? 'Only titles were searched. Search the words too, or check '
                    'the spelling.'
              : 'Check the spelling, or try fewer words.',
          action: KeycapButton(
            onPressed: () {
              _query.clear();
              _field.requestFocus();
            },
            child: const Text('Clear search'),
          ),
        ),
      );
    } else {
      results = Semantics(
        liveRegion: true,
        child: KeycapListGroup(
          header: '${found.length} ${found.length == 1 ? 'note' : 'notes'}',
          children: [
            for (final n in found)
              KeycapListTile(
                title: n.title,
                subtitle: _snippet(n, q),
                maxSubtitleLines: 2,
                trailingText: jotterFolder(n.folder).name,
                showChevron: false,
                onTap: () {
                  // Beside the list from 1024: back to it, the note open.
                  if (frame.split) Navigator.of(context).maybePop();
                  frame.open(n.id);
                },
              ),
          ],
        ),
      );
    }
    return JotterPage(
      title: 'Search',
      maxWidth: KeycapMetrics.readingWidth,
      children: [
        KeycapSearchField(
          controller: _query,
          focusNode: _field,
          hint: 'Search notes',
          autofocus: widget.initialQuery.isEmpty,
        ),
        const SizedBox(height: KeycapSpacing.medium),
        KeycapSegmentedButton<String>(
          semanticLabel: 'Search in',
          segments: const [
            KeycapSegment(value: 'all', label: 'Everything'),
            KeycapSegment(value: 'titles', label: 'Titles only'),
          ],
          selected: {_where},
          onSelectionChanged: (s) => setState(() => _where = s.first),
        ),
        const SizedBox(height: KeycapSpacing.large),
        DefaultTextStyle.merge(style: theme.textTheme.body, child: results),
      ],
    );
  }
}
