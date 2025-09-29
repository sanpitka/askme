import 'package:flutter/material.dart';

class EditExerciseDialog extends StatelessWidget {
  final String currentTitle;
  final String currentQuestionLabel;
  final String currentAnswerLabel;
  final Function(String title, String questionLabel, String answerLabel) onSave;

  const EditExerciseDialog({
    super.key,
    required this.currentTitle,
    required this.currentQuestionLabel,
    required this.currentAnswerLabel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: currentTitle);
    final questionLabelController = TextEditingController(text: currentQuestionLabel);
    final answerLabelController = TextEditingController(text: currentAnswerLabel);

    return AlertDialog(
      title: const Text('Muokkaa harjoitusta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Harjoituksen nimi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: questionLabelController,
            decoration: const InputDecoration(
              labelText: 'Ensimmäinen kenttä',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.help_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: answerLabelController,
            decoration: const InputDecoration(
              labelText: 'Toinen kenttä',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Peruuta'),
        ),
        TextButton(
          onPressed: () {
            final title = titleController.text.isNotEmpty 
                ? titleController.text 
                : 'Uusi harjoitus';
            final questionLabel = questionLabelController.text.isNotEmpty 
                ? questionLabelController.text 
                : 'Kysymys';
            final answerLabel = answerLabelController.text.isNotEmpty 
                ? answerLabelController.text 
                : 'Vastaus';
            
            onSave(title, questionLabel, answerLabel);
            Navigator.pop(context);
          },
          child: const Text('Tallenna'),
        ),
      ],
    );
  }
}