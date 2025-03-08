import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  final AudioPlayer player = AudioPlayer();

  Future<void> playSound(String effect) async {
    // Map to Atari subroutine sounds (e.g., J0=20000, J7=20070)
    String fileName;
    switch (effect) {
      case 'meteor':
        fileName = 'meteor.mp3'; // J6-like descending sound
        break;
      case 'caveIn':
        fileName = 'cave_in.mp3'; // J5-like alert sound
        break;
      case 'dilithium':
        fileName = 'dilithium.mp3'; // J0-like success sound
        break;
      default:
        fileName = 'default.mp3';
    }
    await player.play(AssetSource('sounds/$fileName'), volume: 0.5);
  }

  Future<void> stopSound() async {
    await player.stop();
  }
}