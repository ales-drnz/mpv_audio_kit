// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';

/// The public API a library exports, one sorted line per declaration and
/// per public member: the declaration as written, bodies and comments left
/// out. The public members a public class takes from a private superclass
/// or mixin of the same library count as its own.
///
/// Read from the source alone, so it needs no resolution: it follows the
/// `export` directives with their `show` and `hide`, and the `part` files.
List<String> apiSurface(
  String library,
  CompilationUnit Function(String) parse,
) {
  final lines = <String>{};
  _export(library, null, const {}, parse, lines, {});
  return lines.toList()..sort();
}

void _export(
  String path,
  Set<String>? show,
  Set<String> hide,
  CompilationUnit Function(String) parse,
  Set<String> out,
  Set<String> seen,
) {
  bool visible(String name) =>
      !name.startsWith('_') &&
      (show == null || show.contains(name)) &&
      !hide.contains(name);

  final units = _libraryUnits(path, parse);
  final declarations = <String, CompilationUnitMember>{
    for (final u in units)
      for (final d in u.declarations) ...{for (final n in _names(d)) n: d},
  };

  for (final MapEntry(key: name, value: d) in declarations.entries) {
    if (!visible(name)) continue;
    final key = '$path#$name';
    if (!seen.add(key)) continue;
    for (final l in _describe(name, d, declarations)) {
      out.add(l);
    }
  }

  for (final directive in units.first.directives.whereType<ExportDirective>()) {
    final uri = directive.uri.stringValue!;
    if (uri.startsWith('package:') || uri.startsWith('dart:')) continue;
    Set<String>? s;
    final h = <String>{...hide};
    for (final c in directive.combinators) {
      final names = c is ShowCombinator
          ? c.shownNames.map((n) => n.name).toSet()
          : (c as HideCombinator).hiddenNames.map((n) => n.name).toSet();
      if (c is ShowCombinator) {
        s = s == null ? names : s.intersection(names);
      } else {
        h.addAll(names);
      }
    }
    if (show != null) s = s == null ? {...show} : s.intersection(show);
    _export(
      File(path).parent.uri.resolve(uri).toFilePath(),
      s,
      h,
      parse,
      out,
      seen,
    );
  }
}

List<CompilationUnit> _libraryUnits(
  String path,
  CompilationUnit Function(String) parse,
) {
  final main = parse(path);
  final base = File(path).parent.uri;
  return [
    main,
    for (final p in main.directives.whereType<PartDirective>())
      parse(_relative(base.resolve(p.uri.stringValue!).toFilePath())),
  ];
}

String _relative(String path) {
  final root = '${Directory.current.path}/';
  return path.startsWith(root) ? path.substring(root.length) : path;
}

List<String> _names(CompilationUnitMember d) => switch (d) {
  NamedCompilationUnitMember(:final name) => [name.lexeme],
  TopLevelVariableDeclaration(:final variables) => [
    for (final v in variables.variables) v.name.lexeme,
  ],
  ExtensionDeclaration(:final name?) => [name.lexeme],
  _ => const [],
};

List<String> _describe(
  String name,
  CompilationUnitMember d,
  Map<String, CompilationUnitMember> library,
) {
  if (d is TopLevelVariableDeclaration) {
    final v = d.variables;
    return ['$name: ${v.keyword?.lexeme ?? 'var'} ${v.type ?? ''} $name'];
  }
  if (d is FunctionDeclaration) {
    return ['$name: ${_strip(d.toSource(), d.functionExpression.body)}'];
  }
  if (d is GenericTypeAlias || d is FunctionTypeAlias) {
    return ['$name: ${d.toSource()}'];
  }
  final header = _header(d);
  final members = <String>{};
  _members(d, library, members, {});
  if (d is EnumDeclaration) {
    for (final c in d.constants) {
      members.add('${c.name.lexeme}${c.arguments?.toSource() ?? ''}');
    }
  }
  return ['$name: $header', for (final m in members) '$name.$m'];
}

/// The declaration line of a type: everything before its body.
String _header(CompilationUnitMember d) {
  final source = d.toSource();
  final brace = source.indexOf('{');
  final semicolon = source.indexOf(';');
  final end = brace < 0
      ? semicolon
      : semicolon < 0
      ? brace
      : brace < semicolon
      ? brace
      : semicolon;
  return (end < 0 ? source : source.substring(0, end)).trim();
}

void _members(
  CompilationUnitMember d,
  Map<String, CompilationUnitMember> library,
  Set<String> out,
  Set<String> seen,
) {
  final List<ClassMember> members;
  final supers = <String>[];
  switch (d) {
    case ClassDeclaration():
      members = d.members;
      final e = d.extendsClause?.superclass.name.lexeme;
      if (e != null) supers.add(e);
      supers.addAll(d.withClause?.mixinTypes.map((t) => t.name.lexeme) ?? []);
    case MixinDeclaration():
      members = d.members;
    case EnumDeclaration():
      members = d.members;
      supers.addAll(d.withClause?.mixinTypes.map((t) => t.name.lexeme) ?? []);
    case ExtensionDeclaration():
      members = d.members;
    case ExtensionTypeDeclaration():
      members = d.members;
    default:
      return;
  }
  for (final m in members) {
    final line = _member(m);
    if (line != null) out.add(line);
  }
  for (final s in supers) {
    final sd = library[s];
    if (s.startsWith('_') && sd != null && seen.add(s)) {
      _members(sd, library, out, seen);
    }
  }
}

String? _member(ClassMember m) {
  switch (m) {
    case MethodDeclaration():
      if (m.name.lexeme.startsWith('_')) return null;
      return _strip(m.toSource(), m.body);
    case ConstructorDeclaration():
      if (m.name?.lexeme.startsWith('_') ?? false) return null;
      final params = m.parameters.toSource();
      final kind = [
        if (m.externalKeyword != null) 'external',
        if (m.constKeyword != null) 'const',
        if (m.factoryKeyword != null) 'factory',
      ].join(' ');
      return 'new${m.name == null ? '' : ' ${m.name!.lexeme}'} $kind $params'
          .trim();
    case FieldDeclaration():
      final v = m.fields;
      final names = [
        for (final x in v.variables)
          if (!x.name.lexeme.startsWith('_')) x.name.lexeme,
      ];
      if (names.isEmpty) return null;
      final keyword = [
        if (m.isStatic) 'static',
        if (v.isLate) 'late',
        v.keyword?.lexeme ?? 'var',
      ].join(' ');
      final constValue = v.isConst
          ? ' = ${v.variables.map((x) => x.initializer?.toSource()).join(', ')}'
          : '';
      return '$keyword ${v.type?.toSource() ?? ''} ${names.join(', ')}$constValue';
  }
}

String _strip(String source, FunctionBody body) {
  final b = body.toSource();
  final i = source.lastIndexOf(b);
  final head = i < 0 ? source : source.substring(0, i);
  return head.trim();
}
