/// Exception thrown when an APK build fails.
///
/// This exception provides context about build failures to help
/// users diagnose and fix issues.
class BuildException implements Exception {
  /// A human-readable error message.
  final String message;

  /// The exit code from the Flutter build process, if applicable.
  final int? exitCode;

  /// The stdout output from the build process, if available.
  final String? stdout;

  /// The stderr output from the build process, if available.
  final String? stderr;

  /// The working directory where the build was attempted.
  final String? workingDirectory;

  /// Creates a new build exception with detailed context.
  BuildException(
    this.message, {
    this.exitCode,
    this.stdout,
    this.stderr,
    this.workingDirectory,
  });

  @override
  String toString() {
    final buffer = StringBuffer('BuildException: $message\n');
    if (workingDirectory != null) {
      buffer.writeln('Working Directory: $workingDirectory');
    }
    if (exitCode != null) buffer.writeln('Exit Code: $exitCode');
    if (stderr != null && stderr!.isNotEmpty) {
      buffer.writeln('stderr: ${stderr!.length > 500 ? '${stderr!.substring(0, 500)}...' : stderr}');
    }
    if (stdout != null && stdout!.isNotEmpty) {
      buffer.writeln('stdout: ${stdout!.length > 500 ? '${stdout!.substring(0, 500)}...' : stdout}');
    }
    return buffer.toString();
  }
}
