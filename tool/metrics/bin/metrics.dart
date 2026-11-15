// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The metrics the CI ratchet holds (README.md next to this folder).
//
//   dart tool/metrics/bin/metrics.dart            checks against the baseline
//   dart tool/metrics/bin/metrics.dart --write    writes the baseline
//
// Run from the root of the package. The check fails when a metric gets
// worse than the baseline; a change that makes one worse on purpose writes
// the baseline again in the same commit, where the review sees it.
//
// The tests per line of lib fall when tests are cleaned up (duplicates
// removed, a file of cases turned into a table), which is no loss. Such a
// fall is declared, with its reason:
//
//   dart tool/metrics/bin/metrics.dart --write --test-ratio-drop="<why>"
//
// writes the baseline with the reason in it (test_per_lib_drop), and
// without the flag --write refuses to lower the ratio. The check takes the
// same flag, and then warns with the reason instead of failing.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';

import 'package:mak_metrics/api_surface.dart';
import 'package:mak_metrics/complexity.dart';
import 'package:mak_metrics/struct_metrics.dart';

const baselinePath = 'tool/metrics/baseline.json';
const apiPath = 'tool/metrics/api_surface.txt';
const structsPath = 'tool/metrics/struct_layout.txt';

/// The flag that declares a fall of the tests per line of lib.
const testRatioDropFlag = '--test-ratio-drop';

/// The reason [args] give for a fall of the tests per line of lib: null
/// without the flag, and empty when the flag says nothing.
String? testRatioDropReason(List<String> args) {
  for (final arg in args) {
    if (arg == testRatioDropFlag) return '';
    if (arg.startsWith('$testRatioDropFlag=')) {
      return arg.substring(testRatioDropFlag.length + 1).trim();
    }
  }
  return null;
}

/// Files of lib the metrics leave out: generated code and the license texts.
bool excluded(String path) =>
    path.startsWith('lib/src/generated/') ||
    path == 'lib/src/internals/libmpv_licenses.dart';

CompilationUnit parse(String path) => parseFile(
  path: File(path).absolute.path,
  featureSet: FeatureSet.latestLanguageVersion(),
).unit;

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final dropReason = testRatioDropReason(args);
  if (dropReason != null && dropReason.isEmpty) {
    stderr.writeln(
      'metrics: $testRatioDropFlag needs its reason: '
      '$testRatioDropFlag="<why the ratio falls>"',
    );
    exit(2);
  }
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => p.endsWith('.dart') && !excluded(p))
          .toList()
        ..sort();

  final units = <String, CompilationUnit>{
    for (final path in files) path: parse(path),
  };

  var loc = 0;
  final complexity = <String, int>{};
  Map<String, int>? playerBase;
  for (final MapEntry(key: path, value: unit) in units.entries) {
    loc += codeLines(unit);
    final visitor = ComplexityVisitor(path);
    unit.accept(visitor);
    for (final MapEntry(:key, :value) in visitor.results.entries) {
      complexity[key] = value;
    }
    playerBase ??= playerBaseMetrics(unit);
  }
  if (playerBase == null) {
    stderr.writeln('metrics: class _PlayerBase not found');
    exit(2);
  }

  final over10 = Map.fromEntries(
    complexity.entries.where((e) => e.value > 10).toList()
      ..sort((a, b) => a.key.compareTo(b.key)),
  );
  // The tests against lib: their lines of code per line of lib, in
  // thousandths. Generated tests left out, as generated lib is.
  var testLoc = 0;
  for (final f in Directory('test').listSync(recursive: true)) {
    final path = f.path.replaceAll(r'\', '/');
    if (f is! File || !path.endsWith('.dart')) continue;
    if (path.startsWith('test/generated/')) continue;
    testLoc += codeLines(parse(path));
  }
  final api = apiSurface('lib/mpv_audio_kit.dart', parse);
  final structs = structLayout(parse);

  final current = <String, Object>{
    'loc': loc,
    'test_per_lib_permille': (testLoc * 1000) ~/ loc,
    'complexity_over_15': over10.values.where((c) => c > 15).length,
    'complexity_over_10': over10.length,
    'player_base_fields': playerBase['fields']!,
    'player_base_non_final': playerBase['non_final']!,
    'player_base_abstract': playerBase['abstract']!,
    'functions_over_10': over10,
  };

  if (write) {
    final Map<String, Object> written;
    try {
      written = baselineToWrite(
        File(baselinePath).existsSync()
            ? jsonDecode(File(baselinePath).readAsStringSync())
                  as Map<String, Object?>
            : null,
        current,
        testRatioDrop: dropReason,
      );
    } on StateError catch (e) {
      stderr.writeln('metrics: ${e.message}');
      exit(1);
    }
    File(baselinePath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(written)}\n',
    );
    File(apiPath).writeAsStringSync('${api.join('\n')}\n');
    File(structsPath).writeAsStringSync('${structs.join('\n')}\n');
    stdout.writeln('metrics: baseline written');
    printSummary(current);
    return;
  }

  final baseline =
      jsonDecode(File(baselinePath).readAsStringSync()) as Map<String, Object?>;
  final failures = <String>[
    ...compare(baseline, current, testRatioDrop: dropReason),
    ...compareLines('API', File(apiPath).readAsLinesSync(), api),
    ...compareLines(
      'struct layout',
      File(structsPath).readAsLinesSync(),
      structs,
    ),
  ];
  printSummary(current);
  if (failures.isEmpty) {
    stdout.writeln('metrics: no metric is worse than the baseline');
    return;
  }
  for (final f in failures) {
    stdout.writeln('::error title=metrics::$f');
  }
  stdout.writeln(
    'metrics: ${failures.length} worse than the baseline. A change that '
    'means it writes the baseline again with --write in the same commit.',
  );
  exit(1);
}

