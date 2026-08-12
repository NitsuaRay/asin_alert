import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class EmergencyAlarmService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  /// Starts looping siren audio & continuous vibration
  static Future<void> startAlarm() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      // 1. Loop siren audio in foreground
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/siren.mp3'));

      // 2. Loop continuous vibration pattern: [delay, vibrate, pause, vibrate]
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(
          pattern: [0, 1000, 500, 1000],
          repeat: 0, // 0 = continuous loop
        );
      }
    } catch (e) {
      print('Error starting emergency alarm: $e');
    }
  }

  /// Stops siren audio & vibration
  static Future<void> stopAlarm() async {
    if (!_isPlaying) return;
    _isPlaying = false;

    try {
      await _audioPlayer.stop();
      await Vibration.cancel();
    } catch (e) {
      print('Error stopping emergency alarm: $e');
    }
  }
}