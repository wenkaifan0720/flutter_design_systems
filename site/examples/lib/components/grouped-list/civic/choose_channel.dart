import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class ChooseChannel extends StatefulWidget {
  const ChooseChannel({super.key});
  @override
  State<ChooseChannel> createState() => _ChooseChannelState();
}

class _ChooseChannelState extends State<ChooseChannel> {
  String channel = 'Email';
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CivicSummaryCard(
            title: 'Delivery',
            child: CivicSummaryList(
              rows: [
                for (final name in ['Email', 'Post'])
                  CivicSummaryRow(
                    label: name,
                    value: Text(channel == name ? 'Selected' : 'Available'),
                    actionLabel: 'Choose',
                    actionSemanticLabel: 'Choose $name',
                    onActionPressed: () => setState(() => channel = name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Deliver by $channel'),
        ],
      ),
    ),
  );
}
