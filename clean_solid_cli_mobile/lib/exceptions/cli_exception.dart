class CliException implements Exception {
  final String message;
  final int exitCode;
  const CliException(this.message, {this.exitCode = 1});
  @override
  String toString() => message;
}
