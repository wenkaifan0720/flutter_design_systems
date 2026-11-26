import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => ApplianceButton(
    'File details',
    onPressed: () => showApplianceSideSheet<void>(
      context: context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}
