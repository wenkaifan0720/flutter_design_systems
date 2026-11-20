import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';

import '../kit.dart';

/// The host, the screen and the page change.
Widget kitAppDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'App frame',
  sections: const [_Frame()],
);

class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) {
    final t = context.keycapTheme.textTheme;
    return KitSection(
      title: 'Host and page change',
      note: 'KeycapHost once over the navigator; KeycapScreen per page.',
      children: [
        Text(
          'A pushed page comes in a short way from the reading end and '
          'settles; the page beneath goes back a step and dims.',
          style: t.body,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: KeycapButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => KeycapScreen(
                  topBar: KeycapAppBar(
                    title: 'Pushed',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  body: KeycapCard(
                    child: Text('A page on the case.', style: t.body),
                  ),
                ),
              ),
            ),
            child: const Text('Push a page'),
          ),
        ),
      ],
    );
  }
}
