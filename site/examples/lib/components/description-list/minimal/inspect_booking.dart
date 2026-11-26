import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:material_ui/material_ui.dart' show Icons;

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
          MinimalDescriptionList(
            properties: [
              MinimalProperty(
                icon: Icons.place_outlined,
                label: 'Room',
                value: second ? 'Loft' : 'Hall',
              ),
              MinimalProperty(
                icon: Icons.event_outlined,
                label: 'Day',
                value: second ? 'Friday' : 'Monday',
              ),
            ],
          ),
          const SizedBox(height: 12),
          MinimalButton(
            second ? 'First booking' : 'Second booking',
            onPressed: () => setState(() => second = !second),
          ),
        ],
      ),
    ),
  );
}
