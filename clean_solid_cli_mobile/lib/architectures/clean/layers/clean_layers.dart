class CleanLayers {
  final String domain;
  final String data;
  final String presentation;
  const CleanLayers(this.data, this.domain, this.presentation);

  String get getDomainName => domain.toLowerCase();
  String get getDataName => data.toLowerCase();
  String get getPresentationName => presentation.toLowerCase();
}
