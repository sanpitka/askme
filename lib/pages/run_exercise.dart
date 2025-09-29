import 'package:flutter/material.dart';
import 'dart:math';
import '../components/exercise_completion_dialog.dart';
import '../utils/text_normalizer.dart';
import '../utils/app_colors.dart';

// Enhanced similarity function that considers diacritic variations
double calculateSimilarity(String str1, String str2) {
  if (str1.isEmpty && str2.isEmpty) return 1.0;
  if (str1.isEmpty || str2.isEmpty) return 0.0;
  
  // Convert to lowercase for comparison
  str1 = str1.toLowerCase();
  str2 = str2.toLowerCase();
  
  // First check exact match
  if (str1 == str2) return 1.0;
  
  // Then check normalized match (without diacritics) - this should be "almost correct"
  String normalized1 = TextNormalizer.normalize(str1);
  String normalized2 = TextNormalizer.normalize(str2);
  if (normalized1 == normalized2) return 0.9; // Almost correct for diacritic-only differences
  
  // Calculate Levenshtein distance on original strings
  final matrix = List.generate(
    str1.length + 1,
    (i) => List.generate(str2.length + 1, (j) => 0.0),
  );
  
  // Initialize first row and column
  for (int i = 0; i <= str1.length; i++) {
    matrix[i][0] = i.toDouble();
  }
  for (int j = 0; j <= str2.length; j++) {
    matrix[0][j] = j.toDouble();
  }
  
  // Fill the matrix with enhanced character comparison
  for (int i = 1; i <= str1.length; i++) {
    for (int j = 1; j <= str2.length; j++) {
      double cost;
      if (str1[i - 1] == str2[j - 1]) {
        cost = 0; // Exact match
      } else if (TextNormalizer.normalize(str1[i - 1]) == TextNormalizer.normalize(str2[j - 1])) {
        cost = 0.2; // Small cost for diacritic differences
      } else {
        cost = 1; // Normal substitution cost
      }
      
      matrix[i][j] = [
        matrix[i - 1][j] + 1,     // deletion
        matrix[i][j - 1] + 1,     // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce(min);
    }
  }
  
  final distance = matrix[str1.length][str2.length];
  final maxLength = max(str1.length, str2.length);
  
  // Return similarity as percentage (1.0 = 100% similar, 0.0 = 0% similar)
  return 1.0 - (distance / maxLength);
}

class RunExercisePage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final Map<String, dynamic>? config;

  const RunExercisePage({
    super.key,
    required this.exercise,
    this.config,
  });

  @override
  State<RunExercisePage> createState() => _RunExercisePageState();
}

class _RunExercisePageState extends State<RunExercisePage> {
  late List<Map<String, String>> pairs;
  late Map<int, int> correctAnswers; // Track correct answers per question
  late Set<int> incorrectAnswers; // Track questions answered incorrectly at any point
  late List<int> questionQueue; // Current questions to ask
  late int currentQuestionIndex;
  late String currentQuestion;
  late String correctAnswer;
  
  // Configuration options
  late bool questionFirst; // true = first language as question, false = second language as question
  late int repetitionCount; // How many times each question is asked (1-3)
  late bool acceptAlmostCorrect; // Whether to accept almost correct answers
  
  final TextEditingController answerController = TextEditingController();
  final FocusNode answerFocusNode = FocusNode();
  
  bool isAnswered = false;
  bool isCorrect = false;
  bool isAlmostCorrect = false;
  String userAnswer = '';
  int totalQuestions = 0;
  int completedQuestions = 0;

  @override
  void initState() {
    super.initState();
    _initializeExercise();
  }

