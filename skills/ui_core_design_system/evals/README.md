# Evaluating the skill

Three cold briefs measure whether an agent with only this skill gives an app
a design of its own that passes. Each stresses a different failure:
restraint and alignment ([brief_plain.md](brief_plain.md)), character
without loss of usability ([brief_graphic.md](brief_graphic.md)), and states
that stay true to a physical material ([brief_material.md](brief_material.md)).

## Running a brief

Run the briefs only against published packages: ui_core ^0.6.1 and
ui_core_test ^0.4.0 on pub.dev, and Flutter 3.47 or later.

1. Start a fresh agent with this skill installed and nothing else: no
   design's source, no earlier run's output. Leave out this folder's briefs,
   rubric and `score.sh`.
2. Give it an empty Flutter app (`flutter create --empty <name>`) and the
   brief's quoted text, verbatim.
3. Answer no questions; it decides from the brief and the skill.
4. When it reports done, score the app:

   ```sh
   evals/score.sh path/to/<name> [out dir]
   ```

   `score.sh` copies the app, runs the gates G1 to G6 of
   [rubric.md](rubric.md) on the copy, and prints one line per gate with its
   log. G3 runs [sweep.dart](sweep.dart), which pumps every screen of the
   app's `lib/screens.dart` under each of sixteen conditions (390 and 1024
   wide, day and night, left to right and right to left, 1x and 2x text)
   and runs ui_core_test's checks over it.
5. Read the pictures `score.sh` draws with `shootScreens`: every screen in
   six conditions, and under keyboard focus by day and by night, all at
   twice their size with the app's fonts. Score the review items R1 to R9.

A brief passes with every gate and 80 or more review points. The skill passes
when all three briefs do.

## What a failure tells you

Record the page and line of the skill the agent followed, or should have
found, for every failed gate, every deduction and every ui_core name it
guessed wrong. A fault the skill does not mention is a gap to fill; a fault
it mentions that the agent missed means the page is too long, too vague or
in the wrong place.

## The sweep is tested too

`samples/test/sweep_test.dart` runs `sweepScreens` over the sample app's
screens, so the scoring code compiles and passes against the same published
packages as the skill's samples.
