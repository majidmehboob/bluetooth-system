// audio_helper.dart
import 'package:audioplayers/audioplayers.dart';

class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> initialize() async {
    await _player.setVolume(1.0);
  }

  static Future<void> playClassStartSound() async {
    try {
      await _player.play(AssetSource('sounds/sound.mp3'));
    } catch (e) {
      // SnackbarHelper.showError(context, 'Error playing sound: $e');
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
