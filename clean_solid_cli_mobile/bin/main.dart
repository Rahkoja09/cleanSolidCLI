import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/commands/add_widget_command.dart';
import 'package:clean_solid_cli_mobile/commands/commit_command.dart';
import 'package:clean_solid_cli_mobile/commands/config_command.dart';
import 'package:clean_solid_cli_mobile/commands/create_auth.dart';
import 'package:clean_solid_cli_mobile/commands/create_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/generate_all_command.dart';
import 'package:clean_solid_cli_mobile/commands/history_command.dart';
import 'package:clean_solid_cli_mobile/commands/implemente_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/init_command.dart';
import 'package:clean_solid_cli_mobile/commands/list_command.dart';
import 'package:clean_solid_cli_mobile/commands/status_command.dart';
import 'package:clean_solid_cli_mobile/commands/test_command.dart';
import 'package:clean_solid_cli_mobile/commands/undo_command.dart';
import 'package:clean_solid_cli_mobile/exceptions/cli_exception.dart';
import 'package:clean_solid_cli_mobile/utils/cli_ui.dart';

const _version = '2.0.0';

bool _shouldShowLogo(List<String> arguments) {
  // Help doit afficher le branding.
  if (arguments.isEmpty) return true;

  if (arguments.contains('--help') || arguments.contains('-h')) {
    return true;
  }

  // Une commande précise ne doit pas afficher le gros logo.
  return false;
}

void main(List<String> arguments) async {
  // ═══════════════════════════════════════════════════
  // BRANDING
  // ═══════════════════════════════════════════════════

  if (_shouldShowLogo(arguments)) {
    CliUI.logo(
      version: _version,
      subtitle: 'Flutter Clean Architecture Scaffolding',
    );
  }

  // ═══════════════════════════════════════════════════
  // COMMAND RUNNER
  // ═══════════════════════════════════════════════════

  final runner = CommandRunner(
    'cscm',
    'Clean Solid CLI Mobile — '
        'Flutter Clean Architecture scaffolding tool.',
  );

  // ═══════════════════════════════════════════════════
  // COMMANDS
  // ═══════════════════════════════════════════════════

  runner.addCommand(InitCommand());
  runner.addCommand(ConfigCommand());

  runner.addCommand(CreateNewFeature());
  runner.addCommand(TestCommand());
  runner.addCommand(ImplementeNewFeature());

  runner.addCommand(GenerateAllCommand());
  runner.addCommand(CreateAuth());
  runner.addCommand(AddWidgetCommand());

  runner.addCommand(ListCommand());
  runner.addCommand(HistoryCommand());

  runner.addCommand(StatusCommand());
  runner.addCommand(UndoCommand());
  runner.addCommand(CommitCommand());

  // ═══════════════════════════════════════════════════
  // EXECUTION
  // ═══════════════════════════════════════════════════

  try {
    await runner.run(arguments);
  }
  // ───────────────────────────────────────────────────
  // User input / command error
  // ───────────────────────────────────────────────────
  on UsageException catch (e) {
    stderr.writeln();

    CliUI.error(e.message);

    stderr.writeln();

    CliUI.hint('Run "cscm --help" to see available commands.');

    exitCode = 64;
  }
  // ───────────────────────────────────────────────────
  // Expected CSCM error
  // ───────────────────────────────────────────────────
  on CliException catch (e) {
    stderr.writeln();

    CliUI.error(e.message);

    exitCode = e.exitCode;
  }
  // ───────────────────────────────────────────────────
  // Unexpected error
  // ───────────────────────────────────────────────────
  catch (e, stack) {
    stderr.writeln();

    CliUI.error('Unexpected error: $e');

    // Affiché uniquement en mode debug si tu veux
    if (Platform.environment['CSCM_DEBUG'] == '1') {
      stderr.writeln();
      stderr.writeln(CliUI.dim(stack.toString()));
    }

    exitCode = 1;
  }
}
