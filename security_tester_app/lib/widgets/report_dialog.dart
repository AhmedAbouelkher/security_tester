import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:applist_detector_flutter/applist_detector_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:security_tester/env.dart';
import 'package:security_tester/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toml/toml.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reportGenerator = ReportGenerator();
  late final Stream<String> statusStream;

  bool generating = false;
  Object? error;
  String? report;

  @override
  void initState() {
    super.initState();
    statusStream = _reportGenerator.statusStream;
  }

  @override
  void dispose() {
    _reportGenerator.dispose();
    super.dispose();
  }

  Future<void> runChecks() async {
    if (mounted) {
      setState(() {
        report = null;
        generating = true;
        error = null;
      });
    }
    try {
      final r = await _reportGenerator.runChecks();
      report = r;
      debugPrint(r);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }

  Future<void> createReportFile() async {
    if (report == null) return;
    if (mounted) {
      setState(() => generating = true);
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        "${tempDir.path}/security_report-${DateTime.now().toIso8601String()}.toml",
      ).writeAsString(report!);
      final xFile = XFile(file.path, name: file.path.split("/").last);
      await Share.shareXFiles(
        [xFile],
        subject: "My Security Report",
      );
      file.delete().then((fse) {
        debugPrint("Temp report file cleaned");
      });
    } catch (e) {
      // Do Nothing
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Generate Report"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Generate a report of the current device security state, "
            "and share it with the developer or other trusted parties.\n"
            "The report will be generated by running a series of checks.",
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 8),
          const Text(
            "This report is not a definitive proof of anything, "
            "but it can be used as a starting point for further investigation.",
            textAlign: TextAlign.justify,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              "Error: ${error.toString()}",
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: _buildResultsSection(),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        if (generating) ...[
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 1.2),
          ),
          const SizedBox(width: 8),
        ] else ...[
          ElevatedButton(
            onPressed: runChecks,
            child: const Text("Generate"),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection() {
    if (report == null) {
      return StreamBuilder(
        stream: statusStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Text("Running: ${snapshot.data}"),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        children: [
          const Text("Report generated successfully!"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Share.shareWithResult(
                  report!,
                  subject: "My Security Report",
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Share Report"),
              ),
              TextButton(
                onPressed: createReportFile,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Export Report"),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ReportGenerator {
  final _plugin = ApplistDetectorFlutter();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get statusStream => _controller.stream.asBroadcastStream();

  Future<String> runChecks() async {
    final checks = getChecks();
    final results = <ResultWrapper>[];
    for (final check in checks) {
      final result = await check;
      _controller.add(result.testName);
      results.add(result);
    }

    _controller.add("Play Integrity Check");
    final playIntegrity = await _checkPlayIntegrity();
    results.add(playIntegrity);

    final pkg = await PackageInfo.fromPlatform();
    final metadata = {
      "app": "Security Tester",
      "version": pkg.version,
      "buildNumber": pkg.buildNumber,
      "checkedAt": DateTime.now().toUtc().toIso8601String(),
      "playStore":
          "https://play.google.com/store/apps/details?id=com.ahmed.security_tester",
      "license":
          "https://github.com/AhmedAbouelkher/security_tester/blob/main/LICENSE",
      "sourceCode": "https://github.com/AhmedAbouelkher/security_tester",
    };

    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    final data = <String, dynamic>{
      ...metadata,
      ...deviceInfo.data,
    };

    for (final result in results) {
      if (result.error != null) {
        data[result.testName] = {"error": result.error.toString()};
        continue;
      }
      final details = result.result.details;
      if (details.isEmpty) continue;
      data[result.testName] =
          details.map((key, value) => MapEntry(key, value.str));
    }
    final document = TomlDocument.fromMap(data);
    return document.toString();
  }

  Future<ResultWrapper> _checkPlayIntegrity() async {
    late final ResultWrapper result;
    final nonce = _generateNonce();
    try {
      final token = await _plugin.checkPlayIntegrityApi(nonce);
      final url = Uri.parse("$playIntegrityURL/api/check?token=$token");
      final response = await http.get(url);
      final body = response.body;
      final details = {
        "MEETS_BASIC_INTEGRITY": body.contains("MEETS_BASIC_INTEGRITY")
            ? DetectorResultType.notFound
            : DetectorResultType.found,
        "MEETS_DEVICE_INTEGRITY": body.contains("MEETS_DEVICE_INTEGRITY")
            ? DetectorResultType.notFound
            : DetectorResultType.found,
        "MEETS_STRONG_INTEGRITY": body.contains("MEETS_STRONG_INTEGRITY")
            ? DetectorResultType.notFound
            : DetectorResultType.found,
      };

      result = ResultWrapper(
        testName: "Play Integrity API",
        result: DetectorResult(
          type: DetectorResultType.notFound,
          details: details,
        ),
      );
    } catch (e, t) {
      result = ResultWrapper(
        testName: "Play Integrity API",
        error: e,
        stackTrace: t,
      );
    }
    return result;
  }

  String _generateNonce() {
    const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    final random = math.Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<Future<ResultWrapper>> getChecks() {
    return [
      buildWrapper("Running Emulator", process: () {
        return _plugin.emulatorCheck();
      }),
      buildWrapper("Basic Root Checks (RootBeer)", process: () {
        return _plugin.checkRootBeer();
      }),
      buildWrapper("Settings Props", process: () {
        return _plugin.settingsProps();
      }),
      buildWrapper("Abnormal Environment", process: () {
        return _plugin.abnormalEnvironment();
      }),
      buildWrapper("Libc File Detection", process: () {
        return _plugin.fileDetection();
      }),
      buildWrapper("Syscall File Detection", process: () {
        return _plugin.fileDetection(useSysCall: true);
      }),
      buildWrapper("Xposed Framework", process: () {
        return _plugin.xposedFramework();
      }),
      buildWrapper("Xposed Modules", process: () {
        return _plugin.xposedModules();
      }),
      buildWrapper("LS Patch Xposed Modules", process: () {
        return _plugin.xposedModules(lspatch: true);
      }),
      buildWrapper("Magisk App", process: () {
        return _plugin.magiskApp();
      }),
      buildWrapper("PM Command", process: () {
        return _plugin.pmCommand();
      }),
      buildWrapper("PM Conventional APIs", process: () {
        return _plugin.pmConventionalAPIs();
      }),
      buildWrapper("PM Sundry APIs", process: () {
        return _plugin.pmSundryAPIs();
      }),
      buildWrapper("PM QueryIntentActivities", process: () {
        return _plugin.pmQueryIntentActivities();
      }),
    ];
  }

  String toJsonParser(List<ResultWrapper> results) {
    final data = <String, Map<String, String>>{};

    for (final result in results) {
      if (result.error != null) {
        data[result.testName] = {"error": result.error.toString()};
        continue;
      }
      final details = result.result.details;
      if (details.isEmpty) continue;
      data[result.testName] =
          details.map((key, value) => MapEntry(key, value.str));
    }
    // convert data map to json with 2 spaces indentation
    // return const JsonEncoder.withIndent("  ").convert(data);
    return jsonEncode(data);
  }

  static const _kTestsSeparator = "#######";
  String customerParser(List<ResultWrapper> results) {
    String report = "";
    for (final result in results) {
      report += "${result.testName}\n";
      if (result.error != null) {
        report += "error: ${result.error}\n";
        continue;
      }
      final details = result.result.details;
      if (details.isEmpty) continue;
      // print details with the same spaces between key and value
      final maxKeyLength =
          details.keys.map((e) => e.length).reduce((a, b) => a > b ? a : b);
      details.forEach((key, value) {
        report += "${key.padRight(maxKeyLength)}: ${value.str}\n";
      });
      // add new line after each test
      // check if last test don't add any separator
      if (result != results.last) report += "$_kTestsSeparator\n";
    }
    // clean trailing newlines
    report = report.trim();
    return report;
  }

  void dispose() {
    _controller.close();
  }
}

extension on DetectorResultType {
  String get str {
    switch (this) {
      case DetectorResultType.notFound:
        return "NOT_FOUND";
      case DetectorResultType.methodUnavailable:
        return "METHOD_UNAVAILABLE";
      case DetectorResultType.suspicious:
        return "SUSPICIOUS";
      case DetectorResultType.found:
        return "FOUND";
    }
  }
}