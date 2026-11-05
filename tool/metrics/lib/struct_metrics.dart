// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// The layout of the client API structs the package reads, as written in
/// lib: each field of each `Struct` and `Union` of mpv_bindings.dart with
/// its native type, and the wasm32 table of web_layout.dart. A change shows
/// in the review together with the libmpv it follows.
List<String> structLayout(CompilationUnit Function(String) parse) {
  final out = <String>[];
  final bindings = parse('lib/src/mpv_bindings.dart');
  for (final d in bindings.declarations.whereType<ClassDeclaration>()) {
    final base = d.extendsClause?.superclass.name.lexeme;
    if (base != 'Struct' && base != 'Union') continue;
    final name = d.name.lexeme;
    var index = 0;
    for (final m in d.members.whereType<FieldDeclaration>()) {
      if (m.isStatic) continue;
      final native = m.metadata.map((a) => a.toSource()).join(' ');
      for (final v in m.fields.variables) {
        out.add(
          'ffi $name.${index++} ${v.name.lexeme}: '
          '${native.isEmpty ? '' : '$native '}${m.fields.type?.toSource()}',
        );
      }
    }
  }
  final web = parse('lib/src/backend/web/web_layout.dart');
  for (final d in web.declarations.whereType<TopLevelVariableDeclaration>()) {
    for (final v in d.variables.variables) {
      final name = v.name.lexeme;
      if (name != '_kLayout' && name != '_kEndFileReadError') continue;
      out.add('wasm32 $name = ${v.initializer?.toSource()}');
    }
  }
  return out;
}
