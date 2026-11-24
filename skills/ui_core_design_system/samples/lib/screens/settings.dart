import 'package:flutter/widgets.dart';

import '../design/design.dart';
import '../garden.dart';

/// The app's settings: day or night, reminders, and the rooms' order.
class SettingsScreen extends StatelessWidget {
  /// The settings, pushed from the plants.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = GardenScope.of(context);
    final theme = TendTheme.of(context);
    return TendScaffold(
      title: 'Settings',
      body: TendColumn(
        maxWidth: 560,
        children: [
          const TendHeading('Appearance'),
          TendRadioGroup<Appearance>(
            value: garden.appearance,
            onChanged: (next) => garden.appearance = next,
            options: const [
              TendRadioOption(
                value: Appearance.system,
                label: 'As the device is set',
              ),
              TendRadioOption(value: Appearance.light, label: 'Day'),
              TendRadioOption(value: Appearance.dark, label: 'Night'),
            ],
          ),
          const SizedBox(height: 16),
          const TendHeading('Reminders'),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text('Remind me on watering days', style: theme.body),
                ),
                TendSwitch(
                  value: garden.reminders,
                  onChanged: (next) => garden.reminders = next,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TendSelect<String>(
            labelText: 'Remind me in the',
            options: const ['Morning', 'Afternoon', 'Evening'],
            value: garden.reminderTime,
            // Off while reminders are off.
            onChanged: garden.reminders
                ? (next) => garden.reminderTime = next
                : null,
          ),
          const SizedBox(height: 16),
          const TendHeading('Rooms'),
          Text(
            'The plants are listed room by room, in this order. Drag a room '
            'by its grip, or move it with Alt and the arrow keys.',
            style: theme.body.copyWith(color: theme.colors.mutedInk),
          ),
          const SizedBox(height: 8),
          TendReorderableList<String>(
            items: garden.rooms,
            labelOf: (room) => room,
            onReorder: garden.moveRoom,
            itemBuilder: (context, room) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Text(room, style: theme.body),
            ),
          ),
        ],
      ),
    );
  }
}
