// The behaviour law (looks/COMPLETE.md §2a). Every part that takes a callback is enumerated from the source, so a new
// one fails here until it is named in the table. Each one: Tab reaches it, its focus ring paints, Enter and Space press
// it, with no callback it takes no focus and its face is told it is disabled, a hover reaches its face's states, and with
// animations disabled nothing it does leaves a running animation. Each part, and every example page, lays out with no
// exception at 390, 768, 1024 and 1440, at text scale 2.0 and right to left.
// The parts as drawn, and the laws of the table and the press; behaviour_styled_test checks the parts styled,
// behaviour_pages_test the example pages (behaviour_support.dart).
import 'behaviour_support.dart';

void main() {
  behaviourHarness();
  behaviourLaws();
  partBehaviours(styled: false);
}
