# Evaluating the skill

Three cold briefs measure whether an agent with only this skill builds a look
that passes. Each brief stresses a different failure: restraint and alignment
([brief_plain.md](brief_plain.md)), character without loss of usability
([brief_graphic.md](brief_graphic.md)), and states that stay true to a
physical material ([brief_material.md](brief_material.md)).

## Running a brief

Run the briefs only against published packages: ui_core ^0.4.0 and
ui_core_test ^0.2.0 on pub.dev, and Flutter 3.50 or later.

1. Start a fresh agent with this skill installed and nothing else about the
   looks: no other look's source, no earlier run's output.
2. Give it the brief's quoted text, verbatim, in an empty folder.
3. Answer its questions only from the brief; record each question.
4. When it reports done, score the package:

   ```sh
   evals/score.sh path/to/<name>_ui
   ```

   `score.sh` copies the package, runs the gates G1 to G10 of
   [rubric.md](rubric.md) on the copy, and prints one line per gate with its
   log. G3 to G5 read the example's `lib/inventory.dart`, which each brief
   asks for: `final DesignInventory inventory` and
   `Widget lookHost(BuildContext context, Widget child, Brightness brightness)`.
   G5 runs [sweep.dart](sweep.dart), which pumps every present part alone
   under each of sixteen conditions (390 and 1440 wide, day and night, left
   to right and right to left, 1x and 2x text) and runs ui_core_test's
   checks over it.
5. Shoot the gallery as [checks.md](../references/checks.md) describes and
   score the review items R1 to R9.

A brief passes with every gate and 80 or more review points. The skill passes
when all three briefs do.

## What a failure tells you

Record the page and line of the skill the agent followed, or should have
found, for every failed gate and every deduction. A fault the skill does not
mention is a gap to fill; a fault it mentions that the agent missed means the
page is too long, too vague or in the wrong place.

## The sweep is tested too

`samples/test/sweep_test.dart` runs `sweepInventory` over the sample look's
inventory, so the scoring code compiles and passes against the same published
packages as the skill's samples.
