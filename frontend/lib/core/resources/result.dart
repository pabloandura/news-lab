sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final Exception error;
  const Failure(this.error);

  String get message {
    final s = error.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}
