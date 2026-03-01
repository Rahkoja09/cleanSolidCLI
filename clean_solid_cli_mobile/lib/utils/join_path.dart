import 'package:path/path.dart' as p;

class JoinPath {
  static String joinAllPath(List<String> paths) {
    return p.joinAll(paths);
  }
}
