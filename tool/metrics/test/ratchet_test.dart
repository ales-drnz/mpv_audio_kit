// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The ratchet of the tests per line of lib: a fall fails, unless it is
// declared with its reason.

import 'package:test/test.dart';

import '../bin/metrics.dart';

Map<String, Object> metrics({int ratio = 2400, int loc = 16000}) => {
  'loc': loc,
  'test_per_lib_permille': ratio,
  'complexity_over_15': 4,
  'complexity_over_10': 40,
  'player_base_fields': 54,
  'player_base_non_final': 14,
  'player_base_abstract': 12,
  'functions_over_10': <String, int>{},
};

void main() {
  group('the reason on the command line', () {
    test('no flag is no reason', () {
      expect(testRatioDropReason(['--write']), isNull);
    });
    test('the flag with a reason gives it, trimmed', () {
      expect(
        testRatioDropReason(['--write', '--test-ratio-drop= a table ']),
        'a table',
      );
    });
    test('the flag alone or with nothing is an empty reason', () {
      expect(testRatioDropReason(['--test-ratio-drop']), '');
      expect(testRatioDropReason(['--test-ratio-drop=']), '');
    });
  });

  group('the check', () {
    test('a ratio that holds or rises passes', () {
      expect(compare(metrics(), metrics()), isEmpty);
      expect(compare(metrics(), metrics(ratio: 2500)), isEmpty);
    });
    test('a fall fails and names the flag', () {
      final failures = compare(metrics(), metrics(ratio: 2100));
      expect(failures, hasLength(1));
      expect(
        failures.single,
        allOf(
          contains('test_per_lib_permille went from 2400 to 2100'),
          contains('--test-ratio-drop'),
        ),
      );
    });
    test('a declared fall passes', () {
      expect(
        compare(metrics(), metrics(ratio: 2100), testRatioDrop: 'a table'),
        isEmpty,
      );
    });
    test('an empty reason declares nothing', () {
      expect(
        compare(metrics(), metrics(ratio: 2100), testRatioDrop: ''),
        hasLength(1),
      );
    });
    test('the reason excuses the ratio alone', () {
      final worse = metrics(ratio: 2100)..['complexity_over_10'] = 41;
      expect(compare(metrics(), worse, testRatioDrop: 'a table'), [
        'complexity_over_10 went from 40 to 41',
      ]);
    });
    test('a baseline written with a reason reads as any other', () {
      final baseline = <String, Object?>{
        ...metrics(ratio: 2100),
        'test_per_lib_drop': 'from 2400 to 2100: a table',
      };
      expect(compare(baseline, metrics(ratio: 2100)), isEmpty);
      expect(compare(baseline, metrics(ratio: 2099)), hasLength(1));
    });
  });

  group('the baseline to write', () {
    test('with no fall it is the metrics, without a reason', () {
      expect(
        baselineToWrite(metrics(), metrics(ratio: 2500)),
        metrics(ratio: 2500),
      );
      expect(baselineToWrite(null, metrics()), metrics());
      // A reason nobody needed is not kept.
      expect(
        baselineToWrite(metrics(), metrics(), testRatioDrop: 'a table'),
        metrics(),
      );
    });
    test('a fall without a reason is refused', () {
      expect(
        () => baselineToWrite(metrics(), metrics(ratio: 2100)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('from 2400 to 2100'), contains('--test-ratio-drop')),
          ),
        ),
      );
      expect(
        () =>
            baselineToWrite(metrics(), metrics(ratio: 2100), testRatioDrop: ''),
        throwsStateError,
      );
    });
    test('a declared fall is written with its reason beside the ratio', () {
      final written = baselineToWrite(
        metrics(),
        metrics(ratio: 2100),
        testRatioDrop: 'a table',
      );
      expect(written['test_per_lib_permille'], 2100);
      expect(written['test_per_lib_drop'], 'from 2400 to 2100: a table');
      expect(written.keys.toList().sublist(0, 3), [
        'loc',
        'test_per_lib_permille',
        'test_per_lib_drop',
      ]);
    });
    test('the reason of an older fall does not stay', () {
      final previous = <String, Object?>{
        ...metrics(ratio: 2100),
        'test_per_lib_drop': 'from 2400 to 2100: a table',
      };
      expect(
        baselineToWrite(previous, metrics(ratio: 2100)),
        isNot(contains('test_per_lib_drop')),
      );
    });
  });
}
