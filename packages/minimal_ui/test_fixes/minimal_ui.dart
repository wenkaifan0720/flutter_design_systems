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

// minimal_ui 0.8.0: a label only a screen reader hears is a semanticLabel.
void spokenLabels(BuildContext context) {
  MinimalIconButton(any, label: any);
  MinimalToggleGroup(items: any, selected: any, label: any);
  MinimalCircularProgressIndicator(label: any);
  MinimalComposerAction(label: any);
  MinimalBadge(label: any);
  MinimalCarouselView(children: any, label: any);
  MinimalMenu(items: any, child: any, label: any);
  MinimalCheckbox(value: any, onChanged: any, label: any);
  MinimalCheckMark(value: any, label: any);
  MinimalPopover(anchor: any, content: any, label: any);
  MinimalRadio(selected: any, onPressed: any, label: any);
  MinimalRadioGroup(options: any, value: any, label: any);
  MinimalMenuBar(menus: any, label: any);
  MinimalLinearProgressIndicator(label: any);
  MinimalTreeView(roots: any, childrenOf: any, labelOf: any, label: any);
  MinimalScrollArea(child: any, label: any);
  MinimalResizable(first: any, second: any, label: any);
  MinimalMenu.button(any, items: any, label: any);
  MinimalMenu.popover<void>(context, anchor: any, builder: any, label: any);
  showMinimalMenu(context, anchor: any, items: any, label: any);
  MinimalRating(value: any, label: any);
  MinimalSegmentedButton(segments: any, value: any, onChanged: any, label: any);
}

Object? s0(MinimalIconButton w) => w.label;
Object? s1(MinimalToggleGroup w) => w.label;
Object? s2(MinimalCircularProgressIndicator w) => w.label;
Object? s3(MinimalComposerAction w) => w.label;
Object? s4(MinimalBadge w) => w.label;
Object? s5(MinimalCarouselView w) => w.label;
Object? s6(MinimalMenu w) => w.label;
Object? s7(MinimalCheckbox w) => w.label;
Object? s8(MinimalCheckMark w) => w.label;
Object? s9(MinimalPopover w) => w.label;
Object? s10(MinimalRadio w) => w.label;
Object? s11(MinimalRadioGroup w) => w.label;
Object? s12(MinimalMenuBar w) => w.label;
Object? s13(MinimalLinearProgressIndicator w) => w.label;
Object? s14(MinimalTreeView w) => w.label;
Object? s15(MinimalScrollArea w) => w.label;
Object? s16(MinimalResizable w) => w.label;
Object? s17(MinimalRating w) => w.label;
Object? s18(MinimalSegmentedButton w) => w.label;
