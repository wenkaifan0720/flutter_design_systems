import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
          LedgerTimeline(
            entries: [
              const LedgerTimelineEntry(when: '10 am', title: 'Packed'),
              if (delivered)
                const LedgerTimelineEntry(when: '2 pm', title: 'Delivered'),
            ],
          ),
          const SizedBox(height: 12),
          LedgerButton(
            delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
