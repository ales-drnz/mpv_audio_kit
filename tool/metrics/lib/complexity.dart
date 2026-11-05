// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The cyclomatic complexity of every function of a file: 1, plus one for
/// each `if` (statement and collection element), `for`, `while`, `do`,
/// `case` (statement, pattern and switch expression), `catch`, `?:`, `&&`,
/// `||` and `??`, in expressions and in patterns. `?.` and `??=` count
/// nothing. A closure or a local function is a function of its own, named
/// after the one it sits in, and its branches leave that one alone. The
/// initializer of a field or of a top-level variable counts as a function
/// when it branches.
///
/// The names hold the file and the class, not the line, so moving code
/// within a file keeps them: `lib/a.dart|Class.method`, `...|Class.method#1`
/// for its first closure.
class ComplexityVisitor extends RecursiveAstVisitor<void> {
  /// A visitor for the file at [path].
  ComplexityVisitor(this.path);

  /// The file, first part of every name.
  final String path;

  /// The complexity of each function, by name.
  final Map<String, int> results = {};

  final List<_Unit> _stack = [];
  String? _container;

  void _run(String name, AstNode node, void Function() visit) {
    var unique = name;
    for (var i = 2; results.containsKey('$path|$unique'); i++) {
      unique = '$name~$i';
    }
    final unit = _Unit(unique);
    _stack.add(unit);
    visit();
    _stack.removeLast();
    results['$path|$unique'] = unit.complexity;
  }

  void _add() {
    if (_stack.isNotEmpty) _stack.last.complexity++;
  }

  String _member(String name) =>
      _container == null ? name : '$_container.$name';

  void _inContainer(String name, void Function() visit) {
    final before = _container;
    _container = name;
    visit();
    _container = before;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _inContainer(node.name.lexeme, () => super.visitClassDeclaration(node));

  @override
  void visitMixinDeclaration(MixinDeclaration node) =>
      _inContainer(node.name.lexeme, () => super.visitMixinDeclaration(node));

  @override
  void visitEnumDeclaration(EnumDeclaration node) =>
      _inContainer(node.name.lexeme, () => super.visitEnumDeclaration(node));

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) => _inContainer(
    node.name?.lexeme ?? '<extension>',
    () => super.visitExtensionDeclaration(node),
  );

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) =>
      _inContainer(
        node.name.lexeme,
        () => super.visitExtensionTypeDeclaration(node),
      );

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final kind = node.isGetter
        ? 'get '
        : node.isSetter
        ? 'set '
        : '';
    _run(
      _member('$kind${node.name.lexeme}'),
      node,
      () => super.visitMethodDeclaration(node),
    );
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final named = node.name?.lexeme;
    _run(
      _member(named == null ? '<new>' : 'new $named'),
      node,
      () => super.visitConstructorDeclaration(node),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final name = node.name.lexeme;
    _run(
      _stack.isEmpty ? _member(name) : '${_stack.last.name}>$name',
      node,
      () => super.visitFunctionDeclaration(node),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      super.visitFunctionExpression(node);
      return;
    }
    final outer = _stack.isEmpty ? _member('<top>') : _stack.last.name;
    final index = _stack.isEmpty ? 1 : ++_stack.last.closures;
    _run('$outer#$index', node, () => super.visitFunctionExpression(node));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_stack.isNotEmpty || node.initializer == null) {
      super.visitVariableDeclaration(node);
      return;
    }
    // A field or top-level initializer: kept only when it branches.
    final name = _member('=${node.name.lexeme}');
    _run(name, node, () => super.visitVariableDeclaration(node));
    if (results['$path|$name'] == 1) results.remove('$path|$name');
  }

  @override
  void visitIfStatement(IfStatement node) {
    _add();
    super.visitIfStatement(node);
  }

  @override
  void visitIfElement(IfElement node) {
    _add();
    super.visitIfElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _add();
    super.visitForStatement(node);
  }

  @override
  void visitForElement(ForElement node) {
    _add();
    super.visitForElement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _add();
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _add();
    super.visitDoStatement(node);
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    _add();
    super.visitSwitchCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    _add();
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    _add();
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitCatchClause(CatchClause node) {
    _add();
    super.visitCatchClause(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _add();
    super.visitConditionalExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final op = node.operator.type;
    if (op == TokenType.AMPERSAND_AMPERSAND ||
        op == TokenType.BAR_BAR ||
        op == TokenType.QUESTION_QUESTION) {
      _add();
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitLogicalAndPattern(LogicalAndPattern node) {
    _add();
    super.visitLogicalAndPattern(node);
  }

  @override
  void visitLogicalOrPattern(LogicalOrPattern node) {
    _add();
    super.visitLogicalOrPattern(node);
  }
}

class _Unit {
  _Unit(this.name);

  final String name;
  int complexity = 1;
  int closures = 0;
}
