import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_bloc.dart';
import 'package:news_lab/features/publish_article/presentation/screens/upload_article_page.dart';
import 'package:news_lab/injection_container.dart';

/// Wraps UploadArticlePage with its required BlocProvider for the Publish tab.
class PublishTabPage extends StatelessWidget {
  final VoidCallback? onPublishSuccess;

  const PublishTabPage({super.key, this.onPublishSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UploadArticleBloc>(),
      child: UploadArticlePage(isTab: true, onPublishSuccess: onPublishSuccess),
    );
  }
}
