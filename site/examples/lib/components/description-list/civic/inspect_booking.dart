import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class InspectBooking extends StatefulWidget {
  const InspectBooking({super.key});
  @override
  State<InspectBooking> createState() => _InspectBookingState();
}

class _InspectBookingState extends State<InspectBooking> {
  bool second = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivicSummaryList(
            rows: [
              CivicSummaryRow(
                label: 'Room',
                value: Text(second ? 'Loft' : 'Hall'),
              ),
              CivicSummaryRow(
                label: 'Day',
                value: Text(second ? 'Friday' : 'Monday'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CivicButton(
            onPressed: () => setState(() => second = !second),
            child: Text(second ? 'First booking' : 'Second booking'),
          ),
        ],
      ),
    ),
  );
}
