import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
          MinimalTimeline(
            entries: [
              MinimalActivity(
                at: DateTime(2026, 5, 7, 10),
                text: 'Packed',
                stamp: '10 am',
              ),
              if (delivered)
                MinimalActivity(
                  at: DateTime(2026, 5, 7, 14),
                  text: 'Delivered',
                  stamp: '2 pm',
                ),
            ],
          ),
          const SizedBox(height: 12),
          MinimalButton(
            delivered ? 'Reset' : 'Record delivery',
            onPressed: () => setState(() => delivered = !delivered),
          ),
        ],
      ),
    ),
  );
}
