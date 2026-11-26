import 'package:material_ui/material_ui.dart';

class ReadPickup extends StatelessWidget {
  const ReadPickup({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 440,
    child: SingleChildScrollView(
      child: ExpansionTile(
        title: Text('Pickup instructions'),
        expandedAlignment: AlignmentDirectional.centerStart,
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text('Collect your parcel at the front desk.')],
      ),
    ),
  );
}
