import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSound(String soundType) async {
    try {
      // Libera qualquer recurso anterior
      await _player.stop();

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

      // Aguarda o som terminar de tocar
      await Future.delayed(const Duration(seconds: 1));
      await _player.stop();
    } catch (e) {
      print('Erro ao tocar som: $e');
      // Tenta liberar o recurso em caso de erro
      await _player.stop();
    }
  }
}
