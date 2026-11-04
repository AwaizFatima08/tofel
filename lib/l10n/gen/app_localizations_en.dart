// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Prep Simulator for TOEFL';

  @override
  String loadError(String code) {
    return 'Could not load this. Please restart the app. ($code)';
  }

  @override
  String get tabTests => 'Mock tests';

  @override
  String get tabPractice => 'Practice';

  @override
  String get tabGuide => 'Guide';

  @override
  String get tabProgress => 'Progress';

  @override
  String get about => 'About';

  @override
  String testsIntro(int count) {
    return '$count full-length mock tests in the current TOEFL iBT format (since January 2026): adaptive Reading and Listening, then Writing and Speaking, about 1 hour 30 minutes. Each section is scored 1-6 with an overall band, CEFR level and comparable 0-120 score.';
  }

  @override
  String bestScore(String band) {
    return 'Best overall band $band';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get notStarted => 'Not taken';

  @override
  String aboutMinutes(int minutes) {
    return 'about $minutes min';
  }

  @override
  String totalTime(int hours, int minutes) {
    return 'About $hours h $minutes min';
  }

  @override
  String stagesCount(int count) {
    return '$count timed parts, each with its own intro screen.';
  }

  @override
  String get partsReading =>
      'Complete the Words, Read in Daily Life, Read an Academic Passage · router + module';

  @override
  String get partsListening =>
      'Choose a Response, Conversations, Announcements, Academic Talks · router + module';

  @override
  String get partsWriting => 'Build a Sentence (10), Write an Email, Academic Discussion';

  @override
  String get partsSpeaking => 'Listen and Repeat (7), Take an Interview (4)';

  @override
  String bandLine(
    String reading,
    String listening,
    String writing,
    String speaking,
    String overall,
  ) {
    return 'R $reading · L $listening · W $writing · S $speaking · overall $overall';
  }

  @override
  String get startTest => 'Start mock test';

  @override
  String get resumeTest => 'Resume';

  @override
  String get restartTest => 'Start again';

  @override
  String get paperRules =>
      'Reading and Listening are adaptive: how you do in the first module decides whether the second is easier or harder. In Reading you can go back within a module; Listening runs forward only and every recording plays once, as on the test, so take notes. Writing has three timed tasks. Speaking runs by itself: listen, then speak when the microphone turns on. Use headphones in a quiet room. Leaving the app pauses the clock (the real test does not).';

  @override
  String get unofficialNote =>
      'Independent practice test. Scores are estimates; ETS sets and scores the real TOEFL iBT.';

  @override
  String get previousAttempts => 'Previous attempts';

  @override
  String questionOf(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String get previous => 'Back';

  @override
  String get next => 'Next';

  @override
  String get review => 'Review';

  @override
  String get endSection => 'End this part';

  @override
  String get finish => 'Finish';

  @override
  String get mark => 'Mark';

  @override
  String get marked => 'Marked';

  @override
  String get answered => 'Answered';

  @override
  String answeredOf(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String get clearAnswer => 'Clear answer';

  @override
  String get timeLeft => 'Time left in this part';

  @override
  String timeLeftValue(String time) {
    return 'Time left $time';
  }

  @override
  String get leaveTitle => 'Leave the test?';

  @override
  String get leaveBody =>
      'Your answers are saved and the clock pauses. You can resume from the Mock tests tab. A recording that was playing will play again from the start.';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get endSectionTitle => 'End this part?';

  @override
  String get finishTitle => 'Finish the test?';

  @override
  String get endSectionBody => 'You cannot return to this part after it ends.';

  @override
  String unansweredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions are not answered.',
      one: '1 question is not answered.',
    );
    return '$_temp0 There is no penalty for guessing.';
  }

  @override
  String get keepWorking => 'Keep working';

  @override
  String get finishTest => 'Finish and see scores';

  @override
  String stageOf(int number, int total) {
    return 'Part $number of $total';
  }

  @override
  String stageSize(int count, int minutes) {
    return '$count points · $minutes minutes';
  }

  @override
  String stageItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0 · timed answers';
  }

  @override
  String get beginSection => 'Begin';

  @override
  String get introReading =>
      'Complete the Words: type the missing letters to finish each word. Read in Daily Life and Read an Academic Passage: answer the questions about each text; the text stays on screen. You can go back and change answers within this module, and mark questions to revisit.';

  @override
  String get introListening =>
      'Each recording plays once, then its questions appear one by one. Notes are allowed. Choose a Response: hear one line and pick the best reply. Then conversations, announcements and short academic talks. You cannot go back in Listening.';

  @override
  String get introBas =>
      'Build a Sentence: for each short exchange, tap the word groups in the right order to make the reply. Tap a placed group to take it back. One group may not belong. About 6 minutes for 10 sentences.';

  @override
  String get introEmail =>
      'Write an Email: read the situation and write an email that does all three things listed. Use a greeting and a closing, and match your tone to the reader. 7 minutes; about 100-150 words is a good length. There is no spell-check.';

  @override
  String get introDiscussion =>
      'Write for an Academic Discussion: read the professor\'s question and two students\' posts, then post your own opinion with reasons and an example. Add something new to the discussion. 10 minutes; at least 100 words.';

  @override
  String get introRepeat =>
      'Listen and Repeat: you will hear a short scenario, then 7 sentences one at a time. After each sentence the microphone turns on: repeat it exactly. The sentences get longer.';

  @override
  String get introInterview =>
      'Take an Interview: an interviewer asks 4 questions about one topic. After each question you have 45 seconds to answer. There is no preparation time; start speaking when the microphone turns on.';

  @override
  String get introAdaptive =>
      'This first module is of medium difficulty. How you do here decides whether the second module is easier or harder; only the harder module opens the top bands (5-6).';

  @override
  String get introSound =>
      'Turn your volume up and use headphones. Recordings are read by your phone\'s English voice; if you hear nothing, install or update the English voice in your phone\'s text-to-speech settings.';

  @override
  String get sectionReading => 'Reading';

  @override
  String get sectionListening => 'Listening';

  @override
  String get sectionWriting => 'Writing';

  @override
  String get sectionSpeaking => 'Speaking';

  @override
  String moduleTitle(String section, int number) {
    return '$section · Module $number';
  }

  @override
  String moduleN(int number) {
    return 'Module $number';
  }

  @override
  String get routeUpper => 'harder';

  @override
  String get routeLower => 'easier';

  @override
  String get taskBas => 'Build a Sentence';

  @override
  String get taskEmail => 'Write an Email';

  @override
  String get taskDiscussion => 'Academic Discussion';

  @override
  String get taskRepeat => 'Listen and Repeat';

  @override
  String get taskInterview => 'Take an Interview';

  @override
  String get ctwInstruction => 'Fill in the missing letters in the paragraph.';

  @override
  String get basInstruction => 'Make an appropriate sentence. Tap the word groups in order.';

  @override
  String get basHint => 'Tap the word groups below';

  @override
  String get lcrInstruction => 'Choose the best response.';

  @override
  String get lcrSituation => 'Listen to the speaker and choose the best response.';

  @override
  String get listenOnce => 'The recording plays once. Its questions appear when it ends.';

  @override
  String get nowPlaying => 'Listening…';

  @override
  String get recordingDone => 'Recording finished.';

  @override
  String get play => 'Play';

  @override
  String get playAgain => 'Play again';

  @override
  String get listenNow => 'Listen';

  @override
  String get speakNow => 'Speak now';

  @override
  String get recordingNow => 'Recording';

  @override
  String secondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get doneSpeaking => 'I\'m done';

  @override
  String get answerSaved => 'Answer saved.';

  @override
  String get micRefused =>
      'The microphone is off for this app, so your answer cannot be recorded. Allow the microphone in your phone\'s settings, then try again.';

  @override
  String get speakerMan => 'Man';

  @override
  String get speakerWoman => 'Woman';

  @override
  String get transcript => 'Transcript';

  @override
  String get emailHint => 'Write your email here';

  @override
  String get discussionHint => 'Write your post here';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get readPassage => 'Show text';

  @override
  String get hidePassage => 'Hide text';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get correctAnswer => 'Correct answer';

  @override
  String get explanation => 'Explanation';

  @override
  String get check => 'Check answer';

  @override
  String get estimatedScores => 'Estimated overall band';

  @override
  String overallLine(String cefr, int total) {
    return 'CEFR $cefr · comparable total about $total / 120';
  }

  @override
  String get provisional =>
      'Provisional: rate your Writing and Speaking answers to complete the score (unrated tasks count as 0).';

  @override
  String scoreOutOf(int correct, int total) {
    return '$correct of $total';
  }

  @override
  String get notRated => 'not rated';

  @override
  String get rubricPoints => 'Rubric points';

  @override
  String rateNow(String section, int count) {
    return 'Rate your $section answers ($count to rate)';
  }

  @override
  String modelAnswersFor(String section) {
    return '$section: your answers and model answers';
  }

  @override
  String get reviewAnswers => 'Review answers and explanations';

  @override
  String get weakTopics => 'Tasks to work on';

  @override
  String get scoreDisclaimer =>
      'Practice estimate. ETS scores the real test with statistical equating and AI scoring of Writing and Speaking; these bands follow the 1-6 scale and its published 0-120 comparison but cannot match it exactly. Track your trend over several mocks.';

  @override
  String get backHome => 'Back to home';

  @override
  String get reviewTitle => 'Answer review';

  @override
  String get filterAll => 'All';

  @override
  String get filterWrong => 'Wrong';

  @override
  String get filterSkipped => 'Skipped';

  @override
  String get filterMarked => 'Marked';

  @override
  String get filterEmpty => 'Nothing here.';

  @override
  String get notAnswered => 'not answered';

  @override
  String get hearRecording => 'Hear the recording';

  @override
  String get hearAgain => 'Hear it again';

  @override
  String get hearScenario => 'Hear the scenario';

  @override
  String rateTitle(String section) {
    return 'Rate: $section';
  }

  @override
  String get rateIntro =>
      'Compare each answer with the model and the description of each score, then pick the score that fits honestly. Listen to your recording before rating a spoken answer. Your ratings set the Writing and Speaking bands.';

  @override
  String sectionBand(String band) {
    return 'Section band: $band';
  }

  @override
  String stillToRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers',
      one: '1 answer',
    );
    return '$_temp0 still to rate';
  }

  @override
  String get yourResponse => 'Your response';

  @override
  String get essayEmpty => '(Nothing written.)';

  @override
  String get strongResponse => 'What a strong response does';

  @override
  String get sentenceWas => 'The sentence was';

  @override
  String get questionWas => 'The question was';

  @override
  String get modelAnswer => 'Model answer';

  @override
  String get whatToWatch => 'What to watch';

  @override
  String get rateYourself => 'Rate yourself (0-5)';

  @override
  String get playMyAnswer => 'Play my answer';

  @override
  String get stopPlaying => 'Stop';

  @override
  String get noRecording => 'No recording saved.';

  @override
  String get writing5 =>
      'Fully successful: does everything the task asks, ideas well explained with details, clear organization, varied and precise language, almost no errors, tone right for the reader.';

  @override
  String get writing4 =>
      'Generally successful: does the task with relevant, adequate support; one part a little thin; good language with a few minor errors.';

  @override
  String get writing3 =>
      'Partly successful: understandable, but some of the task is missing or support is thin; noticeable errors sometimes distract.';

  @override
  String get writing2 =>
      'Mostly unsuccessful: little development, limited vocabulary and grammar, frequent errors that make some ideas unclear.';

  @override
  String get writing1 =>
      'Unsuccessful: very short or few connected ideas; errors make most of it hard to follow.';

  @override
  String get writing0 => 'No response, off-topic, copied from the prompt, or not in English.';

  @override
  String get repeat5 => 'Exact: every word in the right order, clear and natural.';

  @override
  String get repeat4 => 'One small slip (an article or ending), meaning kept, easy to understand.';

  @override
  String get repeat3 => 'A few words changed or missing, but the meaning is mostly kept.';

  @override
  String get repeat2 => 'Parts of the sentence missing or changed; meaning partly lost.';

  @override
  String get repeat1 => 'Only a few words of the sentence.';

  @override
  String get repeat0 => 'No answer, or nothing recognizable.';

  @override
  String get interview5 =>
      'Answers the question fully and fluently, with reasons and examples; varied, accurate language; easy to understand throughout.';

  @override
  String get interview4 =>
      'Answers well with some development; mostly fluent; minor errors or hesitation.';

  @override
  String get interview3 =>
      'Answers the question but development is limited; noticeable pauses or errors; generally understandable.';

  @override
  String get interview2 =>
      'Short or partly relevant answer; frequent pauses or errors; sometimes hard to follow.';

  @override
  String get interview1 => 'A few words or phrases only; very hard to understand.';

  @override
  String get interview0 => 'No answer or not related to the question.';

  @override
  String get practiceIntro =>
      'Every TOEFL task, each with a lesson and its own practice items (never used in the mock tests). Answers and explanations show as you go; listening can be replayed with a transcript.';

  @override
  String get lesson => 'Lesson';

  @override
  String get lessonHelp => 'What\'s on screen, method, examples and traps';

  @override
  String get practiceSet => 'Practice set';

  @override
  String practicePool(int count) {
    return '$count practice items';
  }

  @override
  String practiceTally(int correct, int total) {
    return '$correct of $total points so far';
  }

  @override
  String get practiceEmpty => 'No practice items here yet.';

  @override
  String get practiceDone => 'Set complete';

  @override
  String get practiceAgain => 'Another set';

  @override
  String get backToTopic => 'Back to task';

  @override
  String get practiceNow => 'Practice this task';

  @override
  String readingTime(int minutes) {
    return 'About $minutes minutes';
  }

  @override
  String levelName(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        '1': 'Easy',
        '2': 'Medium',
        'other': 'Hard',
      },
    );
    return '$_temp0';
  }

  @override
  String get taskPracticeIntro =>
      'Pick one. Do the task under the real time limit, then compare with the model answer and rate yourself.';

  @override
  String get doneShowModel => 'Done: show the model answer';

  @override
  String get startSentence => 'Start: hear the sentence';

  @override
  String get startQuestion => 'Start: hear the question';

  @override
  String get tryAgain => 'Try again';

  @override
  String get vocabulary => 'Vocabulary flashcards';

  @override
  String get vocabularyHelp =>
      'Academic words, phrasal verbs and idioms with meanings, examples and synonyms';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get includeKnown => 'Include words I know';

  @override
  String vocabProgress(int known, int total) {
    return '$known of $total words known';
  }

  @override
  String get vocabDone =>
      'You have marked every word as known. Switch on \"Include words I know\" to review.';

  @override
  String cardOf(int number, int total) {
    return 'Card $number of $total';
  }

  @override
  String get markKnown => 'I know this';

  @override
  String get unmarkKnown => 'Not yet';

  @override
  String get tapToReveal => 'Tap to see the meaning';

  @override
  String synonyms(String list) {
    return 'Synonyms: $list';
  }

  @override
  String get progressEmpty => 'Take a mock test or a practice set and your progress shows here.';

  @override
  String get testsTaken => 'Mocks taken';

  @override
  String get averageOverall => 'Average band';

  @override
  String get recentOverall => 'Last 3 mocks';

  @override
  String get topicMastery => 'Weakest tasks';

  @override
  String get history => 'History';

  @override
  String percentLabel(int percent) {
    return '$percent%';
  }

  @override
  String get version => 'Version 1.0.0';

  @override
  String get website => 'Website';

  @override
  String get privacy => 'Privacy policy';

  @override
  String get privacyChoices => 'Privacy choices (ads)';

  @override
  String get terms => 'Terms of use';

  @override
  String get contact => 'Contact: homilabs.smc@gmail.com';

  @override
  String get aboutBody =>
      'Prep Simulator for TOEFL is an independent practice app by HomiLabs. TOEFL® and TOEFL iBT® are registered trademarks of ETS. This app is not endorsed or approved by ETS and is not affiliated with it. All texts, recordings, questions, prompts, lessons and explanations are original practice material written for this app, not real test questions, and scores are practice estimates only. Listening recordings are spoken by your phone\'s text-to-speech voice. Your answers and voice recordings stay on your phone.';
}
