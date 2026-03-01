import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/commands/create_new_feature.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner("cli", "create new arch to new features");
  runner.addCommand(CreateNewFeature());
  try {
    runner.run(arguments);
  } catch (e) {
    print("Error: $e");
  }
}
