import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
          TermTimeline(
            entries: [
              const TermTimelineEntry(title: 'Packed', time: '10 am'),
              if (delivered)
                const TermTimelineEntry(
                  title: 'Delivered',
                  time: '2 pm',
                  tone: TermTone.success,
                ),
            ],
          ),
          const SizedBox(height: 12),
          TermButton(
            label: delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
