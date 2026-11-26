import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class TrackParcel extends StatefulWidget {
  const TrackParcel({super.key});
  @override
  State<TrackParcel> createState() => _TrackParcelState();
}

class _TrackParcelState extends State<TrackParcel> {
  bool delivered = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpressiveTimeline(
            entries: [
              const ExpressiveTimelineEntry(title: 'Packed', time: '10 am'),
              if (delivered)
                const ExpressiveTimelineEntry(title: 'Delivered', time: '2 pm'),
            ],
          ),
          const SizedBox(height: 12),
          ExpressiveOutlinedButton(
            delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
