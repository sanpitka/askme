import 'package:flutter/material.dart';
import 'run_exercise.dart';

class ExerciseConfigPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final String currentPath;

  const ExerciseConfigPage({
    super.key,
    required this.exercise,
    required this.currentPath,
  });

  @override
  State<ExerciseConfigPage> createState() => _ExerciseConfigPageState();
}

class _ExerciseConfigPageState extends State<ExerciseConfigPage> {
  bool questionFirst = true; // true = first field as question, false = second field as question
  int repetitionCount = 2; // How many times each question is asked (1-3)
  bool acceptAlmostCorrect = true; // Whether to accept almost correct answers
  bool askInOrder = false; // Whether to ask questions in order

  String firstFieldLabel = '';
  String secondFieldLabel = '';

  @override
  void initState() {
    super.initState();
    _extractFieldLabels();
  }

  void _extractFieldLabels() {
    // Extract labels from exercise metadata
    firstFieldLabel = widget.exercise['questionLabel']?.toString() ?? 'Ensimmäinen';
    secondFieldLabel = widget.exercise['answerLabel']?.toString() ?? 'Toinen';
  }

  void _startExercise() {
    // Create exercise configuration
    final config = {
      'questionFirst': questionFirst,
      'repetitionCount': repetitionCount,
      'acceptAlmostCorrect': acceptAlmostCorrect,
      'askInOrder': askInOrder,
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunExercisePage(
          exercise: widget.exercise,
          config: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = widget.exercise['title']?.toString() ?? 'Harjoitus';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Harjoituksen asetukset'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.quiz,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Direction selection
            Text(
              'Kysymysten suunta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Card(
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Text('$firstFieldLabel → $secondFieldLabel'),
                    value: true,
                    groupValue: questionFirst,
                    onChanged: (value) {
                      setState(() {
                        questionFirst = value!;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  Divider(height: 1),
                  RadioListTile<bool>(
                    title: Text('$secondFieldLabel → $firstFieldLabel'),
                    value: false,
                    groupValue: questionFirst,
                    onChanged: (value) {
                      setState(() {
                        questionFirst = value!;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Repetition count
            Text(
              'Toistojen määrä',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kuinka monta kertaa jokainen kysymys kysytään:'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 1; i <= 3; i++)
                          Expanded(
                            child: RadioListTile<int>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text('$i'),
                              value: i,
                              groupValue: repetitionCount,
                              onChanged: (value) {
                                setState(() {
                                  repetitionCount = value!;
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Almost correct answers toggle
            Text(
              'Lähes oikeat vastaukset',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Card(
              child: CheckboxListTile(
                title: Text('Hyväksy lähes oikeat vastaukset'),
                value: acceptAlmostCorrect,
                onChanged: (value) {
                  setState(() {
                    acceptAlmostCorrect = value!;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            SizedBox(height: 24),

            // Question order toggle
            Text(
              'Kysymysten järjestys',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            Card(
              child: CheckboxListTile(
                title: Text('Kysy kysymykset järjestyksessä'),
                value: askInOrder,
                onChanged: (value) {
                  setState(() {
                    askInOrder = value!;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            SizedBox(height: 32),
            
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text(
                      'Aloita harjoitus',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
