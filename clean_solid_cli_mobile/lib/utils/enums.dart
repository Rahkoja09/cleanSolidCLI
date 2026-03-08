enum FileTemplateType {
  entity,
  remoteSource,
  controller,
  model,
  usecase,
  states,
  repository,
  repositoryImpl,
  pages,
  di,
  action,
  successErrorListener,
  lastNetworkTimeProvider,
}

enum ImplementationType { entityImpl, modelImpl, remoteSourceImpl }

enum AuthFileType {
  entity,
  model,
  remoteSource,
  remoteSourceImpl,
  socialService,
  emailService,
  repository,
  repositoryImpl,
  usecases,
  states,
  action,
  controller,
}

enum AuthEmailType { emailRemote }

enum AuthSocilaType { socialRemote }
