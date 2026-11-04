import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/content/models.dart';

Question question(
  String id, {
  String section = 'reading',
  String topic = 'rap',
  QuestionType type = QuestionType.mc,
  List<int> answer = const [0],
  List<String> options = const ['a', 'b', 'c', 'd'],
  String stem = 'Stem',
  List<String> chunks = const [],
  String? extra,
  List<List<int>> alt = const [],
  String? setId,
}) => Question(
  id: id,
  section: section,
  topic: topic,
  isPractice: false,
  level: 2,
  type: type,
  stem: stem,
  options: options,
  answer: answer,
  chunks: chunks,
  extra: extra,
  alt: alt,
  suffix: '.',
  explanation: 'Because.',
  setId: setId,
);

const catalog = Catalog(
  sections: [],
  adaptive: [
    AdaptiveInfo(
      key: 'reading',
      minutes: {'router': 20, 'lower': 9, 'upper': 9},
      items: {'router': 2, 'lower': 2, 'upper': 2},
      upperAt: 2,
    ),
    AdaptiveInfo(
      key: 'listening',
      minutes: {'router': 18, 'lower': 7, 'upper': 11},
      items: {'router': 2, 'lower': 2, 'upper': 2},
      upperAt: 2,
    ),
  ],
  writingMinutes: {'bas': 6, 'eml': 7, 'dsc': 10},
  speakingSeconds: {'lrp': 12, 'int': 45},
);

/// A tiny mock: two questions per module keyed to option 0, one task of each writing and speaking kind.
Sitting sittingOf({required Map<String, String> routes}) {
  final ids = <String, List<String>>{};
  final questions = <String, Question>{};
  for (final section in ['reading', 'listening']) {
    for (final part in ['router', 'lower', 'upper']) {
      ids['$section/$part'] = ['$section-$part-1', '$section-$part-2'];
      for (final id in ids['$section/$part']!) {
        questions[id] = question(id, section: section, topic: part);
      }
    }
  }
  const tasks = {
    'bas': QuestionType.bas,
    'eml': QuestionType.email,
    'dsc': QuestionType.disc,
    'lrp': QuestionType.repeat,
    'int': QuestionType.interview,
  };
  for (final MapEntry(:key, :value) in tasks.entries) {
    questions[key] = question(
      key,
      section: key == 'lrp' || key == 'int' ? 'speaking' : 'writing',
      topic: key,
      type: value,
      options: const [],
      answer: const [],
      chunks: key == 'bas' ? const ['i', 'went', 'home'] : const [],
    );
  }
  ModulePaper module(String section) => ModulePaper(
    router: ids['$section/router']!,
    lower: ids['$section/lower']!,
    upper: ids['$section/upper']!,
  );
  final paper = Paper(
    id: 'toefl-01',
    number: 1,
    title: 'Mock Test 1',
    reading: module('reading'),
    listening: module('listening'),
    tasks: {
      for (final key in tasks.keys) key: [key],
    },
  );
  return Sitting(
    paper: paper,
    stages: buildStages(paper, catalog, routes),
    questions: questions,
    sets: const {},
  );
}
