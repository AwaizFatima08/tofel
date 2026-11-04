import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/attempts/attempt.dart';
import 'package:toefl_prep/attempts/attempt_repository.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/result.dart';
import 'package:toefl_prep/core/scoring.dart';
import 'package:toefl_prep/features/exam/exam_widgets.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Pattern of one mock, the start or resume button, and past attempts.
class PaperScreen extends ConsumerWidget {
  const PaperScreen({required this.paperId, super.key});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
    value: ref.watch(papersProvider),
    data: (papers) {
      final paper = papers.firstWhere((candidate) => candidate.id == paperId);
      return Scaffold(
        appBar: AppBar(title: Text(paper.title)),
        body: AsyncBody(
          value: ref.watch(catalogProvider),
          data: (catalog) => AsyncBody(
            value: ref.watch(attemptsProvider),
            data: (attempts) => _PaperBody(
              paper: paper,
              catalog: catalog,
              attempts: [
                for (final attempt in attempts)
                  if (attempt.paperId == paper.id) attempt,
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Approximate minutes per section (router plus upper module for the adaptive sections, as the longer route).
Map<String, int> sectionMinutes(Catalog catalog) => {
  for (final key in ['reading', 'listening'])
    key: catalog.section(key).minutes['router']! + catalog.section(key).minutes['upper']!,
  'writing': catalog.writingMinutes.values.fold(0, (sum, m) => sum + m),
  'speaking': 8,
};

String sectionParts(BuildContext context, String section) {
  final l10n = context.l10n;
  return switch (section) {
    'reading' => l10n.partsReading,
    'listening' => l10n.partsListening,
    'writing' => l10n.partsWriting,
    _ => l10n.partsSpeaking,
  };
}

/// "R 5 · L 4.5 · W 4 · S 4.5 · overall 4.5".
String bandLine(BuildContext context, MockScore score) => context.l10n.bandLine(
  formatBand(score.reading),
  formatBand(score.listening),
  formatBand(score.writing),
  formatBand(score.speaking),
  formatBand(score.overall),
);

class _PaperBody extends ConsumerWidget {
  const _PaperBody({required this.paper, required this.catalog, required this.attempts});

  final Paper paper;
  final Catalog catalog;
  final List<Attempt> attempts;

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final started = await ref
        .read(attemptRepositoryProvider)
        .start(paperId: paper.id, seconds: buildStages(paper, catalog, const {}).first.seconds);
    if (started case Ok(:final value) when context.mounted) {
      unawaited(context.push('/exam/${value.id}'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final open = attempts.where((attempt) => !attempt.isFinished).firstOrNull;
    final finished = [...attempts.where((attempt) => attempt.isFinished)];
    final stages = buildStages(paper, catalog, const {});
    final totalMinutes = sectionMinutes(catalog).values.fold(0, (sum, m) => sum + m);
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          l10n.totalTime(totalMinutes ~/ 60, totalMinutes % 60),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final (i, MapEntry(key: section, value: minutes)) in sectionMinutes(
          catalog,
        ).entries.indexed)
          ListTile(
            dense: true,
            leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
            title: Text(sectionTitle(context, section)),
            subtitle: Text(sectionParts(context, section)),
            trailing: Text(l10n.aboutMinutes(minutes)),
          ),
        Text(l10n.stagesCount(stages.length), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.paperRules, style: const TextStyle(height: 1.45)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.unofficialNote, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        if (open != null) ...[
          FilledButton(
            onPressed: () => unawaited(context.push('/exam/${open.id}')),
            child: Text(l10n.resumeTest),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () async {
              await ref.read(attemptRepositoryProvider).delete(open.id);
              if (context.mounted) await _start(context, ref);
            },
            child: Text(l10n.restartTest),
          ),
        ] else
          FilledButton(
            onPressed: () => unawaited(_start(context, ref)),
            child: Text(l10n.startTest),
          ),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.previousAttempts, style: Theme.of(context).textTheme.titleMedium),
          for (final attempt in finished)
            ListTile(
              title: Text(
                attempt.score == null ? '–' : bandLine(context, attempt.score!),
              ),
              subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(attempt.startedAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(context.push('/results/${attempt.id}')),
            ),
        ],
      ],
    );
  }
}
