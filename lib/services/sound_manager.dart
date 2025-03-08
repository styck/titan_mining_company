import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  final AudioPlayer player = AudioPlayer();

  Future<void> playSound(String effect) async {
    String fileName;
    switch (effect) {
      case 'meteor':
        fileName = 'meteor.mp3';
        break;
      case 'caveIn':
        fileName = 'cave_in.mp3';
        break;
      case 'dilithium':
        fileName = 'dilithium.mp3';
        break;
      case 'endgame':
        fileName = 'endgame.mp3';
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