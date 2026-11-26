import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => KeycapButton(
    onPressed: () => showKeycapSideSheet<void>(
      context: context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
    child: const Text('File details'),
  );
}
