package com.shaimaa.safechild

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "safechild/native"
    private val TEXT_MONITOR_CHANNEL = "com.shaimaa.safechild/text_monitor"
    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize encrypted shared preferences for secure token storage
        try {
            val masterKey = MasterKey.Builder(this, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            
            prefs = EncryptedSharedPreferences.create(
                this,
                "safechild_prefs",
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback to regular shared preferences if encrypted preferences fail
            prefs = getSharedPreferences("safechild_prefs", MODE_PRIVATE)
        }
        
        // Original native channel for app blocking
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLimit" -> {
                    val pkg = call.argument<String>("package")
                    val ms = call.argument<Int>("ms")?.toLong() ?: 0L
                    
                    if (pkg != null && ms > 0) {
                        val intent = Intent(this, AppBlockerService::class.java)
                        intent.putExtra(pkg, ms)
                        startService(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARG", "Package or limit missing", null)
                    }
                }
                "openUsageAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Text Monitor channel for writing restrictions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXT_MONITOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "isTextMonitorEnabled" -> {
                    val enabled = isTextMonitorServiceEnabled()
                    result.success(enabled)
                }
                "setWritingRestrictionsEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    prefs.edit().putBoolean("writing_restrictions_enabled", enabled).apply()
                    result.success(true)
                }
                "isWritingRestrictionsEnabled" -> {
                    val enabled = prefs.getBoolean("writing_restrictions_enabled", false)
                    result.success(enabled)
                }
                "saveChildInfo" -> {
                    val parentId = call.argument<String>("parentId") ?: ""
                    val childName = call.argument<String>("childName") ?: ""
                    val childId = call.argument<String>("childId") ?: ""
                    val token = call.argument<String>("token") ?: ""
                    val refreshToken = call.argument<String>("refreshToken") ?: ""
                    
                    prefs.edit().apply {
                        putString("parent_id", parentId)
                        putString("child_name", childName)
                        putString("child_id", childId)
                        putString("auth_token", token)
                        if (refreshToken.isNotEmpty()) {
                            putString("refresh_token", refreshToken)
                        }
                        apply()
                    }
                    result.success(true)
                }
                "getChildInfo" -> {
                    val info = mapOf(
                        "parentId" to (prefs.getString("parent_id", "") ?: ""),
                        "childName" to (prefs.getString("child_name", "") ?: ""),
                        "childId" to (prefs.getString("child_id", "") ?: ""),
                        "token" to (prefs.getString("auth_token", "") ?: "")
                    )
                    result.success(info)
                }
                "clearChildInfo" -> {
                    prefs.edit().apply {
                        remove("parent_id")
                        remove("child_name")
                        remove("child_id")
                        remove("auth_token")
                        remove("writing_restrictions_enabled")
                        apply()
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun isTextMonitorServiceEnabled(): Boolean {
        val service = "$packageName/.TextMonitorService"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains(service) || enabledServices.contains("TextMonitorService")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
