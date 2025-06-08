// lib/widgets/progress_bar.dart
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;
  final Color color;
  final bool invertProgress; 

  const ProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.percentage,
    this.color = Colors.blue,
    this.invertProgress = true, 
  });

  @override
  Widget build(BuildContext context) {
    // Calculer la valeur à afficher en fonction du mode
    // Si invertProgress est true, on affiche le pourcentage restant (100 - percentage)
    final displayPercentage = invertProgress ? 100 - percentage : percentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: displayPercentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}