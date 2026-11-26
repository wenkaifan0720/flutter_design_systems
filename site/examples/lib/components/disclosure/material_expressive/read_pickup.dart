import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ReadPickup extends StatelessWidget {
  const ReadPickup({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: const ExpressiveDisclosure(
        title: Text('Pickup instructions'),
        child: Text('Collect your parcel at the front desk.'),
      ),
    ),
  );
}
