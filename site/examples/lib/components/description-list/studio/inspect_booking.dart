import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
          StudioDescriptionList(
            entries: [
              StudioDescription('Room', second ? 'Loft' : 'Hall'),
              StudioDescription('Day', second ? 'Friday' : 'Monday'),
            ],
          ),
          const SizedBox(height: 12),
          StudioButton(
            second ? 'First booking' : 'Second booking',
            onPressed: () => setState(() => second = !second),
          ),
        ],
      ),
    ),
  );
}
