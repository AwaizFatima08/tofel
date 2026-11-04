import 'dart:math';

import 'package:flutter/material.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/ui/theme.dart';

/// A reading text (daily-life text or academic passage), collapsible so the question stays in view.
class SetPanel extends StatefulWidget {
  const SetPanel({required this.set, this.startOpen = true, super.key});

  final QuestionSet set;
  final bool startOpen;

  @override
  State<SetPanel> createState() => _SetPanelState();
}

class _SetPanelState extends State<SetPanel> {
  late bool _open = widget.startOpen;

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final theme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (set.kind case final kind?)
              Text(kind.toUpperCase(), style: theme.labelSmall?.copyWith(letterSpacing: 1.2)),
            if (set.title.isNotEmpty) Text(set.title, style: theme.titleMedium),
            if (_open) ...[
              const SizedBox(height: AppSpacing.sm),
              SelectableText(set.text, style: const TextStyle(height: 1.55, fontSize: 15.5)),
            ],
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? context.l10n.hidePassage : context.l10n.readPassage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How an option should look once answers are revealed.
enum OptionMark { none, selected, correct, missed, wrong }

/// Four lettered options. Read-only when [onChanged] is null; with [reveal], marks the key and the
/// candidate's mistake.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    required this.question,
    required this.response,
    this.onChanged,
    this.reveal = false,
    super.key,
  });

  final Question question;
  final String? response;
  final ValueChanged<String>? onChanged;
  final bool reveal;

  OptionMark _mark(int index, int? chosen) {
    final picked = chosen == index;
    if (!reveal) return picked ? OptionMark.selected : OptionMark.none;
    if (question.answer.first == index) return picked ? OptionMark.correct : OptionMark.missed;
    return picked ? OptionMark.wrong : OptionMark.none;
  }

  @override
  Widget build(BuildContext context) {
    final chosen = Responses.choice(response);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < question.options.length; i++)
          OptionTile(
            letter: String.fromCharCode(65 + i),
            text: question.options[i],
            mark: _mark(i, chosen),
            onTap: onChanged == null || reveal ? null : () => onChanged!('$i'),
          ),
      ],
    );
  }
}

/// One answer row with a lettered circle.
class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.letter,
    required this.text,
    required this.mark,
    this.onTap,
    super.key,
  });

  final String letter;
  final String text;
  final OptionMark mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = switch (mark) {
      OptionMark.none => scheme.outline,
      OptionMark.selected => scheme.primary,
      OptionMark.correct || OptionMark.missed => AppColors.correct,
      OptionMark.wrong => AppColors.incorrect,
    };
    final filled =
        mark == OptionMark.selected || mark == OptionMark.correct || mark == OptionMark.wrong;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Semantics(
          selected: filled,
          button: onTap != null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: colour, width: mark == OptionMark.none ? 1 : 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    shape: CircleBorder(side: BorderSide(color: colour, width: 1.5)),
                    color: filled ? colour : null,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: filled ? Colors.white : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 15.5, height: 1.35))),
                if (mark == OptionMark.missed)
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.correct,
                    semanticLabel: context.l10n.correctAnswer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Complete the Words: the paragraph with a small box after each word start. With [reveal], each box shows
/// whether it was right and the full word.
class CtwView extends StatefulWidget {
  const CtwView({
    required this.question,
    required this.response,
    this.onChanged,
    this.reveal = false,
    super.key,
  });

  final Question question;
  final String? response;
  final ValueChanged<String>? onChanged;
  final bool reveal;

  @override
  State<CtwView> createState() => _CtwViewState();
}

class _CtwViewState extends State<CtwView> {
  late final List<CtwPart> _parts = parseCtw(widget.question.stem);
  late final List<Gap> _gaps = [
    for (final part in _parts)
      if (part is CtwGap) part.gap,
  ];
  late final List<TextEditingController> _controllers = [
    for (final answer in Responses.gapAnswers(widget.response, _gaps.length))
      TextEditingController(text: answer),
  ];
  late final List<FocusNode> _focus = [for (final _ in _gaps) FocusNode()];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focus) {
      node.dispose();
    }
    super.dispose();
  }

  void _changed() =>
      widget.onChanged?.call(Responses.encodeGaps([for (final c in _controllers) c.text]));

  /// One damaged word: its first letters, the box for the rest, and any punctuation that follows it.
  Widget _gap(BuildContext context, CtwGap part, String trailing) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controllers[part.index];
    final right = gapCorrect(part.gap, controller.text);
    final width = max(3, part.gap.missing.length + 1) * 11.0 + 12;
    final colour = widget.reveal
        ? (right ? AppColors.correct : AppColors.incorrect)
        : scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(part.gap.shown, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
        SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            focusNode: _focus[part.index],
            enabled: widget.onChanged != null && !widget.reveal,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: part.index == _gaps.length - 1
                ? TextInputAction.done
                : TextInputAction.next,
            onSubmitted: (_) {
              if (part.index + 1 < _focus.length) _focus[part.index + 1].requestFocus();
            },
            style: TextStyle(fontSize: 16.5, color: widget.reveal ? colour : null),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsetsDirectional.only(start: 1, top: 4, bottom: 4),
              hintText: '_' * part.gap.missing.length,
              hintStyle: TextStyle(color: scheme.outline, letterSpacing: 2),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colour)),
              disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colour, width: 2)),
            ),
            onChanged: (_) => _changed(),
          ),
        ),
        if (trailing.isNotEmpty) Text(trailing, style: const TextStyle(fontSize: 16.5)),
        if (widget.reveal && !right)
          Text(
            ' (${part.gap.word})',
            style: const TextStyle(color: AppColors.correct, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = <Widget>[];
    for (final (i, part) in _parts.indexed) {
      switch (part) {
        case CtwText(:final text):
          final tokens = text.split(' ');
          // Punctuation straight after a gap ("rea___,") is drawn with the gap, not as its own word.
          final glued = i > 0 && _parts[i - 1] is CtwGap && !text.startsWith(' ');
          for (final word in glued ? tokens.skip(1) : tokens) {
            if (word.isEmpty) continue;
            words.add(Text(word, style: const TextStyle(fontSize: 16.5, height: 1.6)));
          }
        case final CtwGap gap:
          final next = i + 1 < _parts.length ? _parts[i + 1] : null;
          final trailing = next is CtwText && !next.text.startsWith(' ')
              ? next.text.split(' ').first
              : '';
          words.add(_gap(context, gap, trailing));
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Wrap(
          spacing: 5,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: words,
        ),
      ),
    );
  }
}

