import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class ReadGuide extends StatelessWidget {
  const ReadGuide({super.key});

  @override
  Widget build(BuildContext context) => ClayLink(
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
                ClayLink(
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
