import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
          ApplianceTimeline(
            entries: [
              const ApplianceTimelineEntry(title: 'Packed', time: '10 am'),
              if (delivered)
                const ApplianceTimelineEntry(title: 'Delivered', time: '2 pm'),
            ],
          ),
          const SizedBox(height: 12),
          ApplianceButton(
            delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
