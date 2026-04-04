import 'package:equatable/equatable.dart';

abstract class UploadArticleState extends Equatable {
  const UploadArticleState();

  @override
  List<Object?> get props => [];
}

class UploadArticleInitial extends UploadArticleState {
  const UploadArticleInitial();
}

class UploadArticleLoading extends UploadArticleState {
  const UploadArticleLoading();
}

class UploadArticleSuccess extends UploadArticleState {
  const UploadArticleSuccess();
}

class UploadArticleError extends UploadArticleState {
  final String message;

  const UploadArticleError(this.message);

  @override
  List<Object?> get props => [message];
}
