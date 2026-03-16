import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('run global version installed via pub global activate', () {
    final output = runExampleCli(workingDirectory: '.');

    expect(
      output,
      matches(
        RegExp(
          '.*Running v1 with local version null and global version 1.0.0.*',
        ),
      ),
    );
  });

  group('run in source package', () {
    test('with same local and global version', () {
      final output = runExampleCli(
        workingDirectory: 'fixture_packages/example_v1',
      );

      expect(
        output,
        matches(
          RegExp(
            '.*Running v1 with local version 1.0.0 and global version 1.0.0.*',
          ),
        ),
      );
    });

    test('with different local and global version', () {
      final output = runExampleCli(
        workingDirectory: 'fixture_packages/example_v2',
      );

      expect(
        output,
        matches(
          RegExp(
            '.*Running v2 with local version 2.0.0 and global version 1.0.0.*',
          ),
        ),
      );
    });
  });

  test('run global version installed via dart install', () {
    // Install the example CLI via `dart install` which creates an
    // AOT-compiled binary.
    final installResult = Process.runSync(
      'dart',
      ['install', '.'],
      workingDirectory: 'fixture_packages/example_v1',
      stderrEncoding: utf8,
      stdoutEncoding: utf8,
    );
    if (installResult.exitCode != 0) {
      throw Exception(
        'dart install failed with exit code ${installResult.exitCode}:'
        '\n${installResult.stdout}\n${installResult.stderr}',
      );
    }

    try {
      // Run the dart-installed binary from a directory without a local
      // installation, so it uses the global (dart install) version.
      final result = Process.runSync(
        'example',
        [],
        runInShell: true,
        workingDirectory: '.',
        stderrEncoding: utf8,
        stdoutEncoding: utf8,
      );

      if (result.exitCode != 0) {
        throw Exception(
          'example CLI (dart install) failed with exit code ${result.exitCode}:'
          '\n${result.stdout}\n${result.stderr}',
        );
      }

      expect(
        result.stdout as String,
        matches(
          RegExp(
            '.*Running v1 with local version null and global version 1.0.0.*',
          ),
        ),
      );
    } finally {
      // Uninstall to not interfere with other tests.
      Process.runSync('dart', ['uninstall', 'cli_launcher_example']);
    }
  });

  group('run in consumer package', () {
    test('with same local and global version', () {
      final output = runExampleCli(
        workingDirectory: './fixture_packages/consumer_v1',
      );

      expect(
        output,
        matches(
          RegExp(
            '.*Running v1 with local version 1.0.0 and global version 1.0.0.*',
          ),
        ),
      );
    });

    test('with different local and global version', () {
      final output = runExampleCli(
        workingDirectory: './fixture_packages/consumer_v2',
      );

      expect(
        output,
        matches(
          RegExp(
            '.*Running v2 with local version 2.0.0 and global version 1.0.0.*',
          ),
        ),
      );
    });

    test('with different local and global version in sub directory', () {
      final dir = Directory('./fixture_packages/consumer_v2/sub')
        ..createSync(recursive: true);

      final output = runExampleCli(workingDirectory: dir.path);

      expect(
        output,
        matches(
          RegExp(
            '.*Running v2 with local version 2.0.0 and global version 1.0.0.*',
          ),
        ),
      );
    });

    test('with local launch config', () {
      final output = runExampleCli(
        workingDirectory: './fixture_packages/consumer_v1',
        arguments: ['--local-launch-config'],
        forcePubGet: true,
      );

      // Verify that `dart pub get` was run with `--verbose`.
      expect(output, matches('MSG : Resolving dependencies...'));

      // Verify that `dart run` was run with `--enable-asserts`.
      expect(output, matches('Assertions are enabled.'));
    });
  });
}

String runExampleCli({
  List<String> arguments = const [],
  required String workingDirectory,
  bool forcePubGet = false,
}) {
  if (forcePubGet) {
    // Remove the pubspec.lock file to ensure a fresh run.
    final lockFile = File('$workingDirectory/pubspec.lock');
    if (lockFile.existsSync()) {
      lockFile.deleteSync();
    }
  }

  final result = Process.runSync(
    'example',
    arguments,
    runInShell: true,
    workingDirectory: workingDirectory,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );

  if (result.exitCode != 0) {
    throw Exception(
      'example CLI failed with exit code ${result.exitCode}:'
      '\n${result.stdout}\n${result.stderr}',
    );
  }

  return result.stdout as String;
}
