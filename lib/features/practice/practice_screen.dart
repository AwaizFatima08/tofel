import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/ads/ad_service.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/audio/audio.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/features/exam/exam_screen.dart';
import 'package:toefl_prep/features/practice/practice_notifier.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/audio_widgets.dart';
import 'package:toefl_prep/ui/question_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Practice for the machine-marked tasks (reading, listening, Build a Sentence): instant answers and
/// explanations; listening can be replayed and its transcript read after answering.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({required this.section, required this.topic, super.key});

  final String section;
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = PracticeKey(section, topic);
    return AsyncValueView(
      value: ref.watch(practiceProvider(key)),
      data: (practice) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.tabPractice)),
        body: switch (practice) {
          PracticeState(questions: []) => Center(child: Text(context.l10n.practiceEmpty)),
          PracticeState(finished: true) => _Summary(practice: practice, practiceKey: key),
          _ => _QuestionPage(
            practice: practice,
            notifier: ref.read(practiceProvider(key).notifier),
          ),
        },
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({required this.practice, required this.notifier});

  final PracticeState practice;
  final PracticeNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = practice.question;
    final set = practice.sets[question.setId];
    final last = practice.index == practice.questions.length - 1;
    final right = practice.checked && isCorrect(question, practice.response);
    final listening = question.section == 'listening';
    final lines = listeningLines(question, set);
    // A set's recording plays automatically on its first question only.
    final firstOfRecording =
        question.setId == null ||
        practice.index == 0 ||
        practice.questions[practice.index - 1].setId != question.setId;
    return ListView(
      key: PageStorageKey(question.id),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        Text(
          '${l10n.questionOf(practice.index + 1, practice.questions.length)} · ${l10n.levelName('${question.level}')}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (listening)
          ListenPanel(
            key: ValueKey('listen-${question.setId ?? question.id}'),
            lines: lines,
            situation: set?.text ?? l10n.lcrSituation,
            autoPlay: firstOfRecording,
            replay: true,
          ),
        ...questionBody(
          context,
          question,
          listening ? null : set,
          practice.response,
          notifier.respond,
          reveal: practice.checked,
        ),
        if (!practice.checked && !checksOnTap(question))
          FilledButton(
            onPressed: Responses.isAnswered(question, practice.response) ? notifier.check : null,
            child: Text(l10n.check),
          ),
        if (practice.checked) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Text(
              right ? l10n.correct : l10n.incorrect,
              style: TextStyle(
                color: right ? AppColors.correct : AppColors.incorrect,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (listening) TranscriptBox(lines: lines, roles: set?.roles ?? const {}),
          ExplanationBox(text: question.explanation),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => unawaited(notifier.next()),
            child: Text(last ? l10n.finish : l10n.next),
          ),
        ],
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.practice, required this.practiceKey});

  final PracticeState practice;
  final PracticeKey practiceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.practiceDone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.practiceTally(practice.correct, practice.points),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => ref.invalidate(practiceProvider(practiceKey)),
              child: Text(l10n.practiceAgain),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () async {
                await ref.read(adServiceProvider).showReportInterstitial();
                if (context.mounted) context.pop();
              },
              child: Text(l10n.backToTopic),
            ),
          ],
        ),
      ),
    );
  }
}
