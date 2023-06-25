import 'package:flutter/foundation.dart' show immutable;

enum DetectorResultType {
  notFound,
  methodUnavailable,
  suspicious,
  found,
}

typedef Details = Map<String, DetectorResultType>;

@immutable
class DetectorResult {
  final DetectorResultType type;
  final Details details;
  const DetectorResult({required this.type, this.details = const {}});
  factory DetectorResult.fromMap(Map map) {
    return DetectorResult(
      type: _parseTypeString(map['type']),
      details: _parseDetailMap(map['details']),
    );
  }

  @override
  String toString() => 'DetectorResult(type: $type)';

  static DetectorResultType _parseTypeString(String type) {
    final data = {
      "NOT_FOUND": DetectorResultType.notFound,
      "METHOD_UNAVAILABLE": DetectorResultType.methodUnavailable,
      "SUSPICIOUS": DetectorResultType.suspicious,
      "FOUND": DetectorResultType.found,
    };
    return data[type] ?? DetectorResultType.notFound;
  }

  static Details _parseDetailMap(Map<dynamic, dynamic> map) {
    final detail = <String, DetectorResultType>{};
    map.forEach((key, value) {
      detail[key] = _parseTypeString(value);
    });
    return detail;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetectorResult && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}
