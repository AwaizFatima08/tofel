import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/core/result.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Standard loading / error / data rendering for an [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({required this.value, required this.data, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => data(value),
    AsyncError(:final error) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
          child: Text(
            context.l10n.loadError(error is Failure ? error.code : '$error'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
  };
}

/// Like [AsyncValueView] but without its own [Scaffold], for use in a body.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({required this.value, required this.data, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) data;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) => data(value),
    AsyncError(:final error) => Center(
      child: Text(
        context.l10n.loadError(error is Failure ? error.code : '$error'),
      ),
    ),
    _ => const Center(child: CircularProgressIndicator()),
  };
}
