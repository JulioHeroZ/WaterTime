import '../sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:achievement_view/achievement_view.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final int points;
  final String badgeAsset;
  final String requirement;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.badgeAsset,
    required this.requirement,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUnlocked': isUnlocked,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      badgeAsset: json['badgeAsset'],
      requirement: json['requirement'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: DateTime.parse(json['unlockedAt']),
    );
  }
}

class AchievementManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> initializeAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    for (var achievement in achievements) {
      achievement.isUnlocked =
          prefs.getBool('achievement_${achievement.id}') ?? false;
    }
  }

  static final List<Achievement> achievements = [
    Achievement(
      id: 'first_water',
      title: 'Primeira Gota',
      description: 'Registrou seu primeiro copo de água',
      points: 10,
      badgeAsset: 'assets/badges/first_water.png',
      requirement: 'Registre seu primeiro copo de água',
      unlockedAt: DateTime.now(),
    ),
    Achievement(
      id: 'daily_goal',
      title: 'Meta Diária',
      description: 'Atingiu a meta diária pela primeira vez',
      points: 20,
      badgeAsset: 'assets/badges/daily_goal.png',
      requirement: 'Atinja sua meta diária de água',
      unlockedAt: DateTime.now(),
    ),
    Achievement(
      id: 'streak_3',
      title: 'Hidratação Constante',
      description: 'Atingiu a meta diária por 3 dias seguidos',
      points: 30,
      badgeAsset: 'assets/badges/streak_3.png',
      requirement: '3 dias seguidos atingindo a meta',
      unlockedAt: DateTime.now(),
    ),
  ];

  static Future<void> checkAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final achievement = achievements.firstWhere((a) => a.id == achievementId);

    // Verifica se já está desbloqueada
    achievement.isUnlocked =
        prefs.getBool('achievement_${achievement.id}') ?? false;

    if (!achievement.isUnlocked) {
      achievement.isUnlocked = true;
      achievement.unlockedAt = DateTime.now();
      await prefs.setBool('achievement_${achievement.id}', true);
      // Salva também a data de desbloqueio
      await prefs.setString('achievement_${achievement.id}_date',
          achievement.unlockedAt!.toIso8601String());
      _showAchievementNotification(achievement);
    }
  }

  static Future<void> _showAchievementNotification(
      Achievement achievement) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      await SoundManager.playSound('achievement');

      AchievementView(
          title: achievement.title,
          subTitle: "${achievement.points}G",
          icon: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
          ),
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          textStyleTitle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textStyleSubTitle: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          alignment: Alignment.topCenter,
          duration: const Duration(milliseconds: 7500),
          isCircle: false,
          listener: (status) {
            print(status);
          }).show(context);
    }
  }

  static Future<void> testAchievement(String achievementId) async {
    final achievement = achievements.firstWhere((a) => a.id == achievementId);
    _showAchievementNotification(achievement);
  }

  static Future<List<Achievement>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    List<Achievement> unlockedAchievements = [];

    for (var achievement in achievements) {
      bool isUnlocked = prefs.getBool('achievement_${achievement.id}') ?? false;
      if (isUnlocked) {
        // Recupera a data de desbloqueio
        String? unlockedAtString =
            prefs.getString('achievement_${achievement.id}_date');
        achievement.isUnlocked = true;
        achievement.unlockedAt = unlockedAtString != null
            ? DateTime.parse(unlockedAtString)
            : DateTime.now(); // Fallback para agora se não houver data
        unlockedAchievements.add(achievement);
      }
    }
    return unlockedAchievements;
  }
}
