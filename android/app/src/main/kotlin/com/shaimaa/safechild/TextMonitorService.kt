package com.shaimaa.safechild

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import android.content.SharedPreferences
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject
import org.json.JSONArray

class TextMonitorService : AccessibilityService() {
    
    companion object {
        private const val TAG = "TextMonitorService"
        private const val PREFS_NAME = "safechild_prefs"
        
        // API Configuration
        private const val API_BASE_URL = "http://10.0.2.2:8000" // Default for Android emulator; change this to your server IP for other devices
        private const val WRITING_CHECK_ENDPOINT = "/api/v1/writing-check/"
        private const val NOTIFICATIONS_ENDPOINT = "/api/notifications/send-to-parent/"
        private const val RESTRICTED_WORDS_CHILD_ENDPOINT = "/api/v1/restricted-words/child/"
    }
    
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var lastCheckedText = ""
    private var lastCheckTime = 0L
    private lateinit var prefs: SharedPreferences
    
    // Password protection for disabling service
    private var passwordDialog: android.app.AlertDialog? = null
    
    // Local bad words for quick check (before API call)
    private val badWords = listOf(
        // English
        "fuck", "shit", "porn", "sex", "xxx", "bitch", "ass", "dick", "pussy",
        // Arabic offensive words
        "قذر", "اباحي", "جنس", "لعنة", "مثلي", "شاذ", "عاهرة", 
        "زنا", "سافل", "حقير", "كلب", "حمار", "غبي", "احمق",
        "خنزير", "فاسق", "منحرف", "لوطي", "زاني", "شرموط",
        "عرص", "متخلف", "وسخ", "قحبة", "ديوث", "اهبل", "سخيف",
        "حمق", "اوبس", "섹스", "포르노"  // Additional offensive terms
    )
    
