/// Settings: the account, how episodes download, what the app tells the
/// listener, and how it looks (lit, which way it reads, how tight). Every
/// choice here drives the app.
library;

import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import 'data.dart';
import 'roomtone.dart';

/// Settings.
class RoomtoneSettings extends StatelessWidget {
  /// Settings.
  const RoomtoneSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = RoomtonePrefs.of(context);
    return RoomtonePage(
      title: 'Settings',
      maxWidth: roomtonePageWidth(context),
      children: roomtoneColumns(
        context,
        [
          StudioListGroup(
            header: 'Account',
            children: [
              if (!prefs.signedIn)
                StudioListTile(
                  title: 'Sign in',
                  subtitle: 'Use the Roomtone demo account',
                  showChevron: false,
                  onTap: () => prefs.update((p) => p.signedIn = true),
                )
              else ...[
                StudioListTile(
                  leading: StudioAvatar(name: roomtoneListener.name, size: 32),
                  title: roomtoneListener.name,
                  subtitle: roomtoneBreakable(roomtoneListener.email),
                  onTap: () => showStudioDialog<void>(
                    context: context,
                    builder: (context) => StudioDialog(
                      title: roomtoneListener.name,
                      content: SelectableText(roomtoneListener.email),
                      actions: [
                        StudioButton(
                          'Done',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                StudioListTile(
                  title: 'Sign out',
                  isDestructiveAction: true,
                  showChevron: false,
                  onTap: () {
                    prefs.update((p) => p.signedIn = false);
                    showStudioToast(context, 'Signed out');
                  },
                ),
              ],
            ],
          ),
          roomtoneGroupGap,
          const StudioSectionHeader('Downloads'),
          StudioSelect<String>(
            label: 'Audio quality',
            value: prefs.quality,
            helper: 'Higher quality takes more room on the device.',
            items: const [
              StudioSelectItem(value: 'standard', label: 'Standard, 64 kbps'),
              StudioSelectItem(value: 'high', label: 'High, 128 kbps'),
              StudioSelectItem(value: 'lossless', label: 'Lossless'),
            ],
            onChanged: (v) => prefs.update((p) => p.quality = v),
          ),
          const SizedBox(height: StudioSpacing.regular),
          StudioListGroup(
            children: [
              StudioListTile.toggle(
                title: 'Download on mobile data',
                value: prefs.cellular,
                onChanged: (v) => prefs.update((p) => p.cellular = v),
              ),
              StudioListTile.toggle(
                title: 'Remove played episodes',
                subtitle: 'A day after you finish them',
                value: prefs.autoDelete,
                onChanged: (v) => prefs.update((p) => p.autoDelete = v),
              ),
              StudioListTile(
                title: 'Remove all downloads',
                isDestructiveAction: true,
                showChevron: false,
                enabled: !prefs.downloadsRemoved,
                onTap: () {
                  prefs.update((p) => p.downloadsRemoved = true);
                  showStudioToast(context, 'Downloads removed');
                },
              ),
            ],
          ),
        ],
        [
          StudioListGroup(
            header: 'Notifications',
            children: [
              StudioListTile.toggle(
                title: 'New episodes',
                value: prefs.newEpisodes,
                onChanged: (v) => prefs.update((p) => p.newEpisodes = v),
              ),
              StudioListTile.toggle(
                title: 'Weekly digest by email',
                value: prefs.digest,
                onChanged: (v) => prefs.update((p) => p.digest = v),
              ),
            ],
          ),
          roomtoneGroupGap,
          const StudioSectionHeader('Appearance'),
          _Labelled(
            label: 'Day or night',
            child: StudioSegmentedButton<RoomtoneAppearance>(
              semanticLabel: 'Day or night',
              expand: true,
              segments: const [
                StudioSegment(value: RoomtoneAppearance.light, label: 'Day'),
                StudioSegment(value: RoomtoneAppearance.dark, label: 'Night'),
                StudioSegment(
                  value: RoomtoneAppearance.system,
                  label: 'System',
                ),
              ],
              value: prefs.appearance,
              onChanged: (v) => prefs.update((p) => p.appearance = v),
            ),
          ),
          const SizedBox(height: StudioSpacing.regular),
          _Labelled(
            label: 'Reading direction',
            child: StudioSegmentedButton<TextDirection>(
              semanticLabel: 'Reading direction',
              expand: true,
              segments: const [
                StudioSegment(value: TextDirection.ltr, label: 'Left to right'),
                StudioSegment(value: TextDirection.rtl, label: 'Right to left'),
              ],
              value: prefs.direction,
              onChanged: (v) => prefs.update((p) => p.direction = v),
            ),
          ),
          const SizedBox(height: StudioSpacing.regular),
          _Labelled(
            label: 'Density',
            child: StudioSegmentedButton<StudioDensity>(
              semanticLabel: 'Density',
              expand: true,
              segments: const [
                StudioSegment(value: StudioDensity.standard, label: 'Standard'),
                StudioSegment(value: StudioDensity.comfortable, label: 'Snug'),
                StudioSegment(value: StudioDensity.compact, label: 'Compact'),
              ],
              value: prefs.density,
              onChanged: (v) => prefs.update((p) => p.density = v),
            ),
          ),
          roomtoneGroupGap,
          const StudioListGroup(
            header: 'About',
            children: [StudioListTile(title: 'Version', trailingText: '0.1.1')],
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(child: StudioFieldLabel(label)),
      child,
    ],
  );
}
