/// A recoverable outcome: either a value or a typed failure. Never thrown.
sealed class Result<T, F extends Failure> {
  const Result();
}

/// The success branch of a [Result].
final class Ok<T, F extends Failure> extends Result<T, F> {
  const Ok(this.value);
  final T value;
}

/// The failure branch of a [Result].
final class Err<T, F extends Failure> extends Result<T, F> {
  const Err(this.failure);
  final F failure;
}

/// Base of every typed failure. [code] is stable; UI maps it to a message.
sealed class Failure implements Exception {
  const Failure(this.code, {this.cause});
  final String code;
  final Object? cause;

  @override
  String toString() => 'Failure($code${cause == null ? '' : ': $cause'})';
}

/// Bundled content is missing or malformed.
final class ContentFailure extends Failure {
  const ContentFailure(super.code, {super.cause});
}

/// Saving or reading the user's attempts failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.code, {super.cause});
}
