import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
          KeycapDescriptionList(
            items: [
              (term: 'Room', value: second ? 'Loft' : 'Hall'),
              (term: 'Day', value: second ? 'Friday' : 'Monday'),
            ],
          ),
          const SizedBox(height: 12),
          KeycapButton(
            onPressed: () => setState(() => second = !second),
            child: Text(second ? 'First booking' : 'Second booking'),
          ),
        ],
      ),
    ),
  );
}
