import 'package:cupertino_ui/cupertino_ui.dart';

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
        children: [
          CupertinoListSection.insetGrouped(
            children: [
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.location),
                title: const Text('Room'),
                additionalInfo: Text(second ? 'Loft' : 'Hall'),
              ),
              CupertinoListTile(
                leading: const Icon(CupertinoIcons.calendar),
                title: const Text('Day'),
                additionalInfo: Text(second ? 'Friday' : 'Monday'),
              ),
            ],
          ),
          CupertinoButton(
            onPressed: () => setState(() => second = !second),
            child: Text(second ? 'First booking' : 'Second booking'),
          ),
        ],
      ),
    ),
  );
}
