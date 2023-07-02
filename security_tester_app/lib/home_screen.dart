import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:applist_detector_flutter/applist_detector_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:security_tester/widgets/report_dialog.dart';

import 'env.dart';
import 'more_tools.dart';
import 'utils.dart';
import 'widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoadingPlayIntegrityRequest = false;
  http.Response? playIntegrityResponse;
  Object? playIntegrityError;

  final _plugin = ApplistDetectorFlutter();
  bool isLoading = false;

  List<ResultWrapper> results = [];
  Set<ResultWrapper> selected = {};

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        _fetchPlayIntegrityAPI(),
        _startTests(),
      ]);
    });
    super.initState();
  }

  Future<void> _fetchPlayIntegrityAPI({bool cleanFirst = false}) async {
    if (isLoadingPlayIntegrityRequest) return;

    isLoadingPlayIntegrityRequest = true;

    String generateNonce() {
      const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
      final random = math.Random.secure();
      return List.generate(32, (_) => chars[random.nextInt(chars.length)])
          .join();
    }

    if (cleanFirst) {
      setState(() {
        playIntegrityResponse = null;
        playIntegrityError = null;
      });
    }
    try {
      final nonce = generateNonce();

      final token = await _plugin.checkPlayIntegrityApi(nonce);
      final response =
          await http.get(Uri.parse("$playIntegrityURL/api/check?token=$token"));

      if (!response.body.contains(nonce)) {
        throw Exception("Invalid response");
      }

      playIntegrityResponse = response;
      playIntegrityError = null;
    } catch (e) {
      playIntegrityResponse = null;
      playIntegrityError = e;
    } finally {
      isLoadingPlayIntegrityRequest = false;
      setState(() {});
    }
  }

  Future<void> _startTests({bool cleanFirst = false}) async {
    if (cleanFirst && mounted) {
      setState(() {
        results = [];
        selected = {};
        isLoading = true;
      });
    }
    try {
      final tests = [
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
      results = await Future.wait(tests);
    } catch (e, t) {
      log("ERROR Init", error: e, stackTrace: t);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Tester"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoreToolsScreen(),
                ),
              );
            },
            child: const Text("More Tools"),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AboutDialog(),
              );
            },
            icon: const Icon(Icons.emoji_objects_outlined),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            FloatingActionButton.extended(
              heroTag: "report",
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const ReportDialog(),
                );
              },
              icon: const Icon(Icons.file_open),
              label: const Text("Generate Report"),
            ),
            const Spacer(),
            FloatingActionButton(
              onPressed: () {
                Future.wait([
                  _fetchPlayIntegrityAPI(cleanFirst: true),
                  _startTests(cleanFirst: true),
                ]);
              },
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Wrap(
              runSpacing: 10,
              spacing: 5,
              children: DetectorResultType.values.map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 10),
                    icons[type] ?? const SizedBox.shrink(),
                    const SizedBox(width: 5),
                    Text(labels[type] ?? "-"),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('Play Integrity API'),
              trailing: IconButton(
                onPressed: () => _fetchPlayIntegrityAPI(cleanFirst: true),
                icon: const Icon(Icons.refresh_outlined),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playIntegrityError == null &&
                      playIntegrityResponse == null) ...[
                    const SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  ],
                  if (playIntegrityResponse != null) ...[
                    PlayIntegrityResult(response: playIntegrityResponse!),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 5),
                  Builder(
                    builder: (context) {
                      if (playIntegrityError == null) {
                        return const SizedBox.shrink();
                      }
                      if (playIntegrityError is PlayIntegrityException) {
                        final e = playIntegrityError as PlayIntegrityException;
                        return Text(
                          "${e.message}-${e.error} (${e.errorCode})",
                          style: const TextStyle(color: Colors.red),
                        );
                      } else if (playIntegrityError is PlatformException) {
                        final e = playIntegrityError as PlatformException;
                        return Text(
                          "${e.message} (${e.code})",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      return Text(
                        playIntegrityError.toString(),
                        style: const TextStyle(color: Colors.red),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 0),
            ListTile(
              title: const Text('Security Tests'),
              trailing: IconButton(
                onPressed: () => _startTests(cleanFirst: true),
                icon: const Icon(Icons.refresh_outlined),
              ),
            ),
            Builder(
              builder: (context) {
                if (isLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if (results.isEmpty) ...[
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      ],
                      ExpansionPanelList(
                        dividerColor: Colors.transparent,
                        expansionCallback: (index, isExpanded) {
                          final item = results[index];
                          if (isExpanded) {
                            selected.remove(item);
                          } else {
                            selected.add(item);
                          }
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        children: results.map((e) {
                          final isExpanded = selected.contains(e);
                          final hasError = e.error != null;
                          return buildExpPanel(
                            e,
                            testName: e.testName,
                            isExpanded: hasError || isExpanded,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 100)
          ],
        ),
      ),
    );
  }

  static const Map<DetectorResultType, Widget> icons = {
    DetectorResultType.notFound: Icon(Icons.done, color: Colors.green),
    DetectorResultType.found: Icon(Icons.coronavirus, color: Colors.red),
    DetectorResultType.suspicious: Icon(Icons.visibility, color: Colors.orange),
    DetectorResultType.methodUnavailable: Icon(Icons.code_off),
  };

  static const Map<DetectorResultType, String> labels = {
    DetectorResultType.notFound: "Not Found",
    DetectorResultType.found: "Found",
    DetectorResultType.suspicious: "Suspicious",
    DetectorResultType.methodUnavailable: "Method Unavailable",
  };

  ExpansionPanel buildExpPanel(
    ResultWrapper wrapper, {
    required String testName,
    bool isExpanded = false,
  }) {
    final details = wrapper.result.details;
    final type = wrapper.result.type;
    final error = wrapper.error;
    return ExpansionPanel(
      isExpanded: isExpanded,
      headerBuilder: (context, isExpanded) {
        return ListTile(
          leading: error != null
              ? const Icon(Icons.error, color: Colors.red)
              : icons[type],
          title: Text(testName),
          trailing: Text(error != null ? "ERROR" : ""),
          subtitle: Text(labels[type] ?? "Unknown"),
        );
      },
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ).add(const EdgeInsets.only(bottom: 15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.entries.map((e) {
                return Row(
                  children: [
                    icons[e.value]!,
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key)),
                  ],
                );
              }).toList(),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error.toString()),
            ],
          ],
        ),
      ),
    );
  }
}

