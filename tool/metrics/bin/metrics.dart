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
  final api = apiSurface('lib/mpv_audio_kit.dart', parse);
  final structs = structLayout(parse);

  final current = <String, Object>{
    'loc': loc,
    'complexity_over_15': over10.values.where((c) => c > 15).length,
    'complexity_over_10': over10.length,
    'player_base_fields': playerBase['fields']!,
    'player_base_non_final': playerBase['non_final']!,
    'player_base_abstract': playerBase['abstract']!,
    'functions_over_10': over10,
  };

  if (write) {
    File(baselinePath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(current)}\n',
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
    ...compare(baseline, current),
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
    'complexity_over_15',
    'complexity_over_10',
    'player_base_fields',
    'player_base_non_final',
    'player_base_abstract',
  ]) {
    stdout.writeln('$k: ${m[k]}');
  }
}

/// What got worse from [baseline] to [current]: a count that grew, a
/// function over 10 that grew, or a function new over 10.
List<String> compare(
  Map<String, Object?> baseline,
  Map<String, Object> current,
) {
  final failures = <String>[];
  for (final k in [
    'loc',
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
