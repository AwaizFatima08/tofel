import 'package:flutter_test/flutter_test.dart';
import 'package:toefl_prep/content/models.dart';
import 'package:toefl_prep/core/grading.dart';
import 'package:toefl_prep/core/scoring.dart';

import '../support.dart';

void main() {
  group('grading', () {
    test('complete the words gives a point per word, case-insensitive, ending or whole word', () {
      final q = question(
        'c',
        type: QuestionType.ctw,
        stem: 'Bees matter. They [[mo|ve]] pollen [[fr|om]] one flower to the [[ne|xt]].',
      );
      expect(q.gaps.map((g) => g.word), ['move', 'from', 'next']);
      expect(autoPoints(q, 've|OM|wrong'), 2);
      expect(autoPoints(q, 'move|om|xt'), 3);
      expect(autoPoints(q, ''), 0);
      expect(Responses.isAnswered(q, '||'), isFalse);
      expect(Responses.encodeGaps(['', ' ', '']), '');
    });

    test('build a sentence needs the key order (or an alternative) and no extra chunk', () {
      final q = question(
        'b',
        type: QuestionType.bas,
        chunks: const ['i', 'went', 'home', 'early'],
        extra: 'goes',
        alt: const [
          [0, 3, 1, 2],
        ],
      );
      expect(basCorrect(q, [0, 1, 2, 3]), isTrue);
      expect(basCorrect(q, [0, 3, 1, 2]), isTrue);
      expect(basCorrect(q, [0, 4, 2, 3]), isFalse);
      expect(basCorrect(q, [0, 1, 2]), isFalse);
      expect(q.replyFrom([0, 1, 2, 3]), 'i went home early.');
    });

    test('multiple choice', () {
      final q = question('m', answer: const [2]);
      expect(isCorrect(q, '2'), isTrue);
      expect(isCorrect(q, '1'), isFalse);
      expect(isCorrect(q, null), isFalse);
    });
  });

  group('bands', () {
    test('the lower module caps the band at 4.5; the upper opens 6', () {
      expect(adaptiveBand(const Tally(50, 50), upper: false), 4.5);
      expect(adaptiveBand(const Tally(50, 50), upper: true), 6);
      expect(adaptiveBand(const Tally(0, 50), upper: false), 1);
      expect(adaptiveBand(const Tally(20, 50), upper: true), 3);
    });

    test('overall is the mean rounded to the nearest half band, as ETS reports it', () {
      expect(overallBand([5, 5, 5, 5.5]), 5); // 5.125
      expect(overallBand([5, 5, 5.5, 5.5]), 5.5); // 5.25
      expect(overallBand([4, 4.5, 4, 4]), 4); // 4.125
      expect(overallBand([6, 6, 6, 6]), 6);
    });

    test('comparable 0-120 totals and CEFR follow the published table', () {
      expect(comparableTotal(6), 117);
      expect(comparableTotal(4), 79);
      expect(comparableTotal(1), 6);
      expect(cefrOf(5.5), 'C1');
      expect(cefrOf(4.5), 'B2');
      expect(cefrOf(2), 'A2');
      expect(formatBand(4), '4');
      expect(formatBand(4.5), '4.5');
    });
  });

  group('a sitting', () {
    test('routes to the upper module at the threshold and scores each section', () {
      final sitting = sittingOf(routes: const {'reading': 'upper', 'listening': 'lower'});
      final responses = {
        'reading-router-1': '0',
        'reading-router-2': '0',
        'reading-upper-1': '0',
        'listening-router-1': '1',
        'bas': '0,1,2',
        'eml': 'Dear Sir',
        'lrp': Responses.recorded,
      };
      expect(routerPoints(sitting, 'reading', responses), 2);
      expect(routerPoints(sitting, 'listening', responses), 0);
      final result = scoreSitting(sitting, responses, const {'eml': 4});
      final reading = result.sections['reading']!;
      expect(reading.upper, isTrue);
      expect(reading.points.correct, 3);
      expect(result.sections['listening']!.upper, isFalse);
      final writing = result.sections['writing']!;
      expect(writing.points.correct, 5); // build a sentence 1 + email 4; discussion blank = 0
      expect(writing.points.total, 11);
      expect(writing.unrated, 0);
      expect(result.sections['speaking']!.unrated, 1); // repeat recorded, not rated yet
      expect(result.complete, isFalse);
    });

    test('the second module is empty until routed', () {
      final stages = sittingOf(routes: const {}).stages;
      expect(stages.map((s) => s.part), [
        'router',
        'module',
        'router',
        'module',
        'bas',
        'eml',
        'dsc',
        'lrp',
        'int',
      ]);
      expect(stages[1].itemIds, isEmpty);
      expect(stages.last.isTimed, isFalse);
    });
  });
}