void printSummary(Map<String, Object> m) {
  for (final k in [
    'loc',
    'test_per_lib_permille',
    'complexity_over_15',
    'complexity_over_10',
    'player_base_fields',
    'player_base_non_final',
    'player_base_abstract',
  ]) {
    stdout.writeln('$k: ${m[k]}');
  }
}

/// The baseline to write for [current] over the [previous] one, if any.
///
/// A fall of the tests per line of lib needs [testRatioDrop], its reason,
/// which the baseline then keeps under `test_per_lib_drop` with the two
/// numbers, so the review reads it in the diff. Throws a [StateError]
/// without one. A baseline written with no fall carries no reason.
Map<String, Object> baselineToWrite(
  Map<String, Object?>? previous,
  Map<String, Object> current, {
  String? testRatioDrop,
}) {
  final was = previous?['test_per_lib_permille'] as int? ?? 0;
  final now = current['test_per_lib_permille']! as int;
  if (now >= was) return current;
  if (testRatioDrop == null || testRatioDrop.isEmpty) {
    throw StateError(
      'test_per_lib_permille would go from $was to $now. If the tests were '
      'cleaned up and nothing is checked less, write the baseline with '
      '$testRatioDropFlag="<why>"',
    );
  }
  return {
    for (final MapEntry(:key, :value) in current.entries) ...{
      key: value,
      if (key == 'test_per_lib_permille')
        'test_per_lib_drop': 'from $was to $now: $testRatioDrop',
    },
  };
}

/// What got worse from [baseline] to [current]: a count that grew, a
/// function over 10 that grew, or a function new over 10.
///
/// A fall of the tests per line of lib is a failure unless
/// [testRatioDrop] gives its reason: it is then a warning with the reason.
List<String> compare(
  Map<String, Object?> baseline,
  Map<String, Object> current, {
  String? testRatioDrop,
}) {
  final failures = <String>[];
  // lib may grow with what it does: a warning past 300 lines, which the
  // body of the commit explains.
  final locWas = baseline['loc'] as int;
  final locNow = current['loc'] as int;
  if (locNow > locWas + 300) {
    stdout.writeln(
      '::warning title=metrics::lib grew by ${locNow - locWas} lines: '
      'say why in the commit',
    );
  }
  final ratioWas = baseline['test_per_lib_permille'] as int? ?? 0;
  final ratioNow = current['test_per_lib_permille'] as int;
  if (ratioNow < ratioWas) {
    if (testRatioDrop != null && testRatioDrop.isNotEmpty) {
      stdout.writeln(
        '::warning title=metrics::test_per_lib_permille went from $ratioWas '
        'to $ratioNow, declared: $testRatioDrop',
      );
    } else {
      failures.add(
        'test_per_lib_permille went from $ratioWas to $ratioNow. If the '
        'tests were cleaned up and nothing is checked less, declare it: '
        '--write $testRatioDropFlag="<why>"',
      );
    }
  }
  for (final k in [
    'complexity_over_15',
    'complexity_over_10',
    'player_base_fields',
    'player_base_non_final',
    'player_base_abstract',
  ]) {
    final was = baseline[k] as int;
    final now = current[k] as int;
    if (now > was) failures.add('$k went from $was to $now');
  }
  final was = (baseline['functions_over_10'] as Map).cast<String, int>();
  final now = current['functions_over_10'] as Map<String, int>;
  for (final MapEntry(:key, :value) in now.entries) {
    final before = was[key];
    if (before == null) {
      failures.add('$key is new over 10, at $value');
    } else if (value > before) {
      failures.add('$key went from $before to $value');
    }
  }
  return failures;
}

/// The lines of [now] missing from [was] and the other way round. Any
/// change fails: an addition writes the baseline again too, so the review
/// sees the API or the layout grow.
List<String> compareLines(String what, List<String> was, List<String> now) {
  final before = was.where((l) => l.isNotEmpty).toSet();
  final after = now.toSet();
  return [
    for (final l in before.difference(after)) '$what lost or changed: $l',
    for (final l in after.difference(before)) '$what gained: $l',
  ];
}

/// The lines of [unit] that hold code: every line a token covers, so blank
/// lines and lines of comment alone are left out.
int codeLines(CompilationUnit unit) {
  final LineInfo info = unit.lineInfo;
  final lines = <int>{};
  Token? t = unit.beginToken;
  while (t != null && !t.isEof) {
    final first = info.getLocation(t.offset).lineNumber;
    final last = info.getLocation(t.end).lineNumber;
    for (var l = first; l <= last; l++) {
      lines.add(l);
    }
    if (t.next == t) break;
    t = t.next;
  }
  return lines.length;
}

/// The fields of `_PlayerBase` (static ones left out), the ones not final,
/// and its abstract members (a getter and its setter count as two).
Map<String, int>? playerBaseMetrics(CompilationUnit unit) {
  for (final d in unit.declarations) {
    if (d is! ClassDeclaration || nameOf(d) != '_PlayerBase') continue;
    var fields = 0, nonFinal = 0, abstract = 0;
    for (final m in d.members) {
      if (m is FieldDeclaration && !m.isStatic) {
        final n = m.fields.variables.length;
        fields += n;
        if (!m.fields.isFinal && !m.fields.isConst) nonFinal += n;
      } else if (m is MethodDeclaration && m.isAbstract) {
        abstract++;
      }
    }
    return {'fields': fields, 'non_final': nonFinal, 'abstract': abstract};
  }
  return null;
}

/// The name of a class.
String nameOf(ClassDeclaration d) => d.name.lexeme;