class PlayIntegrityResult extends StatefulWidget {
  final http.Response response;
  const PlayIntegrityResult({
    Key? key,
    required this.response,
  }) : super(key: key);

  @override
  State<PlayIntegrityResult> createState() => _PlayIntegrityResultState();
}

class _PlayIntegrityResultState extends State<PlayIntegrityResult> {
  late final String result;

  @override
  void initState() {
    result = widget.response.body;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (kDebugMode) ...[
          Text("Status Code: ${widget.response.statusCode}"),
          const SizedBox(height: 10),
        ],
        IntegrityResult(
          title: "MEETS_BASIC_INTEGRITY",
          isPassed: result.contains("MEETS_BASIC_INTEGRITY"),
        ),
        const SizedBox(height: 5),
        IntegrityResult(
          title: "MEETS_DEVICE_INTEGRITY",
          isPassed: result.contains("MEETS_DEVICE_INTEGRITY"),
        ),
        const SizedBox(height: 5),
        IntegrityResult(
          title: "MEETS_STRONG_INTEGRITY",
          isPassed: result.contains("MEETS_STRONG_INTEGRITY"),
        ),
      ],
    );
  }
}

class IntegrityResult extends StatelessWidget {
  final String title;
  final bool isPassed;
  const IntegrityResult({
    Key? key,
    required this.title,
    required this.isPassed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isPassed) ...[
          const Icon(Icons.done_rounded, color: Colors.green),
        ] else ...[
          const Icon(Icons.coronavirus, color: Colors.red),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Text(title),
        ),
      ],
    );
  }
}
