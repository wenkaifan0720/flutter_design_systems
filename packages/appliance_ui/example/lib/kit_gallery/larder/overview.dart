/// The look's Overview: what Appliance is, its three moves shown live, and
/// the index of every part's page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'larder.dart';

/// The Overview.
class LarderOverview extends StatefulWidget {
  /// The Overview, its index over [parts].
  const LarderOverview({super.key, this.parts = const []});

  /// The package's parts.
  final List<LarderPart> parts;

  @override
  State<LarderOverview> createState() => _LarderOverviewState();
}

class _LarderOverviewState extends State<LarderOverview> {
  bool _power = true;
  bool _timer = false;
  String _mode = 'bake';
  int _preset = 1;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = LarderFrame.of(context);
    const gap = SizedBox(height: ApplianceSpacing.extraLarge);
    Widget move(String n, String title, String words, Widget show) =>
        AppliancePanel(
          padding: const EdgeInsets.all(ApplianceSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(n, style: t.legend),
              const SizedBox(height: ApplianceSpacing.small),
              Text(
                title,
                style: t.heading.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: ApplianceSpacing.tight),
              Text(words, style: t.secondary),
              const SizedBox(height: ApplianceSpacing.large),
              show,
            ],
          ),
        );
    return LarderPage(
      title: 'Appliance',
      maxWidth: 720,
      children: [
        Text('A calm household device.', style: t.display),
        const SizedBox(height: ApplianceSpacing.small),
        Text(
          'Warm-white moulded plastic in three depths under one light, '
          'crisp parting lines, one signal orange, lamps that say what is on, '
          'and selectors you can feel. By night, the same objects in a dim '
          'room.',
          style: t.body.copyWith(color: c.printMuted),
        ),
        const SizedBox(height: ApplianceSpacing.large),
        Wrap(
          spacing: ApplianceSpacing.medium,
          runSpacing: ApplianceSpacing.medium,
          children: [
            ApplianceButton.filled(
              'Open the shop',
              onPressed: () => frame.go(LarderPlace.home),
            ),
            ApplianceButton(
              'Settings',
              icon: const Icon(LucideIcons.settings),
              onPressed: () => frame.go(LarderPlace.settings),
            ),
          ],
        ),
        gap,
        move(
          '01',
          'Moulded panels and seams',
          'Content sits on smooth faceplates seated in a grained housing; '
              'keys stand up, wells sink in, and every part is lit from the '
              'top.',
          Wrap(
            spacing: ApplianceSpacing.medium,
            runSpacing: ApplianceSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ApplianceButton('Start', onPressed: () {}),
              ApplianceButton.filled('Start', onPressed: () {}),
              const ApplianceButton('Off', onPressed: null),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.timer),
                semanticLabel: 'Timer',
                selected: _timer,
                onPressed: () => setState(() => _timer = !_timer),
              ),
            ],
          ),
        ),
        const SizedBox(height: ApplianceSpacing.medium),
        move(
          '02',
          'The lamp',
          'A small lamp says what is on: the current place, the chosen '
              'preset, a switch that is on. Nothing is said by a tint alone.',
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: ApplianceSpacing.medium),
                Column(
                  children: [
                    ApplianceRadio<int>(
                      value: i,
                      groupValue: _preset,
                      semanticLabel: 'Preset ${i + 1}',
                      onChanged: (v) => setState(() => _preset = v),
                    ),
                    const SizedBox(height: ApplianceSpacing.small),
                    Text('P${i + 1}', style: t.legend),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ApplianceSpacing.medium),
        move(
          '03',
          'Mechanical selectors',
          'Slide switches and a slide selector snap into their detents; '
              'a key latches down and stays.',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ApplianceSwitch(
                    value: _power,
                    semanticLabel: 'Power',
                    onChanged: (v) => setState(() => _power = v),
                  ),
                  const SizedBox(width: ApplianceSpacing.medium),
                  Text(_power ? 'On' : 'Off', style: t.body),
                ],
              ),
              const SizedBox(height: ApplianceSpacing.large),
              ApplianceSegmentedButton<String>(
                semanticLabel: 'Mode',
                segments: const [
                  ApplianceSegment(value: 'bake', label: 'Bake'),
                  ApplianceSegment(value: 'grill', label: 'Grill'),
                  ApplianceSegment(value: 'fan', label: 'Fan'),
                ],
                value: _mode,
                onChanged: (v) => setState(() => _mode = v),
              ),
            ],
          ),
        ),
        if (widget.parts.isNotEmpty) ...[
          gap,
          ApplianceListGroup(
            header: 'Every part',
            children: [
              for (final part in widget.parts)
                ApplianceListTile(
                  title: part.title,
                  onTap: () => frame.push(part.build(theme.brightness)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
