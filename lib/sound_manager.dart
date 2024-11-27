import 'package:audioplayers/audioplayers.dart';
import 'sound_manager.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  
  static Future<void> playSound(String soundType) async {
    try {
      switch (soundType) {
        case 'add_water':
          await _player.play(AssetSource('sounds/water_add.mp3'));
          break;
        case 'remove_water':
          await _player.play(AssetSource('sounds/water_remove.mp3'));
          break;
        case 'goal_complete':
          await _player.play(AssetSource('sounds/goal_complete.mp3'));
          break;
        case 'notification':
          await _player.play(AssetSource('sounds/notification.mp3'));
          break;
        case 'achievement':
          await _player.play(AssetSource('sounds/achievement.mp3'));
          break;
      }
    } catch (e) {
      print('Erro ao tocar som: $e');
    }
  }
}