/// Build a Sentence: person A's line, the reply being built, and the chunks to tap in order.
class BasView extends StatelessWidget {
  const BasView({
    required this.question,
    required this.response,
    this.onChanged,
    this.reveal = false,
    super.key,
  });

  final Question question;
  final String? response;
  final ValueChanged<String>? onChanged;
  final bool reveal;

  /// A fixed shuffle of the chunk bank per question, so the order is the same every time.
  List<int> _shuffled() {
    final indexes = [for (var i = 0; i < question.chunkBank.length; i++) i]
      ..shuffle(Random(question.id.hashCode));
    if (indexes.length > 1 && _isKeyOrder(indexes)) indexes.add(indexes.removeAt(0));
    return indexes;
  }

  bool _isKeyOrder(List<int> indexes) {
    for (var i = 0; i < indexes.length; i++) {
      if (indexes[i] != i) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final order = Responses.order(response);
    final line = Line.parse(question.stem);
    final editable = onChanged != null && !reveal;
    final right = basCorrect(question, order);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bubble(text: line.text, label: line.isMan ? l10n.speakerMan : l10n.speakerWoman),
        const SizedBox(height: AppSpacing.sm),
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: reveal ? (right ? AppColors.correct : AppColors.incorrect) : scheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (question.prefix.isNotEmpty)
                Text(question.prefix, style: const TextStyle(fontSize: 16)),
              for (final (position, index) in order.indexed)
                InputChip(
                  label: Text(question.chunkBank[index]),
                  onPressed: editable
                      ? () => onChanged!(Responses.encodeOrder([...order]..removeAt(position)))
                      : null,
                ),
              if (order.isEmpty) Text(l10n.basHint, style: TextStyle(color: scheme.outline)),
              Text(question.suffix, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final index in _shuffled())
              ActionChip(
                label: Text(question.chunkBank[index]),
                onPressed: editable && !order.contains(index)
                    ? () => onChanged!(Responses.encodeOrder([...order, index]))
                    : null,
              ),
          ],
        ),
        if (editable && order.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => onChanged!(''), child: Text(l10n.clearAnswer)),
          ),
        if (reveal) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${right ? l10n.correct : l10n.incorrect} · ${question.reply}',
            style: TextStyle(
              color: right ? AppColors.correct : AppColors.incorrect,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18, color: scheme.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The words of a recording, shown after answering in practice and in review.
class TranscriptBox extends StatelessWidget {
  const TranscriptBox({required this.lines, this.roles = const {}, super.key});

  final List<Line> lines;
  final Map<String, String> roles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final single = lines.map((l) => l.voice).toSet().length == 1;
    String who(Line line) {
      final role = roles[line.voice];
      if (role == null || role.isEmpty) return line.isMan ? l10n.speakerMan : l10n.speakerWoman;
      return role[0].toUpperCase() + role.substring(1);
    }

    return ExpansionTile(
      tilePadding: EdgeInsetsDirectional.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      leading: const Icon(Icons.subject),
      title: Text(l10n.transcript),
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Text.rich(
              TextSpan(
                children: [
                  if (!single)
                    TextSpan(
                      text: '${who(line)}: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: line.text),
                ],
              ),
              style: const TextStyle(height: 1.45),
            ),
          ),
      ],
    );
  }
}

/// The explanation (or model answer) shown after an answer is revealed.
class ExplanationBox extends StatelessWidget {
  const ExplanationBox({required this.text, this.title, super.key});

  final String text;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title ?? context.l10n.explanation, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(text, style: TextStyle(color: scheme.onSecondaryContainer, height: 1.45)),
        ],
      ),
    );
  }
}

/// Bullet list of what a strong response does.
class PointsList extends StatelessWidget {
  const PointsList({required this.points, super.key});

  final List<String> points;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final point in points)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(point, style: const TextStyle(height: 1.4))),
            ],
          ),
        ),
    ],
  );
}

/// The writing prompt: email situation and bullets, or the discussion board.
class WritingPrompt extends StatelessWidget {
  const WritingPrompt({required this.question, super.key});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (question.type == QuestionType.email) {
      return Card(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.stem, style: const TextStyle(height: 1.5)),
              const SizedBox(height: AppSpacing.sm),
              Text(question.task ?? '', style: theme.titleSmall),
              for (final bullet in question.bullets)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                  child: Text('•  $bullet', style: const TextStyle(height: 1.4)),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(question.task ?? '', style: theme.bodySmall?.copyWith(height: 1.4)),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.prof ?? '', style: theme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(question.stem, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ),
        for (final post in question.posts)
          Card(
            color: scheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.name, style: theme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(post.text, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
