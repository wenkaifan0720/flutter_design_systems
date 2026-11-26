import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class SplitReceipt extends StatefulWidget {
  const SplitReceipt({super.key});
  @override
  State<SplitReceipt> createState() => _SplitReceiptState();
}

class _SplitReceiptState extends State<SplitReceipt> {
  bool delivery = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subtotal £12'),
        const SizedBox(height: 12),
        const NeumorphicDivider(),
        const SizedBox(height: 12),
        Text(delivery ? 'Total £15' : 'Total £12'),
        const SizedBox(height: 12),
        NeumorphicButton(
          delivery ? 'Remove delivery' : 'Add delivery',
          onPressed: () => setState(() => delivery = !delivery),
        ),
      ],
    ),
  );
}
