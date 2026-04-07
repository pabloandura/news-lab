import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/auth/presentation/screens/login_page.dart';
import 'package:news_lab/features/daily_news/presentation/screens/article_detail/article_detail.dart';
import 'package:news_lab/features/daily_news/presentation/screens/home/daily_news.dart';
import 'package:news_lab/features/daily_news/presentation/screens/saved_article/saved_article.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/screens/journalist_profile_page.dart';
import 'package:news_lab/injection_container.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const articleDetails = '/ArticleDetails';
  static const savedArticles = '/SavedArticles';
  static const login = '/Login';
  static const journalistProfile = '/JournalistProfile';

  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _materialRoute(const DailyNews());

      case articleDetails:
        return _materialRoute(
            ArticleDetailsView(article: settings.arguments as ArticleEntity));

      case savedArticles:
        return _materialRoute(const SavedArticles());

      case login:
        return _materialRoute(const LoginPage());

      case journalistProfile:
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
