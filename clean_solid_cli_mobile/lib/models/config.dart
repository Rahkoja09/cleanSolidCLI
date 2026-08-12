class CscmConfig {
  final String projectName;
  final String backend;
  final String stateManagement;
  final String di;
  final bool useScreenUtil;
  final bool useGoRouter;

  const CscmConfig({
    required this.projectName,
    this.backend = 'supabase',
    this.stateManagement = 'riverpod',
    this.di = 'get_it',
    this.useScreenUtil = true,
    this.useGoRouter = true,
  });

  factory CscmConfig.fromMap(Map<String, dynamic> map) {
    return CscmConfig(
      projectName: (map['project_name'] as String?) ?? 'my_app',
      backend: (map['backend'] as String?) ?? 'supabase',
      stateManagement: (map['state_management'] as String?) ?? 'riverpod',
      di: (map['di'] as String?) ?? 'get_it',
      useScreenUtil: (map['use_screenutil'] as bool?) ?? true,
      useGoRouter: (map['use_go_router'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_name': projectName,
      'backend': backend,
      'state_management': stateManagement,
      'di': di,
      'use_screenutil': useScreenUtil,
      'use_go_router': useGoRouter,
    };
  }

  String get projectNameSnake => projectName.replaceAll(' ', '_').toLowerCase();
}