    // Child-specific restricted words (loaded from API)
    private var childRestrictedWords = mutableMapOf<String, List<String>>()
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        
        // Initialize encrypted shared preferences for secure token storage
        try {
            val masterKey = MasterKey.Builder(this, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            
            prefs = EncryptedSharedPreferences.create(
                this,
                PREFS_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            Log.d(TAG, "✅ EncryptedSharedPreferences initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing encrypted preferences, falling back to regular preferences: ${e.message}")
            prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        }
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
        
        Log.d(TAG, "✅ TextMonitorService connected and configured")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        
        // Check if monitoring is enabled
        val isEnabled = prefs.getBoolean("writing_restrictions_enabled", false)
        if (!isEnabled) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                val text = event.text?.joinToString("") ?: return
                if (text.isEmpty() || text == lastCheckedText) return
                
                // Avoid checking too frequently
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastCheckTime < 500) return
                lastCheckTime = currentTime
                lastCheckedText = text
                
                Log.d(TAG, "📝 Text detected: $text")
                
                // Quick local check first
                scope.launch {
                    if (containsBadWords(text)) {
                        withContext(Dispatchers.Main) {
                            Log.d(TAG, "⛔ Bad word detected locally: $text")
                            clearEditText(event)
                            showBlockedAlert()
                            sendAlertToParent(text, "local")
                        }
                    }
                }
                
                // Check with AI API (for text longer than 3 chars)
                if (text.length >= 3) {
                    checkWithAI(text, event)
                }
            }
        }
    }
    
    private fun containsBadWordsLocal(text: String): Boolean {
        val lowerText = text.lowercase()
        return badWords.any { word -> 
            val wordLower = word.lowercase()
            // Check for exact word matches (with word boundaries) or substring matches
            lowerText.contains(wordLower) || 
            lowerText.contains(" $wordLower") || 
            lowerText.contains("$wordLower ") || 
            lowerText.startsWith(wordLower) || 
            lowerText.endsWith(wordLower)
        }
    }
    
    private suspend fun containsBadWords(text: String): Boolean {
        // First check the local hardcoded bad words
        if (containsBadWordsLocal(text)) {
            return true
        }
        
        // Then check child-specific restricted words if child info is available
        val childId = prefs.getString("child_id", "") ?: ""
        if (childId.isNotEmpty()) {
            // Try to get API words first
            val apiMatch = containsChildRestrictedWords(text, childId)
            if (apiMatch) return true
            
            // If API fails, also check local stored words as fallback
            val localRestrictedWords = getLocalRestrictedWordsForChild(childId)
            val lowerText = text.lowercase()
            
            return localRestrictedWords.any { word ->
                val wordLower = word.lowercase()
                lowerText.contains(wordLower) ||
                lowerText.contains(" $wordLower") ||
                lowerText.contains("$wordLower ") ||
                lowerText.startsWith(wordLower) ||
                lowerText.endsWith(wordLower)
            }
        }
        
        return false
    }
    
    private fun checkWithAI(text: String, event: AccessibilityEvent) {
        scope.launch {
            try {
                Log.d(TAG, "🔵 Checking with AI API: $text")
                
                val result = makeApiCall(text)
                
                if (result.isSuccess) {
                    handleApiResponse(result, text, event)
                } else {
                    // If first attempt failed with 401, try to refresh token and retry
                    if (result.responseCode == 401) {
                        Log.d(TAG, "🔄 Attempting to refresh token and retry")
                        val refreshResult = refreshAuthToken()
                        
                        if (refreshResult) {
                            // Retry the API call with new token
                            val retryResult = makeApiCall(text)
                            if (retryResult.isSuccess) {
                                handleApiResponse(retryResult, text, event)
                            } else {
                                handleApiFailure(retryResult, text, event)
                            }
                        } else {
                            handleApiFailure(result, text, event)
                        }
                    } else {
                        handleApiFailure(result, text, event)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error checking with AI: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    private data class ApiResult(
        val isSuccess: Boolean,
        val responseCode: Int,
        val responseBody: String?,
        val errorResponse: String?
    )
    
    private suspend fun makeApiCall(text: String): ApiResult {
        return withContext(Dispatchers.IO) {
            try {
                val url = URL("$API_BASE_URL$WRITING_CHECK_ENDPOINT")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // Get auth token
                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }
                
                // Send request
                val jsonBody = JSONObject().apply {
                    put("text", text)
                }
                connection.outputStream.write(jsonBody.toString().toByteArray())
                
                // Read response
                val responseCode = connection.responseCode
                val responseBody = if (responseCode == 200) {
                    connection.inputStream.bufferedReader().readText()
                } else {
                    null
                }
                
                val errorResponse = if (responseCode != 200) {
                    try {
                        connection.errorStream?.bufferedReader()?.readText() ?: "No error details"
                    } catch (e: Exception) {
                        "Error reading error response: ${e.message}"
                    }
                } else {
                    null
                }
                
                connection.disconnect()
                
                ApiResult(
                    isSuccess = responseCode == 200,
                    responseCode = responseCode,
                    responseBody = responseBody,
                    errorResponse = errorResponse
                )
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error making API call: ${e.message}")
                ApiResult(
                    isSuccess = false,
                    responseCode = -1,
                    responseBody = null,
                    errorResponse = e.message
                )
            }
        }
    }
    
    private fun handleApiResponse(result: ApiResult, text: String, event: AccessibilityEvent) {
        if (result.isSuccess && result.responseBody != null) {
            try {
                Log.d(TAG, "✅ AI Response: ${result.responseBody}")
                
                val jsonResponse = JSONObject(result.responseBody)
                val isToxic = jsonResponse.optBoolean("is_toxic", false)
                val isAllowed = jsonResponse.optBoolean("is_allowed", true)
                val confidence = jsonResponse.optDouble("confidence", 0.0)
                
                Log.d(TAG, "📊 is_toxic: $isToxic, is_allowed: $isAllowed, confidence: $confidence")
                
                if (isToxic || !isAllowed) {
                    scope.launch(Dispatchers.Main) {
                        clearEditText(event)
                        showBlockedAlert()
                        sendAlertToParent(text, "ai")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error parsing API response: ${e.message}")
            }
        }
    }
    
    private fun handleApiFailure(result: ApiResult, text: String, event: AccessibilityEvent) {
        val errorMessage = result.errorResponse ?: "Unknown error"
        Log.e(TAG, "❌ API Error: ${result.responseCode} - $errorMessage")
        
        // Handle 401 specifically
        if (result.responseCode == 401) {
            Log.e(TAG, "🔒 Authentication failed. Token may be invalid or expired.")
            
            // Even with auth failure, if we detect bad words locally or child-specific words, still block
            val hasLocalBadWords = containsBadWordsLocal(text)
            
            // Check child-specific restricted words from local storage
            val childId = prefs.getString("child_id", "") ?: ""
            val hasChildRestrictedWords = if (childId.isNotEmpty()) {
                val localRestrictedWords = getLocalRestrictedWordsForChild(childId)
                val lowerText = text.lowercase()
                
                localRestrictedWords.any { word ->
                    val wordLower = word.lowercase()
                    lowerText.contains(wordLower) ||
                    lowerText.contains(" $wordLower") ||
                    lowerText.contains("$wordLower ") ||
                    lowerText.startsWith(wordLower) ||
                    lowerText.endsWith(wordLower)
                }
            } else {
                false
            }
            
            if (hasLocalBadWords || hasChildRestrictedWords) {
                Log.d(TAG, "⚠️ Blocking text locally despite API auth failure")
                scope.launch(Dispatchers.Main) {
                    clearEditText(event)
                    showBlockedAlert()
                    sendAlertToParent(text, "local-fallback")
                }
            }
        }
    }
    
    private suspend fun refreshAuthToken(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "🔄 Attempting to refresh auth token")
                
                // Try to get refresh token from multiple possible keys
                var refreshToken = prefs.getString("refresh_token", "") ?: ""
                if (refreshToken.isEmpty()) {
                    // Try alternative key names
                    refreshToken = prefs.getString("refresh", "") ?: ""
                }
                if (refreshToken.isEmpty()) {
                    // Try other common key names for refresh tokens
                    refreshToken = prefs.getString("refreshToken", "") ?: ""
                }
                if (refreshToken.isEmpty()) {
                    // Try with "_" prefix variations
                    refreshToken = prefs.getString("_refresh_token", "") ?: ""
                }
                if (refreshToken.isEmpty()) {
                    Log.e(TAG, "❌ No refresh token available")
                    return@withContext false
                }
                
                val url = URL("$API_BASE_URL/api/refresh/")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // Send refresh token
                val jsonBody = JSONObject().apply {
                    put("refresh", refreshToken)
                }
                connection.outputStream.write(jsonBody.toString().toByteArray())
                
                val responseCode = connection.responseCode
                if (responseCode == 200) {
                    val responseBody = connection.inputStream.bufferedReader().readText()
                    val jsonResponse = JSONObject(responseBody)
                    val newAccessToken = jsonResponse.optString("access", "")
                    
                    if (newAccessToken.isNotEmpty()) {
                        // Save the new access token
                        prefs.edit().putString("auth_token", newAccessToken).apply()
                        Log.d(TAG, "✅ Token refreshed successfully")
                        return@withContext true
                    }
                } else {
                    val errorResponse = try {
                        connection.errorStream?.bufferedReader()?.readText() ?: "No error details"
                    } catch (e: Exception) {
                        "Error reading error response: ${e.message}"
                    }
                    Log.e(TAG, "❌ Token refresh failed with code $responseCode: $errorResponse")
                }
                
                connection.disconnect()
                return@withContext false
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error refreshing auth token: ${e.message}")
                e.printStackTrace()
                return@withContext false
            }
        }
    }
    
    /**
     * Fetch restricted words for a specific child from the API
     */
    private suspend fun fetchRestrictedWordsForChild(childId: String): List<String> {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "🌐 Fetching restricted words for child: $childId")
                
                val url = URL("$API_BASE_URL$RESTRICTED_WORDS_CHILD_ENDPOINT$childId/")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                // Disable caching to ensure fresh data
                connection.setRequestProperty("Cache-Control", "no-cache")
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // Get auth token
                val token = prefs.getString("auth_token", "") ?: ""
                Log.d(TAG, "🔑 Auth token available: ${token.isNotEmpty()}")
                
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                } else {
                    Log.e(TAG, "❌ No auth token available")
                }
                
                // Read response
                val responseCode = connection.responseCode
                val responseBody = if (responseCode == 200) {
                    connection.inputStream.bufferedReader().readText()
                } else {
                    null
                }
                
                connection.disconnect()
                
                if (responseCode == 200 && responseBody != null) {
                    Log.d(TAG, "✅ Received restricted words response for child $childId: $responseBody")
                    
                    // Parse the JSON response to extract words
                    val words = mutableListOf<String>()
                    try {
                        val jsonResponse = JSONObject(responseBody)
                        if (jsonResponse.has("words")) {
                            val wordsArray = jsonResponse.getJSONArray("words")
                            for (i in 0 until wordsArray.length()) {
                                val wordObj = wordsArray.getJSONObject(i)
                                if (wordObj.has("word")) {
                                    words.add(wordObj.getString("word"))
                                }
                            }
                        }
                        
                        // Update the cache with fresh data
                        childRestrictedWords[childId] = words.toList()
                        Log.d(TAG, "📚 Updated cache with ${words.size} restricted words for child $childId")
                        return@withContext words.toList()
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error parsing restricted words response: ${e.message}")
                        return@withContext emptyList()
                    }
                } else {
                    Log.e(TAG, "❌ Failed to fetch restricted words. Response code: $responseCode")
                    Log.e(TAG, "❌ Response body: $responseBody")
                    
                    // If we get a 401, try to refresh the token and retry
                    if (responseCode == 401) {
                        Log.d(TAG, "🔄 Token expired, attempting to refresh...")
                        val refreshResult = refreshAuthToken()
                        if (refreshResult) {
                            Log.d(TAG, "✅ Token refreshed successfully, retrying fetch...")
                            // Retry the request with new token
                            return@withContext fetchRestrictedWordsForChild(childId) // Recursive call with new token
                        } else {
                            Log.e(TAG, "❌ Failed to refresh token")
                        }
                    }
                    
                    // If there was an error, but we have cached data, return cached data as fallback
                    if (childRestrictedWords.containsKey(childId)) {
                        Log.d(TAG, "⚠️ Using cached data as fallback after fetch error")
                        return@withContext childRestrictedWords[childId] ?: emptyList()
                    }
                    
                    return@withContext emptyList()
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error fetching restricted words: ${e.message}")
                e.printStackTrace()
                
                // If there was an exception, but we have cached data, return cached data as fallback
                if (childRestrictedWords.containsKey(childId)) {
                    Log.d(TAG, "⚠️ Using cached data as fallback after exception")
                    return@withContext childRestrictedWords[childId] ?: emptyList()
                }
                
                return@withContext emptyList()
            }
        }
    }
    
    /**
     * Check if text contains child-specific restricted words
     */
    private suspend fun containsChildRestrictedWords(text: String, childId: String): Boolean {
        val lowerText = text.lowercase()
        
        Log.d(TAG, "🔍 Checking child-specific restricted words for child: $childId")
        Log.d(TAG, "🔍 Text to check: $text")
        
        // First, check locally stored words (primary fallback)
        val localRestrictedWords = getLocalRestrictedWordsForChild(childId)
        Log.d(TAG, "🔍 Local restricted words count: ${localRestrictedWords.size}")
        Log.d(TAG, "🔍 Local restricted words: $localRestrictedWords")
        
        var matchedWord: String? = null
        var localMatch = false
        for (word in localRestrictedWords) {
            val wordLower = word.lowercase()
            val match = lowerText.contains(wordLower) ||
                       lowerText.contains(" $wordLower") ||
                       lowerText.contains("$wordLower ") ||
                       lowerText.startsWith(wordLower) ||
                       lowerText.endsWith(wordLower)
            if (match) {
                matchedWord = word
                localMatch = true
                break
            }
        }
        
        if (localMatch) {
            Log.d(TAG, "✅ Local match found for text: $text, matched word: $matchedWord")
            // Delete the matched word from local storage
            if (matchedWord != null) {
                removeRestrictedWordFromLocal(childId, matchedWord)
            }
            return true
        }
        
        // If no local match, try API as secondary option
        Log.d(TAG, "🔍 No local match, trying API...")
        val apiRestrictedWords = fetchRestrictedWordsForChild(childId)
        Log.d(TAG, "🔍 API restricted words count: ${apiRestrictedWords.size}")
        Log.d(TAG, "🔍 API restricted words: $apiRestrictedWords")
        
        matchedWord = null
        var apiMatch = false
        for (word in apiRestrictedWords) {
            val wordLower = word.lowercase()
            val match = lowerText.contains(wordLower) ||
                       lowerText.contains(" $wordLower") ||
                       lowerText.contains("$wordLower ") ||
                       lowerText.startsWith(wordLower) ||
                       lowerText.endsWith(wordLower)
            if (match) {
                matchedWord = word
                apiMatch = true
                break
            }
        }
        
        if (apiMatch) {
            Log.d(TAG, "✅ API match found for text: $text, matched word: $matchedWord")
            // Delete the matched word from API cache
            if (matchedWord != null) {
                removeFromCache(childId, matchedWord)
                deleteWordFromServer(childId, matchedWord)
            }
            return true
        }
        
        Log.d(TAG, "❌ No match found for text: $text")
        return false
    }
    
    private fun getLocalRestrictedWordsForChild(childId: String): List<String> {
        val key = "restricted_words_${childId}"
        val wordsString = prefs.getString(key, "[]") ?: "[]"
        return try {
            // Try to parse as JSON array first
            val wordsList = JSONArray(wordsString)
            val words = mutableListOf<String>()
            for (i in 0 until wordsList.length()) {
                words.add(wordsList.getString(i))
            }
            words
        } catch (e: Exception) {
            // If JSON parsing fails, try to parse as comma-separated values
            try {
                if (wordsString.startsWith("[") && wordsString.endsWith("]")) {
                    // Handle empty array case
                    if (wordsString == "[]") {
                        return emptyList()
                    }
                    Log.e(TAG, "Error parsing as JSON: ${e.message}")
                    emptyList()
                } else {
                    // Handle comma-separated format
                    val words = wordsString.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                    Log.d(TAG, "Parsed comma-separated words: ${words}")
                    words
                }
            } catch (ex: Exception) {
                Log.e(TAG, "Error parsing local restricted words: ${ex.message}")
                emptyList()
            }
        }
    }
    
    private fun removeRestrictedWordFromLocal(childId: String, wordToRemove: String) {
        val key = "restricted_words_${childId}"
        val wordsString = prefs.getString(key, "[]") ?: "[]"
        
        try {
            // Try to parse as JSON array first
            val wordsList = JSONArray(wordsString)
            val words = mutableListOf<String>()
            for (i in 0 until wordsList.length()) {
                words.add(wordsList.getString(i))
            }
            
            // Remove the specified word
            words.remove(wordToRemove)
            
            // Save back to SharedPreferences
            val jsonArray = JSONArray()
            for (word in words) {
                jsonArray.put(word)
            }
            
            val editor = prefs.edit()
            editor.putString(key, jsonArray.toString())
            editor.apply()
            
            Log.d(TAG, "🗑️ Removed word '$wordToRemove' from local storage for child $childId")
        } catch (e: Exception) {
            // If JSON parsing fails, try comma-separated format
            try {
                if (wordsString.startsWith("[") && wordsString.endsWith("]")) {
                    if (wordsString == "[]") {
                        Log.d(TAG, "No words to remove for child $childId")
                        return
                    }
                } else {
                    // Handle comma-separated format
                    var words = wordsString.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                    words = words.filter { it != wordToRemove }
                    
                    val updatedString = words.joinToString(",")
                    val editor = prefs.edit()
                    editor.putString(key, updatedString)
                    editor.apply()
                    
                    Log.d(TAG, "🗑️ Removed word '$wordToRemove' from local storage for child $childId")
                }
            } catch (ex: Exception) {
                Log.e(TAG, "Error removing word from local storage: ${ex.message}")
            }
        }
    }
    
    private fun removeFromCache(childId: String, wordToRemove: String) {
        if (childRestrictedWords.containsKey(childId)) {
            val words = childRestrictedWords[childId]?.toMutableList() ?: mutableListOf()
            words.remove(wordToRemove)
            childRestrictedWords[childId] = words.toList()
            
            Log.d(TAG, "🗑️ Removed word '$wordToRemove' from cache for child $childId")
        }
    }
    
    private suspend fun deleteWordFromServer(childId: String, wordToDelete: String) {
        return withContext(Dispatchers.IO) {
            try {
                Log.d(TAG, "🗑️ Attempting to delete word '$wordToDelete' from server for child $childId")
                
                val url = URL("$API_BASE_URL/api/v1/restricted-words/delete/")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "DELETE"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // Get auth token
                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }
                
                // Send request
                val jsonBody = JSONObject().apply {
                    put("child_id", if (childId.isNotEmpty()) childId.toInt() else 0)
                    put("word", wordToDelete)
                }
                connection.outputStream.write(jsonBody.toString().toByteArray())
                
                val responseCode = connection.responseCode
                val responseBody = if (responseCode == 200 || responseCode == 204) {
                    connection.inputStream.bufferedReader().readText()
                } else {
                    null
                }
                
                Log.d(TAG, "🗑️ Delete word response: $responseCode - $responseBody")
                
                connection.disconnect()
                
                if (responseCode == 200 || responseCode == 204) {
                    Log.d(TAG, "✅ Successfully deleted word '$wordToDelete' from server")
                } else {
                    Log.e(TAG, "❌ Failed to delete word from server. Response code: $responseCode")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error deleting word from server: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    private fun clearEditText(event: AccessibilityEvent) {
        try {
            val sourceNode = event.source
            if (sourceNode != null) {
                // Attempt to find the EditText node
                val editTextNodes = mutableListOf<AccessibilityNodeInfo>()
                findEditTextNodes(sourceNode, editTextNodes)
                
                if (editTextNodes.isNotEmpty()) {
                    for (node in editTextNodes) {
                        // Clear the text by setting it to empty
                        val arguments = Bundle()
                        arguments.putCharSequence(
                            AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                            ""
                        )
                        node.performAction(
                            AccessibilityNodeInfo.ACTION_SET_TEXT,
                            arguments
                        )
                        Log.d(TAG, "🧹 Cleared text from EditText")
                    }
                } else {
                    Log.d(TAG, "🧹 No EditText nodes found to clear")
                }
            } else {
                Log.d(TAG, "🧹 No source node available to clear")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error clearing EditText: ${e.message}")
        }
    }
    
    private fun findEditTextNodes(
        node: AccessibilityNodeInfo,
        result: MutableList<AccessibilityNodeInfo>
    ) {
        // Check if current node is an EditText
        if (node.className?.contains("EditText", ignoreCase = true) == true) {
            result.add(node)
        }
        
        // Recursively check children
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findEditTextNodes(child, result)
            }
        }
    }
    
    private fun showBlockedAlert() {
        try {
            Toast.makeText(
                this,
                "⛔ تم اكتشاف محتوى غير لائق",
                Toast.LENGTH_LONG
            ).show()
        } catch (e: Exception) {
            Log.e(TAG, "Error showing toast: ${e.message}")
        }
    }
    
    private fun sendAlertToParent(text: String, source: String) {
        scope.launch {
            try {
                val parentId = prefs.getString("parent_id", "") ?: ""
                val childId = prefs.getString("child_id", "") ?: ""
                val childName = prefs.getString("child_name", "الطفل") ?: "الطفل"
                
                if (parentId.isEmpty() || childId.isEmpty()) {
                    Log.w(TAG, "⚠️ No parent ID or child ID found, skipping notification")
                    return@launch
                }
                
                Log.d(TAG, "📤 Sending alert to parent: $parentId for child: $childId")
                
                val url = URL("$API_BASE_URL$NOTIFICATIONS_ENDPOINT")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }
                
                val description = if (source == "local") {
                    "الطفل $childName حاول كتابة كلمة محظورة: $text"
                } else {
                    "الطفل $childName حاول كتابة محتوى غير لائق (AI): $text"
                }
                
                // Construct JSON body according to backend specification
                val jsonBody = JSONObject().apply {
                    put("child_id", childId.toInt())
                    put("parent", parentId.toInt())
                    put("title", "تنبيه قيود الكتابة")
                    put("description", description)
                    put("category", "system")
                }
                
                connection.outputStream.write(jsonBody.toString().toByteArray())
                
                val responseCode = connection.responseCode
                val responseMessage = try {
                    connection.inputStream?.bufferedReader()?.readText() ?: "No response details"
                } catch (e: Exception) {
                    "Error reading response: ${e.message}"
                }
                
                Log.d(TAG, "📬 Notification sent, response: $responseCode - $responseMessage")
                
                // Handle 401 and 405 specifically for notifications
                if (responseCode == 401 || responseCode == 405) {
                    Log.e(TAG, "🔒 Notification API failed. Response code: $responseCode. Token may be invalid or expired, or endpoint not found.")
                    Log.d(TAG, "🔄 Attempting to refresh token and retry notification")
                    val refreshResult = refreshAuthToken()
                    
                    if (refreshResult) {
                        Log.d(TAG, "✅ Token refreshed successfully, retrying notification...")
                        // Retry sending the notification with new token
                        sendAlertToParentRetry(text, source, parentId, childId, childName)
                    } else {
                        Log.e(TAG, "❌ Failed to refresh token for notification")
                        // Even if refresh fails, try to handle locally
                        handleLocalNotificationFallback(text, source, childName)
                    }
                }
                
                connection.disconnect()
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending alert: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    private fun handleLocalNotificationFallback(text: String, source: String, childName: String) {
        // Handle notification locally when API fails
        scope.launch(Dispatchers.Main) {
            showBlockedAlert()
            Log.d(TAG, "🔔 Local notification fallback triggered for: $childName - $text")
        }
    }
    
    private fun sendAlertToParentRetry(text: String, source: String, parentId: String, childId: String, childName: String) {
        scope.launch {
            try {
                Log.d(TAG, "📤 Retrying to send alert to parent: $parentId for child: $childId")
                
                val url = URL("$API_BASE_URL$NOTIFICATIONS_ENDPOINT")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Accept", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                
                // Use the newly refreshed token
                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) {
                    connection.setRequestProperty("Authorization", "Bearer $token")
                }
                
                val description = if (source == "local") {
                    "الطفل $childName حاول كتابة كلمة محظورة: $text"
                } else {
                    "الطفل $childName حاول كتابة محتوى غير لائق (AI): $text"
                }
                
                // Construct JSON body according to backend specification
                val jsonBody = JSONObject().apply {
                    put("child_id", childId.toInt())
                    put("parent", parentId.toInt())
                    put("title", "تنبيه قيود الكتابة")
                    put("description", description)
                    put("category", "system")
                }
                
                connection.outputStream.write(jsonBody.toString().toByteArray())
                
                val responseCode = connection.responseCode
                val responseMessage = try {
                    connection.inputStream?.bufferedReader()?.readText() ?: "No response details"
                } catch (e: Exception) {
                    "Error reading response: ${e.message}"
                }
                
                Log.d(TAG, "📬 Retried notification, response: $responseCode - $responseMessage")
                
                connection.disconnect()
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error retrying to send alert: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Save parent's special password for this child device
     */
    fun setPasswordForChild(password: String) {
        val editor = prefs.edit()
        editor.putString("protection_password", password)
        editor.apply()
        Log.d(TAG, "✅ Protection password saved for child")
    }
    
    /**
     * Save child information and start location monitoring
     */
    fun saveChildInfo(childId: String, parentId: String, childName: String, password: String) {
        val editor = prefs.edit()
        editor.putString("child_id", childId)
        editor.putString("parent_id", parentId)
        editor.putString("child_name", childName)
        editor.putString("protection_password", password)
        editor.apply()
        
        Log.d(TAG, "✅ Child info saved: ID=$childId, Name=$childName, Parent=$parentId")
        
        // Start location monitoring service
        startLocationMonitoringService()
    }
    
    private fun startLocationMonitoringService() {
        try {
            val intent = Intent(this, Class.forName("com.shaimaa.safechild.LocationMonitorService"))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.d(TAG, "✅ Location monitoring service started")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting location monitoring service: ${e.message}")
        }
    }
    
    /**
     * Verify if the entered password matches the parent's special password
     */
    fun verifyPassword(enteredPassword: String): Boolean {
        val storedPassword = prefs.getString("protection_password", "")
        return storedPassword != null && storedPassword == enteredPassword
    }
    
    /**
     * Enable/disable writing restrictions with password protection
     */
    fun setWritingRestrictionsEnabled(enabled: Boolean, password: String? = null): Boolean {
        if (!enabled) {
            // If trying to disable, verify the password
            if (password == null || !verifyPassword(password)) {
                Log.d(TAG, "❌ Incorrect password. Cannot disable writing restrictions.")
                return false
            }
            Log.d(TAG, "✅ Password verified. Disabling writing restrictions.")
        }
        
        val editor = prefs.edit()
        editor.putBoolean("writing_restrictions_enabled", enabled)
        editor.apply()
        Log.d(TAG, "✅ Writing restrictions ${if (enabled) "enabled" else "disabled"}")
        return true
    }
    
    /**
     * Check if writing restrictions are currently enabled
     */
    fun isWritingRestrictionsEnabled(): Boolean {
        return prefs.getBoolean("writing_restrictions_enabled", false)
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        Log.d(TAG, "Service destroyed")
    }
}
