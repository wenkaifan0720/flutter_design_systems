/// The shapes of an interactive list item, shared by every row that is one
/// (`ExpressiveListTile`, the labelled control rows, the action sheet's
/// rows). Internal: the barrel never exports it.
library;

import '../shape.dart';
import '../states.dart' show ExpressivePressShapes;
import 'tokens/list_tokens.g.dart';

/// Compose's `ListItemDefaults.shapes()` (`ListTokens`' expressive item
/// shapes): 4dp corners at rest, 12dp hovered, 16dp focused and pressed, in
/// [shapes]' family. The row's highlight takes the morphing shape, so a
/// hover is never a square over the row.
ExpressivePressShapes expressiveListItemPressShapes(ExpressiveShapes shapes) =>
    ExpressivePressShapes(
      shape: shapes.of(ListTokens.itemContainerExpressiveShape),
      hovered: shapes.of(ListTokens.itemHoveredContainerExpressiveShape),
      focused: shapes.of(ListTokens.itemFocusedContainerExpressiveShape),
      pressed: shapes.of(ListTokens.itemPressedContainerExpressiveShape),
    );
