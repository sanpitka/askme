import 'package:flutter/material.dart';
import '../services/exercise_storage.dart';
import '../utils/app_colors.dart';
import 'add_exercise_page.dart';
import 'exercise_config_page.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  List<String> currentPath = []; // Current folder path
  List<String> folders = [];
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;
  bool isFABExpanded = false; // Track FAB expansion state

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  String get currentFolderName {
    return currentPath.isEmpty ? 'Harjoitukset' : currentPath.last;
  }

  String get currentFolderPath {
    return currentPath.join('/');
  }

  String get breadcrumbTitle {
    if (currentPath.isEmpty) return 'Harjoitukset';
    
    final fullPath = 'Harjoitukset > ${currentPath.join(' > ')}';
    
    // If the path is too long, show the end with "..." at the beginning
    // This ensures the current folder name is always visible
    const maxLength = 30; // Adjust this value as needed
    
    if (fullPath.length <= maxLength) {
      return fullPath;
    } else {
      // Take the last part that fits within the limit, prefixed with "..."
      final suffix = '...${fullPath.substring(fullPath.length - (maxLength - 3))}';
      
      // Make sure we don't cut in the middle of a folder name
      // Find the first " > " after the "..." to start from a clean folder boundary
      final cleanSuffixStart = suffix.indexOf(' > ');
      if (cleanSuffixStart != -1 && cleanSuffixStart > 3) {
        return '...${suffix.substring(cleanSuffixStart)}';
      }
      
      return suffix;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCurrentFolder() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Load folders in current path
      final allFolders = await ExerciseStorage.getAllFolders();
      final currentFolderPrefix = currentPath.isEmpty ? '' : '${currentPath.join('/')}/';
      
      // Filter folders that are direct children of current path
      final foldersInCurrentPath = allFolders
          .where((folder) => 
              folder.startsWith(currentFolderPrefix) && 
              folder != currentFolderPrefix.replaceAll('/', '') &&
              folder.substring(currentFolderPrefix.length).split('/').length == 1)
          .map((folder) => folder.substring(currentFolderPrefix.length))
          .toList();
      
      // Load exercises in current folder
      final folderPath = currentPath.join('/');  // Empty string for root folder
      final exercisesInFolder = await ExerciseStorage.getExercisesInFolder(folderPath);
      
      setState(() {
        folders = foldersInCurrentPath;
        exercises = exercisesInFolder;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        folders = [];
        exercises = [];
      });
    }
  }

  void _navigateToFolder(String folderName) {
    setState(() {
      currentPath.add(folderName);
    });
    _loadCurrentFolder();
  }

  void _navigateUp() {
    if (currentPath.isNotEmpty) {
      setState(() {
        currentPath.removeLast();
      });
      _loadCurrentFolder();
    }
  }

  Future<void> _createNewFolder() async {
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) {
        String newFolderName = '';
        return AlertDialog(
          title: const Text('Luo uusi kansio'),
          content: TextField(
            onChanged: (value) => newFolderName = value,
            decoration: const InputDecoration(
              labelText: 'Kansion nimi',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Peruuta'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, newFolderName.trim()),
              child: const Text('Luo'),
            ),
          ],
        );
      },
    );

    if (folderName != null && folderName.isNotEmpty && !folders.contains(folderName)) {
      final fullFolderPath = currentPath.isEmpty ? folderName : '${currentPath.join('/')}/$folderName';
      await ExerciseStorage.createFolder(fullFolderPath);
      await _loadCurrentFolder();
      if (!mounted) return; // Check if widget is still mounted
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kansio "$folderName" luotu'),
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poista kansio'),
        content: Text('Haluatko varmasti poistaa kansion "$folderName"?\n\nKaikki kansion sisältö (alikansiot ja harjoitukset) poistetaan pysyvästi.'),
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

    if (confirmed == true) {
      final fullFolderPath = currentPath.isEmpty ? folderName : '${currentPath.join('/')}/$folderName';
      
      // Delete all exercises in this folder and its subfolders
      await _deleteAllExercisesInFolder(fullFolderPath);
      
      // Delete all subfolders
      await _deleteAllSubFolders(fullFolderPath);
      
      // Delete the folder itself
      await ExerciseStorage.deleteFolder(fullFolderPath);
      
      await _loadCurrentFolder();
      if (!mounted) return; // Check if widget is still mounted
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kansio "$folderName" ja sen sisältö poistettu'),
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAllSubFolders(String folderPath) async {
    try {
      // Get all folders and find ones that are subfolders of the folder being deleted
      final allFolders = await ExerciseStorage.getAllFolders();
      final subFoldersToDelete = allFolders.where((folder) => folder.startsWith('$folderPath/')).toList();
      
      // Delete each subfolder
      for (final subFolder in subFoldersToDelete) {
        await ExerciseStorage.deleteFolder(subFolder);
      }
    } catch (e) {
      debugPrint('Error deleting subfolders: $e');
    }
  }

  Future<void> _deleteAllExercisesInFolder(String folderPath) async {
    try {
      // Get all exercises in this folder
      final exercisesInFolder = await ExerciseStorage.getExercisesInFolder(folderPath);
      
      // Delete each exercise
      for (final exercise in exercisesInFolder) {
        await ExerciseStorage.deleteExercise(exercise['filename']);
      }
      
      // Get all subfolders and recursively delete their contents
      final allFolders = await ExerciseStorage.getAllFolders();
      final subFolders = allFolders.where((folder) => folder.startsWith('$folderPath/')).toList();
      
      for (final subFolder in subFolders) {
        final exercisesInSubFolder = await ExerciseStorage.getExercisesInFolder(subFolder);
        for (final exercise in exercisesInSubFolder) {
          await ExerciseStorage.deleteExercise(exercise['filename']);
        }
      }
    } catch (e) {
      // Handle errors silently or log them
      debugPrint('Error deleting folder contents: $e');
    }
  }

  void _showItemContextMenu(String itemName, String itemType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (itemType == 'exercise') ...[
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.askyYellowDark), // Use darker golden yellow for edit
                title: const Text('Muokkaa'),
                onTap: () {
                  Navigator.pop(context);
                  final exercise = exercises.firstWhere((ex) => ex['filename'] == itemName);
                  _openExercise(exercise);
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Käynnistä'),
                onTap: () {
                  Navigator.pop(context);
                  final exercise = exercises.firstWhere((ex) => ex['filename'] == itemName);
                  _runExercise(exercise);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Poista'),
              onTap: () {
                Navigator.pop(context);
                if (itemType == 'exercise') {
                  final exercise = exercises.firstWhere((ex) => ex['filename'] == itemName);
                  _deleteExercise(exercise['filename'], exercise['title']);
                } else {
                  _deleteFolder(itemName);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExercise(String filename, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poista harjoitus'),
        content: Text('Haluatko varmasti poistaa harjoituksen "$title"?'),
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

    if (confirmed == true) {
      final success = await ExerciseStorage.deleteExercise(filename);
      if (!mounted) return; // Check if widget is still mounted
      
      if (success) {
        _loadCurrentFolder();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title poistettu'),
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virhe poistettaessa harjoitusta'),
            margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openExercise(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExercisePage(
          existingExercise: exercise,
          existingFilename: exercise['filename'],
          currentPath: currentPath,
        ),
      ),
    ).then((_) {
      _loadCurrentFolder();
    });
  }

  void _runExercise(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseConfigPage(
          exercise: exercise,
          currentPath: currentPath.join('/'),
        ),
      ),
    );
  }

  Widget _buildExerciseTile(Map<String, dynamic> exercise) {
    final pairCount = (exercise['pairs'] as List?)?.length ?? 0;
    final modifiedDate = DateTime.tryParse(exercise['modifiedAt'] ?? '');
    
    return Dismissible(
      key: Key(exercise['filename']),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        color: AppColors.askyYellowDark, // Use darker golden yellow for edit background
        child: const Icon(
          Icons.edit,
          color: Colors.white,
          size: 30,
        ),
      ),
      secondaryBackground: Container(
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
        if (direction == DismissDirection.endToStart) {
          // Swipe left - delete
          _deleteExercise(exercise['filename'], exercise['title']);
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right - edit
          _openExercise(exercise);
          return false;
        }
        return false;
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.askyYellow, // Use theme golden yellow
          child: const Icon(Icons.quiz, color: Colors.white),
        ),
        title: Text(
          exercise['title'] ?? 'Nimetön harjoitus',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$pairCount tehtävää'),
            if (modifiedDate != null)
              Text(
                'Muokattu: ${_formatDate(modifiedDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _runExercise(exercise),
        onLongPress: () => _showItemContextMenu(exercise['filename'], 'exercise'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(breadcrumbTitle),
        leading: currentPath.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateUp,
              )
            : null,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanEnd: (details) {
          // Check if it's a significant right swipe and we're not at root
          if (details.velocity.pixelsPerSecond.dx > 500 && 
              currentPath.isNotEmpty) {
            // Navigate up one folder level
            debugPrint('Pan swipe detected: velocity = ${details.velocity.pixelsPerSecond.dx}');
            _navigateUp();
          }
        },
        child: Stack(
          children: [
            _buildFolderContents(),
            // Semi-transparent overlay when FAB is expanded
            if (isFABExpanded)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isFABExpanded = false;
                  });
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isFABExpanded ? 0.3 : 0.0,
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildExpandableFAB(),
    );
  }

  Widget _buildFolderContents() {
    final hasContent = folders.isNotEmpty || exercises.isNotEmpty;
    
    if (!hasContent) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tyhjä kansio',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Luo kansioita tai harjoituksia',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Extra padding for FAB
      ),
      children: [
        // Show folders first
        ...folders.map((folder) => ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.askyYellowDark, // Use darker golden yellow for folders
            child: const Icon(Icons.folder, color: Colors.white),
          ),
          title: Text(
            folder,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Kansio'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _navigateToFolder(folder),
          onLongPress: () => _showItemContextMenu(folder, 'folder'),
        )),
        
        // Show exercises
        ...exercises.map((exercise) => _buildExerciseTile(exercise)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildExpandableFAB() {
    return SizedBox(
      width: 250,
      height: 140,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Expanded FAB Container
          if (isFABExpanded)
            Positioned(
              bottom: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isFABExpanded ? 1.0 : 0.0,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(28),
                  color: AppColors.askyYellowTint100,
                  child: Container(
                    width: 250,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
/*                       boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ], */
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Add Exercise Button (now first)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isFABExpanded = false;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddExercisePage(
                                    currentPath: currentPath,
                                  ),
                                ),
                              ).then((_) {
                                _loadCurrentFolder();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 220,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.askyYellowDarker, // Darker golden yellow for folder button
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.quiz, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Lisää harjoitus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Add Folder Button (now second)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                          onTap: () {
                            setState(() {
                              isFABExpanded = false;
                            });
                            _createNewFolder();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 220,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.askyYellowLight, // Lighter golden yellow for exercise button
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.create_new_folder, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Lisää kansio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Regular FAB (Plus Button)
          Positioned(
            bottom: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isFABExpanded ? 0.0 : 1.0,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    isFABExpanded = !isFABExpanded;
                  });
                },
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}