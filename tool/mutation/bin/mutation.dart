// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Runs mutation_test on the hot files of hot_files.xml, from the root of
// the package (README.md next to this folder):
//
//   dart tool/mutation/bin/mutation.dart [--dry] [--coverage coverage/lcov.info]
//
// Writes the html report to mutation-test-report. Never fails: the score
// is read, not gated. MAK_MUTATION_CONFIG names another configuration.

import 'dart:io';

import 'package:mutation_test/mutation_test.dart';

Future<void> main(List<String> args) async {
  final at = args.indexOf('--coverage');
  final mutations = MutationTest(
    [
      Platform.environment['MAK_MUTATION_CONFIG'] ??
          'tool/mutation/hot_files.xml',
    ],
    'mutation-test-report',
    false,
    args.contains('--dry'),
    ReportFormat.HTML,
    coverage: at >= 0 ? args[at + 1] : null,
    excludeStrings: true,
  );
  await mutations.runMutationTest();
  if (!args.contains('--dry')) {
    stdout.writeln(
      'mutation: the mutants that lived are in mutation-test-report',
    );
  }
}
