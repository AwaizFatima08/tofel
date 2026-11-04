import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/settings/settings_repository.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

class PracticeTab extends ConsumerWidget {
  const PracticeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tally = ref.watch(practiceTallyProvider).value ?? const <String, List<int>>{};
    return AsyncBody(
      value: ref.watch(catalogProvider),
      data: (catalog) => ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(context.l10n.practiceIntro),
          for (final section in catalog.sections) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.md, bottom: AppSpacing.xs),
              child: Text(section.title, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final topic in section.topics)
              Card(
                child: ListTile(
                  title: Text(topic.title),
                  subtitle: switch (tally['${section.key}/${topic.key}']) {
                    [final correct, final total] when total > 0 => Text(
                      context.l10n.practiceTally(correct, total),
                    ),
                    _ => null,
                  },
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => unawaited(context.push('/topic/${section.key}/${topic.key}')),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
