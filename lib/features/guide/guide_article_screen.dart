import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl_prep/content/content_repository.dart';
import 'package:toefl_prep/ui/async_value_view.dart';
import 'package:toefl_prep/ui/rich_lines.dart';
import 'package:toefl_prep/ui/theme.dart';

class GuideArticleScreen extends ConsumerWidget {
  const GuideArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncValueView(
    value: ref.watch(guideProvider),
    data: (articles) {
      final article = articles.firstWhere((candidate) => candidate.id == articleId);
      return Scaffold(
        appBar: AppBar(title: Text(article.title)),
        body: ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          children: [RichLines(article.lines)],
        ),
      );
    },
  );
}
