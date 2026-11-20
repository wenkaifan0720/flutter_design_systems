/// How wide a select or a date field stands.
library;

import 'package:flutter/widgets.dart';

/// Below 600 wide [field] fills its column. From 600 it stands at most
/// [most] wide, on its start edge; in a column not much wider than that (a
/// pane, a dialog, a sheet: up to a quarter more) it spans the column, so
/// it ends with the list and the keys under it.
Widget keycapFieldWidth(BuildContext context, Widget field, double most) {
  if (MediaQuery.sizeOf(context).width < 600) return field;
  return LayoutBuilder(
    builder: (context, box) => Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: box.maxWidth <= most * 1.25 ? double.infinity : most,
        ),
        child: field,
      ),
    ),
  );
}
