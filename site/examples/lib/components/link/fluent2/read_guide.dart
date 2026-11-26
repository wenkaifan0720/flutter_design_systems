import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class ReadGuide extends StatelessWidget {
  const ReadGuide({super.key});

  @override
  Widget build(BuildContext context) => Fluent2Link(
    'Reading guide',
    onPressed: () => Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Borrow a book for up to three weeks.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Fluent2Link(
                  'Back to library',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
