import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart'
    show RawDialogAction, RawMenuEntry, RawToast;

import '../design/design.dart';
import '../garden.dart';
import 'plant.dart';
import 'settings.dart';

enum _Show { all, thirsty }

/// The plants, the ones that want water first, with a key to water each.
class PlantsScreen extends StatefulWidget {
  /// The app's first screen.
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  _Show _show = _Show.all;
  bool _indoor = true;
  bool _outdoor = true;

  @override
  Widget build(BuildContext context) {
    final garden = GardenScope.of(context);
    final shown = [
      for (final plant in garden.plants)
        if ((_show == _Show.all || plant.daysLeft(garden.today) <= 0) &&
            (garden.outdoorRooms.contains(plant.room) ? _outdoor : _indoor))
          plant,
    ];
    return TendScaffold(
      title: 'Plants',
      actions: [
        TendIconButton(
          icon: Icons.settings_outlined,
          semanticLabel: 'Settings',
          onPressed: () => Navigator.of(context).push(
            TendPageRoute<void>(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
      bottomBar: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TendButton(
          'Add a plant',
          icon: Icons.add,
          onPressed: () => openPlant(context, null),
        ),
      ),
      body: TendColumn(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TendTabs<_Show>(
                value: _show,
                semanticLabel: 'Show',
                onChanged: (show) => setState(() => _show = show),
                tabs: const [
                  TendTab(value: _Show.all, label: 'All'),
                  TendTab(value: _Show.thirsty, label: 'Thirsty'),
                ],
              ),
              TendToolbar(
                toggles: [
                  TendToolbarToggle(
                    icon: Icons.chair_outlined,
                    semanticLabel: 'Indoor plants',
                    isSelected: _indoor,
                    onPressed: () => setState(() => _indoor = !_indoor),
                  ),
                  TendToolbarToggle(
                    icon: Icons.park_outlined,
                    semanticLabel: 'Outdoor plants',
                    isSelected: _outdoor,
                    onPressed: () => setState(() => _outdoor = !_outdoor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            TendNotice(
              icon: Icons.water_drop_outlined,
              title: _show == _Show.thirsty
                  ? 'Nobody is thirsty'
                  : 'No plants here',
              message: _show == _Show.thirsty
                  ? 'Every plant has had its water. Look again tomorrow.'
                  : 'Add a plant, or show the plants of every kind of room.',
            )
          else
            for (final plant in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlantRow(plant: plant, today: garden.today),
              ),
        ],
      ),
    );
  }
}

/// Opens [plant] to edit it, or a new plant when null, as a sheet.
void openPlant(BuildContext context, Plant? plant) =>
    Navigator.of(context).push(
      TendPageRoute<void>(
        fullscreenDialog: plant == null,
        builder: (context) => PlantScreen(plant: plant),
      ),
    );

class _PlantRow extends StatelessWidget {
  const _PlantRow({required this.plant, required this.today});

  final Plant plant;
  final DateTime today;

  String get _due => switch (plant.daysLeft(today)) {
    0 => 'Water today',
    1 => 'Water tomorrow',
    final days when days > 1 => 'Water in $days days',
    -1 => 'A day late',
    final days => '${-days} days late',
  };

  void _water(BuildContext context) {
    final garden = GardenScope.of(context);
    final before = plant;
    garden.water(plant);
    TendToaster.of(context).show(
      RawToast(
        message: 'Watered ${plant.name}',
        actionLabel: 'Undo',
        onAction: () => garden.put(before),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final garden = GardenScope.of(context);
    final sure = await showTendDialog<bool>(
      context,
      title: 'Delete ${plant.name}?',
      content: const Text('Its notes and watering days go with it.'),
      actions: (context) => [
        RawDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        RawDialogAction(
          label: 'Delete',
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (sure ?? false) garden.remove(plant);
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      RawMenuEntry(label: 'Edit', onPressed: () => openPlant(context, plant)),
      RawMenuEntry(
        label: 'Delete',
        isDestructiveAction: true,
        onPressed: () => _delete(context),
      ),
    ];
    // A right click, a long press or Shift+F10 on the row opens the same
    // menu as its "…" key.
    return TendMenu(
      entries: entries,
      child: TendListRow(
        title: plant.name,
        subtitle: '${plant.room} · $_due',
        onPressed: () => openPlant(context, plant),
        trailing: [
          TendTooltip(
            message: 'Water now',
            child: TendIconButton(
              icon: Icons.water_drop_outlined,
              semanticLabel: 'Water ${plant.name}',
              onPressed: () => _water(context),
            ),
          ),
          TendMoreMenu(
            semanticLabel: 'More for ${plant.name}',
            entries: entries,
          ),
        ],
      ),
    );
  }
}
