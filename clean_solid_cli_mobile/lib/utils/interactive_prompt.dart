import 'dart:io';

class InteractivePrompt {
  /// Pose une question et retourne la réponse.
  /// Si [required] est true, répète jusqu'à obtenir une réponse non vide.
  static String ask(String question, {bool required = false}) {
    while (true) {
      stdout.write('   $question : ');
      final input = stdin.readLineSync()?.trim() ?? '';
      if (input.isNotEmpty || !required) return input;
      print('   ⚠️  Ce champ est requis.');
    }
  }

  /// Pose une question oui/non.
  static bool askBool(String question, {bool defaultValue = true}) {
    final hint = defaultValue ? '[O/n]' : '[o/N]';
    stdout.write('   $question $hint : ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes' || input == 'oui' || input == 'o';
  }

  /// Demande des champs un par un avec type.
  /// Retourne une liste de "nom:type" séparés par des virgules.
  static String askFields() {
    print('\n   📝 Ajoutez vos champs (laissez vide pour terminer) :');
    final fields = <String>[];

    int index = 1;
    while (true) {
      final name = ask('   Champ #$index (nom, ou Entrée pour terminer)');
      if (name.isEmpty) break;

      print(
        '      Types disponibles : string, int, double, bool, datetime, num',
      );
      final type = ask('   Type du champ "$name"', required: true);

      fields.add('$name:$type');
      index++;
    }

    return fields.join(',');
  }

  /// Affiche un menu de sélection.
  static int choose(String title, List<String> options) {
    print('\n   $title :');
    for (var i = 0; i < options.length; i++) {
      print('   [$i] ${options[i]}');
    }

    while (true) {
      final input = ask('   Votre choix', required: true);
      final choice = int.tryParse(input);
      if (choice != null && choice >= 0 && choice < options.length) {
        return choice;
      }
      print(
        '   ⚠️  Choix invalide. Entrez un nombre entre 0 et ${options.length - 1}.',
      );
    }
  }
}
