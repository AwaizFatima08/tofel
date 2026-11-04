import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:toefl_prep/features/about/about_screen.dart';
import 'package:toefl_prep/features/exam/exam_screen.dart';
import 'package:toefl_prep/features/guide/guide_article_screen.dart';
import 'package:toefl_prep/features/home/home_screen.dart';
import 'package:toefl_prep/features/home/paper_screen.dart';
import 'package:toefl_prep/features/practice/practice_screen.dart';
import 'package:toefl_prep/features/practice/task_practice_screen.dart';
import 'package:toefl_prep/features/practice/topic_screen.dart';
import 'package:toefl_prep/features/results/rate_screen.dart';
import 'package:toefl_prep/features/results/results_screen.dart';
import 'package:toefl_prep/features/results/review_screen.dart';
import 'package:toefl_prep/features/vocab/vocab_screen.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/vocab', builder: (_, _) => const VocabScreen()),
      GoRoute(
        path: '/paper/:id',
        builder: (_, state) => PaperScreen(paperId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/exam/:id',
        builder: (_, state) => ExamScreen(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/results/:id',
        builder: (_, state) => ResultsScreen(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (_, state) => ReviewScreen(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rate/:id/:section',
        builder: (_, state) => RateScreen(
          attemptId: state.pathParameters['id']!,
          section: state.pathParameters['section']!,
        ),
      ),
      GoRoute(
        path: '/task/:section/:id',
        builder: (_, state) => TaskPracticeScreen(
          section: state.pathParameters['section']!,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/guide/:id',
        builder: (_, state) => GuideArticleScreen(articleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lesson/:topic',
        builder: (_, state) => LessonScreen(topic: state.pathParameters['topic']!),
      ),
      GoRoute(
        path: '/topic/:section/:topic',
        builder: (_, state) => TopicScreen(
          section: state.pathParameters['section']!,
          topic: state.pathParameters['topic']!,
        ),
      ),
      GoRoute(
        path: '/practice/:section/:topic',
        builder: (_, state) => PracticeScreen(
          section: state.pathParameters['section']!,
          topic: state.pathParameters['topic']!,
        ),
      ),
    ],
  ),
);
