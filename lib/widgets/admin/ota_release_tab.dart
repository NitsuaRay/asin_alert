import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtaReleaseTab extends StatefulWidget {
  const OtaReleaseTab({super.key});

  @override
  State<OtaReleaseTab> createState() => _OtaReleaseTabState();
}

class _OtaReleaseTabState extends State<OtaReleaseTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  final _versionController = TextEditingController();
  final _buildNumberController = TextEditingController();
  final _changelogController = TextEditingController();

  PlatformFile? _selectedApk;
  Uint8List? _apkBytes;
  String _fileSizeDisplay = '';

  @override
  void dispose() {
    _versionController.dispose();
    _buildNumberController.dispose();
    _changelogController.dispose();
    super.dispose();
  }

  Future<void> _pickApkFile() async {
    // Static file picker call
    final PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );

    if (result != null) {
      final bytes = await result.readAsBytes();

      // Calculate MB size safely from the loaded Uint8List bytes
      final sizeInMb = (bytes.length / (1024 * 1024)).toStringAsFixed(2);

      setState(() {
        _selectedApk = result;
        _apkBytes = bytes;
        _fileSizeDisplay = '$sizeInMb MB';
      });
    }
  }

  Future<void> _publishOtaUpdate() async {
    if (_selectedApk == null ||
        _versionController.text.trim().isEmpty ||
        _buildNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select an APK and fill out version details.',
          ),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apkBytes = _apkBytes;
      if (apkBytes == null) {
        throw Exception("Failed to read file bytes. Please reselect the APK.");
      }

      // 1. Upload app-release.apk to Supabase Storage
      await _supabase.storage
          .from('apk-releases')
          .uploadBinary(
            'app-release.apk',
            apkBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Prepare version.json content
      final apkPublicUrl = _supabase.storage
          .from('apk-releases')
          .getPublicUrl('app-release.apk');

      final versionJsonData = {
        "version": _versionController.text.trim(),
        "build_number": int.parse(_buildNumberController.text.trim()),
        "download_url": apkPublicUrl,
        "changelog": _changelogController.text.trim(),
      };

      final jsonBytes = utf8.encode(jsonEncode(versionJsonData));

      // 3. Upload version.json to Supabase Storage
      await _supabase.storage
          .from('apk-releases')
          .uploadBinary(
            'version.json',
            jsonBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/json',
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('OTA Release published successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _versionController.clear();
        _buildNumberController.clear();
        _changelogController.clear();
        setState(() {
          _selectedApk = null;
          _apkBytes = null;
          _fileSizeDisplay = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing update: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApkSelected = _selectedApk != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_security_update_rounded,
                    color: Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OTA Release Deployment',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload and push binary packages to active user devices.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // File Picker Dropzone Area
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickApkFile,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isApkSelected
                      ? Colors.green.shade50.withValues(alpha: 0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isApkSelected
                        ? Colors.green.shade400
                        : Colors.grey.shade300,
                    width: isApkSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: isApkSelected
                          ? Colors.green.shade100
                          : const Color(0xFF0F172A).withValues(alpha: 0.05),
                      child: Icon(
                        isApkSelected
                            ? Icons.check_circle_rounded
                            : Icons.cloud_upload_outlined,
                        size: 28,
                        color: isApkSelected
                            ? Colors.green.shade700
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isApkSelected
                          ? _selectedApk!.name
                          : 'Tap to select .apk package',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isApkSelected
                            ? Colors.green.shade900
                            : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isApkSelected
                          ? 'Package Size: $_fileSizeDisplay'
                          : 'Supports Android Application Packages (.apk)',
                      style: TextStyle(
                        color: isApkSelected
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Release Details Form Header
          Text(
            'Release Specifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Version Input
          TextField(
            controller: _versionController,
            decoration: InputDecoration(
              labelText: 'Version Name',
              hintText: 'e.g. 1.0.4',
              prefixIcon: const Icon(Icons.tag_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0F172A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Build Number Input
          TextField(
            controller: _buildNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Build Code',
              hintText: 'e.g. 12',
              prefixIcon: const Icon(Icons.build_circle_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0F172A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Changelog Input
          TextField(
            controller: _changelogController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Release Notes / Changelog',
              hintText: 'Describe bug fixes, enhancements, and patches...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Icon(Icons.notes_rounded),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0F172A),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Action Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _publishOtaUpdate,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.rocket_launch_rounded),
            label: Text(
              _isLoading ? 'Deploying Binary...' : 'Publish OTA Release',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
