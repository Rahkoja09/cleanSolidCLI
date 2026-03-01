import 'package:args/command_runner.dart';
import 'package:clean_solid_cli_mobile/architectures/architectures.dart';
import 'package:clean_solid_cli_mobile/architectures/clean/layers/clean_layers.dart';
import 'package:clean_solid_cli_mobile/utils/enums.dart';
import 'package:clean_solid_cli_mobile/utils/file_helper.dart';
import 'package:clean_solid_cli_mobile/utils/reformate_class_name.dart';
import 'package:clean_solid_cli_mobile/utils/injection_helper.dart';

class CreateNewFeature extends Command {
  @override
  String get description => "Créer une nouvelle feature complète";

  @override
  String get name => "create";

  @override
  void run() async {
    final layers = CleanLayers("data", "domain", "presentation");
    final arch = Architectures("Clean", "Style NMV", layers);

    if (argResults?.rest.isEmpty ?? true) {
      print("Erreur : nom de feature manquant.");
      return;
    }

    final featureName = argResults!.rest.first.toLowerCase();

    final capitalizedName = ReformateClassName.capitalizeClassName(
      featureName: featureName,
    );

    print(" Génération de la feature : $capitalizedName...");

    for (var type in FileTemplateType.values) {
      if (type == FileTemplateType.di) continue;

      try {
        final targetPath = FileHelper.generateAndGetTargetPath(
          featureName: featureName,
          templateType: type,
          architecture: arch,
        );

        FileHelper.generateFormTemplate(
          featureName: featureName,
          templateName: type.name,
          targetPath: targetPath,
        );
      } catch (e) {
        print(" Erreur lors de la génération de $type : $e");
      }
    }

    print(" Mise à jour de l'injection de dépendances...");
    InjectionHelper.updateInjectionContainer(featureName, capitalizedName);

    print(" Feature [$capitalizedName] créée avec succès !");
  }
}
