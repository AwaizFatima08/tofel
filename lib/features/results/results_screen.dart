import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/ads/ad_service.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/core/scoring.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/features/exam/exam_widgets.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({required this.attemptId, super.key});

  final String attemptId;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  Future<void> _home() async {
    await ref.read(adServiceProvider).showReportInterstitial();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context).textTheme;
    return AsyncValueView(
      value: ref.watch(reviewProvider(widget.attemptId)),
      data: (exam) {
        final result = exam.result();
        return Scaffold(
          appBar: AppBar(title: Text(exam.sitting.paper.title)),
          body: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            children: [
              _ScoreCard(result: result),
              const SizedBox(height: AppSpacing.md),
              for (final key in ['writing', 'speaking'])
                if (result.sections[key]!.unrated > 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                    child: FilledButton.icon(
                      onPressed: () => unawaited(context.push('/rate/${widget.attemptId}/$key')),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(
                        l10n.rateNow(sectionTitle(context, key), result.sections[key]!.unrated),
                      ),
                    ),
                  ),
              FilledButton.tonalIcon(
                onPressed: () => unawaited(context.push('/review/${widget.attemptId}')),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.reviewAnswers),
              ),
              for (final key in ['writing', 'speaking'])
                if (result.sections[key]!.unrated == 0)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(context.push('/rate/${widget.attemptId}/$key')),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(l10n.modelAnswersFor(sectionTitle(context, key))),
                    ),
                  ),
              const SizedBox(height: AppSpacing.lg),
              for (final section in result.sections.values) ...[
                Text(sectionTitle(context, section.key), style: theme.titleMedium),
                if (section.isAdaptive) ...[
                  _ScoreRow(l10n.moduleN(1), section.router!),
                  _ScoreRow(
                    '${l10n.moduleN(2)} · ${section.upper! ? l10n.routeUpper : l10n.routeLower}',
                    section.module ?? const Tally(0, 0),
                  ),
                ] else
                  _ScoreRow(l10n.rubricPoints, section.points),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(l10n.weakTopics, style: theme.titleMedium),
              _WeakTopics(result: result),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.scoreDisclaimer, style: theme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: () => unawaited(_home()), child: Text(l10n.backHome)),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final MockResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context).textTheme;
    final overall = result.overall;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          children: [
            Text(l10n.estimatedScores, style: theme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(formatBand(overall), style: theme.displayMedium),
            Text(l10n.overallLine(cefrOf(overall), comparableTotal(overall))),
            if (!result.complete)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                child: Text(
                  l10n.provisional,
                  textAlign: TextAlign.center,
                  style: theme.bodySmall?.copyWith(color: AppColors.amber),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final section in result.sections.values)
                  Expanded(
                    child: Column(
                      children: [
                        Text(sectionTitle(context, section.key), style: theme.labelMedium),
                        Text(formatBand(section.band), style: theme.headlineSmall),
                        Text(cefrOf(section.band), style: theme.bodySmall),
                        if (section.unrated > 0) Text(l10n.notRated, style: theme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.title, this.tally);

  final String title;
  final Tally tally;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title)),
            Text(context.l10n.scoreOutOf(tally.correct, tally.total)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(value: tally.percent / 100),
      ],
    ),
  );
}

class _WeakTopics extends ConsumerWidget {
  const _WeakTopics({required this.result});

  final MockResult result;

  static const _shown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncBody(
    value: ref.watch(catalogProvider),
    data: (catalog) => Column(
      children: [
        for (final topic in result.topics.take(_shown))
          InkWell(
            onTap: () => unawaited(context.push('/topic/${topic.section}/${topic.topic}')),
            child: _ScoreRow(catalog.topicTitle(topic.section, topic.topic), topic.tally),
          ),
      ],
    ),
  );
}
