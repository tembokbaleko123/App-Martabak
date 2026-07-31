abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}
