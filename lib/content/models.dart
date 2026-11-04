typedef Json = Map<String, Object?>;

List<T> _list<T>(Object? raw, T Function(Json) read) => [
  for (final item in raw! as List<Object?>) read(item! as Json),
];

List<String> _strings(Object? raw) => (raw as List<Object?>? ?? const []).cast<String>();

/// The TOEFL iBT task formats.
enum QuestionType {
  /// Complete the Words: a paragraph with 10 half-words to finish (10 points).
  ctw,

  /// Multiple choice with four options (reading and listening sets).
  mc,

  /// Listen and Choose a Response: one spoken line, four written replies.
  lcr,

  /// Build a Sentence: put word chunks in order.
  bas,

  /// Write an Email.
  email,

  /// Write for an Academic Discussion.
  disc,

  /// Listen and Repeat.
  repeat,

  /// Take an Interview.
  interview
  ;

  static QuestionType parse(String raw) => values.byName(raw);

  /// Whether the app marks it; the rest are rated by the candidate against a model answer.
  bool get isAutoScored => this == ctw || this == mc || this == lcr || this == bas;

  bool get isChoice => this == mc || this == lcr;

  bool get isWriting => this == email || this == disc;

  bool get isSpoken => this == repeat || this == interview;
}

/// One damaged word of a Complete the Words paragraph.
class Gap {
  const Gap(this.shown, this.missing);

  final String shown;
  final String missing;

  String get word => shown + missing;
}

/// A piece of a Complete the Words paragraph: plain text, or a gap.
sealed class CtwPart {
  const CtwPart();
}

class CtwText extends CtwPart {
  const CtwText(this.text);

  final String text;
}

class CtwGap extends CtwPart {
  const CtwGap(this.index, this.gap);

  final int index;
  final Gap gap;
}

final _gapPattern = RegExp(r'\[\[([^\[\]|]*)\|([^\[\]|]*)\]\]');

/// Splits a `[[shown|missing]]` paragraph into text and gaps.
List<CtwPart> parseCtw(String stem) {
  final parts = <CtwPart>[];
  var last = 0;
  var index = 0;
  for (final match in _gapPattern.allMatches(stem)) {
    if (match.start > last) parts.add(CtwText(stem.substring(last, match.start)));
    parts.add(CtwGap(index++, Gap(match.group(1)!, match.group(2)!)));
    last = match.end;
  }
  if (last < stem.length) parts.add(CtwText(stem.substring(last)));
  return parts;
}

/// A post on the academic discussion board.
class Post {
  const Post({required this.name, required this.text});

  factory Post.fromJson(Json json) =>
      Post(name: json['name']! as String, text: json['text']! as String);

  final String name;
  final String text;
}

/// One spoken line: `W` (woman) or `M` (man) and the words.
class Line {
  const Line(this.voice, this.text);

  /// Parses "W: Hello." into a line; text without a speaker is read by the woman's voice.
  factory Line.parse(String raw) {
    if (raw.length > 3 && raw[1] == ':' && (raw[0] == 'W' || raw[0] == 'M')) {
      return Line(raw[0], raw.substring(3).trim());
    }
    return Line('W', raw.trim());
  }

  final String voice;
  final String text;

  bool get isMan => voice == 'M';
}

/// One question (or task) from the bank.
class Question {
  const Question({
    required this.id,
    required this.section,
    required this.topic,
    required this.isPractice,
    required this.level,
    required this.type,
    required this.stem,
    required this.explanation,
    this.options = const [],
    this.answer = const [],
    this.setId,
    this.say,
    this.chunks = const [],
    this.prefix = '',
    this.suffix = '',
    this.extra,
    this.alt = const [],
    this.bullets = const [],
    this.task,
    this.points = const [],
    this.prof,
    this.posts = const [],
  });

  factory Question.fromJson(Json json, String section) => Question(
    id: json['id']! as String,
    section: section,
    topic: json['tp']! as String,
    isPractice: json['pl'] == 'p',
    level: json['lv']! as int,
    type: QuestionType.parse(json['ty']! as String),
    stem: json['s']! as String,
    explanation: json['e']! as String,
    options: _strings(json['o']),
    answer: (json['a'] as List<Object?>? ?? const []).cast<int>(),
    setId: json['st'] as String?,
    say: json['sy'] as String?,
    chunks: _strings(json['ck']),
    prefix: json['pf'] as String? ?? '',
    suffix: json['sf'] as String? ?? '',
    extra: json['ex'] as String?,
    alt: [
      for (final order in json['al'] as List<Object?>? ?? const [])
        (order! as List<Object?>).cast<int>(),
    ],
    bullets: _strings(json['bl']),
    task: json['tk'] as String?,
    points: _strings(json['pt']),
    prof: json['pr'] as String?,
    posts: json['ps'] == null ? const [] : _list(json['ps'], Post.fromJson),
  );

