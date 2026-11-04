import 'package:toefl_prep/content/models.dart';

/// Responses are stored as strings:
/// - multiple choice: the chosen option index ("2");
/// - Complete the Words: the typed endings of the 10 gaps joined by `|` ("ple|ey||...");
/// - Build a Sentence: the chunk-bank indexes in the order placed ("3,0,2,1");
/// - email and discussion: the text written;
/// - speaking: "rec" once a recording was saved.
/// An empty string means no answer.
abstract final class Responses {
  static const recorded = 'rec';

  static int? choice(String? response) =>
      response == null || response.isEmpty ? null : int.tryParse(response);

  static List<String> gapAnswers(String? response, int count) {
    final parts = (response ?? '').split('|');
    return [for (var i = 0; i < count; i++) i < parts.length ? parts[i] : ''];
  }

  static String encodeGaps(List<String> answers) =>
      answers.every((a) => a.trim().isEmpty) ? '' : answers.map((a) => a.trim()).join('|');

  static List<int> order(String? response) => [
    if (response != null && response.isNotEmpty)
      for (final part in response.split(',')) int.parse(part),
  ];

  static String encodeOrder(List<int> order) => order.join(',');

  /// Whether the response is complete enough to count as answered.
  static bool isAnswered(Question question, String? response) {
    if (response == null || response.trim().isEmpty) return false;
    return switch (question.type) {
      QuestionType.ctw => gapAnswers(response, 10).any((a) => a.isNotEmpty),
      QuestionType.bas => order(response).isNotEmpty,
      _ => true,
    };
  }
}

/// Case-insensitive match of a typed ending; the candidate may also type the whole word.
bool gapCorrect(Gap gap, String typed) {
  final answer = typed.trim().toLowerCase();
  if (answer.isEmpty) return false;
  return answer == gap.missing.toLowerCase() || answer == gap.word.toLowerCase();
}

/// Machine-marked points for [question]: one per correct word in Complete the Words, else 0 or 1.
/// Writing and speaking tasks return 0 here; their points come from the candidate's rating.
int autoPoints(Question question, String? response) {
  if (response == null || response.isEmpty) return 0;
  switch (question.type) {
    case QuestionType.ctw:
      final gaps = question.gaps;
      final answers = Responses.gapAnswers(response, gaps.length);
      return [
        for (var i = 0; i < gaps.length; i++) gapCorrect(gaps[i], answers[i]),
      ].where((ok) => ok).length;
    case QuestionType.mc || QuestionType.lcr:
      return Responses.choice(response) == question.answer.first ? 1 : 0;
    case QuestionType.bas:
      return basCorrect(question, Responses.order(response)) ? 1 : 0;
    case QuestionType.email || QuestionType.disc || QuestionType.repeat || QuestionType.interview:
      return 0;
  }
}

/// A built sentence is right when its chunks are in the key order (or an accepted alternative) and the
/// extra chunk is left out. Chunks with the same words count as the same.
bool basCorrect(Question question, List<int> order) {
  final bank = question.chunkBank;
  final built = [for (final i in order) bank[i].toLowerCase()];
  bool same(List<int> key) {
    final want = [for (final i in key) question.chunks[i].toLowerCase()];
    if (want.length != built.length) return false;
    for (var i = 0; i < want.length; i++) {
      if (want[i] != built[i]) return false;
    }
    return true;
  }

  return same([for (var i = 0; i < question.chunks.length; i++) i]) || question.alt.any(same);
}

/// Whether an auto-scored question earned full points.
bool isCorrect(Question question, String? response) =>
    question.type.isAutoScored && autoPoints(question, response) == question.maxPoints;

int wordCount(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
