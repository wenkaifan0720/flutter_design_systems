import 'package:material_ui/material_ui.dart';

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
        const Divider(height: 24),
        Text(delivery ? 'Total £15' : 'Total £12'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => delivery = !delivery),
          child: Text(delivery ? 'Remove delivery' : 'Add delivery'),
        ),
      ],
    ),
  );
}
