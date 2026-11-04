import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/result.dart';

/// Reads a bundled text asset. Swapped in tests.
typedef AssetReader = Future<String> Function(String path);

class SectionBank {
  const SectionBank({required this.questions, required this.sets});

  final List<Question> questions;
  final Map<String, QuestionSet> sets;
}

SectionBank _parseBank((String, String) input) {
  final (raw, section) = input;
  final json = jsonDecode(raw) as Json;
  return SectionBank(
    questions: [
      for (final item in json['questions']! as List<Object?>)
        Question.fromJson(item! as Json, section),
    ],
    sets: {
      for (final entry in (json['sets']! as Json).entries)
        entry.key: QuestionSet.fromJson(entry.value! as Json),
    },
  );
}

/// Bundled content. Banks load on demand and stay cached for the session.
class ContentRepository {
  ContentRepository(this._read);

  final AssetReader _read;
  final _banks = <String, Future<SectionBank>>{};

  Future<Object> _json(String name) async => jsonDecode(await _read('assets/data/$name')) as Object;

  Future<Catalog> catalog() async => Catalog.fromJson(await _json('catalog.json') as Json);

  Future<List<Paper>> papers() async => [
    for (final item in await _json('forms.json') as List<Object?>) Paper.fromJson(item! as Json),
  ];

  Future<List<GuideArticle>> guide() async => [
    for (final item in (await _json('guide.json') as Json)['articles']! as List<Object?>)
      GuideArticle.fromJson(item! as Json),
  ];

  Future<List<Lesson>> lessons() async => [
    for (final item in await _json('lessons.json') as List<Object?>) Lesson.fromJson(item! as Json),
  ];

  Future<List<VocabWord>> vocab() async => [
    for (final item in await _json('vocab.json') as List<Object?>)
      VocabWord.fromJson(item! as Json),
  ];

  Future<SectionBank> bank(String section) => _banks[section] ??= () async {
    final raw = await _read('assets/data/bank_$section.json');
    return compute(_parseBank, (raw, section));
  }();

  /// Everything needed to run or review [paper]; the second module of a section appears once [routes]
  /// names it.
  Future<Result<Sitting, ContentFailure>> sitting(
    Paper paper,
    Catalog catalog, {
    required Map<String, String> routes,
  }) async {
    try {
      final questions = <String, Question>{};
      final sets = <String, QuestionSet>{};
      for (final section in sectionOrder) {
        final bank = await this.bank(section);
        for (final question in bank.questions) {
          if (!question.isPractice) questions[question.id] = question;
        }
        sets.addAll(bank.sets);
      }
      final stages = buildStages(paper, catalog, routes);
      for (final stage in stages) {
        for (final id in stage.itemIds) {
          if (!questions.containsKey(id)) return Err(ContentFailure('missing-question:$id'));
        }
      }
      return Ok(Sitting(paper: paper, stages: stages, questions: questions, sets: sets));
    } on FormatException catch (error) {
      return Err(ContentFailure('bad-bank', cause: error));
    } on Exception catch (error) {
      return Err(ContentFailure('missing-bank', cause: error));
    }
  }
}

const sectionOrder = ['reading', 'listening', 'writing', 'speaking'];

/// One timed part of a mock: a Reading or Listening module, or one Writing or Speaking task.
class Stage {
  const Stage({
    required this.section,
    required this.part,
    required this.seconds,
    required this.itemIds,
  });

  /// `reading`, `listening`, `writing` or `speaking`.
  final String section;

  /// `router`, `module` (second module not routed yet), `lower`, `upper`, or a task: `bas`, `eml`,
  /// `dsc`, `lrp`, `int`.
  final String part;

  /// Time for the stage; 0 for speaking tasks, which time each answer instead.
  final int seconds;

  /// Empty for a second module whose route is not decided yet.
  final List<String> itemIds;

  bool get isRouter => part == 'router';

  bool get isModule => part == 'lower' || part == 'upper' || part == 'module';

  bool get isListening => section == 'listening';

  bool get isSpeaking => section == 'speaking';

  /// Email and discussion stages hold one writing task each.
  bool get isEssay => part == 'eml' || part == 'dsc';

  bool get isTimed => seconds > 0;
}

/// Reading (router, then the lower or upper module), Listening (the same), Writing's three tasks and
/// Speaking's two.
List<Stage> buildStages(Paper paper, Catalog catalog, Map<String, String> routes) => [
  for (final section in ['reading', 'listening']) ...[
    Stage(
      section: section,
      part: 'router',
      seconds: catalog.section(section).minutes['router']! * 60,
      itemIds: paper.module(section).router,
    ),
    switch (routes[section]) {
      'upper' => Stage(
        section: section,
        part: 'upper',
        seconds: catalog.section(section).minutes['upper']! * 60,
        itemIds: paper.module(section).upper,
      ),
      'lower' => Stage(
        section: section,
        part: 'lower',
        seconds: catalog.section(section).minutes['lower']! * 60,
        itemIds: paper.module(section).lower,
      ),
      _ => Stage(
        section: section,
        part: 'module',
        seconds: catalog.section(section).minutes['lower']! * 60,
        itemIds: const [],
      ),
    },
  ],
  for (final task in ['bas', 'eml', 'dsc'])
    Stage(
      section: 'writing',
      part: task,
      seconds: catalog.writingMinutes[task]! * 60,
      itemIds: paper.tasks[task] ?? const [],
    ),
  for (final task in ['lrp', 'int'])
    Stage(section: 'speaking', part: task, seconds: 0, itemIds: paper.tasks[task] ?? const []),
];

/// Everything needed to run or review one paper.
class Sitting {
  const Sitting({
    required this.paper,
    required this.stages,
    required this.questions,
    required this.sets,
  });

  final Paper paper;
  final List<Stage> stages;
  final Map<String, Question> questions;
  final Map<String, QuestionSet> sets;

  List<Question> questionsOf(Stage stage) => [for (final id in stage.itemIds) questions[id]!];
}

final assetReaderProvider = Provider<AssetReader>((ref) => rootBundle.loadString);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(assetReaderProvider)),
);

final catalogProvider = FutureProvider<Catalog>(
  (ref) => ref.watch(contentRepositoryProvider).catalog(),
);

final papersProvider = FutureProvider<List<Paper>>(
  (ref) => ref.watch(contentRepositoryProvider).papers(),
);

final guideProvider = FutureProvider<List<GuideArticle>>(
  (ref) => ref.watch(contentRepositoryProvider).guide(),
);

final lessonsProvider = FutureProvider<List<Lesson>>(
  (ref) => ref.watch(contentRepositoryProvider).lessons(),
);

final vocabProvider = FutureProvider<List<VocabWord>>(
  (ref) => ref.watch(contentRepositoryProvider).vocab(),
);

final bankProvider = FutureProvider.family<SectionBank, String>(
  (ref, section) => ref.watch(contentRepositoryProvider).bank(section),
);
