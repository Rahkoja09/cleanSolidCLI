import 'dart:io';
import 'package:args/command_runner.dart';
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
    final featureArg = argResults?.rest.isNotEmpty == true
        ? argResults!.rest.first
        : null;

    if (shouldGenerate && featureArg == null) {
      print("  --generate necessite un nom de feature.");
      print("  Usage : cscm test <feature> --generate");
      return;
    }

    if (featureArg != null) {
      if (featureArg.contains('..') ||
          featureArg.contains('/') ||
          featureArg.contains('\\')) {
        print("  Nom de feature invalide.");
        return;
      }

      final snakeName =
          ReformateClassName.formatToSnakeCase(featureArg);

      if (shouldGenerate) {
        await _generateTestsIfNeeded(snakeName, featureArg);
      }

      final testDir = 'test/features/$snakeName';
      final dir = Directory(testDir);
      if (!dir.existsSync()) {
        print("  Aucun test trouve pour la feature : $featureArg");
        return;
      }

      print("  Lancement des tests pour : $featureArg ...");
      final result = await Process.run(
        'flutter',
        ['test', testDir],
        runInShell: true,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      exitCode = result.exitCode;
    } else {
      final dir = Directory('test');
      if (!dir.existsSync()) {
        print("  Aucun repertoire test/ trouve.");
        return;
      }

      print("  Lancement de tous les tests ...");
      final result = await Process.run(
        'flutter',
        ['test'],
        runInShell: true,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      exitCode = result.exitCode;
    }
  }

  Future<void> _generateTestsIfNeeded(
      String snakeName, String featureArg) async {
    final repoTest =
        'test/features/$snakeName/data/repository/${snakeName}_repository_impl_test.dart';
    final ctrlTest =
        'test/features/$snakeName/presentation/controller/${snakeName}_controller_test.dart';

    final repoExists = File(repoTest).existsSync();
    final ctrlExists = File(ctrlTest).existsSync();

    if (repoExists && ctrlExists) {
      print("  Tests deja existants pour : $featureArg");
      return;
    }

    print("  Generation des tests manquants pour : $featureArg ...");
    try {
      final projectName = _getProjectName();
      await TestGenerator.generate(
        featureName: featureArg,
        projectName: projectName,
      );
    } catch (e) {
      print("  Erreur lors de la generation : $e");
    }
  }

  String _getProjectName() {
    final file = File('.cscm.yaml');
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('project_name:')) {
          return line.split(':').last.trim();
        }
      }
    }
    return Directory.current.path.split('/').last;
  }
}
