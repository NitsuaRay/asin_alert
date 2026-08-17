import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OtaService {
  // ⚠️ Replace with your exact Supabase Storage public URL for version.json
  static const String _versionJsonUrl =
      'https://ntrrrwzyvgpjsptcryhj.supabase.co/storage/v1/object/public/apk-releases/version.json';

  /// Checks if an update is available on Supabase
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_versionJsonUrl));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> remoteData = jsonDecode(response.body);
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      final String currentVersion = packageInfo.version; // e.g. "1.0.0"
      final String remoteVersion =
          remoteData['version'] as String; // e.g. "1.0.1"

      if (_isVersionNewer(currentVersion, remoteVersion)) {
        return {
          'currentVersion': currentVersion,
          'remoteVersion': remoteVersion,
          'downloadUrl': remoteData['download_url'],
          'changelog':
              remoteData['changelog'] ?? 'General improvements & bug fixes.',
        };
      }
    } catch (e) {
      debugPrint('OTA Check Error: $e');
    }
    return null;
  }

  /// Version string comparison helper (e.g. 1.0.1 > 1.0.0)
  static bool _isVersionNewer(String current, String remote) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> remoteParts = remote.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length; i++) {
        int currPart = i < currentParts.length ? currentParts[i] : 0;
        if (remoteParts[i] > currPart) return true;
        if (remoteParts[i] < currPart) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Streams download events to report progress percentage
  static Stream<OtaEvent> startDownloadAndInstall(String downloadUrl) {
    return OtaUpdate().execute(
      downloadUrl,
      destinationFilename: 'asin_alert_update.apk',
    );
  }
}
