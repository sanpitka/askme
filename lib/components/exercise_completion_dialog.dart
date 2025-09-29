import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ExerciseCompletionDialog extends StatelessWidget {
  final int totalQuestions;
  final int rehearsalQuestionCount;
  final VoidCallback onBack;
  final VoidCallback? onRehearsal;
  final VoidCallback onRestart;

  const ExerciseCompletionDialog({
    super.key,
    required this.totalQuestions,
    required this.rehearsalQuestionCount,
    required this.onBack,
    this.onRehearsal,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final hasRehearsalQuestions = rehearsalQuestionCount > 0 && onRehearsal != null;

    return AlertDialog(
      title: const Text('🎉 Harjoitus valmis!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olet vastannut kaikkiin $totalQuestions kysymykseen oikein kaksi kertaa. Hyvä!',
          ),
          if (hasRehearsalQuestions) ...[
            const SizedBox(height: 16),
            Text(
              '$rehearsalQuestionCount kysymystä vaatii kertausta.',
              style: const TextStyle(color: AppColors.askyYellow), // Golden yellow
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onBack,
          child: const Text('Poistu'),
        ),
        if (hasRehearsalQuestions)
          TextButton(
            onPressed: onRehearsal,
            style: TextButton.styleFrom(foregroundColor: AppColors.askyYellow), // Golden yellow
            child: const Text('Kertaa'),
          ),
      ],
    );
  }
}
