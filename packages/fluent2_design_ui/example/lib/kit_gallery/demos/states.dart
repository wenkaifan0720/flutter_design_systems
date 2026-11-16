/// A page's three states (loading under Fluent's spinner, empty with its
/// first act, an error with its retry), the spinner's sizes and its
/// inverted cut on the brand, and the toast in its four intents, raised
/// over the app and drawn in place.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

import '../kit.dart';

Widget kitStatesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'States',
  sections: [
    kitSection('Loading', children: [kitSpecimenStateLoading()]),
    kitSection('Empty', children: [kitSpecimenStateEmpty()]),
    kitSection('Error', children: [kitSpecimenStateError()]),
    kitSection('Done', children: [kitSpecimenStatusView()]),
    kitSection('Spinner sizes', children: [const _Sizes()]),
    kitSection('Spinner', children: [kitSpecimenSpinner()]),
    kitSection(
      'Toasts',
      children: [
        Builder(
          builder: (context) => kitRow([
            for (final intent in Fluent2ToastIntent.values)
              Fluent2Button(
                kitW(kitSay(intent)),
                onPressed: () => showFluent2Toast(
                  context,
                  kitW(_toastWords[intent]!.$2),
                  title: kitW(_toastWords[intent]!.$1),
                  tone: intent,
                  actionLabel: intent == Fluent2ToastIntent.success
                      ? kitW('Undo')
                      : null,
                  onAction: intent == Fluent2ToastIntent.success ? () {} : null,
                ),
              ),
          ]),
        ),
        kitAsShown(Fluent2ChromeMetrics.toastWidth, kitSpecimenToastSuccess()),
        for (final intent in const [
          Fluent2ToastIntent.info,
          Fluent2ToastIntent.warning,
          Fluent2ToastIntent.error,
        ])
          kitAsShown(
            Fluent2ChromeMetrics.toastWidth,
            Fluent2Toast(
              kitW(_toastWords[intent]!.$2),
              title: kitW(_toastWords[intent]!.$1),
              tone: intent,
            ),
          ),
      ],
    ),
  ],
);

const Map<Fluent2ToastIntent, (String, String)> _toastWords = {
  Fluent2ToastIntent.success: ('File moved', 'Launch plan.docx is in Archive.'),
  Fluent2ToastIntent.info: ('Syncing', 'Northwind files update in a minute.'),
  Fluent2ToastIntent.warning: ('Storage almost full', '92% of 1 TB used.'),
  Fluent2ToastIntent.error: ('Upload failed', 'Hero art.png is over 250 MB.'),
};

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Fluent2Spacing.m,
      children: [
        kitRow([
          for (final size in Fluent2SpinnerSize.values)
            Fluent2Spinner(size: size),
        ]),
        // The inverted spinner on a brand panel (a cover, a hero), drawn as
        // a panel of its own rather than a button's size.
        Container(
          constraints: const BoxConstraints(maxWidth: 320, minHeight: 120),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(Fluent2Spacing.l),
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(Fluent2Radius.large),
          ),
          child: Fluent2Spinner(
            inverted: true,
            label: kitW('Uploading the cover'),
          ),
        ),
      ],
    );
  }
}

// --- Specimens --------------------------------------------------------------
// One builder per specimen in metadata.yaml. The stage (kitSpecimenStage)
// styles them; a builder never names a style.

Widget kitSpecimenStateLoading() =>
    Fluent2LoadingState(message: kitW('Loading files'));

Widget kitSpecimenStateEmpty() => Fluent2EmptyState(
  title: kitW('No files yet'),
  body: kitW('Files you create or upload to Northwind show up here.'),
  icon: Fluent2Icons.folder,
  actionLabel: kitW('Upload'),
  actionIcon: Fluent2Icons.arrowUpload,
  onAction: () {},
);

Widget kitSpecimenStateError() => Fluent2ErrorState(
  title: kitW("Couldn't load your chats"),
  message: kitW('Check your connection and try again.'),
  onRetry: () {},
);

/// The medium spinner with its words under it, and the small one with its
/// words after it.
Widget kitSpecimenSpinner() => kitRow([
  Fluent2Spinner(label: kitW('Loading files')),
  Fluent2Spinner(
    size: Fluent2SpinnerSize.small,
    below: false,
    label: kitW('Syncing'),
  ),
]);

/// An invitation sent: the success status with what comes next.
Widget kitSpecimenStatusView() => Fluent2StatusView.success(
  title: kitW('Invitation sent'),
  message: kitW('Ana Ruiz will get an email with a link to Budget.'),
  actionLabel: kitW('Invite someone else'),
  onAction: () {},
);

Widget kitSpecimenToastSuccess() => Fluent2Toast(
  kitW(_toastWords[Fluent2ToastIntent.success]!.$2),
  title: kitW(_toastWords[Fluent2ToastIntent.success]!.$1),
  actionLabel: kitW('Undo'),
  onAction: () {},
);
