import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class SetVolume extends StatefulWidget {
  const SetVolume({super.key});
  @override
  State<SetVolume> createState() => _SetVolumeState();
}

class _SetVolumeState extends State<SetVolume> {
  double volume = 40;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveSlider(
          value: volume,
          max: 100,
          steps: 19,
          semanticLabel: 'Volume',
          onChanged: (next) => setState(() => volume = next),
        ),
        const SizedBox(height: 12),
        Text('Volume ${volume.round()}%'),
      ],
    ),
  );
}
