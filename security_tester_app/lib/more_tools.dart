import 'dart:convert';
import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:flutter/services.dart';

import 'widgets/about_dialog.dart';

class MoreToolsScreen extends StatefulWidget {
  const MoreToolsScreen({super.key});

  @override
  State<MoreToolsScreen> createState() => _MoreToolsScreenState();
}

class _MoreToolsScreenState extends State<MoreToolsScreen> {
  static const platform = MethodChannel('misc_tools');

  AndroidDeviceInfo? androidInfo;
  Object? androidInfoError;
  bool isAndroidInfoExpanded = false;

  Map? cpuInfo;
  Object? cpuInfoError;
  bool isCpuInfoExpanded = false;

  Map? vpnDetails;
  Object? vpnDetailsError;
  bool isVpnDetailsExpanded = false;

  List? displaySettings;
  Object? displaySettingsError;
  bool isDisplaySettingsExpanded = false;

  bool? isRunningOnExternalStorage;
  String? telephoneOperatorName;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        _fetchDeviceInfo(),
        _fetchCPUInfo(),
        _fetchVPNChecks(),
        _displaySettings(),
        _runSimpleChecks(),
      ]);
    });
    super.initState();
  }

  Future<void> _fetchDeviceInfo() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      androidInfo = info;
      androidInfoError = null;
    } catch (e) {
      androidInfo = null;
      androidInfoError = e;
    } finally {
      setState(() {});
    }
  }

  Future<void> _fetchCPUInfo() async {
    try {
      final result = await platform.invokeMethod<Map>('cpu_info');
      cpuInfo = result;
      cpuInfoError = null;
    } catch (e) {
      cpuInfo = null;
      cpuInfoError = e;
    } finally {
      setState(() {});
    }
  }

  Future<void> _fetchVPNChecks() async {
    try {
      final result = await platform.invokeMethod<Map>('check_vpn');
      vpnDetails = result;
      vpnDetailsError = null;
    } catch (e) {
      vpnDetails = null;
      vpnDetailsError = e;
    } finally {
      setState(() {});
    }
  }

  Future<void> _displaySettings() async {
    try {
      final result =
          await platform.invokeMethod<List>('check_display_settings');
      displaySettings = result
          ?.map((e) => const JsonEncoder.withIndent("  ").convert(e))
          .toList();
      displaySettingsError = null;
    } catch (e) {
      displaySettings = null;
      displaySettingsError = e;
    } finally {
      setState(() {});
    }
  }

  Future<void> _runSimpleChecks() async {
    await platform.invokeMethod('check_display_settings');
    try {
      isRunningOnExternalStorage =
          await platform.invokeMethod<bool>('running_on_external_storage');
    } catch (e, t) {
      isRunningOnExternalStorage = null;
      log(
        "failed to check if app is running on external storage",
        error: e,
        stackTrace: t,
      );
    }

    try {
      telephoneOperatorName =
          await platform.invokeMethod<String>('telephone_operator_name');
    } catch (e, t) {
      telephoneOperatorName = null;
      log(
        "failed to check for telephone operator name",
        error: e,
        stackTrace: t,
      );
    } finally {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("More Tools"),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Future.wait([
            _fetchDeviceInfo(),
            _fetchCPUInfo(),
            _fetchVPNChecks(),
            _displaySettings(),
            _runSimpleChecks(),
          ]);
        },
        child: const Icon(Icons.refresh),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey, width: .2),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  "These are some tools which will help you to debug your app.\n"
                  "You will find some experimental tools here.\n"
                  "If you have any idea about a tool, please let me know.",
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                ListTile(
                  title: const Text("Running on External Storage"),
                  trailing: isRunningOnExternalStorage == null
                      ? const Text("UNKNOWN")
                      : isRunningOnExternalStorage!
                          ? const Icon(Icons.coronavirus, color: Colors.red)
                          : const Icon(Icons.check, color: Colors.green),
                ),
                ListTile(
                  title: const Text("Telephone Operator Name"),
                  trailing: telephoneOperatorName == null
                      ? const Text("UNKNOWN")
                      : Text(telephoneOperatorName!),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ListTile(
              onTap: () {
                setState(() {
                  isAndroidInfoExpanded = !isAndroidInfoExpanded;
                });
              },
              title: const Text('Device Info'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _fetchDeviceInfo,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            AnimatedContainer(
              height: isAndroidInfoExpanded ? null : 0,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (androidInfo != null) ...[
                    Text(
                      (androidInfo!.data..remove("systemFeatures"))
                          .entries
                          .map((e) => "${e.key}: ${e.value}")
                          .join("\v"),
                    ),
                  ],
                  const SizedBox(height: 5),
                  if (androidInfoError != null)
                    Text(androidInfoError.toString()),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                setState(() {
                  isCpuInfoExpanded = !isCpuInfoExpanded;
                });
              },
              title: const Text('CPU Info'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _fetchCPUInfo,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            AnimatedContainer(
              height: isCpuInfoExpanded ? null : 0,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  if (cpuInfo != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MODEL: ${cpuInfo?["model_name"] ?? "-"}"),
                        Text("VENDOR: ${cpuInfo?["vendor_id"] ?? "-"}"),
                      ],
                    ),
                    const Divider(thickness: 0.2, height: 20),
                    Text(
                      cpuInfo!.entries
                          .map((e) => "${e.key}: ${e.value}")
                          .join("\n"),
                    ),
                  ],
                  const SizedBox(height: 5),
                  if (cpuInfoError != null) Text(cpuInfoError.toString()),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                setState(() {
                  isVpnDetailsExpanded = !isVpnDetailsExpanded;
                });
              },
              title: const Text('VPN Checks'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _fetchVPNChecks,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            AnimatedContainer(
              height: isVpnDetailsExpanded ? null : 0,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey.shade900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vpnDetails != null) ...[
                    Text(
                      vpnDetails!.entries
                          .map((e) => "${e.key}: ${e.value}")
                          .join("\n"),
                    ),
                  ],
                  const SizedBox(height: 5),
                  if (vpnDetailsError != null) Text(vpnDetailsError.toString()),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                setState(() {
                  isDisplaySettingsExpanded = !isDisplaySettingsExpanded;
                });
              },
              title: const Text('Display Settings'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _displaySettings,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            AnimatedContainer(
              height: isDisplaySettingsExpanded ? null : 0,
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.grey.shade900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displaySettings != null) ...[
                    ...displaySettings!.map((e) {
                      return Text(e);
                    }),
                  ],
                  const SizedBox(height: 5),
                  if (displaySettingsError != null)
                    Text(displaySettingsError.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
