import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toefl_prep/content/models.dart';

/// Checks the built assets: 20 mocks in the TOEFL iBT 2026 pattern, test-pool questions only, no repeats.
void main() {
  final forms = jsonDecode(File('assets/data/forms.json').readAsStringSync()) as List<Object?>;
  final papers = [for (final form in forms) Paper.fromJson(form! as Json)];
  final catalog = Catalog.fromJson(
    jsonDecode(File('assets/data/catalog.json').readAsStringSync()) as Json,
  );
  final questions = <String, Question>{};
  final sets = <String, QuestionSet>{};
  for (final section in ['reading', 'listening', 'writing', 'speaking']) {
    final json = jsonDecode(File('assets/data/bank_$section.json').readAsStringSync()) as Json;
    for (final raw in json['questions']! as List<Object?>) {
      final question = Question.fromJson(raw! as Json, section);
      questions[question.id] = question;
    }
    for (final MapEntry(:key, :value) in (json['sets']! as Json).entries) {
      sets[key] = QuestionSet.fromJson(value! as Json);
    }
  }
  int points(List<String> ids) => ids.fold(0, (sum, id) => sum + questions[id]!.maxPoints);

  test(
    'there are 20 mocks: Reading 35 + 15 points, Listening 32 + 15, Writing 12, Speaking 11',
    () {
      expect(papers, hasLength(20));
      for (final paper in papers) {
        for (final key in ['reading', 'listening']) {
          final module = paper.module(key);
          final items = catalog.section(key).items;
          expect(points(module.router), items['router'], reason: '${paper.id} $key');
          expect(points(module.lower), items['lower'], reason: '${paper.id} $key');
          expect(points(module.upper), items['upper'], reason: '${paper.id} $key');
        }
        expect(points(paper.reading.router) + points(paper.reading.upper), 50);
        expect(points(paper.listening.router) + points(paper.listening.upper), 47);
        expect(paper.tasks['bas'], hasLength(10));
        expect(paper.tasks['eml'], hasLength(1));
        expect(paper.tasks['dsc'], hasLength(1));
        expect(paper.tasks['lrp'], hasLength(7));
        expect(paper.tasks['int'], hasLength(4));
      }
    },
  );

  test('every mock question is from the test pool and used once across all mocks', () {
    final ids = [
      for (final paper in papers) ...[
        for (final module in [paper.reading, paper.listening]) ...[
          ...module.router,
          ...module.lower,
          ...module.upper,
        ],
        for (final task in paper.tasks.values) ...task,
      ],
    ];
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(questions[id]?.isPractice, isFalse, reason: id);
    }
  });

  test('the upper module is harder than the lower one', () {
    double mean(List<String> ids) =>
        ids.map((id) => questions[id]!.level).reduce((a, b) => a + b) / ids.length;
    for (final paper in papers) {
      for (final module in [paper.reading, paper.listening]) {
        expect(mean(module.upper), greaterThan(mean(module.lower) + 1.5), reason: paper.id);
      }
    }
  });

  test('every item is usable', () {
    for (final question in questions.values) {
      final reason = question.id;
      switch (question.type) {
        case QuestionType.mc || QuestionType.lcr:
          expect(question.options, hasLength(4), reason: reason);
          expect(question.answer.single, inInclusiveRange(0, 3), reason: reason);
        case QuestionType.ctw:
          expect(question.gaps, hasLength(10), reason: reason);
        case QuestionType.bas:
          expect(question.chunks.length, inInclusiveRange(4, 7), reason: reason);
        case QuestionType.email:
          expect(question.bullets, hasLength(3), reason: reason);
        case QuestionType.disc:
          expect(question.posts, hasLength(2), reason: reason);
        case QuestionType.repeat || QuestionType.interview:
          expect(question.explanation, isNotEmpty, reason: reason);
      }
      if (question.type == QuestionType.lcr) expect(question.spoken, isNotNull, reason: reason);
      if (question.section == 'listening' && question.setId != null) {
        expect(sets[question.setId]!.script, isNotEmpty, reason: reason);
      }
    }
  });
}
