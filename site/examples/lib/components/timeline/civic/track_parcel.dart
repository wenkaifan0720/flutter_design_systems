import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
          CivicTimeline(
            entries: [
              const CivicTimelineEntry(title: 'Packed', date: '10 am'),
              if (delivered)
                const CivicTimelineEntry(title: 'Delivered', date: '2 pm'),
            ],
          ),
          const SizedBox(height: 12),
          CivicButton(
            onPressed: () => setState(() => delivered = !delivered),
            child: Text(delivered ? 'Reset' : 'Record delivery'),
          ),
        ],
      ),
    ),
  );
}
