/// Jotter's Settings: the account, the editor, the shortcuts and the look.
/// The screen the look must carry with no colour and its own face set
/// aside: keys, latches and wells do it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'jotter.dart';

/// Settings.
class JotterSettings extends StatelessWidget {
  /// Settings.
  const JotterSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = JotterPrefs.of(context);
    final frame = JotterFrame.of(context);
    final theme = context.keycapTheme;
    final apple = switch (Theme.of(context).platform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    // Rubik draws no ⌘: the key's name, as the platform's menus print it.
    final mod = apple ? 'Cmd' : 'Ctrl';
    final modWords = apple ? 'Command' : 'Control';
    final account = KeycapListGroup(
      header: 'Account',
      children: [
        KeycapListTile(
          leading: const Icon(LucideIcons.user),
          title: jotterWriter.name,
          subtitle: jotterWriter.email,
          onTap: () {},
        ),
        KeycapListTile(
          leading: const Icon(LucideIcons.cloudCheck),
          title: 'Sync',
          subtitle: jotterWriter.plan,
          trailingText: 'Just now',
        ),
      ],
    );
    final editor = KeycapListGroup(
      header: 'Editor',
      children: [
        KeycapSwitchListTile(
          title: 'Check spelling',
          value: prefs.spellcheck,
          onChanged: (v) => prefs.update((p) => p.spellcheck = v),
        ),
        KeycapSwitchListTile(
          title: 'Smart punctuation',
          subtitle: 'Curls quotes and joins dashes as you type',
          maxSubtitleLines: 2,
          value: prefs.smartPunctuation,
          onChanged: (v) => prefs.update((p) => p.smartPunctuation = v),
        ),
        KeycapSwitchListTile(
          title: 'Show word count',
          value: prefs.wordCount,
          onChanged: (v) => prefs.update((p) => p.wordCount = v),
        ),
        KeycapListTile(
          title: 'Save drafts',
          value: prefs.autosave,
          onTap: () async {
            final every = await showKeycapBottomSheet<String>(
              context: context,
              title: 'Save drafts',
              builder: (context) => _Pick(
                semanticLabel: 'Save drafts',
                options: jotterAutosaves,
                labelOf: (v) => v,
                initial: prefs.autosave,
                onChosen: (v) => Navigator.of(context).pop(v),
              ),
            );
            if (every != null) prefs.update((p) => p.autosave = every);
          },
        ),
        KeycapListTile(
          title: 'New notes go to',
          value: jotterFolder(prefs.defaultFolder).name,
          onTap: () async {
            final to = await showKeycapBottomSheet<String>(
              context: context,
              title: 'New notes go to',
              builder: (context) => _Pick(
                semanticLabel: 'Folder',
                options: [for (final f in jotterFolders) f.id],
                labelOf: (id) => jotterFolder(id).name,
                initial: prefs.defaultFolder,
                onChosen: (f) => Navigator.of(context).pop(f),
              ),
            );
            if (to != null) prefs.update((p) => p.defaultFolder = to);
          },
        ),
      ],
    );
    final look = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KeycapSectionHeader('Appearance'),
        KeycapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ExcludeSemantics(child: KeycapFieldLabel('Theme')),
              KeycapSegmentedButton<JotterAppearance>(
                semanticLabel: 'Theme',
                segments: const [
                  KeycapSegment(value: JotterAppearance.light, label: 'Light'),
                  KeycapSegment(value: JotterAppearance.dark, label: 'Dark'),
                  KeycapSegment(
                    value: JotterAppearance.system,
                    label: 'System',
                  ),
                ],
                selected: {prefs.appearance},
                onSelectionChanged: (s) =>
                    prefs.update((p) => p.appearance = s.first),
              ),
              const SizedBox(height: KeycapSpacing.large),
              const ExcludeSemantics(
                child: KeycapFieldLabel('Text size in notes'),
              ),
              KeycapSegmentedButton<String>(
                semanticLabel: 'Text size in notes',
                segments: const [
                  KeycapSegment(value: 'Small', label: 'Small'),
                  KeycapSegment(value: 'Medium', label: 'Medium'),
                  KeycapSegment(value: 'Large', label: 'Large'),
                ],
                selected: {prefs.textSize},
                onSelectionChanged: (s) =>
                    prefs.update((p) => p.textSize = s.first),
              ),
            ],
          ),
        ),
      ],
    );
    KeycapListTile shortcut(String what, List<String> keys, String words) =>
        KeycapListTile(
          title: what,
          trailing: KeycapShortcut(keys: keys, semanticLabel: words),
        );
    final shortcuts = KeycapListGroup(
      header: 'Shortcuts',
      children: [
        shortcut('New note', [mod, 'N'], '$modWords N'),
        shortcut('Search notes', [mod, 'K'], '$modWords K'),
        shortcut('Bold', [mod, 'B'], '$modWords B'),
        shortcut('Move to folder', [mod, 'Shift', 'M'], '$modWords Shift M'),
      ],
    );
    final signOut = Align(
      alignment: AlignmentDirectional.centerStart,
      // Signing out loses nothing: a plain key, not the danger ink.
      child: KeycapButton(
        icon: const Icon(LucideIcons.logOut),
        onPressed: () => showKeycapToast(context, 'Signed out of Jotter'),
        child: const Text('Sign out'),
      ),
    );
    final two = MediaQuery.sizeOf(context).width >= 1024;
    return JotterPage(
      title: 'Settings',
      maxWidth: two ? KeycapScreen.pageWidth : KeycapMetrics.readingWidth,
      children: two
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Each column read and tabbed through whole before the
                  // next, not row by row across both.
                  Expanded(
                    child: _Column(children: [account, jotterGroupGap, look]),
                  ),
                  const SizedBox(width: KeycapSpacing.extraLarge),
                  Expanded(
                    child: _Column(
                      children: [editor, jotterGroupGap, shortcuts],
                    ),
                  ),
                ],
              ),
              jotterGroupGap,
              signOut,
              Text(
                'Jotter keeps ${frame.notes.length} notes on this device.',
                style: theme.textTheme.secondary,
              ),
            ]
          : [
              account,
              jotterGroupGap,
              editor,
              jotterGroupGap,
              look,
              jotterGroupGap,
              shortcuts,
              jotterGroupGap,
              signOut,
            ],
    );
  }
}

// A column of the two-column page: a focus group and a node of its own
// for a screen reader, so both go down it before crossing over.
class _Column extends StatelessWidget {
  const _Column({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    child: Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// How often a draft can be saved.
const jotterAutosaves = [
  'Every 30 seconds',
  'Every minute',
  'Every 5 minutes',
  'When I leave a note',
];

class _Pick extends StatefulWidget {
  const _Pick({
    required this.semanticLabel,
    required this.options,
    required this.labelOf,
    required this.initial,
    required this.onChosen,
  });

  final String semanticLabel;
  final List<String> options;
  final String Function(String) labelOf;
  final String initial;
  final ValueChanged<String> onChosen;

  @override
  State<_Pick> createState() => _PickState();
}

class _PickState extends State<_Pick> {
  late String _to = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KeycapRadioGroup<String>(
        semanticLabel: widget.semanticLabel,
        options: widget.options,
        groupValue: _to,
        labelOf: widget.labelOf,
        onChanged: (v) => setState(() => _to = v),
      ),
      const SizedBox(height: KeycapSpacing.large),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        widthFactor: 1,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width < 600
              ? double.infinity
              : null,
          child: KeycapButton.accent(
            onPressed: () => widget.onChosen(_to),
            child: const Text('Done'),
          ),
        ),
      ),
    ],
  );
}
