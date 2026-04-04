import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/config/theme/app_themes.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_event.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/app_shell/app_shell.dart';
import 'package:news_lab/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDependencies();
  runApp(const NewsLabApp());
}

class NewsLabApp extends StatelessWidget {
  const NewsLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<RemoteArticlesBloc>(
          create: (_) => sl<RemoteArticlesBloc>()..add(const GetArticles()),
        ),
        BlocProvider<ArticleCategoryCubit>(
          create: (_) => sl<ArticleCategoryCubit>()..load(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'News Lab',
        theme: theme(),
        onGenerateRoute: AppRoutes.onGenerateRoutes,
        home: const AppShell(),
      ),
    );
  }
}
