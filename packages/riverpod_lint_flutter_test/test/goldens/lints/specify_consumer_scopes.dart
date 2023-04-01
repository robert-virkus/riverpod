import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'specify_consumer_scopes.g.dart';

// TODO handle passing WidgetRef to methods. The methods should be annotated with @Scopes too.
// TODO "Scaffold"-like widget which has an inner ProviderScope overriding providers
// TODO "Builder"-like widget which has an inner ProviderScope overriding providers
// TODO test @Injects with missing/extra scopes

@Riverpod(dependencies: [])
int root(RootRef ref) => 0;

@Riverpod(dependencies: [])
class Root2 extends _$Root2 {
  @override
  int build() => 0;
}

@Riverpod(dependencies: [])
int scoped(ScopedRef ref) => 0;

@Riverpod(dependencies: [])
class Scoped2 extends _$Scoped2 {
  @override
  int build() => 0;
}

@Scopes([scoped, Scoped2])
class DirectConsumer extends ConsumerWidget {
  const DirectConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(rootProvider);
    ref.watch(root2Provider);
    ref.watch(scopedProvider);
    ref.watch(scoped2Provider);
    return Container();
  }
}

@Scopes([scoped, Scoped2])
class TransitiveConsumer extends ConsumerWidget {
  const TransitiveConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DirectConsumer();
  }
}

// expect_lint: specify_consumer_scopes
@Scopes([scoped])
class ExtraScope extends ConsumerWidget {
  const ExtraScope({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}

// expect_lint: specify_consumer_scopes
@Scopes([scoped])
class MissingProvider extends ConsumerWidget {
  const MissingProvider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(scopedProvider);
    ref.watch(scoped2Provider);
    return Container();
  }
}

// expect_lint: specify_consumer_scopes
class MissingAnnotation extends ConsumerWidget {
  const MissingAnnotation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(scopedProvider);
    ref.watch(scoped2Provider);
    return Container();
  }
}

class HandlesProviderScopeOverrides extends ConsumerWidget {
  const HandlesProviderScopeOverrides({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        scopedProvider.overrideWithValue(42),
        scoped2Provider.overrideWith(() => throw UnimplementedError()),
      ],
      child: DirectConsumer(),
    );
  }
}

@Scopes([Scoped2])
class HandlesProviderScopeOverrides2 extends ConsumerWidget {
  const HandlesProviderScopeOverrides2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        scopedProvider.overrideWithValue(42),
      ],
      child: DirectConsumer(),
    );
  }
}

@Scopes([scoped])
class WatchAboveProviderScopeOverride extends ConsumerWidget {
  const WatchAboveProviderScopeOverride({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(scopedProvider);
    return ProviderScope(
      overrides: [
        scopedProvider.overrideWithValue(42),
        scoped2Provider.overrideWith(() => throw UnimplementedError()),
      ],
      child: DirectConsumer(),
    );
  }
}

@Scopes([scoped])
class ReadUsingRefAboveProviderScope extends ConsumerWidget {
  const ReadUsingRefAboveProviderScope({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        scopedProvider.overrideWithValue(42),
      ],
      child: ElevatedButton(
        onPressed: () => ref.read(scopedProvider),
        child: const Text('click me'),
      ),
    );
  }
}

class UsingRefUnderProviderScope extends ConsumerWidget {
  const UsingRefUnderProviderScope({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        scopedProvider.overrideWithValue(42),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          return ElevatedButton(
            onPressed: () => ref.read(scopedProvider),
            child: const Text('click me'),
          );
        },
      ),
    );
  }
}

@Scopes([scoped])
class ProviderScopeInColumn extends ConsumerWidget {
  const ProviderScopeInColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(ref.watch(scopedProvider).toString()),
        ProviderScope(
          overrides: [
            scoped2Provider.overrideWith(() => throw UnimplementedError()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              return Text(ref.watch(scoped2Provider).toString());
            },
          ),
        ),
      ],
    );
  }
}

class MyConsumer extends ConsumerWidget {
  const MyConsumer({
    super.key,
    this.child,
    this.child2,
    this.builder,
    this.builder2,
  });

  @Injects([scoped])
  final Widget? child;
  final Widget? child2;

  @Injects([scoped])
  final Widget Function(BuildContext)? builder;
  final Widget Function(BuildContext)? builder2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ProviderScope(
          overrides: [
            scopedProvider.overrideWithValue(42),
          ],
          child: child!,
        ),
        child2!,
        ProviderScope(
          overrides: [
            scopedProvider.overrideWithValue(42),
          ],
          child: Builder(builder: builder!),
        ),
        Builder(builder: builder!),
      ],
    );
  }
}
