import 'package:args/command_runner.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner("nmv", "create data source commande");
  //runner.addCommand();

  try {
    runner.run(arguments);
  } catch (e) {
    print("Error: $e");
  }
}