  final String id;
  final String section;
  final String topic;
  final bool isPractice;
  final int level;
  final QuestionType type;

  /// The question text; for ctw the `[[shown|missing]]` paragraph, for bas person A's line.
  final String stem;

  /// Why the key is right; for writing and speaking tasks, the model response.
  final String explanation;
  final List<String> options;

  /// Index of the correct option.
  final List<int> answer;
  final String? setId;

  /// The spoken line of a Listen and Choose a Response item, e.g. "W: Is this seat taken?".
  final String? say;

  /// Build a Sentence: the reply's chunks in the correct order.
  final List<String> chunks;
  final String prefix;
  final String suffix;

  /// Build a Sentence: a chunk that does not belong.
  final String? extra;

  /// Build a Sentence: other correct orders of [chunks].
  final List<List<int>> alt;

  /// Write an Email: the three things to do.
  final List<String> bullets;
  final String? task;

  /// What a strong response does.
  final List<String> points;

  /// Academic discussion: the professor's name and the two students' posts.
  final String? prof;
  final List<Post> posts;

  List<Gap> get gaps => [
    for (final part in parseCtw(stem))
      if (part is CtwGap) part.gap,
  ];

  /// Points available: 10 for Complete the Words, 5 for writing and speaking tasks, else 1.
  int get maxPoints => switch (type) {
    QuestionType.ctw => 10,
    QuestionType.email || QuestionType.disc || QuestionType.repeat || QuestionType.interview => 5,
    _ => 1,
  };

  /// Build a Sentence: the chunks offered on screen (the reply's chunks plus the extra one), by index.
  List<String> get chunkBank => [...chunks, ?extra];

  /// Build a Sentence: the full correct reply.
  String get reply => [if (prefix.isNotEmpty) prefix, ...chunks].join(' ') + _suffixText;

  String get _suffixText => suffix.length > 1 ? ' $suffix' : suffix;

  /// The reply built from chunk indexes, for display.
  String replyFrom(List<int> order) =>
      [if (prefix.isNotEmpty) prefix, for (final i in order) chunkBank[i]].join(' ') + _suffixText;

  Line? get spoken => say == null ? null : Line.parse(say!);
}

/// A text, recording or scenario shared by several questions.
class QuestionSet {
  const QuestionSet({
    required this.title,
    required this.text,
    this.kind,
    this.script = const [],
    this.roles = const {},
    this.voice,
  });

  factory QuestionSet.fromJson(Json json) => QuestionSet(
    title: json['t'] as String? ?? '',
    text: json['x']! as String,
    kind: json['k'] as String?,
    script: [for (final line in _strings(json['sc'])) Line.parse(line)],
    roles: (json['r'] as Json? ?? const {}).cast<String, String>(),
    voice: json['v'] as String?,
  );

  final String title;

  /// The reading text, or the one-line situation of a recording, or a speaking scenario.
  final String text;

  /// Daily-life text type: email, notice, text messages, menu ...
  final String? kind;

  /// Listening script.
  final List<Line> script;

  /// Who the speakers are, e.g. {"W": "student", "M": "librarian"}.
  final Map<String, String> roles;

  /// Speaking: the voice of the manager or interviewer.
  final String? voice;

  bool get isAudio => script.isNotEmpty;
}

class TopicInfo {
  const TopicInfo({
    required this.key,
    required this.title,
    required this.practiceCount,
    required this.hasLesson,
  });

  factory TopicInfo.fromJson(Json json) => TopicInfo(
    key: json['key']! as String,
    title: json['title']! as String,
    practiceCount: json['practice']! as int,
    hasLesson: json['lesson'] as bool? ?? false,
  );

  final String key;
  final String title;

  /// Practice questions (or sets) in the pool.
  final int practiceCount;
  final bool hasLesson;
}

class SectionInfo {
  const SectionInfo({required this.key, required this.title, required this.topics});

  factory SectionInfo.fromJson(Json json) => SectionInfo(
    key: json['key']! as String,
    title: json['title']! as String,
    topics: _list(json['topics'], TopicInfo.fromJson),
  );

  final String key;
  final String title;
  final List<TopicInfo> topics;
}

/// Timing and routing of an adaptive section (Reading or Listening).
class AdaptiveInfo {
  const AdaptiveInfo({
    required this.key,
    required this.minutes,
    required this.items,
    required this.upperAt,
  });

