/// Code injection engine — façade qui délègue aux sous-modules spécialisés.
library;

export 'entity_injections.dart';
export 'model_injections.dart';
export 'remote_source_injections.dart';
export 'select_injections.dart';

import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/injections/entity_injections.dart';
import 'package:clean_solid_cli_mobile/injections/model_injections.dart';
import 'package:clean_solid_cli_mobile/injections/remote_source_injections.dart';

/// API legacy — garde la compatibilité avec les appels existants.
class Injections {
  static String injectEntity(String content, List<Field> fields, String name, String projectName) =>
      EntityInjections.inject(content, fields, name, projectName);

  static String injectModel(String content, List<Field> fields, String name, String projectName) =>
      ModelInjections.inject(content, fields, name, projectName);

  static String injectRemoteSource(String content, List<Field> fields) =>
      RemoteSourceInjections.inject(content, fields);
}
