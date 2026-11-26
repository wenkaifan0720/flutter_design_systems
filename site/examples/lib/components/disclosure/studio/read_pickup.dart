import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class ReadPickup extends StatelessWidget {
  const ReadPickup({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: const StudioDisclosure(
        title: 'Pickup instructions',
        child: Text('Collect your parcel at the front desk.'),
      ),
    ),
  );
}