  void _initializeExercise() {
    // Load configuration or use defaults
    final config = widget.config ?? {};
    questionFirst = config['questionFirst'] ?? true;
    repetitionCount = config['repetitionCount'] ?? 2;
    acceptAlmostCorrect = config['acceptAlmostCorrect'] ?? true;
    
    // Extract pairs from exercise data
    final pairsData = widget.exercise['pairs'] as List<dynamic>? ?? [];
    pairs = [];
    for (var pair in pairsData) {
      if (pair is Map<String, dynamic>) {
        // Swap question and answer based on configuration
        String question = pair['question']?.toString() ?? '';
        String answer = pair['answer']?.toString() ?? '';
        
        if (!questionFirst) {
          // Swap question and answer
          String temp = question;
          question = answer;
          answer = temp;
        }
        
        pairs.add({
          'question': question,
          'answer': answer,
        });
      }
    }

    totalQuestions = pairs.length;
    
    // Initialize tracking
    correctAnswers = {};
    incorrectAnswers = <int>{};
    questionQueue = [];
    
    // Create list of question indices and shuffle them first
    List<int> shuffledIndices = List.generate(pairs.length, (i) => i);
    shuffledIndices.shuffle();
    
    // Add all questions to correctAnswers tracking
    for (int i = 0; i < pairs.length; i++) {
      correctAnswers[i] = 0;
    }
    
    // Add shuffled questions based on repetition count to avoid consecutive duplicates
    for (int rep = 0; rep < repetitionCount; rep++) {
      questionQueue.addAll(shuffledIndices);
    }
    
    _shuffleAndSetNextQuestion();
  }

