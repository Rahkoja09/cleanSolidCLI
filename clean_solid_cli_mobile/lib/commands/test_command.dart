import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/test_generator.dart';

class TestCommand extends Command {
  @override
  String get description => 'Lancer les tests (tous ou pour une feature)';

  @override
  String get name => 'test';

  TestCommand() {
    argParser.addFlag(
      'generate',
      abbr: 'g',
      help: 'Generer les tests manquants avant de les lancer',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  Future<void> run() async {
    final shouldGenerate = argResults?['generate'] as bool? ?? false;
    final featureArg =
        argResults?.rest.isNotEmpty == true ? argResults!.rest.first : null;

    if (shouldGenerate && featureArg == null) {
      CliUI.error('--generate necessite un nom de feature.');
      CliUI.hint('Usage: cscm test <feature> --generate');
      return;
    }

    if (featureArg != null) {
      if (featureArg.contains('..') ||
          featureArg.contains('/') ||
          featureArg.contains('\\')) {
        CliUI.error('Nom de feature invalide.');
        return;
      }

      final snakeName = ReformateClassName.formatToSnakeCase(featureArg);

      if (shouldGenerate) {
        await _generateTestsIfNeeded(snakeName, featureArg);
      }

      final testDir = 'test/features/$snakeName';
      if (!Directory(testDir).existsSync()) {
        CliUI.warning("Aucun test pour la feature: $featureArg");
        return;
      }

      await _runTests(label: featureArg, args: ['test', testDir]);
    } else {
      if (!Directory('test').existsSync()) {
        CliUI.warning('Aucun repertoire test/ trouve.');
        return;
      }
      await _runTests(label: 'all', args: ['test']);
    }
  }

  /// Lance flutter test — bufferise TOUTE la sortie.
  /// N'affiche que le resultat final et les erreurs dedupliquées.
  Future<void> _runTests({
    required String label,
    required List<String> args,
  }) async {
    CliUI.header('test $label');

    // ── Spinner ──
    const frames = ['/', '-', '\\', '|'];
    var frame = 0;
    var showSpinner = true;

    final spinner = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!showSpinner) return;
      stdout.write('\r  ${CliUI.cyan(frames[frame])}  Running tests...');
      frame = (frame + 1) % frames.length;
    });

    // ── Lancer le process — tout bufferiser ──
    final process = await Process.start(
      'flutter',
      args,
      runInShell: true,
      mode: ProcessStartMode.normal,
    );

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    final subOut = process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((chunk) => stdoutBuf.write(chunk));

    final subErr = process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((chunk) => stderrBuf.write(chunk));

    final exitCode = await process.exitCode;
    await subOut.cancel();
    await subErr.cancel();
    spinner.cancel();

    // Clear spinner
    stdout.write('\r${" " * 60}\r');

    // ── Extraire le resultat final depuis stdout ──
    final lines = stdoutBuf.toString().split('\n');
    String? resultLine;
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (RegExp(r'^\d{2}:\d{2}\s+\+\d+').hasMatch(t)) {
        resultLine = t;
      }
    }

    if (resultLine != null) {
      stdout.writeln(resultLine);
    }

    // ── Erreurs de compilation (stderr) — dedupliquées ──
    final stderrLines = stderrBuf.toString().split('\n');
    final errors = <String>{};
    for (final line in stderrLines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (!t.contains('Error:') &&
          !t.contains('Compilation failed') &&
          !t.contains('To run this test again'))
        continue;

      if (errors.add(t)) {
        // Première occurrence de cette erreur
        stderr.writeln(t);
      }
    }

    // ── Verdict ──
    print('');
    if (exitCode == 0) {
      // Compter les tests passés depuis le résultat
      final match = RegExp(r'\+(\d+)').firstMatch(resultLine ?? '');
      final count = match?.group(1) ?? '?';
      CliUI.success('$count tests passed');
    } else {
      final failMatch = RegExp(r'-(\d+)').firstMatch(resultLine ?? '');
      final failCount = failMatch?.group(1) ?? 'some';
      CliUI.error('$failCount test(s) failed');
    }

    //this.exitCode = exitCode;
  }

  Future<void> _generateTestsIfNeeded(
    String snakeName,
    String featureArg,
  ) async {
    final repoTest =
        'test/features/$snakeName/data/repository/${snakeName}_repository_impl_test.dart';
    final ctrlTest =
        'test/features/$snakeName/presentation/controller/${snakeName}_controller_test.dart';

    if (File(repoTest).existsSync() && File(ctrlTest).existsSync()) {
      CliUI.info("Tests deja existants pour: $featureArg");
      return;
    }

    try {
      final projectName = _getProjectName();
      await CliUI.withSpinner('Generating tests', () async {
        await TestGenerator.generate(
          featureName: featureArg,
          projectName: projectName,
        );
      });
    } catch (e) {
      CliUI.error("Generation echouee: $e");
    }
  }

  String _getProjectName() {
    final file = File('.cscm.yaml');
    if (file.existsSync()) {
      for (final line in file.readAsLinesSync()) {
        if (line.startsWith('project_name:')) {
          return line.split(':').last.trim();
        }
      }
    }
    return Directory.current.path.split('/').last;
  }
}
