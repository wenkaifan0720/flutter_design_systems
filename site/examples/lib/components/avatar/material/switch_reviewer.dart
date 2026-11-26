import 'package:material_ui/material_ui.dart';

class SwitchReviewer extends StatefulWidget {
  const SwitchReviewer({super.key});
  @override
  State<SwitchReviewer> createState() => _SwitchReviewerState();
}

class _SwitchReviewerState extends State<SwitchReviewer> {
  bool ana = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(child: Text(ana ? 'AL' : 'JR')),
        const SizedBox(height: 12),
        Text(ana ? 'Ana Lee' : 'Jo Ray'),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => ana = !ana),
          child: const Text('Switch reviewer'),
        ),
      ],
    ),
  );
}
