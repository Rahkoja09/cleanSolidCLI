import 'package:clean_solid_cli_mobile/templates/architectures/clean/layers/clean_layers.dart';

class Architectures {
  final String name;
  final String description;
  final CleanLayers layers;
  const Architectures(this.name, this.description, this.layers);

  String get getName => name;
  String get getDescription => description;
  CleanLayers get getLayers => layers;
}
