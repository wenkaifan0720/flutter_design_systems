import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
          ClayTimeline(
            entries: [
              const ClayTimelineEntry(
                title: 'Packed',
                time: '10 am',
                done: true,
              ),
              if (delivered)
                const ClayTimelineEntry(
                  title: 'Delivered',
                  time: '2 pm',
                  done: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClayButton(
            delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
