// What comic_ui 0.8.0 removes that 0.2.0 deprecated: removed_0_8.dart calls it as before `dart fix --apply`,
// removed_0_8.dart.expect as after.
// ignore_for_file: unused_local_variable
import 'package:comic_ui/comic_ui.dart';

void calls(ComicThemeData theme) {
  final a = theme.copyWith(shapes: const ComicShapes(), width: 390);
  final b = theme.copyWith(motion: const ComicMotion());
  final c = theme.copyWith(
    density: ComicDensity.compact,
    shapes: const ComicShapes(),
    motion: const ComicMotion(),
  );
}