  void _shuffleAndSetNextQuestion() {
    if (questionQueue.isEmpty) {
      // Hide keyboard when exercise is complete
      answerFocusNode.unfocus();
      _showCompletionDialog();
      return;
    }

    setState(() {
      // Simply take the first question from the queue (already shuffled to avoid consecutive duplicates)
      currentQuestionIndex = questionQueue[0];
      currentQuestion = pairs[currentQuestionIndex]['question']!;
      correctAnswer = pairs[currentQuestionIndex]['answer']!;
      
      // Reset state
      isAnswered = false;
      isCorrect = false;
      isAlmostCorrect = false;
      userAnswer = '';
      answerController.clear();
    });

    // Maintain focus on answer field to keep keyboard up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!answerFocusNode.hasFocus) {
        answerFocusNode.requestFocus();
      }
    });
  }

  void _checkAnswer() {
    if (answerController.text.trim().isEmpty || isAnswered) return;

    setState(() {
      userAnswer = answerController.text.trim();
      
      // Calculate similarity
      double similarity = calculateSimilarity(userAnswer.toLowerCase(), correctAnswer.toLowerCase());
      
      // Enhanced answer checking logic
      isCorrect = similarity >= 1.0; // Only exact matches are fully correct
      
      // Determine "almost correct" based on specific rules and configuration
      if (!isCorrect && acceptAlmostCorrect) {
        // Check if it's only a diacritic difference
        String normalizedUser = TextNormalizer.normalize(userAnswer.toLowerCase());
        String normalizedCorrect = TextNormalizer.normalize(correctAnswer.toLowerCase());
        
        if (normalizedUser == normalizedCorrect) {
          // Only diacritic differences - almost correct (any word length)
          isAlmostCorrect = true;
        } else if (correctAnswer.length > 5 && similarity >= 0.8) {
          // Words longer than 5 letters with 80%+ similarity - almost correct for small mistakes
          // Examples: "kilencs" vs "kilenc", letter order issues, etc.
          isAlmostCorrect = true;
        } else {
          // Short words (5 letters or less) with non-diacritic issues are incorrect
          isAlmostCorrect = false;
        }
      } else {
        isAlmostCorrect = false;
      }
      
      isAnswered = true;

      // If answered incorrectly (not correct and not almost correct), add to rehearsal set
      if (!isCorrect && !isAlmostCorrect) {
        incorrectAnswers.add(currentQuestionIndex);
        
        // Move the incorrect question to the end of the queue for more practice
        questionQueue.removeAt(0); // Remove from front
        questionQueue.add(currentQuestionIndex); // Add to end
      }

      if (isCorrect) {
        correctAnswers[currentQuestionIndex] = correctAnswers[currentQuestionIndex]! + 1;
        
        // Remove this question instance from the queue
        questionQueue.removeAt(0);
        
        // If this question has been answered correctly the required number of times, remove all instances
        if (correctAnswers[currentQuestionIndex]! >= repetitionCount) {
          questionQueue.removeWhere((index) => index == currentQuestionIndex);
          completedQuestions++;
        }
      } else if (isAlmostCorrect) {
        // For almost correct answers, treat as partially correct
        // Still add to rehearsal but with less penalty
        incorrectAnswers.add(currentQuestionIndex);
        
        // Remove this question instance from the queue
        questionQueue.removeAt(0);
      }
    });

    // Aggressively maintain focus using both methods
    answerFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      answerFocusNode.requestFocus();
    });
  }

  void _nextQuestion() {
    _shuffleAndSetNextQuestion();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExerciseCompletionDialog(
        totalQuestions: totalQuestions,
        rehearsalQuestionCount: incorrectAnswers.length,
        onBack: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Return to exercises page
        },
        onRehearsal: incorrectAnswers.isNotEmpty ? () {
          Navigator.pop(context); // Close dialog
          _startRehearsal();
        } : null,
        onRestart: () {
          Navigator.pop(context); // Close dialog
          _initializeExercise(); // Restart exercise
        },
      ),
    );
  }

  void _startRehearsal() {
    setState(() {
      // Reset tracking for rehearsal
      correctAnswers.clear();
      questionQueue.clear();
      completedQuestions = 0;
      
      // Create list of incorrect question indices and shuffle them first
      List<int> shuffledIncorrectIndices = incorrectAnswers.toList();
      shuffledIncorrectIndices.shuffle();
      
      // Only add questions that were incorrect at any point
      for (int questionIndex in shuffledIncorrectIndices) {
        correctAnswers[questionIndex] = 0;
      }
      
      // Add shuffled questions based on repetition count to avoid consecutive duplicates
      for (int rep = 0; rep < repetitionCount; rep++) {
        questionQueue.addAll(shuffledIncorrectIndices);
      }
      
      // Update total questions for progress calculation
      totalQuestions = incorrectAnswers.length;
      
      // Clear the incorrect set since we're starting fresh
      incorrectAnswers.clear();
    });
    
    _shuffleAndSetNextQuestion();
  }

  @override
  void dispose() {
    // Ensure keyboard is hidden when leaving the page
    answerFocusNode.unfocus();
    answerController.dispose();
    answerFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keskeytä harjoitus'),
          content: const Text('Haluatko varmasti keskeyttää harjoituksen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Keskeytä'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTitle = widget.exercise['title'] ?? 'Harjoitus';
    final questionLabel = widget.exercise['questionLabel'] ?? 'Kysymys';
    final answerLabel = widget.exercise['answerLabel'] ?? 'Vastaus';
    final progress = totalQuestions > 0 ? completedQuestions / totalQuestions : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final shouldPop = await _showExitConfirmationDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(exerciseTitle),
        backgroundColor: AppColors.askyYellow, // Golden yellow
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.askyYellowTint200, // Light golden yellow
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentQuestion,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Answer input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answerLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: answerController,
                      focusNode: answerFocusNode,
                      autofocus: true,
                      enabled: true, // Keep enabled throughout exercise
                      autocorrect: false, // Disable autocorrect
                      enableSuggestions: false, // Disable predictive text suggestions
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Kirjoita vastauksesi tähän...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: isAnswered ? null : _checkAnswer,
                          icon: const Icon(Icons.check),
                        ),
                      ),
                      onSubmitted: isAnswered ? null : (_) => _checkAnswer(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Result feedback
            if (isAnswered) ...[
              const SizedBox(height: 8),
              Card(
                color: isCorrect 
                    ? Colors.green[50] 
                    : isAlmostCorrect 
                        ? AppColors.askyYellowTint50 // Light golden yellow
                        : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect 
                                ? Icons.check_circle 
                                : isAlmostCorrect 
                                    ? Icons.check_circle_outline
                                    : Icons.cancel,
                            color: isCorrect 
                                ? Colors.green 
                                : isAlmostCorrect 
                                    ? AppColors.askyYellow // Golden yellow
                                    : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCorrect 
                                ? 'Oikein!' 
                                : isAlmostCorrect 
                                    ? 'Lähes oikein!'
                                    : 'Väärin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCorrect 
                                  ? Colors.green 
                                  : isAlmostCorrect 
                                      ? AppColors.askyYellow // Golden yellow
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Oikea vastaus: $correctAnswer',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (questionQueue.length <= 1) {
                              // This is the last question, show completion dialog
                              _showCompletionDialog();
                            } else {
                              // More questions available, go to next
                              _nextQuestion();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.askyYellow, // Golden yellow
                            foregroundColor: Colors.white,
                          ),
                          child: Text(questionQueue.length <= 1 ? 'Lopeta' : 'Seuraava kysymys'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
