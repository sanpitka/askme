import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseStorage {
  static const String _exerciseListKey = 'exercise_list';
  static const String _exercisePrefix = 'exercise_';
  static const String _foldersKey = 'folders_list';
  static const String _folderPrefix = 'folder_';

  // Folder management methods
  static Future<List<String>> getAllFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final folders = prefs.getStringList(_foldersKey) ?? [];
    
    // Clean up any existing "Default" folders on first load
    await _migrateFromDefaultFolder();
    
    return folders.where((folder) => folder != 'Default').toList();
  }

  static Future<void> _migrateFromDefaultFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final folders = prefs.getStringList(_foldersKey) ?? [];
    
    if (folders.contains('Default')) {
      // Move exercises from Default folder to root
      final defaultFolderKey = '${_folderPrefix}default';
      final defaultExercises = prefs.getStringList(defaultFolderKey) ?? [];
      
      if (defaultExercises.isNotEmpty) {
        final rootFolderKey = '${_folderPrefix}root';
        final rootExercises = prefs.getStringList(rootFolderKey) ?? [];
        rootExercises.addAll(defaultExercises);
        await prefs.setStringList(rootFolderKey, rootExercises);
      }
      
      // Remove Default folder
      folders.remove('Default');
      await prefs.setStringList(_foldersKey, folders);
      await prefs.remove(defaultFolderKey);
    }
  }

  // Debug method to completely clean up any "Default" folder remnants
  static Future<void> cleanupLegacyDefaultFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Remove any keys related to Default folder
    for (final key in keys) {
      if (key.contains('default') || key.contains('Default')) {
        await prefs.remove(key);
      }
    }
    
    // Clean up folders list
    final folders = prefs.getStringList(_foldersKey) ?? [];
    final cleanedFolders = folders.where((folder) => folder != 'Default').toList();
    await prefs.setStringList(_foldersKey, cleanedFolders);
  }

  static Future<void> createFolder(String folderName) async {
    if (folderName.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final folders = prefs.getStringList(_foldersKey) ?? [];
    
    if (!folders.contains(folderName)) {
      folders.add(folderName);
      await prefs.setStringList(_foldersKey, folders);
      
      // Initialize empty exercise list for this folder
      await prefs.setStringList('$_folderPrefix${_sanitizeFilename(folderName)}', []);
    }
  }

  static Future<void> deleteFolder(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    final folders = prefs.getStringList(_foldersKey) ?? [];
    folders.remove(folderName);
    await prefs.setStringList(_foldersKey, folders);
    
    // Move exercises from deleted folder to root folder
    final folderKey = '$_folderPrefix${_sanitizeFilename(folderName)}';
    final exercisesInFolder = prefs.getStringList(folderKey) ?? [];
    
    if (exercisesInFolder.isNotEmpty) {
      final rootFolderKey = '${_folderPrefix}root';
      final rootExercises = prefs.getStringList(rootFolderKey) ?? [];
      rootExercises.addAll(exercisesInFolder);
      await prefs.setStringList(rootFolderKey, rootExercises);
    }
    
    // Remove the folder's exercise list
    await prefs.remove(folderKey);
  }

  static Future<void> saveExercise({
    required String title,
    required String questionLabel,
    required String answerLabel,
    required List<Map<String, String>> pairs,
    String? folderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final filename = _sanitizeFilename(title);
    final targetFolder = folderName ?? '';  // Empty string for root folder
    
    final exerciseData = {
      'title': title,
      'questionLabel': questionLabel,
      'answerLabel': answerLabel,
      'pairs': pairs,
      'createdAt': DateTime.now().toIso8601String(),
      'modifiedAt': DateTime.now().toIso8601String(),
      'filename': filename,
      'folder': targetFolder,
    };

    // Save the exercise data
    await prefs.setString('$_exercisePrefix$filename', jsonEncode(exerciseData));
    
    // Update the folder's exercise list
    final folderKey = targetFolder.isEmpty ? '${_folderPrefix}root' : '$_folderPrefix${_sanitizeFilename(targetFolder)}';
    final folderExercises = prefs.getStringList(folderKey) ?? [];
    if (!folderExercises.contains(filename)) {
      folderExercises.add(filename);
      await prefs.setStringList(folderKey, folderExercises);
    }
    
    // Legacy: Update the global exercise list for backward compatibility
    final exerciseList = prefs.getStringList(_exerciseListKey) ?? [];
    if (!exerciseList.contains(filename)) {
      exerciseList.add(filename);
      await prefs.setStringList(_exerciseListKey, exerciseList);
    }
  }

  static Future<Map<String, dynamic>?> loadExercise(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_exercisePrefix$filename');
      if (data != null) {
        return jsonDecode(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getExercisesInFolder(String folderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Empty folder name means root folder
      final folderKey = folderName.isEmpty ? '${_folderPrefix}root' : '$_folderPrefix${_sanitizeFilename(folderName)}';
      final exerciseList = prefs.getStringList(folderKey) ?? [];
      
      List<Map<String, dynamic>> exercises = [];
      
      for (String filename in exerciseList) {
        try {
          final data = prefs.getString('$_exercisePrefix$filename');
          if (data != null) {
            final exerciseData = jsonDecode(data);
            exercises.add(exerciseData);
          }
        } catch (e) {
          continue;
        }
      }
      
      // Sort by modified date (newest first)
      exercises.sort((a, b) {
        final aDate = DateTime.tryParse(a['modifiedAt'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['modifiedAt'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      
      return exercises;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exerciseList = prefs.getStringList(_exerciseListKey) ?? [];
      
      List<Map<String, dynamic>> exercises = [];
      
      for (String filename in exerciseList) {
        try {
          final data = prefs.getString('$_exercisePrefix$filename');
          if (data != null) {
            final exerciseData = jsonDecode(data);
            exercises.add(exerciseData);
          }
        } catch (e) {
          continue;
        }
      }
      
      // Sort by modified date (newest first)
      exercises.sort((a, b) {
        final aDate = DateTime.tryParse(a['modifiedAt'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['modifiedAt'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      
      return exercises;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> deleteExercise(String filename) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get exercise data to find its folder
      final exerciseData = prefs.getString('$_exercisePrefix$filename');
      String folderName = '';  // Empty string for root folder
      if (exerciseData != null) {
        final data = jsonDecode(exerciseData);
        folderName = data['folder'] ?? '';
      }
      
      // Remove from folder's exercise list
      final folderKey = folderName.isEmpty ? '${_folderPrefix}root' : '$_folderPrefix${_sanitizeFilename(folderName)}';
      final folderExercises = prefs.getStringList(folderKey) ?? [];
      folderExercises.remove(filename);
      await prefs.setStringList(folderKey, folderExercises);
      
      // Remove from global exercise list (legacy compatibility)
      final exerciseList = prefs.getStringList(_exerciseListKey) ?? [];
      exerciseList.remove(filename);
      await prefs.setStringList(_exerciseListKey, exerciseList);
      
      // Remove the exercise data
      await prefs.remove('$_exercisePrefix$filename');
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> moveExerciseToFolder(String filename, String newFolderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get exercise data to find current folder
      final exerciseData = prefs.getString('$_exercisePrefix$filename');
      if (exerciseData == null) return;
      
      final data = jsonDecode(exerciseData);
      final currentFolder = data['folder'] ?? '';  // Empty string for root folder
      
      if (currentFolder == newFolderName) return; // Already in target folder
      
      // Remove from current folder
      final currentFolderKey = currentFolder.isEmpty ? '${_folderPrefix}root' : '$_folderPrefix${_sanitizeFilename(currentFolder)}';
      final currentFolderExercises = prefs.getStringList(currentFolderKey) ?? [];
      currentFolderExercises.remove(filename);
      await prefs.setStringList(currentFolderKey, currentFolderExercises);
      
      // Add to new folder
      final newFolderKey = newFolderName.isEmpty ? '${_folderPrefix}root' : '$_folderPrefix${_sanitizeFilename(newFolderName)}';
      final newFolderExercises = prefs.getStringList(newFolderKey) ?? [];
      if (!newFolderExercises.contains(filename)) {
        newFolderExercises.add(filename);
        await prefs.setStringList(newFolderKey, newFolderExercises);
      }
      
      // Update exercise data with new folder
      data['folder'] = newFolderName;
      data['modifiedAt'] = DateTime.now().toIso8601String();
      await prefs.setString('$_exercisePrefix$filename', jsonEncode(data));
    } catch (e) {
      // Handle error silently
    }
  }

  static String _sanitizeFilename(String title) {
    return title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .toLowerCase();
  }
}