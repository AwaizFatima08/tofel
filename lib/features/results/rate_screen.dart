import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/core/scoring.dart';
import 'package:toefl_prep/features/exam/exam_notifier.dart';
import 'package:toefl_prep/features/exam/exam_widgets.dart';
import 'package:toefl_prep/features/results/task_rating.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Rate the Writing (email, discussion) or Speaking (repeat, interview) answers of a finished mock.
class RateScreen extends ConsumerWidget {
  const RateScreen({required this.attemptId, required this.section, super.key});

  final String attemptId;

  /// `writing` or `speaking`.
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = reviewProvider(attemptId);
    return AsyncValueView(
      value: ref.watch(provider),
      data: (exam) {
        final items = [
          for (final stage in exam.sitting.stages)
            if (stage.section == section)
              for (final (i, question) in exam.sitting.questionsOf(stage).indexed)
                if (!question.type.isAutoScored) (stage: stage, number: i + 1, question: question),
        ];
        final result = exam.result().sections[section]!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.rateTitle(sectionTitle(context, section)))),
          body: ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const Divider(height: AppSpacing.xl),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.rateIntro, style: const TextStyle(height: 1.45)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      result.unrated == 0
                          ? l10n.sectionBand(formatBand(result.band))
                          : l10n.stillToRate(result.unrated),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                );
              }
              final item = items[index - 1];
              final question = item.question;
              return TaskRating(
                key: ValueKey(question.id),
                label: '${taskTitle(context, item.stage.part)} · ${item.number}',
                question: question,
                set: exam.setOf(question),
                response: exam.attempt.responses[question.id],
                recordKey: recordingKey(exam.attempt.id, question.id),
                rating: exam.attempt.ratings[question.id],
                onRate: (value) => unawaited(ref.read(provider.notifier).rate(question.id, value)),
              );
            },
          ),
        );
      },
    );
  }
}
