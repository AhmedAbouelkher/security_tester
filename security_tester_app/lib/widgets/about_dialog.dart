import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutDialog extends StatefulWidget {
  const AboutDialog({super.key});

  @override
  State<AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<AboutDialog> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    PackageInfo.fromPlatform().then((value) {
      packageInfo = value;
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textBtnStyle = TextButton.styleFrom(
      padding: const EdgeInsets.all(0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(64, 30),
    );
    return AlertDialog(
      title: const Text('About'),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Security Tester", style: textTheme.titleMedium),
          if (packageInfo != null) ...[
            Text("${packageInfo!.version}+${packageInfo!.buildNumber}"),
          ],
          const SizedBox(height: 10),
          const Text("Developed by:"),
          TextButton(
            onPressed: () => url_launcher
                .launchUrl(Uri.parse("https://github.com/AhmedAbouelkher")),
            style: textBtnStyle,
            child: const Text("Ahmed M. Abouelkher"),
          ),
          const SizedBox(height: 15),
          Wrap(
            children: [
              TextButton(
                onPressed: () => url_launcher.launchUrl(Uri.parse(
                    "https://github.com/AhmedAbouelkher/security_tester")),
                style: textBtnStyle,
                child: const Text("Source Code"),
              ),
              TextButton(
                onPressed: () => url_launcher.launchUrl(Uri.parse(
                    "https://github.com/AhmedAbouelkher/security_tester/blob/main/LICENSE")),
                style: textBtnStyle,
                child: const Text("License"),
              ),
              TextButton(
                onPressed: () => url_launcher.launchUrl(Uri.parse(
                    "https://github.com/AhmedAbouelkher/security_tester-privacy_policy/blob/main/privacy.md")),
                style: textBtnStyle,
                child: const Text("Privacy Policy"),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
