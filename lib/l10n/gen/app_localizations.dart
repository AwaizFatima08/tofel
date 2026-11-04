import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Prep Simulator for TOEFL'**
  String get appTitle;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this. Please restart the app. ({code})'**
  String loadError(String code);

  /// No description provided for @tabTests.
  ///
  /// In en, this message translates to:
  /// **'Mock tests'**
  String get tabTests;

  /// No description provided for @tabPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get tabPractice;

  /// No description provided for @tabGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get tabGuide;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @testsIntro.
  ///
  /// In en, this message translates to:
  /// **'{count} full-length mock tests in the current TOEFL iBT format (since January 2026): adaptive Reading and Listening, then Writing and Speaking, about 1 hour 30 minutes. Each section is scored 1-6 with an overall band, CEFR level and comparable 0-120 score.'**
  String testsIntro(int count);

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best overall band {band}'**
  String bestScore(String band);

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get notStarted;

  /// No description provided for @aboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} min'**
  String aboutMinutes(int minutes);

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'About {hours} h {minutes} min'**
  String totalTime(int hours, int minutes);

  /// No description provided for @stagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} timed parts, each with its own intro screen.'**
  String stagesCount(int count);

  /// No description provided for @partsReading.
  ///
  /// In en, this message translates to:
  /// **'Complete the Words, Read in Daily Life, Read an Academic Passage · router + module'**
  String get partsReading;

  /// No description provided for @partsListening.
  ///
  /// In en, this message translates to:
  /// **'Choose a Response, Conversations, Announcements, Academic Talks · router + module'**
  String get partsListening;

  /// No description provided for @partsWriting.
  ///
  /// In en, this message translates to:
  /// **'Build a Sentence (10), Write an Email, Academic Discussion'**
  String get partsWriting;

  /// No description provided for @partsSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Listen and Repeat (7), Take an Interview (4)'**
  String get partsSpeaking;

  /// No description provided for @bandLine.
  ///
  /// In en, this message translates to:
  /// **'R {reading} · L {listening} · W {writing} · S {speaking} · overall {overall}'**
  String bandLine(
    String reading,
    String listening,
    String writing,
    String speaking,
    String overall,
  );

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start mock test'**
  String get startTest;

  /// No description provided for @resumeTest.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeTest;

  /// No description provided for @restartTest.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get restartTest;

  /// No description provided for @paperRules.
  ///
  /// In en, this message translates to:
  /// **'Reading and Listening are adaptive: how you do in the first module decides whether the second is easier or harder. In Reading you can go back within a module; Listening runs forward only and every recording plays once, as on the test, so take notes. Writing has three timed tasks. Speaking runs by itself: listen, then speak when the microphone turns on. Use headphones in a quiet room. Leaving the app pauses the clock (the real test does not).'**
  String get paperRules;

  /// No description provided for @unofficialNote.
  ///
  /// In en, this message translates to:
  /// **'Independent practice test. Scores are estimates; ETS sets and scores the real TOEFL iBT.'**
  String get unofficialNote;

  /// No description provided for @previousAttempts.
  ///
  /// In en, this message translates to:
  /// **'Previous attempts'**
  String get previousAttempts;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}'**
  String questionOf(int number, int total);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @endSection.
  ///
  /// In en, this message translates to:
  /// **'End this part'**
  String get endSection;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @mark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get mark;

  /// No description provided for @marked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get marked;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @answeredOf.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} answered'**
  String answeredOf(int answered, int total);

  /// No description provided for @clearAnswer.
  ///
  /// In en, this message translates to:
  /// **'Clear answer'**
  String get clearAnswer;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left in this part'**
  String get timeLeft;

  /// No description provided for @timeLeftValue.
  ///
  /// In en, this message translates to:
  /// **'Time left {time}'**
  String timeLeftValue(String time);

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the test?'**
  String get leaveTitle;

  /// No description provided for @leaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved and the clock pauses. You can resume from the Mock tests tab. A recording that was playing will play again from the start.'**
  String get leaveBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @endSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'End this part?'**
  String get endSectionTitle;

  /// No description provided for @finishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish the test?'**
  String get finishTitle;

  /// No description provided for @endSectionBody.
  ///
  /// In en, this message translates to:
  /// **'You cannot return to this part after it ends.'**
  String get endSectionBody;

  /// No description provided for @unansweredWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question is not answered.} other{{count} questions are not answered.}} There is no penalty for guessing.'**
  String unansweredWarning(int count);

  /// No description provided for @keepWorking.
  ///
  /// In en, this message translates to:
  /// **'Keep working'**
  String get keepWorking;

  /// No description provided for @finishTest.
  ///
  /// In en, this message translates to:
  /// **'Finish and see scores'**
  String get finishTest;

  /// No description provided for @stageOf.
  ///
  /// In en, this message translates to:
  /// **'Part {number} of {total}'**
  String stageOf(int number, int total);

  /// No description provided for @stageSize.
  ///
  /// In en, this message translates to:
  /// **'{count} points · {minutes} minutes'**
  String stageSize(int count, int minutes);

  /// No description provided for @stageItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} · timed answers'**
  String stageItems(int count);

  /// No description provided for @beginSection.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get beginSection;

  /// No description provided for @introReading.
  ///
  /// In en, this message translates to:
  /// **'Complete the Words: type the missing letters to finish each word. Read in Daily Life and Read an Academic Passage: answer the questions about each text; the text stays on screen. You can go back and change answers within this module, and mark questions to revisit.'**
  String get introReading;

  /// No description provided for @introListening.
  ///
  /// In en, this message translates to:
  /// **'Each recording plays once, then its questions appear one by one. Notes are allowed. Choose a Response: hear one line and pick the best reply. Then conversations, announcements and short academic talks. You cannot go back in Listening.'**
  String get introListening;

  /// No description provided for @introBas.
  ///
  /// In en, this message translates to:
  /// **'Build a Sentence: for each short exchange, tap the word groups in the right order to make the reply. Tap a placed group to take it back. One group may not belong. About 6 minutes for 10 sentences.'**
  String get introBas;

  /// No description provided for @introEmail.
  ///
  /// In en, this message translates to:
  /// **'Write an Email: read the situation and write an email that does all three things listed. Use a greeting and a closing, and match your tone to the reader. 7 minutes; about 100-150 words is a good length. There is no spell-check.'**
  String get introEmail;

  /// No description provided for @introDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Write for an Academic Discussion: read the professor\'s question and two students\' posts, then post your own opinion with reasons and an example. Add something new to the discussion. 10 minutes; at least 100 words.'**
  String get introDiscussion;

  /// No description provided for @introRepeat.
  ///
  /// In en, this message translates to:
  /// **'Listen and Repeat: you will hear a short scenario, then 7 sentences one at a time. After each sentence the microphone turns on: repeat it exactly. The sentences get longer.'**
  String get introRepeat;

  /// No description provided for @introInterview.
  ///
  /// In en, this message translates to:
  /// **'Take an Interview: an interviewer asks 4 questions about one topic. After each question you have 45 seconds to answer. There is no preparation time; start speaking when the microphone turns on.'**
  String get introInterview;

  /// No description provided for @introAdaptive.
  ///
  /// In en, this message translates to:
  /// **'This first module is of medium difficulty. How you do here decides whether the second module is easier or harder; only the harder module opens the top bands (5-6).'**
  String get introAdaptive;

  /// No description provided for @introSound.
  ///
  /// In en, this message translates to:
  /// **'Turn your volume up and use headphones. Recordings are read by your phone\'s English voice; if you hear nothing, install or update the English voice in your phone\'s text-to-speech settings.'**
  String get introSound;

  /// No description provided for @sectionReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get sectionReading;

  /// No description provided for @sectionListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get sectionListening;

  /// No description provided for @sectionWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get sectionWriting;

  /// No description provided for @sectionSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get sectionSpeaking;

  /// No description provided for @moduleTitle.
  ///
  /// In en, this message translates to:
  /// **'{section} · Module {number}'**
  String moduleTitle(String section, int number);

  /// No description provided for @moduleN.
  ///
  /// In en, this message translates to:
  /// **'Module {number}'**
  String moduleN(int number);

  /// No description provided for @routeUpper.
  ///
  /// In en, this message translates to:
  /// **'harder'**
  String get routeUpper;

  /// No description provided for @routeLower.
  ///
  /// In en, this message translates to:
  /// **'easier'**
  String get routeLower;

  /// No description provided for @taskBas.
  ///
  /// In en, this message translates to:
  /// **'Build a Sentence'**
  String get taskBas;

  /// No description provided for @taskEmail.
  ///
  /// In en, this message translates to:
  /// **'Write an Email'**
  String get taskEmail;

  /// No description provided for @taskDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Academic Discussion'**
  String get taskDiscussion;

  /// No description provided for @taskRepeat.
  ///
  /// In en, this message translates to:
  /// **'Listen and Repeat'**
  String get taskRepeat;

  /// No description provided for @taskInterview.
  ///
  /// In en, this message translates to:
  /// **'Take an Interview'**
  String get taskInterview;

  /// No description provided for @ctwInstruction.
  ///
  /// In en, this message translates to:
  /// **'Fill in the missing letters in the paragraph.'**
  String get ctwInstruction;

  /// No description provided for @basInstruction.
  ///
  /// In en, this message translates to:
  /// **'Make an appropriate sentence. Tap the word groups in order.'**
  String get basInstruction;

  /// No description provided for @basHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the word groups below'**
  String get basHint;

  /// No description provided for @lcrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Choose the best response.'**
  String get lcrInstruction;

  /// No description provided for @lcrSituation.
  ///
  /// In en, this message translates to:
  /// **'Listen to the speaker and choose the best response.'**
  String get lcrSituation;

  /// No description provided for @listenOnce.
  ///
  /// In en, this message translates to:
  /// **'The recording plays once. Its questions appear when it ends.'**
  String get listenOnce;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get nowPlaying;

  /// No description provided for @recordingDone.
  ///
  /// In en, this message translates to:
  /// **'Recording finished.'**
  String get recordingDone;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @listenNow.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenNow;

  /// No description provided for @speakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now'**
  String get speakNow;

  /// No description provided for @recordingNow.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recordingNow;

  /// No description provided for @secondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String secondsLeft(int seconds);

  /// No description provided for @doneSpeaking.
  ///
  /// In en, this message translates to:
  /// **'I\'m done'**
  String get doneSpeaking;

  /// No description provided for @answerSaved.
  ///
  /// In en, this message translates to:
  /// **'Answer saved.'**
  String get answerSaved;

  /// No description provided for @micRefused.
  ///
  /// In en, this message translates to:
  /// **'The microphone is off for this app, so your answer cannot be recorded. Allow the microphone in your phone\'s settings, then try again.'**
  String get micRefused;

  /// No description provided for @speakerMan.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get speakerMan;

  /// No description provided for @speakerWoman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get speakerWoman;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Write your email here'**
  String get emailHint;

  /// No description provided for @discussionHint.
  ///
  /// In en, this message translates to:
  /// **'Write your post here'**
  String get discussionHint;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// No description provided for @readPassage.
  ///
  /// In en, this message translates to:
  /// **'Show text'**
  String get readPassage;

  /// No description provided for @hidePassage.
  ///
  /// In en, this message translates to:
  /// **'Hide text'**
  String get hidePassage;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get correctAnswer;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get check;

  /// No description provided for @estimatedScores.
  ///
  /// In en, this message translates to:
  /// **'Estimated overall band'**
  String get estimatedScores;

  /// No description provided for @overallLine.
  ///
  /// In en, this message translates to:
  /// **'CEFR {cefr} · comparable total about {total} / 120'**
  String overallLine(String cefr, int total);

  /// No description provided for @provisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional: rate your Writing and Speaking answers to complete the score (unrated tasks count as 0).'**
  String get provisional;

  /// No description provided for @scoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total}'**
  String scoreOutOf(int correct, int total);

  /// No description provided for @notRated.
  ///
  /// In en, this message translates to:
  /// **'not rated'**
  String get notRated;

  /// No description provided for @rubricPoints.
  ///
  /// In en, this message translates to:
  /// **'Rubric points'**
  String get rubricPoints;

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate your {section} answers ({count} to rate)'**
  String rateNow(String section, int count);

  /// No description provided for @modelAnswersFor.
  ///
  /// In en, this message translates to:
  /// **'{section}: your answers and model answers'**
  String modelAnswersFor(String section);

  /// No description provided for @reviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review answers and explanations'**
  String get reviewAnswers;

  /// No description provided for @weakTopics.
  ///
  /// In en, this message translates to:
  /// **'Tasks to work on'**
  String get weakTopics;

  /// No description provided for @scoreDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Practice estimate. ETS scores the real test with statistical equating and AI scoring of Writing and Speaking; these bands follow the 1-6 scale and its published 0-120 comparison but cannot match it exactly. Track your trend over several mocks.'**
  String get scoreDisclaimer;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backHome;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer review'**
  String get reviewTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get filterWrong;

  /// No description provided for @filterSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get filterSkipped;

  /// No description provided for @filterMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get filterMarked;

  /// No description provided for @filterEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get filterEmpty;

  /// No description provided for @notAnswered.
  ///
  /// In en, this message translates to:
  /// **'not answered'**
  String get notAnswered;

  /// No description provided for @hearRecording.
  ///
  /// In en, this message translates to:
  /// **'Hear the recording'**
  String get hearRecording;

  /// No description provided for @hearAgain.
  ///
  /// In en, this message translates to:
  /// **'Hear it again'**
  String get hearAgain;

  /// No description provided for @hearScenario.
  ///
  /// In en, this message translates to:
  /// **'Hear the scenario'**
  String get hearScenario;

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate: {section}'**
  String rateTitle(String section);

  /// No description provided for @rateIntro.
  ///
  /// In en, this message translates to:
  /// **'Compare each answer with the model and the description of each score, then pick the score that fits honestly. Listen to your recording before rating a spoken answer. Your ratings set the Writing and Speaking bands.'**
  String get rateIntro;

  /// No description provided for @sectionBand.
  ///
  /// In en, this message translates to:
  /// **'Section band: {band}'**
  String sectionBand(String band);

  /// No description provided for @stillToRate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer} other{{count} answers}} still to rate'**
  String stillToRate(int count);

  /// No description provided for @yourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get yourResponse;

  /// No description provided for @essayEmpty.
  ///
  /// In en, this message translates to:
  /// **'(Nothing written.)'**
  String get essayEmpty;

  /// No description provided for @strongResponse.
  ///
  /// In en, this message translates to:
  /// **'What a strong response does'**
  String get strongResponse;

  /// No description provided for @sentenceWas.
  ///
  /// In en, this message translates to:
  /// **'The sentence was'**
  String get sentenceWas;

  /// No description provided for @questionWas.
  ///
  /// In en, this message translates to:
  /// **'The question was'**
  String get questionWas;

  /// No description provided for @modelAnswer.
  ///
  /// In en, this message translates to:
  /// **'Model answer'**
  String get modelAnswer;

  /// No description provided for @whatToWatch.
  ///
  /// In en, this message translates to:
  /// **'What to watch'**
  String get whatToWatch;

  /// No description provided for @rateYourself.
  ///
  /// In en, this message translates to:
  /// **'Rate yourself (0-5)'**
  String get rateYourself;

  /// No description provided for @playMyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Play my answer'**
  String get playMyAnswer;

  /// No description provided for @stopPlaying.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPlaying;

  /// No description provided for @noRecording.
  ///
  /// In en, this message translates to:
  /// **'No recording saved.'**
  String get noRecording;

  /// No description provided for @writing5.
  ///
  /// In en, this message translates to:
  /// **'Fully successful: does everything the task asks, ideas well explained with details, clear organization, varied and precise language, almost no errors, tone right for the reader.'**
  String get writing5;

  /// No description provided for @writing4.
  ///
  /// In en, this message translates to:
  /// **'Generally successful: does the task with relevant, adequate support; one part a little thin; good language with a few minor errors.'**
  String get writing4;

  /// No description provided for @writing3.
  ///
  /// In en, this message translates to:
  /// **'Partly successful: understandable, but some of the task is missing or support is thin; noticeable errors sometimes distract.'**
  String get writing3;

  /// No description provided for @writing2.
  ///
  /// In en, this message translates to:
  /// **'Mostly unsuccessful: little development, limited vocabulary and grammar, frequent errors that make some ideas unclear.'**
  String get writing2;

  /// No description provided for @writing1.
  ///
  /// In en, this message translates to:
  /// **'Unsuccessful: very short or few connected ideas; errors make most of it hard to follow.'**
  String get writing1;

  /// No description provided for @writing0.
  ///
  /// In en, this message translates to:
  /// **'No response, off-topic, copied from the prompt, or not in English.'**
  String get writing0;

  /// No description provided for @repeat5.
  ///
  /// In en, this message translates to:
  /// **'Exact: every word in the right order, clear and natural.'**
  String get repeat5;

  /// No description provided for @repeat4.
  ///
  /// In en, this message translates to:
  /// **'One small slip (an article or ending), meaning kept, easy to understand.'**
  String get repeat4;

  /// No description provided for @repeat3.
  ///
  /// In en, this message translates to:
  /// **'A few words changed or missing, but the meaning is mostly kept.'**
  String get repeat3;

  /// No description provided for @repeat2.
  ///
  /// In en, this message translates to:
  /// **'Parts of the sentence missing or changed; meaning partly lost.'**
  String get repeat2;

  /// No description provided for @repeat1.
  ///
  /// In en, this message translates to:
  /// **'Only a few words of the sentence.'**
  String get repeat1;

  /// No description provided for @repeat0.
  ///
  /// In en, this message translates to:
  /// **'No answer, or nothing recognizable.'**
  String get repeat0;

  /// No description provided for @interview5.
  ///
  /// In en, this message translates to:
  /// **'Answers the question fully and fluently, with reasons and examples; varied, accurate language; easy to understand throughout.'**
  String get interview5;

  /// No description provided for @interview4.
  ///
  /// In en, this message translates to:
  /// **'Answers well with some development; mostly fluent; minor errors or hesitation.'**
  String get interview4;

  /// No description provided for @interview3.
  ///
  /// In en, this message translates to:
  /// **'Answers the question but development is limited; noticeable pauses or errors; generally understandable.'**
  String get interview3;

  /// No description provided for @interview2.
  ///
  /// In en, this message translates to:
  /// **'Short or partly relevant answer; frequent pauses or errors; sometimes hard to follow.'**
  String get interview2;

  /// No description provided for @interview1.
  ///
  /// In en, this message translates to:
  /// **'A few words or phrases only; very hard to understand.'**
  String get interview1;

  /// No description provided for @interview0.
  ///
  /// In en, this message translates to:
  /// **'No answer or not related to the question.'**
  String get interview0;

  /// No description provided for @practiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Every TOEFL task, each with a lesson and its own practice items (never used in the mock tests). Answers and explanations show as you go; listening can be replayed with a transcript.'**
  String get practiceIntro;

  /// No description provided for @lesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lesson;

  /// No description provided for @lessonHelp.
  ///
  /// In en, this message translates to:
  /// **'What\'s on screen, method, examples and traps'**
  String get lessonHelp;

  /// No description provided for @practiceSet.
  ///
  /// In en, this message translates to:
  /// **'Practice set'**
  String get practiceSet;

  /// No description provided for @practicePool.
  ///
  /// In en, this message translates to:
  /// **'{count} practice items'**
  String practicePool(int count);

  /// No description provided for @practiceTally.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} points so far'**
  String practiceTally(int correct, int total);

  /// No description provided for @practiceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice items here yet.'**
  String get practiceEmpty;

  /// No description provided for @practiceDone.
  ///
  /// In en, this message translates to:
  /// **'Set complete'**
  String get practiceDone;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Another set'**
  String get practiceAgain;

  /// No description provided for @backToTopic.
  ///
  /// In en, this message translates to:
  /// **'Back to task'**
  String get backToTopic;

  /// No description provided for @practiceNow.
  ///
  /// In en, this message translates to:
  /// **'Practice this task'**
  String get practiceNow;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} minutes'**
  String readingTime(int minutes);

  /// No description provided for @levelName.
  ///
  /// In en, this message translates to:
  /// **'{level, select, 1{Easy} 2{Medium} other{Hard}}'**
  String levelName(String level);

  /// No description provided for @taskPracticeIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick one. Do the task under the real time limit, then compare with the model answer and rate yourself.'**
  String get taskPracticeIntro;

  /// No description provided for @doneShowModel.
  ///
  /// In en, this message translates to:
  /// **'Done: show the model answer'**
  String get doneShowModel;

  /// No description provided for @startSentence.
  ///
  /// In en, this message translates to:
  /// **'Start: hear the sentence'**
  String get startSentence;

  /// No description provided for @startQuestion.
  ///
  /// In en, this message translates to:
  /// **'Start: hear the question'**
  String get startQuestion;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary flashcards'**
  String get vocabulary;

  /// No description provided for @vocabularyHelp.
  ///
  /// In en, this message translates to:
  /// **'Academic words, phrasal verbs and idioms with meanings, examples and synonyms'**
  String get vocabularyHelp;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @includeKnown.
  ///
  /// In en, this message translates to:
  /// **'Include words I know'**
  String get includeKnown;

  /// No description provided for @vocabProgress.
  ///
  /// In en, this message translates to:
  /// **'{known} of {total} words known'**
  String vocabProgress(int known, int total);

  /// No description provided for @vocabDone.
  ///
  /// In en, this message translates to:
  /// **'You have marked every word as known. Switch on \"Include words I know\" to review.'**
  String get vocabDone;

  /// No description provided for @cardOf.
  ///
  /// In en, this message translates to:
  /// **'Card {number} of {total}'**
  String cardOf(int number, int total);

  /// No description provided for @markKnown.
  ///
  /// In en, this message translates to:
  /// **'I know this'**
  String get markKnown;

  /// No description provided for @unmarkKnown.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get unmarkKnown;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to see the meaning'**
  String get tapToReveal;

  /// No description provided for @synonyms.
  ///
  /// In en, this message translates to:
  /// **'Synonyms: {list}'**
  String synonyms(String list);

  /// No description provided for @progressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Take a mock test or a practice set and your progress shows here.'**
  String get progressEmpty;

  /// No description provided for @testsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mocks taken'**
  String get testsTaken;

  /// No description provided for @averageOverall.
  ///
  /// In en, this message translates to:
  /// **'Average band'**
  String get averageOverall;

  /// No description provided for @recentOverall.
  ///
  /// In en, this message translates to:
  /// **'Last 3 mocks'**
  String get recentOverall;

  /// No description provided for @topicMastery.
  ///
  /// In en, this message translates to:
  /// **'Weakest tasks'**
  String get topicMastery;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @percentLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentLabel(int percent);

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy;

  /// No description provided for @privacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices (ads)'**
  String get privacyChoices;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact: homilabs.smc@gmail.com'**
  String get contact;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Prep Simulator for TOEFL is an independent practice app by HomiLabs. TOEFL® and TOEFL iBT® are registered trademarks of ETS. This app is not endorsed or approved by ETS and is not affiliated with it. All texts, recordings, questions, prompts, lessons and explanations are original practice material written for this app, not real test questions, and scores are practice estimates only. Listening recordings are spoken by your phone\'s text-to-speech voice. Your answers and voice recordings stay on your phone.'**
  String get aboutBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
