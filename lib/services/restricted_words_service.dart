import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/api/api_response.dart';
import '../features/auth/data/services/auth_service.dart';
import '../models/restricted_word_model.dart';

/// Restricted Words Service - Handles all restricted words operations
class RestrictedWordsService {
  final ApiClient _apiClient;

  // Singleton pattern
  static RestrictedWordsService? _instance;
  factory RestrictedWordsService({ApiClient? apiClient}) {
    _instance ??= RestrictedWordsService._internal(
      apiClient ?? AuthService().apiClient,
    );
    return _instance!;
  }

  RestrictedWordsService._internal(this._apiClient);

  /// Get all restricted words for a child
  Future<ApiResponse<List<String>>> getChildRestrictedWords({
    required String childId,
  }) async {
    try {
      print(
        '🔵 [RestrictedWordsService] Getting restricted words for child: $childId',
      );
      final url = '${ApiConstants.restrictedWordsByChild}$childId';
      print('🔵 [RestrictedWordsService] Request URL: $url');

      final response = await _apiClient.get<dynamic>(url, requiresAuth: true);

      if (response.isSuccess && response.data != null) {
        print('✅ [RestrictedWordsService] Raw API Response: ${response.data}');

        // Extract words from the response
        final List<String> words = [];
        if (response.data is List) {
          for (var item in response.data as List) {
            if (item is Map<String, dynamic>) {
              words.add(item['word'] as String);
            } else if (item is String) {
              words.add(item);
            }
          }
        } else if (response.data is Map<String, dynamic>) {
          // Handle case where response is an object with a words array
          final wordsData = response.data['words'];
          if (wordsData is List) {
            for (var item in wordsData) {
              if (item is Map<String, dynamic>) {
                words.add(item['word'] as String);
              } else if (item is String) {
                words.add(item);
              }
            }
          }
        }

        print('✅ [RestrictedWordsService] Parsed words: $words');
        return ApiResponse.success(words);
      } else {
        print('❌ [RestrictedWordsService] Failed: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'Failed to get restricted words',
        );
      }
    } catch (e) {
      print('❌ [RestrictedWordsService] Error getting restricted words: $e');
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Add a restricted word for a child
  Future<ApiResponse<String>> addChildRestrictedWord({
    required String childId,
    required String word,
  }) async {
    try {
      print(
        '🔵 [RestrictedWordsService] Adding restricted word for child: $childId',
      );
      print('🔵 [RestrictedWordsService] Word: $word');

      final response = await _apiClient.post<dynamic>(
        ApiConstants.restrictedWords,
        body: {'child_id': childId, 'word': word},
        requiresAuth: true,
      );

      // Regardless of API success, also save to local storage
      await _saveWordToLocalStorage(childId, word);

      if (response.isSuccess && response.data != null) {
        print('✅ [RestrictedWordsService] Added restricted word successfully');
        return ApiResponse.success(word);
      } else {
        print('❌ [RestrictedWordsService] Failed: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'Failed to add restricted word',
        );
      }
    } catch (e) {
      print('❌ [RestrictedWordsService] Error adding restricted word: $e');
      // Still save to local storage even if API fails
      await _saveWordToLocalStorage(childId, word);
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Save a word to local storage for the Android service to access
  Future<void> _saveWordToLocalStorage(String childId, String word) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'restricted_words_$childId';

    try {
      // Get existing words
      String wordsString = prefs.getString(key) ?? '[]';
      List<dynamic> wordsList;

      if (wordsString.startsWith('[') && wordsString.endsWith(']')) {
        wordsList = jsonDecode(wordsString);
      } else {
        // Handle comma-separated format if needed
        wordsList = wordsString.isEmpty ? [] : wordsString.split(',');
      }

      // Add new word if it doesn't exist
      if (!wordsList.contains(word)) {
        wordsList.add(word);

        // Save back to preferences
        await prefs.setString(key, jsonEncode(wordsList));
        print('✅ [RestrictedWordsService] Saved word to local storage: $word');
      }
    } catch (e) {
      print('❌ [RestrictedWordsService] Error saving to local storage: $e');
    }
  }

  /// Remove a restricted word for a child
  Future<ApiResponse<void>> removeChildRestrictedWord({
    required String childId,
    required String word,
  }) async {
    try {
      print(
        '🔵 [RestrictedWordsService] Removing restricted word for child: $childId',
      );
      print('🔵 [RestrictedWordsService] Word: $word');

      final response = await _apiClient.delete<dynamic>(
        '${ApiConstants.restrictedWordsRemoveByChild}$childId/remove/?word=$word',
        requiresAuth: true,
      );

      // Regardless of API success, also remove from local storage
      await _removeWordFromLocalStorage(childId, word);

      if (response.isSuccess) {
        print(
          '✅ [RestrictedWordsService] Removed restricted word successfully',
        );
        return ApiResponse.success(null);
      } else {
        print('❌ [RestrictedWordsService] Failed: ${response.error}');
        return ApiResponse.error(
          response.error ?? 'Failed to remove restricted word',
        );
      }
    } catch (e) {
      print('❌ [RestrictedWordsService] Error removing restricted word: $e');
      // Still remove from local storage even if API fails
      await _removeWordFromLocalStorage(childId, word);
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Remove a word from local storage
  Future<void> _removeWordFromLocalStorage(String childId, String word) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'restricted_words_$childId';

    try {
      // Get existing words
      String wordsString = prefs.getString(key) ?? '[]';
      List<dynamic> wordsList;

      if (wordsString.startsWith('[') && wordsString.endsWith(']')) {
        wordsList = jsonDecode(wordsString);
      } else {
        // Handle comma-separated format if needed
        wordsList = wordsString.isEmpty ? [] : wordsString.split(',');
      }

      // Remove the word if it exists
      wordsList.remove(word);

      // Save back to preferences
      await prefs.setString(key, jsonEncode(wordsList));
      print(
        '✅ [RestrictedWordsService] Removed word from local storage: $word',
      );
    } catch (e) {
      print('❌ [RestrictedWordsService] Error removing from local storage: $e');
    }
  }

  /// Update all restricted words for a child by clearing and re-adding
  Future<ApiResponse<List<String>>> updateChildRestrictedWords({
    required String childId,
    required List<String> words,
  }) async {
    try {
      print(
        '🔵 [RestrictedWordsService] Updating all restricted words for child: $childId',
      );
      print('🔵 [RestrictedWordsService] Words: $words');

      // Since backend doesn't support PUT, we'll add each word individually
      // This is a simplified approach - in production, implement proper endpoint
      for (String word in words) {
        await addChildRestrictedWord(childId: childId, word: word);
      }

      // Also update local storage directly with the complete list
      await _updateAllWordsInLocalStorage(childId, words);

      print('✅ [RestrictedWordsService] Updated restricted words successfully');
      return ApiResponse.success(words);
    } catch (e) {
      print('❌ [RestrictedWordsService] Error updating restricted words: $e');
      return ApiResponse.error('Error: ${e.toString()}');
    }
  }

  /// Update all words in local storage for a child
  Future<void> _updateAllWordsInLocalStorage(
    String childId,
    List<String> words,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'restricted_words_$childId';

    try {
      await prefs.setString(key, jsonEncode(words));
      print(
        '✅ [RestrictedWordsService] Updated all words in local storage for child $childId',
      );
    } catch (e) {
      print('❌ [RestrictedWordsService] Error updating local storage: $e');
    }
  }
}