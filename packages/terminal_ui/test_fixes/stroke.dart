import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

double lineWidth(BuildContext context) =>
    termStroke(TermTheme.of(context), context.termGrid);
