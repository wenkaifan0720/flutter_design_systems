import 'package:cupertino_ui/cupertino_ui.dart';

class ReadPickup extends StatelessWidget {
  const ReadPickup({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 440,
    child: SingleChildScrollView(
      child: CupertinoExpansionTile(
        title: Text('Pickup instructions'),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Collect your parcel at the front desk.'),
        ),
      ),
    ),
  );
}