  factory AdaptiveInfo.fromJson(Json json) => AdaptiveInfo(
    key: json['key']! as String,
    minutes: (json['minutes']! as Json).cast<String, int>(),
    items: (json['items']! as Json).cast<String, int>(),
    upperAt: json['upperAt']! as int,
  );

  final String key;

  /// Minutes for `router`, `lower` and `upper`.
  final Map<String, int> minutes;

  /// Points in `router`, `lower` and `upper`.
  final Map<String, int> items;

  /// Router points needed for the upper module.
  final int upperAt;
}

class Catalog {
  const Catalog({
    required this.sections,
    required this.adaptive,
    required this.writingMinutes,
    required this.speakingSeconds,
  });

  factory Catalog.fromJson(Json json) => Catalog(
    sections: _list(json['sections'], SectionInfo.fromJson),
    adaptive: _list(json['adaptive'], AdaptiveInfo.fromJson),
    writingMinutes: (json['writingMinutes']! as Json).cast<String, int>(),
    speakingSeconds: (json['speakingSeconds']! as Json).cast<String, int>(),
  );

  final List<SectionInfo> sections;
  final List<AdaptiveInfo> adaptive;

  /// Minutes for `bas`, `eml` and `dsc`.
  final Map<String, int> writingMinutes;

  /// Answer seconds for `lrp` (longest sentence) and `int`.
  final Map<String, int> speakingSeconds;

  AdaptiveInfo section(String key) => adaptive.firstWhere((a) => a.key == key);

  /// Title of a topic, falling back to its key for retired content.
  String topicTitle(String section, String topic) {
    for (final candidate in sections) {
      if (candidate.key != section) continue;
      for (final info in candidate.topics) {
        if (info.key == topic) return info.title;
      }
    }
    return topic;
  }
}

/// The router and both second modules of an adaptive section in one paper.
class ModulePaper {
  const ModulePaper({required this.router, required this.lower, required this.upper});

  factory ModulePaper.fromJson(Json json) => ModulePaper(
    router: _strings(json['router']),
    lower: _strings(json['lower']),
    upper: _strings(json['upper']),
  );

  final List<String> router;
  final List<String> lower;
  final List<String> upper;
}

/// One full-length mock test.
class Paper {
  const Paper({
    required this.id,
    required this.number,
    required this.title,
    required this.reading,
    required this.listening,
    required this.tasks,
  });

  factory Paper.fromJson(Json json) => Paper(
    id: json['id']! as String,
    number: json['number']! as int,
    title: json['title']! as String,
    reading: ModulePaper.fromJson(json['reading']! as Json),
    listening: ModulePaper.fromJson(json['listening']! as Json),
    tasks: {
      for (final MapEntry(:key, :value) in (json['tasks']! as Json).entries) key: _strings(value),
    },
  );

  final String id;
  final int number;
  final String title;
  final ModulePaper reading;
  final ModulePaper listening;

  /// Linear tasks: `bas`, `eml`, `dsc`, `lrp`, `int` to question ids.
  final Map<String, List<String>> tasks;

  ModulePaper module(String section) => section == 'reading' ? reading : listening;
}

/// One article of the Guide tab. Body lines: `## heading`, `- bullet`, `> example`, `! tip`, or a paragraph.
class GuideArticle {
  const GuideArticle({
    required this.id,
    required this.group,
    required this.title,
    required this.lines,
  });

  factory GuideArticle.fromJson(Json json) => GuideArticle(
    id: json['id']! as String,
    group: json['group']! as String,
    title: json['title']! as String,
    lines: _strings(json['lines']),
  );

  final String id;
  final String group;
  final String title;
  final List<String> lines;
}

class Lesson {
  const Lesson({
    required this.section,
    required this.topic,
    required this.title,
    required this.minutes,
    required this.lines,
  });

  factory Lesson.fromJson(Json json) => Lesson(
    section: json['section']! as String,
    topic: json['topic']! as String,
    title: json['title']! as String,
    minutes: json['minutes'] as int? ?? 10,
    lines: _strings(json['lines']),
  );

  final String section;
  final String topic;
  final String title;
  final int minutes;
  final List<String> lines;
}

/// One vocabulary flashcard.
class VocabWord {
  const VocabWord({
    required this.word,
    required this.part,
    required this.definition,
    required this.example,
    required this.synonyms,
  });

  factory VocabWord.fromJson(Json json) => VocabWord(
    word: json['w']! as String,
    part: json['p'] as String? ?? '',
    definition: json['d']! as String,
    example: json['e'] as String? ?? '',
    synonyms: _strings(json['s']),
  );

  final String word;
  final String part;
  final String definition;
  final String example;
  final List<String> synonyms;
}
