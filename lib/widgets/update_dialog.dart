import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../services/ota_service.dart';

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String remoteVersion;
  final String downloadUrl;
  final String changelog;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.remoteVersion,
    required this.downloadUrl,
    required this.changelog,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progressValue = 0.0;
  String _statusText = 'Ready to download update.';

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _statusText = 'Downloading update package...';
    });

    try {
      OtaService.startDownloadAndInstall(widget.downloadUrl).listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final int progress = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _progressValue = progress / 100.0;
                _statusText = 'Downloading: $progress%';
              });
              break;
            case OtaStatus.INSTALLING:
              setState(() {
                _statusText = 'Launching Installer...';
              });
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _statusText = 'An update download is already in progress.';
              });
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _statusText = 'Permission denied to install APKs.';
                _isDownloading = false;
              });
              break;
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            default:
              setState(() {
                _statusText = 'Download failed. Please try again.';
                _isDownloading = false;
              });
              break;
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _statusText = 'Download error: $error';
              _isDownloading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Failed to launch update installer.';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDownloading, // Prevent dismissing while downloading
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.system_update_rounded, color: Color(0xFF0D47A1)),
            SizedBox(width: 10),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${widget.remoteVersion}) is available. Current version is ${widget.currentVersion}.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "What's New:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.changelog,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF0D47A1),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('LATER', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: _startUpdate,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('UPDATE NOW'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}