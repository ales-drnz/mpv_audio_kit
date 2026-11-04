# Mutation testing

[mutation_test](https://pub.dev/packages/mutation_test) changes one thing
at a time in the hot files of the player (an operator, a condition, a
constant), runs the tests, and lists the mutants the tests let live: code
whose behavior no test pins.

    dart pub get -C tool/mutation
    flutter test -x network --coverage test/internal test/event_isolate test/player test/runtime test/reactive
    dart tool/mutation/bin/mutation.dart --coverage coverage/lcov.info

from the root of the package, with libmpv bundled as for the other tests.
The report is in `mutation-test-report`. `--dry` counts the mutants and
runs nothing. `MAK_MUTATION_CONFIG` names another configuration in place
of `hot_files.xml`.

The files and the test command are in `hot_files.xml`. Comments and the
lines that only log are left alone. With the coverage, a mutant of a line
no test reaches is listed as not covered and not run.

The workflow Mutation runs it on Sundays and by hand. It reads, never
gates: it does not fail on mutants that live. A mutant that lives in code
that matters is a test to write.
