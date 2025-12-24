package com.shaimaa.safechild

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import android.content.SharedPreferences
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
        private const val API_BASE_URL = "http://10.0.2.2:8000"
        private const val WRITING_CHECK_ENDPOINT = "/api/v1/writing-check/"
        private const val NOTIFICATIONS_ENDPOINT = "/api/notifications/"
        private const val RESTRICTED_WORDS_CHILD_ENDPOINT = "/api/v1/restricted-words/child/"
    }

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var lastCheckedText = ""
    private var lastCheckTime = 0L
    private lateinit var prefs: SharedPreferences

    // Local bad words for quick check
    private val badWords = listOf(
        "fuck", "shit", "porn", "sex", "xxx", "bitch", "ass", "dick", "pussy",
        "قذر", "اباحي", "جنس", "لعنة", "مثلي", "شاذ", "عاهرة",
        "زنا", "سافل", "حقير", "كلب", "حمار", "غبي", "احمق",
        "خنزير", "فاسق", "منحرف", "لوطي", "زاني", "شرموط",
        "عرص", "متخلف", "وسخ", "قحبة", "ديوث", "اهبل", "سخيف",
        "حمق", "اوبس", "섹스", "포르노"
    )

    // Child-specific restricted words cache
    private var childRestrictedWords = mutableMapOf<String, List<String>>()

    override fun onServiceConnected() {
        super.onServiceConnected()

        // Initialize encrypted shared preferences
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
            Log.d(TAG, "✅ EncryptedSharedPreferences initialized")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing encrypted preferences: ${e.message}")
            prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        }

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
        Log.d(TAG, "✅ TextMonitorService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return

        val isEnabled = prefs.getBoolean("writing_restrictions_enabled", false)
        if (!isEnabled) return

        if (event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            val text = event.text?.joinToString("") ?: return
            if (text.isEmpty() || text == lastCheckedText) return

            val currentTime = System.currentTimeMillis()
            if (currentTime - lastCheckTime < 500) return
            lastCheckTime = currentTime
            lastCheckedText = text

            Log.d(TAG, "📝 Text detected: $text")

            scope.launch {
                if (containsBadWords(text)) {
                    withContext(Dispatchers.Main) {
                        clearEditText(event)
                        showBlockedAlert()
                        sendAlertToParent(text, "local")
                    }
                }
            }

            if (text.length >= 3) {
                checkWithAI(text, event)
            }
        }
    }

    private fun containsBadWordsLocal(text: String): Boolean {
        val lowerText = text.lowercase()
        return badWords.any { word ->
            val w = word.lowercase()
            lowerText.contains(w) || lowerText.contains(" $w") || lowerText.contains("$w ") ||
            lowerText.startsWith(w) || lowerText.endsWith(w)
        }
    }

    private suspend fun containsBadWords(text: String): Boolean {
        if (containsBadWordsLocal(text)) return true

        val childId = prefs.getString("child_id", "") ?: ""
        if (childId.isNotEmpty()) {
            val apiMatch = containsChildRestrictedWords(text, childId)
            if (apiMatch) return true

            val localRestrictedWords = getLocalRestrictedWordsForChild(childId)
            val lowerText = text.lowercase()
            return localRestrictedWords.any { word ->
                val w = word.lowercase()
                lowerText.contains(w) || lowerText.contains(" $w") || lowerText.contains("$w ") ||
                lowerText.startsWith(w) || lowerText.endsWith(w)
            }
        }

        return false
    }

    private fun clearEditText(event: AccessibilityEvent) {
        try {
            val sourceNode = event.source ?: return
            val editTextNodes = mutableListOf<AccessibilityNodeInfo>()
            findEditTextNodes(sourceNode, editTextNodes)

            for (node in editTextNodes) {
                val args = Bundle()
                args.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, "")
                node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
                Log.d(TAG, "🧹 Cleared text")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error clearing text: ${e.message}")
        }
    }

    private fun findEditTextNodes(node: AccessibilityNodeInfo, result: MutableList<AccessibilityNodeInfo>) {
        if (node.className?.contains("EditText", ignoreCase = true) == true) {
            result.add(node)
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { findEditTextNodes(it, result) }
        }
    }

    private fun showBlockedAlert() {
        try {
            Toast.makeText(this, "⛔ تم اكتشاف محتوى غير لائق", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Log.e(TAG, "Error showing toast: ${e.message}")
        }
    }

    private fun getLocalRestrictedWordsForChild(childId: String): List<String> {
        val key = "restricted_words_parent_$childId"
        val wordsString = prefs.getString(key, "[]") ?: "[]"
        return try {
            val arr = JSONArray(wordsString)
            List(arr.length()) { arr.getString(it) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private suspend fun containsChildRestrictedWords(text: String, childId: String): Boolean {
        val lowerText = text.lowercase()

        val localWords = getLocalRestrictedWordsForChild(childId)
        if (localWords.any { lowerText.contains(it.lowercase()) }) return true

        val apiWords = fetchRestrictedWordsForChild(childId)
        return apiWords.any { lowerText.contains(it.lowercase()) }
    }

    private suspend fun fetchRestrictedWordsForChild(childId: String): List<String> {
        if (childRestrictedWords.containsKey(childId)) return childRestrictedWords[childId] ?: emptyList()

        try {
            val url = URL("$API_BASE_URL$RESTRICTED_WORDS_CHILD_ENDPOINT$childId/")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            val token = prefs.getString("auth_token", "") ?: ""
            if (token.isNotEmpty()) connection.setRequestProperty("Authorization", "Bearer $token")
            connection.connectTimeout = 5000
            connection.readTimeout = 5000

            val responseCode = connection.responseCode
            val responseBody = if (responseCode == 200) connection.inputStream.bufferedReader().readText() else null
            connection.disconnect()

            if (responseCode == 200 && responseBody != null) {
                val words = mutableListOf<String>()
                val json = JSONObject(responseBody)
                if (json.has("words")) {
                    val arr = json.getJSONArray("words")
                    for (i in 0 until arr.length()) words.add(arr.getJSONObject(i).getString("word"))
                }
                childRestrictedWords[childId] = words
                return words
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error fetching restricted words: ${e.message}")
        }

        return emptyList()
    }

    private fun sendAlertToParent(text: String, source: String) {
        scope.launch {
            val parentId = prefs.getString("parent_id", "") ?: ""
            val childName = prefs.getString("child_name", "الطفل") ?: "الطفل"
            if (parentId.isEmpty()) return@launch

            try {
                val url = URL("$API_BASE_URL$NOTIFICATIONS_ENDPOINT")
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.setRequestProperty("Accept", "application/json")
                val token = prefs.getString("auth_token", "") ?: ""
                if (token.isNotEmpty()) conn.setRequestProperty("Authorization", "Bearer $token")
                conn.doOutput = true

                val description = if (source == "local") {
                    "الطفل $childName حاول كتابة كلمة محظورة: $text"
                } else {
                    "الطفل $childName حاول كتابة محتوى غير لائق (AI): $text"
                }

                val body = JSONObject().apply {
                    put("title", "تنبيه قيود الكتابة")
                    put("description", description)
                    put("category", "system")
                    try { put("parent", parentId.toInt()) } catch (e: Exception) { put("parent", parentId) }
                }

                conn.outputStream.write(body.toString().toByteArray())
                conn.responseCode // Trigger request
                conn.disconnect()
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending alert: ${e.message}")
            }
        }
    }

    private fun checkWithAI(text: String, event: AccessibilityEvent) {
    scope.launch {
        try {
            val url = URL("$API_BASE_URL$WRITING_CHECK_ENDPOINT")
            val conn = url.openConnection() as HttpURLConnection

            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Accept", "application/json")

            val token = prefs.getString("auth_token", "") ?: ""
            if (token.isNotEmpty()) {
                conn.setRequestProperty("Authorization", "Bearer $token")
            }

            conn.doOutput = true
            conn.connectTimeout = 5000
            conn.readTimeout = 5000

            val body = JSONObject().apply {
                put("text", text)
            }

            conn.outputStream.use {
                it.write(body.toString().toByteArray())
            }

            val responseCode = conn.responseCode
            val response = if (responseCode == 200) {
                conn.inputStream.bufferedReader().readText()
            } else {
                null
            }

            conn.disconnect()

            if (response != null) {
                val json = JSONObject(response)
                val isAllowed = json.optBoolean("is_allowed", true)
                val isToxic = json.optBoolean("is_toxic", false)

                Log.d(TAG, "📊 AI result → is_allowed=$isAllowed , is_toxic=$isToxic")

                if (!isAllowed || isToxic) {
                    withContext(Dispatchers.Main) {
                        clearEditText(event)
                        showBlockedAlert()
                        sendAlertToParent(text, "ai")
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ AI check error: ${e.message}")
        }
    }
}


    override fun onInterrupt() { Log.d(TAG, "Service interrupted") }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        Log.d(TAG, "Service destroyed")
    }

    // AI check remains unchanged (يمكنك إعادة إضافة الكود السابق لـ checkWithAI هنا)
}
