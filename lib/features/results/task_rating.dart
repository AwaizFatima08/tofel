import 'package:flutter/material.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// The 0-5 rubric lines for a task type, from 5 down to 0, in plain English.
List<String> rubricFor(BuildContext context, QuestionType type) {
  final l10n = context.l10n;
  return switch (type) {
    QuestionType.repeat => [
      l10n.repeat5,
      l10n.repeat4,
      l10n.repeat3,
      l10n.repeat2,
      l10n.repeat1,
      l10n.repeat0,
    ],
    QuestionType.interview => [
      l10n.interview5,
      l10n.interview4,
      l10n.interview3,
      l10n.interview2,
      l10n.interview1,
      l10n.interview0,
    ],
    _ => [l10n.writing5, l10n.writing4, l10n.writing3, l10n.writing2, l10n.writing1, l10n.writing0],
  };
}

/// One writing or speaking task with the candidate's answer, the model answer and a 0-5 self-rating.
/// No automatic scoring: the candidate compares honestly with the model and the rubric.
class TaskRating extends StatelessWidget {
  const TaskRating({
    required this.question,
    required this.set,
    required this.response,
    required this.recordKey,
    required this.rating,
    required this.onRate,
    this.label,
    super.key,
  });

  final Question question;
  final QuestionSet? set;
  final String? response;

  /// Where a spoken answer was saved.
  final String recordKey;
  final int? rating;
  final ValueChanged<int> onRate;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context).textTheme;
    final rubric = rubricFor(context, question.type);
    final voice = set?.voice ?? 'W';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label case final text?) Text(text, style: theme.labelLarge),
        if (question.type.isWriting) ...[
          WritingPrompt(question: question),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.yourResponse, style: theme.titleSmall),
          Text(l10n.wordCount(wordCount(response ?? '')), style: theme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              (response ?? '').trim().isEmpty ? l10n.essayEmpty : response!,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ] else ...[
          Text(
            question.type == QuestionType.repeat ? l10n.sentenceWas : l10n.questionWas,
            style: theme.titleSmall,
          ),
          Text(question.stem, style: theme.titleMedium?.copyWith(height: 1.4)),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SayButton(lines: [Line(voice, question.stem)], label: l10n.hearAgain),
              PlaybackButton(recordKey: recordKey),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (question.points.isNotEmpty) ...[
          Text(l10n.strongResponse, style: theme.titleSmall),
          PointsList(points: question.points),
          const SizedBox(height: AppSpacing.sm),
        ],
        ExplanationBox(
          text: question.explanation,
          title: question.type == QuestionType.repeat ? l10n.whatToWatch : l10n.modelAnswer,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.rateYourself, style: theme.titleSmall),
        RadioGroup<int>(
          groupValue: rating,
          onChanged: (value) => onRate(value!),
          child: Column(
            children: [
              for (var score = 5; score >= 0; score--)
                RadioListTile<int>(
                  contentPadding: EdgeInsetsDirectional.zero,
                  dense: true,
                  value: score,
                  title: Text(
                    '$score  ·  ${rubric[5 - score]}',
                    style: const TextStyle(height: 1.3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Recording key helper for a practice answer, re-exported for the practice screen.
String practiceRecording(Question question) => practiceKey(question.id);
