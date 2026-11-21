// What a field's list says while an app's search is on its way and after it
// failed: the combobox's and the multi-select's `loadingBuilder` and
// `errorBuilder` on ui_core's RawCombobox and RawTagInput.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../components/feedback/spinner.dart';
import '../components/input/field_core.dart';
import '../theme.dart';

/// The list while a search is on its way: Fluent's extra-tiny spinner with
/// "Loading" beside it, where the options stand.
Widget fluent2SearchLoading(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: Fluent2Spacing.s,
    vertical: Fluent2Spacing.sNudge,
  ),
  child: Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    child: Fluent2Spinner(
      size: Fluent2SpinnerSize.extraTiny,
      label: RawWidgetsLocalizations.of(context).loadingLabel,
      below: false,
    ),
  ),
);

/// The list after a search threw ([failure]): that it failed, in the
/// secondary ink, and "Try again" as an option row, lit while the keys are on
/// it ([RawSearchError.focused]) and under the pointer. The focus stays in
/// the field: the row is no tab stop.
Widget fluent2SearchFailed(BuildContext context, RawSearchError failure) {
  final t = context.fluent2Theme;
  final words = RawWidgetsLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // The list says it as it appears; the row would say it twice.
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Fluent2Spacing.s,
            vertical: Fluent2Spacing.sNudge,
          ),
          child: Text(
            words.searchFailedMessage,
            style: t.body1.c(t.textSecondary),
          ),
        ),
      ),
      ExcludeFocus(
        child: RawButton(
          onPressed: failure.retry,
          semanticLabel: words.retryButtonLabel,
          builder: (context, states, _) => Fluent2OptionFace(
            label: words.retryButtonLabel,
            selected: false,
            highlighted: failure.focused,
            states: states,
          ),
        ),
      ),
    ],
  );
}
