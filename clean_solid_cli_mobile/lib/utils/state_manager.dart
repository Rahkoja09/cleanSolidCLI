import 'dart:io';
import 'package:yaml/yaml.dart';

// ═══════════════════════════════════════════════════
// MODELES DE DONNEES
// ═══════════════════════════════════════════════════

class FeatureRecord {
  final String name;
  final String snakeName;
  final String pascalName;
  final String createdAt;
  final List<FieldRecord> fields;
  final List<String> filesCreated;
  final List<String> filesUpdated;
  final String? sqlMigration;

  FeatureRecord({
    required this.name,
    required this.snakeName,
    required this.pascalName,
    required this.createdAt,
    this.fields = const [],
    this.filesCreated = const [],
    this.filesUpdated = const [],
    this.sqlMigration,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'snake_name': snakeName,
        'pascal_name': pascalName,
        'created_at': createdAt,
        'fields': fields.map((f) => f.toMap()).toList(),
        'files_created': filesCreated,
        'files_updated': filesUpdated,
        if (sqlMigration != null) 'sql_migration': sqlMigration,
      };

  factory FeatureRecord.fromMap(Map<dynamic, dynamic> m) => FeatureRecord(
        name: m['name'] as String? ?? '',
        snakeName: m['snake_name'] as String? ?? '',
        pascalName: m['pascal_name'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
        fields: (m['fields'] as List?)
                ?.map(
                    (f) => FieldRecord.fromMap(f as Map<dynamic, dynamic>))
                .toList() ??
            [],
        filesCreated: List<String>.from(m['files_created'] as List? ?? []),
        filesUpdated: List<String>.from(m['files_updated'] as List? ?? []),
        sqlMigration: m['sql_migration'] as String?,
      );
}

class FieldRecord {
  final String name;
  final String type;
  final bool isEnum;
  final List<String> enumValues;
  final bool isReference;
  final String referenceTarget;

  FieldRecord({
    required this.name,
    required this.type,
    this.isEnum = false,
    this.enumValues = const [],
    this.isReference = false,
    this.referenceTarget = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        if (isEnum) 'is_enum': true,
        if (isEnum) 'enum_values': enumValues,
        if (isReference) 'is_reference': true,
        if (isReference) 'reference_target': referenceTarget,
      };

  factory FieldRecord.fromMap(Map<dynamic, dynamic> m) => FieldRecord(
        name: m['name'] as String? ?? '',
        type: m['type'] as String? ?? 'string',
        isEnum: m['is_enum'] as bool? ?? false,
        enumValues: List<String>.from(m['enum_values'] as List? ?? []),
        isReference: m['is_reference'] as bool? ?? false,
        referenceTarget: m['reference_target'] as String? ?? '',
      );
}

class AuthRecord {
  final bool configured;
  final String configuredAt;
  final bool email;
  final bool social;
  final List<String> filesCreated;

  AuthRecord({
    required this.configured,
    required this.configuredAt,
    this.email = false,
    this.social = false,
    this.filesCreated = const [],
  });

  Map<String, dynamic> toMap() => {
        'configured': configured,
        'configured_at': configuredAt,
        'email': email,
        'social': social,
        'files_created': filesCreated,
      };

  factory AuthRecord.fromMap(Map<dynamic, dynamic> m) => AuthRecord(
        configured: m['configured'] as bool? ?? false,
        configuredAt: m['configured_at'] as String? ?? '',
        email: m['email'] as bool? ?? false,
        social: m['social'] as bool? ?? false,
        filesCreated: List<String>.from(m['files_created'] as List? ?? []),
      );
}

class ActionRecord {
  final String timestamp;
  final String command;
  final List<String> args;
  final String? detail;

  ActionRecord({
    required this.timestamp,
    required this.command,
    this.args = const [],
    this.detail,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp,
        'command': command,
        'args': args,
        if (detail != null) 'detail': detail,
      };

  factory ActionRecord.fromMap(Map<dynamic, dynamic> m) => ActionRecord(
        timestamp: m['timestamp'] as String? ?? '',
        command: m['command'] as String? ?? '',
        args: List<String>.from(m['args'] as List? ?? []),
        detail: m['detail'] as String?,
      );
}

// ═══════════════════════════════════════════════════
// PROJECT STATE
// ═══════════════════════════════════════════════════

class ProjectState {
  static const String stateFileName = '.cscm-state.yaml';

  int version;
  String projectName;
  String createdAt;
  String backend;
  List<FeatureRecord> features;
  AuthRecord auth;
  List<ActionRecord> actions;

  ProjectState({
    this.version = 1,
    required this.projectName,
    required this.createdAt,
    this.backend = 'supabase',
    this.features = const [],
    AuthRecord? auth,
    this.actions = const [],
  }) : auth = auth ??
            AuthRecord(configured: false, configuredAt: '');

  // ─── Serialization ────────────────────

  Map<String, dynamic> toMap() => {
        'version': version,
        'project_name': projectName,
        'created_at': createdAt,
        'backend': backend,
        'features': features.map((f) => f.toMap()).toList(),
        'auth': auth.toMap(),
        'actions': actions.map((a) => a.toMap()).toList(),
      };

  factory ProjectState.fromMap(Map<dynamic, dynamic> m) => ProjectState(
        version: m['version'] as int? ?? 1,
        projectName: m['project_name'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
        backend: m['backend'] as String? ?? 'supabase',
        features: (m['features'] as List?)
                ?.map(
                    (f) => FeatureRecord.fromMap(f as Map<dynamic, dynamic>))
                .toList() ??
            [],
        auth: m['auth'] != null
            ? AuthRecord.fromMap(m['auth'] as Map<dynamic, dynamic>)
            : null,
        actions: (m['actions'] as List?)
                ?.map(
                    (a) => ActionRecord.fromMap(a as Map<dynamic, dynamic>))
                .toList() ??
            [],
      );

  String toYaml() => _mapToYaml(toMap());

  // ─── YAML serializer (sans dependance yaml write) ──

  static String _mapToYaml(dynamic value, [int indent = 0]) {
    final pad = '  ' * indent;
    if (value is Map) {
      if (value.isEmpty) return '';
      final buf = StringBuffer();
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is List && val.isNotEmpty) {
          buf.writeln('$pad$key:');
          for (final item in val) {
            if (item is Map && item.isNotEmpty) {
              buf.write('$pad  - ');
              final itemStr = _mapToYaml(item, indent + 2);
              buf.write(itemStr.trimLeft());
              if (!buf.toString().endsWith('\n')) buf.writeln();
            } else {
              buf.writeln('$pad  - $item');
            }
          }
        } else if (val is Map && val.isNotEmpty) {
          buf.writeln('$pad$key:');
          buf.write(_mapToYaml(val, indent + 1));
        } else if (val is String && (val.contains(':') || val.contains('#') || val.contains('\n'))) {
          buf.writeln('$pad$key: "$val"');
        } else if (val == true) {
          buf.writeln('$pad$key: true');
        } else if (val == false) {
          buf.writeln('$pad$key: false');
        } else if (val is int) {
          buf.writeln('$pad$key: $val');
        } else if (val == null || val.toString().isEmpty) {
          buf.writeln('$pad$key:');
        } else {
          buf.writeln('$pad$key: $val');
        }
      }
      return buf.toString();
    }
    return value.toString();
  }

  // ─── Persistence ─────────────────────

  static bool stateExists() => File(stateFileName).existsSync();

  static ProjectState load() {
    final file = File(stateFileName);
    if (!file.existsSync()) {
      throw StateError('Aucun projet CSCM trouve (pas de $stateFileName).');
    }
    final yaml = loadYaml(file.readAsStringSync());
    if (yaml is! Map) {
      throw StateError('$stateFileName invalide.');
    }
    return ProjectState.fromMap(yaml);
  }

  static void save(ProjectState state) {
    final comment = '# .cscm-state.yaml — auto-genere par cscm, ne pas editer a la main\n'
        '# Ce fichier suit l\'historique des actions cscm sur le projet.\n\n';
    File(stateFileName).writeAsStringSync(comment + state.toYaml());
  }

  // ─── Helpers ──────────────────────────

  static String _isoNow() => DateTime.now().toUtc().toIso8601String();

  /// Initialise un nouveau state (appele par cscm init)
  static ProjectState create(String projectName, String backend) {
    final now = _isoNow();
    final state = ProjectState(
      projectName: projectName,
      createdAt: now,
      backend: backend,
    );
    state.actions.add(ActionRecord(
      timestamp: now,
      command: 'init',
      args: [projectName],
    ));
    save(state);
    return state;
  }

  /// Ajoute une feature au state
  static void addFeature({
    required String rawName,
    required String snakeName,
    required String pascalName,
    required List<FieldRecord> fields,
    required List<String> filesCreated,
    required List<String> filesUpdated,
    String? sqlMigration,
  }) {
    final state = load();
    final now = _isoNow();

    // Eviter les doublons (re-run sur meme feature)
    final existing = state.features.indexWhere((f) => f.snakeName == snakeName);
    if (existing >= 0) {
      // Mettre a jour les fichiers si on a de nouveaux
      final feat = state.features[existing];
      final merged = {...feat.filesCreated.toSet(), ...filesCreated.toSet()};
      state.features[existing] = FeatureRecord(
        name: feat.name,
        snakeName: feat.snakeName,
        pascalName: feat.pascalName,
        createdAt: feat.createdAt,
        fields: fields.isNotEmpty ? fields : feat.fields,
        filesCreated: merged.toList(),
        filesUpdated: filesUpdated,
        sqlMigration: sqlMigration ?? feat.sqlMigration,
      );
    } else {
      state.features.add(FeatureRecord(
        name: rawName,
        snakeName: snakeName,
        pascalName: pascalName,
        createdAt: now,
        fields: fields,
        filesCreated: filesCreated,
        filesUpdated: filesUpdated,
        sqlMigration: sqlMigration,
      ));
    }

    state.actions.add(ActionRecord(
      timestamp: now,
      command: 'create',
      args: [rawName],
      detail: '${fields.length} field(s)',
    ));

    save(state);
  }

  /// Enregistre la configuration auth
  static void addAuth({
    required bool email,
    required bool social,
    required List<String> filesCreated,
  }) {
    final state = load();
    final now = _isoNow();

    state.auth = AuthRecord(
      configured: true,
      configuredAt: now,
      email: email,
      social: social,
      filesCreated: filesCreated,
    );

    state.actions.add(ActionRecord(
      timestamp: now,
      command: 'auth',
      args: [if (email) 'email', if (social) 'social'].where((a) => a.isNotEmpty).toList(),
    ));

    save(state);
  }

  /// Retire une feature du state et retourne ses fichiers
  static FeatureRecord? removeFeature(String snakeName) {
    final state = load();
    final idx = state.features.indexWhere((f) => f.snakeName == snakeName);
    if (idx < 0) return null;

    final removed = state.features.removeAt(idx);
    final now = _isoNow();

    state.actions.add(ActionRecord(
      timestamp: now,
      command: 'undo',
      args: [removed.name],
      detail: '${removed.filesCreated.length} file(s) removed',
    ));

    save(state);
    return removed;
  }

  /// Trouve une feature par nom (snake ou raw)
  FeatureRecord? findFeature(String name) {
    final snake = name.contains('_') ? name : _toSnakeCase(name);
    try {
      return features.firstWhere((f) =>
          f.snakeName == snake || f.name == name || f.pascalName == name);
    } catch (_) {
      return null;
    }
  }

  static String _toSnakeCase(String input) => input
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
      .toLowerCase();
}

// ═══════════════════════════════════════════════════
// FILE TRACKER — trace les fichiers crees/mis a jour
// durant une commande cscm, pour les loguer dans le state.
// ═══════════════════════════════════════════════════

/// Tracker global actif pendant une commande cscm.
FileTracker? activeTracker;

class FileTracker {
  final List<String> created = [];
  final List<String> updated = [];
  String? lastSqlMigration;

  void trackCreated(String path) {
    if (!created.contains(path)) created.add(path);
  }

  void trackUpdated(String path) {
    if (!updated.contains(path)) updated.add(path);
  }

  void trackSqlMigration(String fileName) {
    lastSqlMigration = fileName;
  }

  void reset() {
    created.clear();
    updated.clear();
    lastSqlMigration = null;
  }

  List<FieldRecord> fieldsToRecords(List<dynamic> fields) {
    return fields.map((f) {
      if (f is FieldRecord) return f;
      // Support pour le model Field du CLI
      return FieldRecord(
        name: f.name.toString(),
        type: f.type.toString(),
        isEnum: f.isEnum == true,
        enumValues: List<String>.from(f.enumValues ?? []),
        isReference: f.isReference == true,
        referenceTarget: f.referenceTarget?.toString() ?? '',
      );
    }).toList();
  }
}
