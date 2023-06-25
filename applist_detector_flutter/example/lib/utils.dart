import 'dart:async';

import 'package:applist_detector_flutter/applist_detector_flutter.dart';
import 'package:flutter/material.dart';

const darkColorScheme = ColorScheme.light(
    primary: Color(0xFF5DD4FC),
    onPrimary: Color(0xFF003544),
    primaryContainer: Color(0xFF004D62),
    onPrimaryContainer: Color(0xFFB5EAFF),
    secondary: Color(0xFFB3CAD5),
    onSecondary: Color(0xFF1E333B),
    secondaryContainer: Color(0xFF354A53),
    onSecondaryContainer: Color(0xFFCFE6F1),
    tertiary: Color(0xFFC4C3EA),
    onTertiary: Color(0xFF2C2D4D),
    tertiaryContainer: Color(0xFF434465),
    onTertiaryContainer: Color(0xFFE1E0FF),
    error: Color(0xFFFFB4A9),
    onError: Color(0xFF680003),
    errorContainer: Color(0xFF930006),
    onErrorContainer: Color(0xFFFFDAD4),
    background: Color(0xFF191C1D),
    onBackground: Color(0xFFE1E3E5),
    surface: Color(0xFF191C1D),
    onSurface: Color(0xFFE1E3E5),
    surfaceVariant: Color(0xFF40484C),
    onSurfaceVariant: Color(0xFFC0C8CC),
    outline: Color(0xFF8A9296));

const lightColorScheme = ColorScheme.light(
  primary: Color(0xFF006782),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFB5EAFF),
  onPrimaryContainer: Color(0xFF001F29),
  secondary: Color(0xFF4C626B),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFCFE6F1),
  onSecondaryContainer: Color(0xFF071E26),
  tertiary: Color(0xFF5A5B7D),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFE1E0FF),
  onTertiaryContainer: Color(0xFF171837),
  error: Color(0xFFBA1B1B),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD4),
  onErrorContainer: Color(0xFF410001),
  background: Color(0xFFF9FDFF),
  onBackground: Color(0xFF191C1D),
  surface: Color(0xFFF9FDFF),
  onSurface: Color(0xFF191C1D),
  surfaceVariant: Color(0xFFF9FDFF),
  onSurfaceVariant: Color(0xFF40484C),
  outline: Color(0xFF70787C),
);

class ResultWrapper {
  final String testName;
  final DetectorResult result;
  final Object? error;
  final StackTrace? stackTrace;
  ResultWrapper({
    required this.testName,
    this.result = const DetectorResult(
      type: DetectorResultType.notFound,
      details: {},
    ),
    this.error,
    this.stackTrace,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResultWrapper && other.testName == testName;
  }

  @override
  int get hashCode {
    return testName.hashCode;
  }
}

Future<ResultWrapper> buildWrapper(
  String name, {
  required FutureOr<DetectorResult> Function() process,
}) async {
  try {
    final result = await process();
    return ResultWrapper(
      testName: name,
      result: result,
    );
  } catch (e, t) {
    return ResultWrapper(
      testName: name,
      error: e,
      stackTrace: t,
    );
  }
}
