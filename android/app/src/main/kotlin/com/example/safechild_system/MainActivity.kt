//package com.example.safechild_system

//import io.flutter.embedding.android.FlutterActivity

//class MainActivity : FlutterActivity()
// android/app/src/main/kotlin/com/example/safechild_system/MainActivity.kt
package com.example.safechild_system

import android.content.Intent
import android.provider.Settings
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  private val CHANNEL = "safechild/native"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "requestUsageAccess" -> {
          val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          startActivity(intent)
          result.success(null)
        }
        "startMonitoring" -> {
          val svc = Intent(this, AppMonitorService::class.java)
          startService(svc)
          result.success(null)
        }
        "stopMonitoring" -> {
          val svc = Intent(this, AppMonitorService::class.java)
          stopService(svc)
          result.success(null)
        }
        "setLimit" -> {
          val pkg = call.argument<String>("package") ?: ""
          val num = call.argument<Number>("millis")
          val millis = num?.toLong() ?: 0L
          AppMonitorService.setLimitForPackage(pkg, millis)
          result.success(null)
        }
        "clearLimit" -> {
          val pkg = call.argument<String>("package") ?: ""
          AppMonitorService.clearLimitForPackage(pkg)
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }
}

