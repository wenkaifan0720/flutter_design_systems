import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
          ApplianceDescriptionList(
            items: [
              ('Room', second ? 'Loft' : 'Hall'),
              ('Day', second ? 'Friday' : 'Monday'),
            ],
          ),
          const SizedBox(height: 12),
          ApplianceButton(
            second ? 'First booking' : 'Second booking',
            onPressed: () => setState(() => second = !second),
          ),
        ],
      ),
    ),
  );
}
