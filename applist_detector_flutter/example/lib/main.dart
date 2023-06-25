import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:applist_detector_flutter/applist_detector_flutter.dart';
import './utils.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Applist Detector Flutter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: darkColorScheme,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _plugin = ApplistDetectorFlutter();
  bool isLoading = false;

  List<ResultWrapper> results = [];
  Set<ResultWrapper> selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTests();
    });
  }

  void _startTests() async {
    try {
      final tests = [
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
        buildWrapper("Settings Props", process: () {
          return _plugin.settingsProps();
        }),
        buildWrapper("Running Emulator", process: () {
          return _plugin.emulatorCheck();
        }),
        buildWrapper("RootBear Checks", process: () {
          return _plugin.checkRootBeer();
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
        title: const Text('Applist Detector Flutter'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => isLoading = true);
          _startTests();
        },
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const SizedBox(
                width: double.infinity,
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return ListView(
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
                if (results.isEmpty) ...[
                  const SizedBox.square(
                    dimension: 50,
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
                    return buildExpPanel(
                      e,
                      testName: e.testName,
                      isExpanded: isExpanded,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 80)
              ],
            );
          },
        ),
      ),
    );
  }

  static const Map<DetectorResultType, Widget> icons = {
    DetectorResultType.notFound: Icon(Icons.done),
    DetectorResultType.found: Icon(Icons.coronavirus, color: Colors.red),
    DetectorResultType.suspicious: Icon(Icons.visibility),
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
