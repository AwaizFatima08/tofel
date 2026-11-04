import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/app.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/settings/settings_repository.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/theme.dart';

/// Flashcards: the word first, tap to see the meaning; mark words you know so the deck shrinks.
class VocabScreen extends ConsumerStatefulWidget {
  const VocabScreen({super.key});

  @override
  ConsumerState<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends ConsumerState<VocabScreen> {
  bool _flipped = false;
  bool _includeKnown = false;
  int _position = 0;
  int _seed = 0;

  List<VocabWord> _deck(List<VocabWord> words, Set<String> known) {
    final deck = [
      for (final word in words)
        if (_includeKnown || !known.contains(word.word)) word,
    ];
    return _seed == 0 ? deck : (deck..shuffle(Random(_seed)));
  }

  void _move(int by, int length) => setState(() {
    _flipped = false;
    _position = length == 0 ? 0 : (_position + by) % length;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final known = ref.watch(knownWordsProvider).value ?? const <String>{};
    return AsyncValueView(
      value: ref.watch(vocabProvider),
      data: (words) {
        final deck = _deck(words, known);
        final word = deck.isEmpty ? null : deck[_position.clamp(0, deck.length - 1)];
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.vocabulary),
            actions: [
              IconButton(
                tooltip: l10n.shuffle,
                icon: const Icon(Icons.shuffle),
                onPressed: () => setState(() {
                  _seed = DateTime.now().millisecondsSinceEpoch;
                  _position = 0;
                  _flipped = false;
                }),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            children: [
              Text(l10n.vocabProgress(known.length, words.length)),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(value: words.isEmpty ? 0 : known.length / words.length),
              SwitchListTile(
                contentPadding: EdgeInsetsDirectional.zero,
                title: Text(l10n.includeKnown),
                value: _includeKnown,
                onChanged: (value) => setState(() {
                  _includeKnown = value;
                  _position = 0;
                }),
              ),
              if (word == null)
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                  child: Text(l10n.vocabDone, textAlign: TextAlign.center),
                )
              else ...[
                Text(
                  l10n.cardOf(_position.clamp(0, deck.length - 1) + 1, deck.length),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _Card(
                  word: word,
                  flipped: _flipped,
                  onTap: () => setState(() => _flipped = !_flipped),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: l10n.previous,
                      onPressed: () => _move(-1, deck.length),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await ref.read(knownWordsProvider.notifier).toggle(word.word);
                          if (!_includeKnown) {
                            setState(() => _flipped = false);
                          } else {
                            _move(1, deck.length);
                          }
                        },
                        icon: Icon(known.contains(word.word) ? Icons.undo : Icons.check),
                        label: Text(known.contains(word.word) ? l10n.unmarkKnown : l10n.markKnown),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.outlined(
                      tooltip: l10n.next,
                      onPressed: () => _move(1, deck.length),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.word, required this.flipped, required this.onTap});

  final VocabWord word;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 260),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(word.word, style: theme.headlineMedium),
                Text(word.part, style: theme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                if (!flipped)
                  Text(context.l10n.tapToReveal, style: theme.bodySmall)
                else ...[
                  Text(word.definition, textAlign: TextAlign.center, style: theme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    word.example,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4),
                  ),
                  if (word.synonyms.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.synonyms(word.synonyms.join(', ')),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
