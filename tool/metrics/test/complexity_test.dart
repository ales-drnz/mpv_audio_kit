// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:mak_metrics/complexity.dart';
import 'package:test/test.dart';

Map<String, int> complexity(String source) {
  final visitor = ComplexityVisitor('a.dart');
  parseString(content: source).unit.accept(visitor);
  return visitor.results;
}

void main() {
  test('a function without branches is 1', () {
    expect(complexity('void f() {}'), {'a.dart|f': 1});
  });

  test('each decision adds 1', () {
    final r = complexity('''
int f(int a, int? b, List<int> l) {
  if (a > 0 && a < 9 || a == 20) return 1;
  for (final x in l) {}
  for (var i = 0; i < a; i++) {}
  while (a > 0) { a--; }
  do { a++; } while (a < 3);
  switch (a) { case 1: break; case 2: break; default: break; }
  try {} catch (_) {}
  final c = a > 1 ? 1 : 2;
  final d = b ?? 0;
  final e = [if (a > 0) 1, for (final y in l) y];
  final g = switch (a) { 1 || 2 => 0, _ => 1 };
  return c + d + e.length + g;
}
''');
    // 1, if, &&, ||, for, for, while, do, case, case, catch, ?:, ??,
    // collection if, collection for, two switch expression cases, ||.
    expect(r['a.dart|f'], 18);
  });

  test('?. and ??= count nothing', () {
    final r = complexity('void f(String? s, int? n) { s?.length; n ??= 1; }');
    expect(r['a.dart|f'], 1);
  });

  test('a closure counts apart from its function', () {
    final r = complexity('''
class C {
  void m(List<int> l) {
    if (l.isEmpty) return;
    l.forEach((x) { if (x > 0) print(x); });
    void local() { if (l.length > 1) {} }
  }
}
''');
    expect(r, {'a.dart|C.m': 2, 'a.dart|C.m#1': 2, 'a.dart|C.m>local': 2});
  });

  test('a field initializer counts when it branches', () {
    final r = complexity('''
class C {
  static final int a = 1;
  static final int b = a > 0 ? 1 : 2;
}
''');
    expect(r, {'a.dart|C.=b': 2});
  });
}
