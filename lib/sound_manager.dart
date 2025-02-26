import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> playSound(String soundType) async {
    try {
      // Cria um novo player se não existir para este tipo de som
      _players[soundType] ??= AudioPlayer();
      final player = _players[soundType]!;

      // Para qualquer som que esteja tocando
      await player.stop();

      // Toca o som
      switch (soundType) {
        case 'add_water':
          await player.play(AssetSource('sounds/water_add.mp3'));
          break;
        case 'remove_water':
          await player.play(AssetSource('sounds/water_remove.mp3'));
          break;
        case 'goal_complete':
          await player.play(AssetSource('sounds/goal_complete.mp3'));
          break;
        case 'notification':
          await player.play(AssetSource('sounds/notification.mp3'));
          break;
        case 'achievement':
          await player.play(AssetSource('sounds/achievement.mp3'));
          break;
      }
    } catch (e) {
      print('Erro ao tocar som: $e');
    }
  }
}
