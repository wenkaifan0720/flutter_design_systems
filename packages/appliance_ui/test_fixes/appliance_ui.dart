// Each name appliance_ui 0.3.0 renamed, used once; dart fix renames it (appliance_ui.dart.expect).
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';

dynamic any;

void constructors() {
  ApplianceListTile(title: any, destructive: any);
  ApplianceMenuRow(label: any, states: any, destructive: any, chosen: any);
  ApplianceSheetAction(any, onPressed: any, destructive: any);
  ApplianceTextField(label: any, hint: any, helper: any, error: any);
  AppliancePasswordField(label: any, helper: any, error: any);
  ApplianceSearchField(hint: any);
  ApplianceInputGroup(label: any, hint: any, helper: any, error: any);
  ApplianceSelect<String>(
    items: any,
    value: any,
    onChanged: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  ApplianceCombobox<String>(label: any, hint: any, helper: any, error: any);
  ApplianceTagInput<String>(
    values: any,
    onChanged: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  ApplianceDatePicker(
    value: any,
    onChanged: any,
    firstDate: any,
    lastDate: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  ApplianceDateRangePicker(
    value: any,
    onChanged: any,
    firstDate: any,
    lastDate: any,
    label: any,
    hint: any,
    helper: any,
    error: any,
  );
  ApplianceInput(label: any, hint: any, error: any, obscure: any);
  ApplianceFieldMessage(helper: any, error: any);
  ApplianceCommandPalette(commands: any, hint: any);
  ApplianceSlider(value: any, onChanged: any, valueText: any);
  AppliancePreview(child: any, activeIndex: any);
}

void fields(
  ApplianceListTile listTile,
  ApplianceMenuRow menuRow,
  ApplianceSheetAction sheetAction,
  ApplianceTextField textField,
  AppliancePasswordField passwordField,
  ApplianceSearchField searchField,
  ApplianceInputGroup inputGroup,
  ApplianceSelect<String> select,
  ApplianceCombobox<String> combobox,
  ApplianceTagInput<String> tagInput,
  ApplianceDatePicker datePicker,
  ApplianceDateRangePicker dateRangePicker,
  ApplianceInput input,
  ApplianceFieldMessage fieldMessage,
  ApplianceCommandPalette commandPalette,
  ApplianceSlider slider,
  AppliancePreview preview,
) {
  listTile.destructive;
  menuRow.destructive;
  menuRow.chosen;
  sheetAction.destructive;
  textField.label;
  textField.hint;
  textField.helper;
  textField.error;
  passwordField.label;
  passwordField.helper;
  passwordField.error;
  searchField.hint;
  inputGroup.label;
  inputGroup.hint;
  inputGroup.helper;
  inputGroup.error;
  select.label;
  select.hint;
  select.helper;
  select.error;
  combobox.label;
  combobox.hint;
  combobox.helper;
  combobox.error;
  tagInput.label;
  tagInput.hint;
  tagInput.helper;
  tagInput.error;
  datePicker.label;
  datePicker.hint;
  datePicker.helper;
  datePicker.error;
  dateRangePicker.label;
  dateRangePicker.hint;
  dateRangePicker.helper;
  dateRangePicker.error;
  input.label;
  input.hint;
  input.error;
  input.obscure;
  fieldMessage.helper;
  fieldMessage.error;
  commandPalette.hint;
  slider.valueText;
  preview.activeIndex;
}

void moves(ApplianceColors colors) {
  const time = ApplianceTime(9, 30);
  time.copyWith(hour: 10);
  ApplianceThemeData.of(Brightness.dark, density: any);
  ApplianceTextTheme.of(colors);
}
