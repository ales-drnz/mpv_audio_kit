// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Generates the copyWith, == and hashCode of the data classes of the
// package (README.md next to this folder), as a mixin in a part file of
// lib/src/generated. Run from the root of the package:
//
//   dart tool/data_classes/bin/data_classes.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A class to generate for: its library, its name, and the doc comment of
/// its copyWith.
typedef DataClass = ({String library, String name, String copyWithDoc});

const List<DataClass> classes = [
  (
    library: 'lib/src/player/state/playback_state.dart',
    name: 'PlaybackState',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/player/state/network_state.dart',
    name: 'NetworkState',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/player/state/file_state.dart',
    name: 'FileState',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/player/state/output_state.dart',
    name: 'OutputState',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/player/state/player_settings.dart',
    name: 'PlayerSettings',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/player/state/library_versions.dart',
    name: 'LibraryVersions',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
  (
    library: 'lib/src/models/mpv_track.dart',
    name: 'MpvTrack',
    copyWithDoc:
        '/// Returns a copy with the given fields replaced. Pass `null` for a\n'
        '/// nullable field to clear it; omitted fields keep their current '
        'value.',
  ),
];

/// A class made of groups, each a data class of [classes]: its fields are
/// the groups, and its copyWith also takes every field of every group, so
/// a caller can set one value without naming its group. Each flat field
/// has a deprecated getter that reads it from its group, but those of
/// [groupOnly], added after the groups, which never were flat.
typedef CompositeClass = ({
  String library,
  String name,
  String copyWithDoc,
  String deprecation,
  Set<String> groupOnly,
});

const List<CompositeClass> composites = [
  (
    library: 'lib/src/player/player_state.dart',
    name: 'PlayerState',
    copyWithDoc:
        '/// Returns a copy with the given groups or fields replaced. A field\n'
        '/// replaces its value in its group, after a group given whole. Pass\n'
        '/// `null` for a nullable field to clear it; omitted fields keep their\n'
        '/// current value.',
    deprecation: 'the flat fields go in 0.8.0',
    groupOnly: {'durationEstimated'},
  ),
];

/// A field of a data class, in the order of its constructor.
typedef Field = ({String name, String type, bool nullable, String kind});

Future<void> main() async {
  final written = <String>[];
  for (final c in classes) {
    final out = 'lib/src/generated/${_snake(c.name)}_data.dart';
    File(out).writeAsStringSync(generate(c, fieldsOf(c)));
    written.add(out);
  }
  for (final c in composites) {
    final out = 'lib/src/generated/${_snake(c.name)}_data.dart';
    final groups = fieldsOf((
      library: c.library,
      name: c.name,
      copyWithDoc: '',
    ));
    final flat = {
      for (final g in groups)
        g.name: fieldsOf(classes.singleWhere((d) => d.name == g.type)),
    };
    File(out).writeAsStringSync(generateComposite(c, groups, flat));
    written.add(out);
  }
  final format = await Process.run('dart', ['format', ...written]);
  if (format.exitCode != 0) {
    stderr.writeln(format.stderr);
    exit(1);
  }
  stdout.writeln('data_classes: ${written.join(', ')}');
}

/// The fields of [c], in the order of the parameters of its unnamed
/// constructor, with their declared types.
List<Field> fieldsOf(DataClass c) {
  final unit = parseFile(
    path: File(c.library).absolute.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;
  final cls = unit.declarations.whereType<ClassDeclaration>().singleWhere(
    (d) => d.name.lexeme == c.name,
  );
  final types = <String, String>{
    for (final f in cls.members.whereType<FieldDeclaration>())
      if (!f.isStatic)
        for (final v in f.fields.variables)
          v.name.lexeme: f.fields.type!.toSource(),
  };
  final ctor = cls.members.whereType<ConstructorDeclaration>().singleWhere(
    (k) => k.name == null,
  );
  return [
    for (final p in ctor.parameters.parameters)
      _field(p.name!.lexeme, types[p.name!.lexeme]!),
  ];
}

Field _field(String name, String type) {
  final nullable = type.endsWith('?');
  final base = nullable ? type.substring(0, type.length - 1) : type;
  final kind = base.startsWith('List<')
      ? 'list'
      : base.startsWith('Map<')
      ? 'map'
      : base.startsWith('Set<')
      ? 'set'
      : 'value';
  return (name: name, type: type, nullable: nullable, kind: kind);
}

/// The part file of [c]: a mixin the class applies, with copyWith, == and
/// hashCode over [fields]. A nullable field takes the `unset` sentinel in
/// copyWith, so `null` clears it. Lists compare element by element, maps
/// by entry, sets by membership; their hashes are `Object.hashAll` of the
/// list, and `Object.hashAllUnordered` of the entries or elements.
String generate(DataClass c, List<Field> fields) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/data_classes from ${c.library}.')
    ..writeln(
      '// Do not edit: run dart tool/data_classes/bin/data_classes.dart.',
    )
    ..writeln()
    ..writeln("part of '../${c.library.substring('lib/src/'.length)}';")
    ..writeln()
    ..writeln('/// The copyWith, == and hashCode of [${c.name}].')
    ..writeln('mixin _\$${c.name} {')
    ..writeln('  ${c.name} get _self => this as ${c.name};')
    ..writeln()
    ..writeln('  ${c.copyWithDoc.replaceAll('\n', '\n  ')}')
    ..writeln('  ${c.name} copyWith({');
  for (final f in fields) {
    b.writeln(
      f.nullable
          ? '    Object? ${f.name} = unset,'
          : '    ${f.type}? ${f.name},',
    );
  }
  b
    ..writeln('  }) => ${c.name}(')
    ..writeAll([
      for (final f in fields)
        f.nullable
            ? '    ${f.name}: identical(${f.name}, unset) '
                  '? _self.${f.name} : ${f.name} as ${f.type},\n'
            : '    ${f.name}: ${f.name} ?? _self.${f.name},\n',
    ])
    ..writeln('  );')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  bool operator ==(Object other) =>')
    ..writeln('      identical(this, other) ||')
    ..writeln('      (other is ${c.name} &&')
    ..writeln(
      [
        for (final f in fields)
          switch (f.kind) {
            'list' => '          _dataListEq(_self.${f.name}, other.${f.name})',
            'map' => '          _dataMapEq(_self.${f.name}, other.${f.name})',
            'set' => '          _dataSetEq(_self.${f.name}, other.${f.name})',
            _ => '          other.${f.name} == _self.${f.name}',
          },
      ].join(' &&\n'),
    )
    ..writeln('      );')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  int get hashCode => Object.hashAll([')
    ..writeAll([
      for (final f in fields)
        switch (f.kind) {
          'list' => '    Object.hashAll(_self.${f.name}),\n',
          'map' =>
            '    Object.hashAllUnordered(_self.${f.name}.entries'
                '.map((e) => Object.hash(e.key, e.value))),\n',
          'set' => '    Object.hashAllUnordered(_self.${f.name}),\n',
          _ => '    _self.${f.name},\n',
        },
    ])
    ..writeln('  ]);')
    ..writeln('}')
    ..writeln()
    ..write(_helpers(fields));
  return b.toString();
}

/// The part file of the composite [c]: copyWith over its [groups] and
/// every [flat] field of each group, == and hashCode over the groups, and a
/// deprecated getter for each flat field. A group none of whose fields is
/// given keeps its instance.
String generateComposite(
  CompositeClass c,
  List<Field> groups,
  Map<String, List<Field>> flat,
) {
  final b = StringBuffer()
    ..writeln('// GENERATED by tool/data_classes from ${c.library}.')
    ..writeln(
      '// Do not edit: run dart tool/data_classes/bin/data_classes.dart.',
    )
    ..writeln()
    ..writeln("part of '../${c.library.substring('lib/src/'.length)}';")
    ..writeln()
    ..writeln(
      '/// The copyWith, == and hashCode of [${c.name}], and its flat fields.',
    )
    ..writeln('mixin _\$${c.name} {')
    ..writeln('  ${c.name} get _self => this as ${c.name};')
    ..writeln()
    ..writeln('  ${c.copyWithDoc.replaceAll('\n', '\n  ')}')
    ..writeln('  ${c.name} copyWith({');
  for (final g in groups) {
    b.writeln('    ${g.type}? ${g.name},');
  }
  for (final g in groups) {
    for (final f in flat[g.name]!) {
      b.writeln(
        f.nullable
            ? '    Object? ${f.name} = unset,'
            : '    ${f.type}? ${f.name},',
      );
    }
  }
  b.writeln('  }) => ${c.name}(');
  for (final g in groups) {
    final fields = flat[g.name]!;
    final none = fields
        .map(
          (f) =>
              f.nullable ? 'identical(${f.name}, unset)' : '${f.name} == null',
        )
        .join(' && ');
    final base = '(${g.name} ?? _self.${g.name})';
    final args = fields.map((f) => '${f.name}: ${f.name}').join(', ');
    b.writeln('    ${g.name}: $none ? $base : $base.copyWith($args),');
  }
  b
    ..writeln('  );')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  bool operator ==(Object other) =>')
    ..writeln('      identical(this, other) ||')
    ..writeln('      (other is ${c.name} &&')
    ..writeln(
      [
        for (final g in groups) '          other.${g.name} == _self.${g.name}',
      ].join(' &&\n'),
    )
    ..writeln('      );')
    ..writeln()
    ..writeln('  @override')
    ..writeln(
      '  int get hashCode => Object.hash('
      '${groups.map((g) => '_self.${g.name}').join(', ')});',
    );
  for (final g in groups) {
    for (final f in flat[g.name]!) {
      if (c.groupOnly.contains(f.name)) continue;
      b
        ..writeln()
        ..writeln(
          '  /// Deprecated: [${g.type}.${f.name}] of [${c.name}.${g.name}].',
        )
        ..writeln("  @Deprecated('Use ${g.name}.${f.name}; ${c.deprecation}.')")
        ..writeln('  ${f.type} get ${f.name} => _self.${g.name}.${f.name};');
    }
  }
  b.writeln('}');
  return b.toString();
}

/// The equality helpers the fields of a class need, private to its
/// library.
String _helpers(List<Field> fields) {
  final kinds = fields.map((f) => f.kind).toSet();
  final parts = <String>[
    if (kinds.contains('list')) _listEq,
    if (kinds.contains('map')) _mapEq,
    if (kinds.contains('set')) _setEq,
  ];
  return '${parts.join('\n')}\n';
}

const _listEq = '''
bool _dataListEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}''';

const _mapEq = '''
bool _dataMapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}''';

const _setEq = '''
bool _dataSetEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}''';

String _snake(String name) => name
    .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
    .substring(1);
