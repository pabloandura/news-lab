import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
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
import 'package:news_lab/features/publish_article/data/data_sources/article_firestore_data_source.dart';
import 'package:news_lab/features/publish_article/data/data_sources/article_storage_data_source.dart';
import 'package:news_lab/features/publish_article/data/repository/publish_article_repository_impl.dart';
import 'package:news_lab/features/publish_article/domain/repository/publish_article_repository.dart';
import 'package:news_lab/features/publish_article/domain/usecases/upload_article.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_bloc.dart';

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

  // ── daily_news data sources ───────────────────────────────────────────────
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));

  // ── auth data sources ─────────────────────────────────────────────────────
  sl.registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(sl()));

  // ── publish_article data sources ──────────────────────────────────────────
  sl.registerSingleton<ArticleStorageDataSource>(
      ArticleStorageDataSourceImpl(sl()));
  sl.registerSingleton<ArticleFirestoreDataSource>(
      ArticleFirestoreDataSourceImpl(sl()));

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerSingleton<ArticleRepository>(
      ArticleRepositoryImpl(sl(), sl(), sl()));
  sl.registerSingleton<AuthRepository>(
      AuthRepositoryImpl(sl()));
  sl.registerSingleton<PublishArticleRepository>(
      PublishArticleRepositoryImpl(sl(), sl()));

  // ── Use cases ─────────────────────────────────────────────────────────────
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));
  sl.registerSingleton<GetSavedArticleUseCase>(GetSavedArticleUseCase(sl()));
  sl.registerSingleton<SaveArticleUseCase>(SaveArticleUseCase(sl()));
  sl.registerSingleton<RemoveArticleUseCase>(RemoveArticleUseCase(sl()));
  sl.registerSingleton<SignInUseCase>(SignInUseCase(sl()));
  sl.registerSingleton<SignOutUseCase>(SignOutUseCase(sl()));
  sl.registerSingleton<GetCurrentUserUseCase>(GetCurrentUserUseCase(sl()));
  sl.registerSingleton<UploadArticleUseCase>(UploadArticleUseCase(sl()));

  // ── BLoCs (factories — new instance per route) ────────────────────────────
  sl.registerFactory<RemoteArticlesBloc>(() => RemoteArticlesBloc(sl()));
  sl.registerFactory<LocalArticleBloc>(
      () => LocalArticleBloc(sl(), sl(), sl()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl(), sl(), sl()));
  sl.registerFactory<UploadArticleBloc>(() => UploadArticleBloc(sl()));
}
