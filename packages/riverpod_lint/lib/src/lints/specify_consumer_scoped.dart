import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:riverpod_analyzer_utils/riverpod_analyzer_utils.dart';

import '../riverpod_custom_lint.dart';

const _scopesChecker = TypeChecker.fromName(
  'Scopes',
  packageName: 'riverpod_annotation',
);

class SpecifyConsumerScopes extends RiverpodLintRule {
  const SpecifyConsumerScopes() : super(code: _code);

  static const _code = LintCode(
    name: 'specify_consumer_scopes',
    problemMessage:
        'Widgets using scoped providers should specify a @Scopes annotation.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.endsWith('specify_consumer_scopes.dart')) {
      return;
    }

    riverpodRegistry(context).addConsumerWidgetDeclaration((node) {
      final visitor = _WidgetRefVisitor();
      node.accept(visitor);

      final scopes = _scopesChecker
          .firstAnnotationOfExact(node.node.declaredElement!)
          ?.getField('scopes')
          ?.toListValue();
    });
  }
}

class _WidgetRefVisitor extends RecursiveRiverpodAstVisitor {
  @override
  void visitWidgetRefListenInvocation(WidgetRefListenInvocation invocation) {}

  @override
  void visitWidgetRefListenManualInvocation(
    WidgetRefListenManualInvocation invocation,
  ) {}

  @override
  void visitWidgetRefReadInvocation(WidgetRefReadInvocation invocation) {}

  @override
  void visitWidgetRefWatchInvocation(WidgetRefWatchInvocation invocation) {}
}

extension on AstNode {
  Iterable<AstNode> get ancestors sync* {
    var parent = this.parent;
    while (parent != null) {
      yield parent;
      parent = parent.parent;
    }
  }
}
