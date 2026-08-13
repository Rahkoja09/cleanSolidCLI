import 'package:clean_solid_cli_mobile/models/field.dart';
import 'package:clean_solid_cli_mobile/utils/anchor_helper.dart';
import 'package:clean_solid_cli_mobile/injections/select_injections.dart';

class RemoteSourceInjections {
  static String inject(String content, List<Field> fields) {
    final filtersStr = fields
        .map((f) {
          String fieldName;
          String dbCol;
          String filterLogic;
          if (f.isReference) {
            fieldName = f.referenceIdName;
            dbCol = f.referenceIdSnake;
            filterLogic = 'query = query.eq("$dbCol", $fieldName);';
          } else if (f.type == 'String') {
            fieldName = f.name;
            dbCol = f.snakeName;
            filterLogic = 'query = query.ilike("$dbCol", "%\$$fieldName%");';
          } else {
            fieldName = f.name;
            dbCol = f.snakeName;
            filterLogic = 'query = query.eq("$dbCol", $fieldName);';
          }
          return '''
        final $fieldName = criteria.$fieldName;
        if ($fieldName != null) {
          $filterLogic
        }''';
        })
        .join('\n');

    var result = replaceAnchor(
      content,
      '// [FILTERS_ANCHOR]',
      filtersStr,
      context: 'remoteSource',
    );
    result = SelectInjections.inject(result, fields);
    return result;
  }
}
