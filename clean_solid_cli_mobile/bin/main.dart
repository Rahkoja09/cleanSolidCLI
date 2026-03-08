import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/commands/create_auth.dart';
import 'package:clean_solid_cli_mobile/commands/create_new_feature.dart';
import 'package:clean_solid_cli_mobile/commands/implemente_new_feature.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner(
    "cscm",
    "create and implemente new features : clean architecture + solid",
  );
  runner.addCommand(CreateNewFeature());
  runner.addCommand(ImplementeNewFeature());
  runner.addCommand(CreateAuth());
  try {
    runner.run(arguments);
  } catch (e) {
    print("Error: $e");
  }
}
