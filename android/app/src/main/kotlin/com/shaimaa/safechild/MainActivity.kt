//package com.shaimaa.safechild
//
//import android.content.Intent
//import android.net.Uri
//import android.os.Build
//import android.os.Bundle
//import android.provider.Settings
//import android.content.SharedPreferences
//import androidx.security.crypto.EncryptedSharedPreferences
//import androidx.security.crypto.MasterKey
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import android.util.Log
//
//class MainActivity : FlutterActivity() {
//    companion object {
//        private const val TAG_POLICY = "POLICY_NATIVE"
//    }
//
//
//    private val CHANNEL = "safechild/native"
//    private val TEXT_MONITOR_CHANNEL = "com.shaimaa.safechild/text_monitor"
//    private lateinit var prefs: SharedPreferences
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        // ✅ Encrypted prefs (كما عندك)
//        prefs = try {
//            val masterKey = MasterKey.Builder(this, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
//                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
//                .build()
//
//            EncryptedSharedPreferences.create(
//                this,
//                "safechild_prefs",
//                masterKey,
//                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
//                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
//            )
//        } catch (e: Exception) {
//            getSharedPreferences("safechild_prefs", MODE_PRIVATE)
//        }
//
//        // ✅ Channel الأساسي للحظر + الصلاحيات
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//            try {
//                when (call.method) {
//
//                    /**
//                     * Flutter: setLimit({'package': pkg, 'ms': ms}) أو 'millis'
//                     */
//                    "setLimit" -> {
//                        val pkg = call.argument<String>("package")
//                        Log.d(TAG_POLICY, "Flutter->setLimit pkg=$pkg ms=$ms")
//
//                        val msAny = call.argument<Any>("ms")
//                            ?: call.argument<Any>("millis")
//                            ?: call.argument<Any>("limit_ms")
//
//                        val ms: Long = when (msAny) {
//                            is Int -> msAny.toLong()
//                            is Long -> msAny
//                            is String -> msAny.toLongOrNull() ?: 0L
//                            else -> 0L
//                        }
//
//                        if (!pkg.isNullOrEmpty() && ms > 0) {
//                            val intent = Intent(this, AppBlockerService::class.java).apply {
//                                putExtra("action", "set_limit")
//                                putExtra("package", pkg)
//                                putExtra("limit_ms", ms)
//                            }
//                            startAppBlockerService(intent)
//                            result.success(true)
//                        } else {
//                            result.error("INVALID_ARG", "Package or limit missing", null)
//                        }
//                    }
//
//                    /**
//                     * Flutter: clearLimit({'package': pkg})
//                     */
//                    "clearLimit" -> {
//                        val pkg = call.argument<String>("package")
//                        if (!pkg.isNullOrEmpty()) {
//                            Log.d(TAG_POLICY, "Flutter->clearAllLimits")
//
//                            val intent = Intent(this, AppBlockerService::class.java).apply {
//                                putExtra("action", "clear_limit")
//                                putExtra("package", pkg)
//                            }
//                            startAppBlockerService(intent)
//                            result.success(true)
//                        } else {
//                            result.error("INVALID_ARG", "Package missing", null)
//                        }
//                    }
//
//                    /**
//                     * Flutter: clearAllLimits()
//                     */
//                    "clearAllLimits" -> {
//                        val intent = Intent(this, AppBlockerService::class.java).apply {
//                            putExtra("action", "clear_all")
//                        }
//                        startAppBlockerService(intent)
//                        result.success(true)
//                    }
//
//                    /**
//                     * Flutter: getLimit({'package': pkg})
//                     * ✅ يقرأ من نفس prefs الخاصة بالـ AppBlockerService
//                     */
//                    "getLimit" -> {
//                        val pkg = call.argument<String>("package") ?: ""
//                        if (pkg.isEmpty()) {
//                            result.success(null)
//                            return@setMethodCallHandler
//                        }
//
//                        val blockerPrefs = getSharedPreferences("safechild_blocker_prefs", MODE_PRIVATE)
//                        val key = "limit_$pkg"
//
//                        if (!blockerPrefs.contains(key)) {
//                            result.success(null)
//                        } else {
//                            val limitMs = blockerPrefs.getLong(key, 0L)
//                            // رجّع int (Flutter يحب int)
//                            result.success(limitMs.toInt())
//                        }
//                    }
//
//                    /**
//                     * Flutter: startMonitoring()
//                     */
//                    "startMonitoring" -> {
//                        val intent = Intent(this, AppBlockerService::class.java).apply {
//                            Log.d(TAG_POLICY, "Flutter->startMonitoring")
//
//                            putExtra("action", "start")
//                        }
//                        startAppBlockerService(intent)
//                        result.success(true)
//                    }
//
//                    /**
//                     * Flutter: stopMonitoring()
//                     */
//                    "stopMonitoring" -> {
//                        val intent = Intent(this, AppBlockerService::class.java).apply {
//                            putExtra("action", "stop")
//                        }
//                        startAppBlockerService(intent)
//                        result.success(true)
//                    }
//
//                    /**
//                     * Flutter: openUsageAccessSettings() (اسم جديد)
//                     * Flutter: requestUsageAccess() (اسم قديم)
//                     */
//                    "openUsageAccessSettings", "requestUsageAccess" -> {
//                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
//                        result.success(true)
//                    }
//
//                    /**
//                     * Flutter: openAccessibilitySettings()
//                     */
//                    "openAccessibilitySettings" -> {
//                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
//                        result.success(true)
//                    }
//
//                    /**
//                     * Flutter: openOverlaySettings()
//                     */
//                    "openOverlaySettings" -> {
//                        openOverlaySettings()
//                        result.success(true)
//                    }
//
//                    else -> result.notImplemented()
//                }
//            } catch (e: Exception) {
//                result.error("NATIVE_ERROR", e.message ?: "Unknown native error", null)
//            }
//        }
//
//        // ✅ Text Monitor channel (كما عندك) - بدون تغيير
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXT_MONITOR_CHANNEL).setMethodCallHandler { call, result ->
//            when (call.method) {
//                "openAccessibilitySettings" -> {
//                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
//                    startActivity(intent)
//                    result.success(true)
//                }
//                "isTextMonitorEnabled" -> {
//                    val enabled = isTextMonitorServiceEnabled()
//                    result.success(enabled)
//                }
//                "setWritingRestrictionsEnabled" -> {
//                    val enabled = call.argument<Boolean>("enabled") ?: false
//                    prefs.edit().putBoolean("writing_restrictions_enabled", enabled).apply()
//                    result.success(true)
//                }
//                "isWritingRestrictionsEnabled" -> {
//                    val enabled = prefs.getBoolean("writing_restrictions_enabled", false)
//                    result.success(enabled)
//                }
//                "saveChildInfo" -> {
//                    val parentId = call.argument<String>("parentId") ?: ""
//                    val childName = call.argument<String>("childName") ?: ""
//                    val childId = call.argument<String>("childId") ?: ""
//                    val token = call.argument<String>("token") ?: ""
//                    val refreshToken = call.argument<String>("refreshToken") ?: ""
//
//                    prefs.edit().apply {
//                        putString("parent_id", parentId)
//                        putString("child_name", childName)
//                        putString("child_id", childId)
//                        putString("auth_token", token)
//                        if (refreshToken.isNotEmpty()) putString("refresh_token", refreshToken)
//                        apply()
//                    }
//                    result.success(true)
//                }
//                "getChildInfo" -> {
//                    val info = mapOf(
//                        "parentId" to (prefs.getString("parent_id", "") ?: ""),
//                        "childName" to (prefs.getString("child_name", "") ?: ""),
//                        "childId" to (prefs.getString("child_id", "") ?: ""),
//                        "token" to (prefs.getString("auth_token", "") ?: "")
//                    )
//                    result.success(info)
//                }
//                "clearChildInfo" -> {
//                    prefs.edit().apply {
//                        remove("parent_id")
//                        remove("child_name")
//                        remove("child_id")
//                        remove("auth_token")
//                        remove("writing_restrictions_enabled")
//                        apply()
//                    }
//                    result.success(true)
//                }
//                else -> result.notImplemented()
//            }
//        }
//    }
//
//    private fun startAppBlockerService(intent: Intent) {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            startForegroundService(intent)
//        } else {
//            startService(intent)
//        }
//    }
//
//    private fun openOverlaySettings() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
//            val uri = Uri.parse("package:$packageName")
//            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, uri)
//            startActivity(intent)
//        }
//    }
//
//    private fun isTextMonitorServiceEnabled(): Boolean {
//        val service = "$packageName/.TextMonitorService"
//        val enabledServices = Settings.Secure.getString(
//            contentResolver,
//            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
//        ) ?: return false
//        return enabledServices.contains(service) || enabledServices.contains("TextMonitorService")
//    }
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//    }
//}

package com.shaimaa.safechild

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG_POLICY = "POLICY_NATIVE"
    }

    private val CHANNEL = "safechild/native"
    private val TEXT_MONITOR_CHANNEL = "com.shaimaa.safechild/text_monitor"
    private lateinit var prefs: SharedPreferences

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Encrypted prefs (كما عندك)
        prefs = try {
            val masterKey = MasterKey.Builder(this, MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                this,
                "safechild_prefs",
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            getSharedPreferences("safechild_prefs", MODE_PRIVATE)
        }

        // ✅ Channel الأساسي
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {

                        "setLimit" -> {
                            val pkg = call.argument<String>("package")

                            val msAny = call.argument<Any>("ms")
                                ?: call.argument<Any>("millis")
                                ?: call.argument<Any>("limit_ms")

                            val ms: Long = when (msAny) {
                                is Int -> msAny.toLong()
                                is Long -> msAny
                                is String -> msAny.toLongOrNull() ?: 0L
                                else -> 0L
                            }

                            // ✅ الـ Log بعد تعريف ms (هذا هو الإصلاح)
                            Log.d(TAG_POLICY, "Flutter->setLimit pkg=$pkg ms=$ms")

                            if (!pkg.isNullOrEmpty() && ms > 0) {
                                val intent = Intent(this, AppBlockerService::class.java).apply {
                                    putExtra("action", "set_limit")
                                    putExtra("package", pkg)
                                    putExtra("limit_ms", ms)
                                }
                                startAppBlockerService(intent)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARG", "Package or limit missing", null)
                            }
                        }

                        "clearLimit" -> {
                            val pkg = call.argument<String>("package")
                            if (!pkg.isNullOrEmpty()) {
                                Log.d(TAG_POLICY, "Flutter->clearLimit pkg=$pkg")

                                val intent = Intent(this, AppBlockerService::class.java).apply {
                                    putExtra("action", "clear_limit")
                                    putExtra("package", pkg)
                                }
                                startAppBlockerService(intent)
                                result.success(true)
                            } else {
                                result.error("INVALID_ARG", "Package missing", null)
                            }
                        }

                        "clearAllLimits" -> {
                            val intent = Intent(this, AppBlockerService::class.java).apply {
                                putExtra("action", "clear_all")
                            }
                            startAppBlockerService(intent)
                            result.success(true)
                        }

                        "getLimit" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            if (pkg.isEmpty()) {
                                result.success(null)
                                return@setMethodCallHandler
                            }

                            val blockerPrefs =
                                getSharedPreferences("safechild_blocker_prefs", MODE_PRIVATE)
                            val key = "limit_$pkg"

                            if (!blockerPrefs.contains(key)) {
                                result.success(null)
                            } else {
                                result.success(blockerPrefs.getLong(key, 0L).toInt())
                            }
                        }

                        "startMonitoring" -> {
                            val intent = Intent(this, AppBlockerService::class.java).apply {
                                putExtra("action", "start")
                            }
                            startAppBlockerService(intent)
                            result.success(true)
                        }

                        "stopMonitoring" -> {
                            val intent = Intent(this, AppBlockerService::class.java).apply {
                                putExtra("action", "stop")
                            }
                            startAppBlockerService(intent)
                            result.success(true)
                        }

                        "openUsageAccessSettings", "requestUsageAccess" -> {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(true)
                        }

                        "openAccessibilitySettings" -> {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                            result.success(true)
                        }

                        "openOverlaySettings" -> {
                            openOverlaySettings()
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", e.message ?: "Unknown native error", null)
                }
            }

        // ✅ Text monitor channel (بدون تغيير)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TEXT_MONITOR_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }

                "isTextMonitorEnabled" -> {
                    result.success(isTextMonitorServiceEnabled())
                }

                "setWritingRestrictionsEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    prefs.edit().putBoolean("writing_restrictions_enabled", enabled).apply()
                    result.success(true)
                }

                "isWritingRestrictionsEnabled" -> {
                    result.success(
                        prefs.getBoolean("writing_restrictions_enabled", false)
                    )
                }

                "saveChildInfo" -> {
                    prefs.edit().apply {
                        putString("parent_id", call.argument("parentId"))
                        putString("child_name", call.argument("childName"))
                        putString("child_id", call.argument("childId"))
                        putString("auth_token", call.argument("token"))
                        call.argument<String>("refreshToken")?.let {
                            putString("refresh_token", it)
                        }
                        apply()
                    }
                    result.success(true)
                }

                "getChildInfo" -> {
                    result.success(
                        mapOf(
                            "parentId" to prefs.getString("parent_id", ""),
                            "childName" to prefs.getString("child_name", ""),
                            "childId" to prefs.getString("child_id", ""),
                            "token" to prefs.getString("auth_token", "")
                        )
                    )
                }

                "clearChildInfo" -> {
                    prefs.edit().clear().apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startAppBlockerService(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun openOverlaySettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val uri = Uri.parse("package:$packageName")
            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, uri))
        }
    }

    private fun isTextMonitorServiceEnabled(): Boolean {
        val service = "$packageName/.TextMonitorService"
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.contains(service) || enabled.contains("TextMonitorService")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
