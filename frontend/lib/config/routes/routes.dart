import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/auth/presentation/pages/login_page.dart';
import 'package:news_lab/features/daily_news/domain/entities/article.dart';
import 'package:news_lab/features/daily_news/presentation/pages/article_detail/article_detail.dart';
import 'package:news_lab/features/daily_news/presentation/pages/home/daily_news.dart';
import 'package:news_lab/features/daily_news/presentation/pages/saved_article/saved_article.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/pages/journalist_profile_page.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_bloc.dart';
import 'package:news_lab/features/publish_article/presentation/pages/upload_article_page.dart';
import 'package:news_lab/injection_container.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _materialRoute(const DailyNews());

      case '/ArticleDetails':
        return _materialRoute(
            ArticleDetailsView(article: settings.arguments as ArticleEntity));

      case '/SavedArticles':
        return _materialRoute(const SavedArticles());

      case '/Login':
        return _materialRoute(const LoginPage());

      case '/UploadArticle':
        return _materialRoute(
          BlocProvider(
            create: (_) => sl<UploadArticleBloc>(),
            child: const UploadArticlePage(),
          ),
        );

      case '/JournalistProfile':
        final args = settings.arguments as JournalistProfileArgs;
        return _materialRoute(
          BlocProvider(
            create: (_) => sl<JournalistProfileBloc>()
              ..add(LoadJournalistProfile(args.authorId)),
            child: JournalistProfilePage(args: args),
          ),
        );

      default:
        return _materialRoute(const DailyNews());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }
}
