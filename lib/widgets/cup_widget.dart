import 'package:flutter/material.dart';

class CupWidget extends StatelessWidget {
  final double currentIntake;
  final double dailyGoal;

  const CupWidget({
    Key? key,
    required this.currentIntake,
    required this.dailyGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String assetName;

    if (currentIntake < dailyGoal / 2) {
      assetName = 'assets/images/Copo Vazio.png';
    } else if (currentIntake < dailyGoal) {
      assetName = 'assets/images/Copo Metade.png';
    } else {
      assetName = 'assets/images/Copo Cheio.png';
    }

    return Image.asset(
      assetName,
      width: 100,
      height: 200,
      fit: BoxFit.contain,
    );
  }
}
