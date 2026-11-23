/// Keycap's Overview: the pitch. The look live, in one sentence, its
/// showcase screens, what the package holds, then every part's page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'editor.dart';
import 'jotter.dart';

/// The Overview.
class JotterOverview extends StatelessWidget {
  /// The Overview, ending in [parts]' index.
  const JotterOverview({super.key, this.parts = const []});

  /// The gallery's part pages.
  final List<JotterPart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    final frame = JotterFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Keycap',
            style: theme.textTheme.display.copyWith(fontSize: 34, height: 1.2),
          ),
        ),
        const SizedBox(height: KeycapSpacing.small),
        Text(
          'Controls as keycaps on a mechanical keyboard: sculpted keys you '
          'press, wells you read, one coloured key for the main thing.',
          style: theme.textTheme.body.copyWith(
            fontSize: 17,
            height: 26 / 17,
            color: theme.colors.inkMuted,
          ),
        ),
        const SizedBox(height: KeycapSpacing.large),
        Wrap(
          spacing: KeycapSpacing.small,
          runSpacing: KeycapSpacing.small,
          children: [
            KeycapButton(
              icon: const Icon(LucideIcons.compass),
              onPressed: () => frame.go(JotterPlace.home),
              child: const Text('Tour Jotter'),
            ),
            KeycapButton.text(
              onPressed: () => frame.open('talk'),
              child: const Text('Open the editor'),
            ),
          ],
        ),
      ],
    );
    const specimen = _Specimen();
    final showcase = KeycapListGroup(
      header: 'Jotter, a notebook in Keycap',
      children: [
        KeycapListTile(
          leading: const Icon(LucideIcons.house),
          title: 'Home',
          subtitle: 'The pinned draft, the folders as keys',
          maxSubtitleLines: 2,
          onTap: () => frame.go(JotterPlace.home),
        ),
        KeycapListTile(
          leading: const Icon(LucideIcons.notebookText),
          title: 'Notes',
          subtitle: 'By folder and filter; beside the editor on a desktop',
          maxSubtitleLines: 2,
          onTap: () => frame.go(JotterPlace.notes),
        ),
        KeycapListTile(
          leading: const Icon(LucideIcons.penLine),
          title: 'Editor',
          subtitle: 'A row of formatting keys over the page',
          maxSubtitleLines: 2,
          onTap: () => frame.open('talk'),
        ),
        KeycapListTile(
          leading: const Icon(LucideIcons.settings),
          title: 'Settings',
          subtitle: 'Switches, latches and shortcuts printed as keys',
          maxSubtitleLines: 2,
          onTap: () => frame.go(JotterPlace.settings),
        ),
      ],
    );
    final holds = KeycapListGroup(
      header: 'In the package',
      children: const [
        KeycapListTile(
          title: 'Keys, fields, choices, lists, navigation, overlays',
          subtitle: 'Each with a theme of its own and a style: to override',
          maxSubtitleLines: 2,
        ),
        KeycapListTile(
          title: 'Phone, tablet and desktop',
          subtitle: 'A row of places, a rail, a side column',
          maxSubtitleLines: 2,
        ),
        KeycapListTile(
          title: 'Day and night colourways',
          subtitle: 'The accent faintly backlit by night',
          maxSubtitleLines: 2,
        ),
        KeycapListTile(
          title: 'Keyboard, screen reader, right to left, large text',
        ),
      ],
    );
    final index = parts.isEmpty
        ? const SizedBox()
        : KeycapListGroup(
            header: 'Every part',
            children: [
              for (final p in parts)
                KeycapListTile(
                  title: p.title,
                  onTap: () => frame.push(p.build(theme.brightness)),
                ),
            ],
          );
    return KeycapScreen(
      body: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: pitch),
                    const SizedBox(width: KeycapSpacing.huge),
                    const Expanded(child: specimen),
                  ],
                ),
                const SizedBox(height: KeycapSpacing.huge),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: showcase),
                    const SizedBox(width: KeycapSpacing.extraLarge),
                    Expanded(child: holds),
                  ],
                ),
                jotterGroupGap,
                index,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pitch,
                jotterGroupGap,
                specimen,
                jotterGroupGap,
                showcase,
                jotterGroupGap,
                holds,
                jotterGroupGap,
                index,
              ],
            ),
    );
  }
}

// The look at work, live: a note's toolbar of latching keys, a well of
// settings, and the three kinds of key in an action row.
class _Specimen extends StatefulWidget {
  const _Specimen();

  @override
  State<_Specimen> createState() => _SpecimenState();
}

class _SpecimenState extends State<_Specimen> {
  final _on = <String>{'bold'};
  bool _sync = true;
  String _view = 'list';

  @override
  Widget build(BuildContext context) {
    final theme = context.keycapTheme;
    Widget latch(String id, IconData icon, String label) => KeycapIconButton(
      icon: Icon(icon),
      semanticLabel: label,
      isSelected: _on.contains(id),
      onPressed: () => setState(() {
        if (!_on.remove(id)) _on.add(id);
      }),
    );
    return KeycapCard(
      padding: const EdgeInsets.all(KeycapSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              latch('bold', LucideIcons.bold, 'Bold'),
              const SizedBox(width: KeycapMetrics.keyGap),
              latch('italic', LucideIcons.italic, 'Italic'),
              const SizedBox(width: KeycapMetrics.keyGap),
              latch('list', LucideIcons.list, 'Bulleted list'),
              const Spacer(),
              Text('96 words', style: theme.textTheme.figure),
            ],
          ),
          const SizedBox(height: KeycapSpacing.large),
          KeycapSegmentedButton<String>(
            semanticLabel: 'View',
            segments: const [
              KeycapSegment(value: 'list', label: 'List'),
              KeycapSegment(value: 'grid', label: 'Grid'),
              KeycapSegment(value: 'board', label: 'Board'),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
          const SizedBox(height: KeycapSpacing.regular),
          Row(
            children: [
              Expanded(
                child: Text('Sync on mobile data', style: theme.textTheme.body),
              ),
              KeycapSwitch(
                value: _sync,
                semanticLabel: 'Sync on mobile data',
                onChanged: (v) => setState(() => _sync = v),
              ),
            ],
          ),
          const SizedBox(height: KeycapSpacing.large),
          Wrap(
            spacing: KeycapSpacing.small,
            runSpacing: KeycapSpacing.small,
            alignment: WrapAlignment.end,
            children: [
              KeycapButton(onPressed: () {}, child: const Text('Cancel')),
              KeycapButton.modifier(
                onPressed: () {},
                child: const Text('Save draft'),
              ),
              KeycapButton.accent(
                onPressed: () =>
                    JotterFrame.of(context)
                        .push(const JotterEditorPage(noteId: 'talk')),
                child: const Text('Publish'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
