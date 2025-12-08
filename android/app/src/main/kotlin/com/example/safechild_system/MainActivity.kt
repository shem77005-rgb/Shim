package com.example.safechild_system

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {
    private val CHANNEL = "safechild/native"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        io.flutter.plugin.common.MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    startActivity(Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // No hardcoded limits anymore. Waiting for Flutter to set them.
    }
}