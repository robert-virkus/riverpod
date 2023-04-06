import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:riverpod/riverpod.dart';
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
      final scopeAnnotation = ScopesAnnotationElement.parse(
        node.node.declaredElement!,
      );

      final currentScopes = {
        ...?scopeAnnotation?.providers.map((e) => e.element),
      };

      print('');
      print('Node: ${node.node.name} (${node.node.runtimeType})');
      print('  with scopes ${scopeAnnotation?.providers.map((e) => e.name)}');
      final visitIdentifier = _VisitIdentifier();
      node.node.accept(visitIdentifier);

      final refVisitor = _WidgetRefVisitor();
      node.accept(refVisitor);

      final usedScopes = <Element>{
        ...visitIdentifier._currentScopes.map((e) => e.element),
        ...refVisitor.scopedProviderListenables
            .map((e) => e.providerElement?.element)
            .whereNotNull(),
      };

      print('  with uses ${usedScopes.map((e) => e.name)}');

      for (final currentScope in currentScopes) {
        if (!usedScopes.contains(currentScope)) {
          print('Specified scope $currentScope but unused');
          reporter.reportErrorForToken(
            _code,
            node.node.name,
          );
        }
      }

      for (final usedScope in usedScopes) {
        if (!currentScopes.contains(usedScope)) {
          print('Used $usedScope but not specified in @Scopes');
          reporter.reportErrorForToken(
            _code,
            node.node.name,
          );
        }
      }
    });
  }
}

class ScopesAnnotationElement {
  ScopesAnnotationElement._(this.providers);

  static ScopesAnnotationElement? parse(
    Element element,
  ) {
    final annotation = _scopesChecker.firstAnnotationOfExact(element);
    if (annotation == null) {
      return null;
    }

    final providers = annotation.getField('scopes')?.toListValue();
    if (providers == null) {
      return null;
    }

    return ScopesAnnotationElement._(
      providers
          .map(
            (e) {
              final type = e.toTypeValue();
              if (type != null) {
                return StatefulProviderDeclarationElement.parse(
                  type.element! as ClassElement,
                  annotation: null,
                );
              }

              final function = e.toFunctionValue();
              if (function != null) {
                return StatelessProviderDeclarationElement.parse(
                  function,
                  annotation: null,
                );
              }

              // TODO handle unknown values
            },
          )
          .whereNotNull()
          .toList(),
    );
  }

  final List<GeneratorProviderDeclarationElement> providers;
}

class _ScopedInstanceCreation {
  final InstanceCreationExpression node;
  final List<ProviderListenableExpression> listenables;

  _ScopedInstanceCreation(this.node, this.listenables);
}

class _VisitIdentifier extends RecursiveAstVisitor {
  List<GeneratorProviderDeclarationElement> _currentScopes = [];

  ProviderScopeInstanceCreationExpression? _enclosingProviderScope;

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.staticElement!.returnType.element;

    final scopes = ScopesAnnotationElement.parse(element);
    if (scopes != null) {
      // TODO add only if not overridden in ancestor scopes
      _currentScopes.addAll(scopes.providers);
      print('InstanceCreationExpression: ${node.constructorName}');
      print(
        'Scopes: ${scopes.providers.map((e) => e.name)}'
        '\nwith parent: ${_enclosingProviderScope?.node}'
        '\n which overrides: ${_enclosingProviderScope?.overrides?.overrides?.map((e) => e.providerElement?.name)}',
      );
      return super.visitInstanceCreationExpression(node);
    }

    final providerScope = ProviderScopeInstanceCreationExpression.parse(node);
    if (providerScope != null) {
      try {
        _enclosingProviderScope = providerScope;
        return super.visitInstanceCreationExpression(node);
      } finally {
        _enclosingProviderScope = null;
      }
    }
  }
}

class _WidgetRefVisitor extends RecursiveRiverpodAstVisitor {
  final scopedProviderListenables = <ProviderListenableExpression>[];

  @override
  void visitProviderListenableExpression(
    ProviderListenableExpression expression,
  ) {
    final provider = expression.providerElement;
    if (provider is GeneratorProviderDeclarationElement && provider.isScoped) {
      scopedProviderListenables.add(expression);
    }
  }
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
