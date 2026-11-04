import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/scoring.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

class TestsTab extends ConsumerWidget {
  const TestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempts = ref.watch(attemptsProvider).value ?? const <Attempt>[];
    return AsyncBody(
      value: ref.watch(papersProvider),
      data: (papers) => ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(context.l10n.testsIntro(papers.length)),
          const SizedBox(height: AppSpacing.sm),
          for (final paper in papers) _PaperTile(paper: paper, attempts: attempts),
        ],
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile({required this.paper, required this.attempts});

  final Paper paper;
  final List<Attempt> attempts;

  String _status(BuildContext context) {
    final mine = [
      for (final attempt in attempts)
        if (attempt.paperId == paper.id) attempt,
    ];
    final l10n = context.l10n;
    if (mine.any((attempt) => !attempt.isFinished)) return l10n.inProgress;
    final scored = [for (final attempt in mine) ?attempt.score];
    if (scored.isEmpty) return l10n.notStarted;
    final best = scored.reduce((a, b) => a.overall >= b.overall ? a : b);
    return l10n.bestScore(formatBand(best.overall));
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Text('${paper.number}')),
      title: Text(paper.title),
      subtitle: Text(_status(context)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(context.push('/paper/${paper.id}')),
    ),
  );
}
