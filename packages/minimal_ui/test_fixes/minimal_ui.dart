// Each name minimal_ui 0.5.0 renamed, used once; dart fix renames it (minimal_ui.dart.expect).
import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

dynamic any;

void constructors() {
  MinimalToggleGroup(
    items: any,
    selected: any,
    onChanged: any,
    multiple: any,
    allowEmpty: any,
  );
  MinimalDatePicker(value: any, first: any, last: any, today: any, label: any);
  MinimalCalendar(firstDate: any, lastDate: any, today: any);
  MinimalDateRangePicker(
    firstDate: any,
    lastDate: any,
    today: any,
    label: any,
    hint: any,
  );
  MinimalCombobox(
    displayString: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  MinimalMultiSelect(
    values: any,
    displayString: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  MinimalTextField(
    onFocusChanged: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  MinimalSearchField(onFocusChanged: any, hint: any);
  MinimalDisclosure(title: any, child: any, onChanged: any, leading: any);
  MinimalPageDots(count: any, selectedIndex: any, onChanged: any);
  MinimalComposer(style: any, hint: any);
  MinimalFormField(child: any, help: any, label: any, error: any);
  MinimalRadioOption(value: any, label: any, description: any);
  MinimalMenuItem(any, destructive: any);
  MinimalTextArea(label: any, hint: any, helper: any, error: any);
  MinimalInputGroup(label: any, hint: any, helper: any, error: any);
  MinimalPasswordField(label: any, hint: any, helper: any, error: any);
  MinimalInputOtp(label: any, error: any);
  MinimalInputRow(label: any, hint: any, error: any);
  MinimalTimePicker(value: any, label: any);
  MinimalSelect(value: any, options: any, label: any, prompt: any);
  MinimalNumberField(value: any, min: any, max: any, label: any);
  MinimalCommand(actions: any, hint: any);
  MinimalComposerAction(style: any);
}

Object? f0(MinimalToggleGroup w) => [w.onChanged, w.multiple, w.allowEmpty];
Object? f1(MinimalDatePicker w) => [w.first, w.last, w.today, w.label];
Object? f2(MinimalCalendar w) => [w.today];
Object? f3(MinimalDateRangePicker w) => [w.today, w.label, w.hint];
Object? f4(MinimalCombobox w) => [
  w.displayString,
  w.label,
  w.hint,
  w.helper,
  w.error,
];
Object? f5(MinimalMultiSelect w) => [
  w.displayString,
  w.label,
  w.hint,
  w.helper,
  w.error,
];
Object? f6(MinimalTextField w) => [
  w.onFocusChanged,
  w.label,
  w.hint,
  w.helper,
  w.error,
];
Object? f7(MinimalSearchField w) => [w.onFocusChanged, w.hint];
Object? f8(MinimalDisclosure w) => [w.onChanged, w.leading];
Object? f9(MinimalPageDots w) => [w.count, w.selectedIndex, w.onChanged];
Object? f10(MinimalComposer w) => [w.style, w.hint];
Object? f11(MinimalFormField w) => [w.help, w.label, w.error];
Object? f12(MinimalRadioOption w) => [w.description];
Object? f13(MinimalMenuItem w) => [w.destructive];
Object? f14(MinimalTextArea w) => [w.label, w.hint, w.helper, w.error];
Object? f15(MinimalInputGroup w) => [w.label, w.hint, w.helper, w.error];
Object? f16(MinimalPasswordField w) => [w.label, w.hint, w.helper, w.error];
Object? f17(MinimalInputOtp w) => [w.label, w.error];
Object? f18(MinimalInputRow w) => [w.label, w.hint, w.error];
Object? f19(MinimalTimePicker w) => [w.label];
Object? f20(MinimalSelect w) => [w.label, w.prompt];
Object? f21(MinimalNumberField w) => [w.label];
Object? f22(MinimalCommand w) => [w.hint];
Object? f23(MinimalComposerAction w) => [w.style];

MinimalComposerStyle? v0 = MinimalComposerStyle.messages;
MinimalTextTheme v1 = MinimalTextTheme.of(any);
void command(BuildContext context) =>
    MinimalCommand.show(context, actions: any, hint: any);
