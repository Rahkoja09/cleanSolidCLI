class ReformateClassName {
  static String capitalizeClassName({required String featureName}) {
    return featureName[0].toUpperCase() + featureName.substring(1);
  }
}
