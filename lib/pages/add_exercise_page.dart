import 'package:flutter/material.dart';
import '../components/input_component.dart';
import '../components/edit_exercise_dialog.dart';
import '../services/exercise_storage.dart';
import '../utils/app_colors.dart';

class AddExercisePage extends StatefulWidget {
  final Map<String, dynamic>? existingExercise;
  final String? existingFilename;
  final List<String>? currentPath;

  const AddExercisePage({
    super.key,
    this.existingExercise,
    this.existingFilename,
    this.currentPath,
  });

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final List<Map<String, String>> exercise = [];
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final FocusNode questionFocusNode = FocusNode();
  final FocusNode answerFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  
  // Editable titles
  String exerciseTitle = 'Uusi harjoitus';
  String questionLabel = 'Kysymys';
  String answerLabel = 'Vastaus';
  String currentFolderName = 'Harjoitukset';  // Display name for current folder
  
  // Edit mode tracking
  int? editingIndex;
  bool hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadExistingExercise();
    _setCurrentFolderName();
  }

  void _setCurrentFolderName() {
    setState(() {
      currentFolderName = widget.currentPath?.isEmpty ?? true 
        ? 'Harjoitukset' 
        : widget.currentPath!.last;
    });
  }

  void _loadExistingExercise() {
    if (widget.existingExercise != null) {
      setState(() {
        exerciseTitle = widget.existingExercise!['title'] ?? 'Uusi harjoitus';
        questionLabel = widget.existingExercise!['questionLabel'] ?? 'Kysymys';
        answerLabel = widget.existingExercise!['answerLabel'] ?? 'Vastaus';
        
        final pairs = widget.existingExercise!['pairs'] as List<dynamic>? ?? [];
        exercise.clear();
        for (var pair in pairs) {
          if (pair is Map<String, dynamic>) {
            exercise.add({
              'question': pair['question']?.toString() ?? '',
              'answer': pair['answer']?.toString() ?? '',
            });
          }
        }
      });
    }
  }

  void addPair() {
    if (questionController.text.isNotEmpty && answerController.text.isNotEmpty) {
      setState(() {
        if (editingIndex != null) {
          // Update existing pair
          exercise[editingIndex!] = {
            'question': questionController.text,
            'answer': answerController.text,
          };
          editingIndex = null;
        } else {
          // Add new pair
          exercise.add({
            'question': questionController.text,
            'answer': answerController.text,
          });
        }
        questionController.clear();
        answerController.clear();
        hasUnsavedChanges = true;
      });
      // Focus back to the first input field
      questionFocusNode.requestFocus();
      
      // Scroll to bottom after adding item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void moveToAnswerField() {
    answerFocusNode.requestFocus();
  }

  void _editPair(int index) {
    final pair = exercise[index];
    setState(() {
      editingIndex = index;
      questionController.text = pair['question'] ?? '';
      answerController.text = pair['answer'] ?? '';
    });
    questionFocusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      editingIndex = null;
      questionController.clear();
      answerController.clear();
    });
    questionFocusNode.requestFocus();
  }

  void _deletePair(int index) {
    setState(() {
      exercise.removeAt(index);
      hasUnsavedChanges = true;
      if (editingIndex == index) {
        editingIndex = null;
        questionController.clear();
        answerController.clear();
      } else if (editingIndex != null && editingIndex! > index) {
        editingIndex = editingIndex! - 1;
      }
    });
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditExerciseDialog(
        currentTitle: exerciseTitle,
        currentQuestionLabel: questionLabel,
        currentAnswerLabel: answerLabel,
        onSave: (title, questionLabel, answerLabel) {
          setState(() {
            exerciseTitle = title;
            this.questionLabel = questionLabel;
            this.answerLabel = answerLabel;
            hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _saveExercise() async {
    if (exercise.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lisää ainakin yksi tehtävä tallentaaksesi'),
          margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Determine the folder name based on current path
      String folderName = '';
      if (widget.currentPath?.isNotEmpty ?? false) {
        folderName = widget.currentPath!.join('/');
      }
      
      await ExerciseStorage.saveExercise(
        title: exerciseTitle,
        questionLabel: questionLabel,
        answerLabel: answerLabel,
        pairs: exercise,
        folderName: folderName,
      );
      
      setState(() {
        hasUnsavedChanges = false;
      });
      
      if (!mounted) return; // Check if widget is still mounted
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$exerciseTitle tallennettu!'),
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Automatically exit after successful save
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Virhe tallentaessa'),
          margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    questionFocusNode.dispose();
    answerFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showEditDialog,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  exerciseTitle,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        actions: [
          if (editingIndex != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Peruuta muokkaus',
            ),
          IconButton(
            icon: const Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: _saveExercise,
            tooltip: 'Tallenna harjoitus',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: editingIndex != null ? AppColors.askyYellowTint50 : null, // Light golden yellow
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (editingIndex != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Muokataan tehtävää ${editingIndex! + 1}',
                      style: TextStyle(
                        color: AppColors.askyYellowDark, // Dark golden yellow
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          InputComponent(
                            group: questionLabel, 
                            controller: questionController,
                            focusNode: questionFocusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: moveToAnswerField,
                          ),
                          InputComponent(
                            group: answerLabel, 
                            controller: answerController,
                            focusNode: answerFocusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: addPair,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: exercise.length,
            itemBuilder: (context, index) {
              final isBeingEdited = editingIndex == index;
              return Dismissible(
                key: Key('exercise_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Poista tehtävä'),
                      content: const Text('Haluatko varmasti poistaa tämän tehtävän?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Peruuta'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Poista'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deletePair(index);
                },
                child: Container(
                  color: isBeingEdited ? AppColors.askyYellowTint100 : null, // Light golden yellow
                  child: ListTile(
                    title: Text(
                      exercise[index]['question'] ?? '',
                      style: TextStyle(
                        fontWeight: isBeingEdited ? FontWeight.bold : FontWeight.normal,
                        color: isBeingEdited ? AppColors.askyYellowDarker : null, // Dark golden yellow
                      ),
                    ),
                    subtitle: Text(
                      exercise[index]['answer'] ?? '',
                      style: TextStyle(
                        color: isBeingEdited ? AppColors.askyYellow : null, // Medium golden yellow
                      ),
                    ),
                    onTap: () => _editPair(index),
                  ),
                ),
              );
            }
          ),
        ),
        ],
      ),
    );
  }
}