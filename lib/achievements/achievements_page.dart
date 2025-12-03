import 'package:flutter/material.dart';
import '../tray_manager.dart';
import '../widgets/close_button_widget.dart';
import 'achievement_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsPage extends StatefulWidget {
  final TrayManager? trayManager;

  const AchievementsPage({
    super.key,
    this.trayManager,
  });

  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
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
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                title: const Text(
                  'Conquistas',
                  style: TextStyle(color: Colors.white),
                ),
                leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                actions: [
                  CustomCloseButton(trayManager: widget.trayManager),
                ],
                backgroundColor: const Color.fromARGB(255, 95, 189, 212),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                            return const Icon(Icons.emoji_events, size: 40);
                          },
                        ),
                        title: Text(achievement.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(achievement.description),
                            Text(
                              'Pontos: ${achievement.points}G',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: achievement.isUnlocked
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : const Icon(Icons.lock_outline,
                                color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

    );
  }
}
