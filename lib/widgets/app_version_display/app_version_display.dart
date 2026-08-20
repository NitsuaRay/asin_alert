import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionDisplay extends StatelessWidget {
  const AppVersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String versionText = 'ASIN ALERT RESPONDER v1.0.0'; // Fallback

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final info = snapshot.data!;
          versionText = 'ASIN ALERT RESPONDER v${info.version}';
        }

        return Center(
          child: Text(
            versionText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        );
      },
    );
  }
}

// 