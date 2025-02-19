import 'package:flutter/material.dart';
import 'achievement_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<StatefulWidget> {
  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var achievement in AchievementManager.achievements) {
        achievement.isUnlocked =
            prefs.getBool('achievement_${achievement.id}') ?? false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conquistas'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: AchievementManager.achievements.length,
        itemBuilder: (context, index) {
          final achievement = AchievementManager.achievements[index];
          return Card(
            child: ListTile(
              leading: Image.asset(
                achievement.badgeAsset,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.emoji_events, size: 40);
                },
              ),
              title: Text(achievement.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.description),
                  Text(
                    'Pontos: ${achievement.points}G',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: achievement.isUnlocked
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.lock_outline, color: Colors.grey),
            ),
          );
        },
      ),
      // Botão para testar conquistas (remover em produção)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Testa o desbloqueio da primeira conquista
          AchievementManager.checkAchievement('first_water');
        },
        child: Icon(Icons.add),
        tooltip: 'Testar Conquista',
      ),
    );
  }
}
