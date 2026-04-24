import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class WaterProgress extends StatelessWidget {
  final int intake;
  final int goal;

  const WaterProgress({super.key, required this.intake, required this.goal});

  @override
  Widget build(BuildContext context) {
    double progress = (intake / goal).clamp(0, 1);

    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.blue,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$intake / $goal",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text("Glasses"),
            ],
          )
        ],
      ),
    );
  }
}