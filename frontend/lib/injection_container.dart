import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:news_lab/core/data/data_sources/articles_remote_data_source.dart';
import 'package:news_lab/core/data/data_sources/articles_storage_data_source.dart';
import 'package:news_lab/features/bias_report/data/data_sources/bias_report_remote_data_source.dart';
import 'package:news_lab/features/bias_report/data/data_sources/polarize_api_data_source.dart';
import 'package:news_lab/features/bias_report/data/repository/bias_report_repository_impl.dart';
import 'package:news_lab/features/bias_report/domain/repository/bias_report_repository.dart';
import 'package:news_lab/features/bias_report/domain/usecases/get_bias_report_usecase.dart';
import 'package:news_lab/features/bias_report/domain/usecases/run_polarize_use_case.dart';
import 'package:news_lab/features/bias_report/domain/usecases/watch_bias_report_use_case.dart';
import 'package:news_lab/features/bias_report/presentation/bloc/bias_report_bloc.dart';
import 'package:news_lab/features/fact_check/data/data_sources/bot_check_api_data_source.dart';
import 'package:news_lab/features/fact_check/data/data_sources/fact_check_remote_data_source.dart';
import 'package:news_lab/features/fact_check/data/repository/fact_check_repository_impl.dart';
import 'package:news_lab/features/fact_check/domain/repository/fact_check_repository.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_article_list_fact_checks_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/get_fact_check_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/run_bot_check_use_case.dart';
import 'package:news_lab/features/fact_check/domain/usecases/submit_community_vote_usecase.dart';
import 'package:news_lab/features/fact_check/domain/usecases/watch_bot_check_use_case.dart';
import 'package:news_lab/features/fact_check/presentation/bloc/fact_check_bloc.dart';
import 'package:news_lab/features/article_category/data/data_sources/article_category_data_source.dart';
import 'package:news_lab/features/article_category/data/repository/article_category_repository_impl.dart';
import 'package:news_lab/features/article_category/domain/repository/article_category_repository.dart';
import 'package:news_lab/features/article_category/domain/usecases/get_categories_usecase.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:news_lab/features/auth/data/repository/auth_repository_impl.dart';
import 'package:news_lab/features/auth/domain/repository/auth_repository.dart';
import 'package:news_lab/features/auth/domain/usecases/get_current_user.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_in.dart';
import 'package:news_lab/features/auth/domain/usecases/sign_out.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/daily_news/data/data_sources/local/app_database.dart';
import 'package:news_lab/features/daily_news/data/data_sources/remote/news_api_service.dart';
import 'package:news_lab/features/daily_news/data/repository/article_repository_impl.dart';
import 'package:news_lab/features/daily_news/domain/repository/article_repository.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_article.dart';
import 'package:news_lab/features/daily_news/domain/usecases/get_saved_article.dart';
import 'package:news_lab/features/daily_news/domain/usecases/remove_article.dart';
import 'package:news_lab/features/daily_news/domain/usecases/save_article.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/local/local_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/journalist_profile/data/data_sources/journalist_profile_data_source.dart';
import 'package:news_lab/features/journalist_profile/data/repository/journalist_profile_repository_impl.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/delete_article_usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/get_journalist_articles_usecase.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/update_article_usecase.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/publish_article/data/repository/publish_article_repository_impl.dart';
import 'package:news_lab/features/publish_article/domain/repository/publish_article_repository.dart';
import 'package:news_lab/features/publish_article/domain/usecases/upload_article.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_bloc.dart';
import 'package:news_lab/features/similar_articles/data/data_sources/sensemaker_api_data_source.dart';
import 'package:news_lab/features/similar_articles/data/repository/similar_articles_repository_impl.dart';
import 'package:news_lab/features/similar_articles/domain/repository/similar_articles_repository.dart';
import 'package:news_lab/features/similar_articles/domain/usecases/get_similar_articles_usecase.dart';
import 'package:news_lab/features/similar_articles/presentation/bloc/similar_articles_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // ── Local DB ──────────────────────────────────────────────────────────────
  final database =
      await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  sl.registerSingleton<AppDatabase>(database);

  // ── HTTP ──────────────────────────────────────────────────────────────────
  sl.registerSingleton<Dio>(Dio());

  // ── Firebase ──────────────────────────────────────────────────────────────
  sl.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  sl.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  sl.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // ── Core data sources ─────────────────────────────────────────────────────
  sl.registerSingleton<ArticlesRemoteDataSource>(
      ArticlesRemoteDataSourceImpl(sl()));
  sl.registerSingleton<ArticlesStorageDataSource>(
      ArticlesStorageDataSourceImpl(sl()));

  // ── daily_news data sources ───────────────────────────────────────────────
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));

  // ── auth data sources ─────────────────────────────────────────────────────
  sl.registerSingleton<AuthRemoteDataSource>(AuthRemoteDataSourceImpl(sl()));

  // ── journalist_profile data sources ───────────────────────────────────────
  sl.registerSingleton<JournalistProfileDataSource>(
      JournalistProfileDataSourceImpl(sl()));

  // ── article_category data sources ─────────────────────────────────────────
  sl.registerSingleton<ArticleCategoryDataSource>(
      ArticleCategoryDataSourceImpl(sl()));

  // ── fact_check data sources ───────────────────────────────────────────────
  sl.registerSingleton<FactCheckRemoteDataSource>(
      FactCheckRemoteDataSourceImpl(sl()));
  sl.registerSingleton<BotCheckApiDataSource>(
      BotCheckApiDataSourceImpl(sl(), sl()));

  // ── bias_report data sources ──────────────────────────────────────────────
  sl.registerSingleton<BiasReportRemoteDataSource>(
      BiasReportRemoteDataSourceImpl(sl()));
  sl.registerSingleton<PolarizeApiDataSource>(
      PolarizeApiDataSourceImpl(sl(), sl()));

  // ── similar_articles data sources ─────────────────────────────────────────
  sl.registerSingleton<SensemakerApiDataSource>(
      SensemakerApiDataSourceImpl(sl(), sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerSingleton<ArticleRepository>(
      ArticleRepositoryImpl(sl(), sl(), sl()));
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl(sl()));
  sl.registerSingleton<PublishArticleRepository>(
      PublishArticleRepositoryImpl(sl(), sl()));
  sl.registerSingleton<JournalistProfileRepository>(
      JournalistProfileRepositoryImpl(sl(), sl()));
  sl.registerSingleton<ArticleCategoryRepository>(
      ArticleCategoryRepositoryImpl(sl()));
  sl.registerSingleton<FactCheckRepository>(
      FactCheckRepositoryImpl(sl(), sl()));
  sl.registerSingleton<BiasReportRepository>(
      BiasReportRepositoryImpl(sl(), sl()));
  sl.registerSingleton<SimilarArticlesRepository>(
      SimilarArticlesRepositoryImpl(sl()));

  // ── Use cases ─────────────────────────────────────────────────────────────
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));
  sl.registerSingleton<GetSavedArticleUseCase>(GetSavedArticleUseCase(sl()));
  sl.registerSingleton<SaveArticleUseCase>(SaveArticleUseCase(sl()));
  sl.registerSingleton<RemoveArticleUseCase>(RemoveArticleUseCase(sl()));
  sl.registerSingleton<SignInUseCase>(SignInUseCase(sl()));
  sl.registerSingleton<SignOutUseCase>(SignOutUseCase(sl()));
  sl.registerSingleton<GetCurrentUserUseCase>(GetCurrentUserUseCase(sl()));
  sl.registerSingleton<UploadArticleUseCase>(UploadArticleUseCase(sl()));
  sl.registerSingleton<GetJournalistArticlesUseCase>(
      GetJournalistArticlesUseCase(sl()));
  sl.registerSingleton<DeleteArticleUseCase>(DeleteArticleUseCase(sl()));
  sl.registerSingleton<UpdateArticleUseCase>(UpdateArticleUseCase(sl()));
  sl.registerSingleton<GetCategoriesUseCase>(GetCategoriesUseCase(sl()));
  sl.registerSingleton<GetFactCheckUseCase>(GetFactCheckUseCase(sl()));
  sl.registerSingleton<RunBotCheckUseCase>(RunBotCheckUseCase(sl()));
  sl.registerSingleton<SubmitCommunityVoteUseCase>(
      SubmitCommunityVoteUseCase(sl()));
  sl.registerSingleton<GetArticleListFactChecksUseCase>(
      GetArticleListFactChecksUseCase(sl()));
  sl.registerSingleton<WatchBotCheckUseCase>(WatchBotCheckUseCase(sl()));
  sl.registerSingleton<GetBiasReportUseCase>(GetBiasReportUseCase(sl()));
  sl.registerSingleton<RunPolarizeUseCase>(RunPolarizeUseCase(sl()));
  sl.registerSingleton<WatchBiasReportUseCase>(WatchBiasReportUseCase(sl()));
  sl.registerSingleton<GetSimilarArticlesUseCase>(
      GetSimilarArticlesUseCase(sl()));

  // ── BLoCs (factories — new instance per route) ────────────────────────────
  sl.registerFactory<RemoteArticlesBloc>(() => RemoteArticlesBloc(sl(), sl()));
  sl.registerFactory<LocalArticleBloc>(
      () => LocalArticleBloc(sl(), sl(), sl()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl(), sl(), sl()));
  sl.registerFactory<UploadArticleBloc>(() => UploadArticleBloc(sl()));
  sl.registerFactory<ArticleCategoryCubit>(
      () => ArticleCategoryCubit(sl()));
  sl.registerFactory<JournalistProfileBloc>(
      () => JournalistProfileBloc(sl(), sl(), sl()));
  sl.registerFactory<FactCheckBloc>(
      () => FactCheckBloc(sl(), sl(), sl(), sl()));  // GetFactCheckUseCase, RunBotCheckUseCase, SubmitCommunityVoteUseCase, WatchBotCheckUseCase
  sl.registerFactory<BiasReportBloc>(
      () => BiasReportBloc(sl(), sl(), sl()));       // GetBiasReportUseCase, RunPolarizeUseCase, WatchBiasReportUseCase
  sl.registerFactory<SimilarArticlesBloc>(
      () => SimilarArticlesBloc(sl()));
}
