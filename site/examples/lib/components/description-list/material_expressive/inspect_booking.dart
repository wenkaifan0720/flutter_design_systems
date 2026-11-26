import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
          ExpressiveDescriptionList(
            items: [
              ExpressiveDescriptionItem('Room', second ? 'Loft' : 'Hall'),
              ExpressiveDescriptionItem('Day', second ? 'Friday' : 'Monday'),
            ],
          ),
          const SizedBox(height: 12),
          ExpressiveOutlinedButton(
            second ? 'First booking' : 'Second booking',
            onPressed: () => setState(() => second = !second),
          ),
        ],
      ),
    ),
  );
}
