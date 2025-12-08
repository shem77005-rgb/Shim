package com.example.safechild_system

import android.app.Service
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager

class AppBlockerService : Service() {

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var currentPackage: String? = null
    private val handler = Handler()

    // سيتم ملؤها من MainActivity عند بدء الخدمة
    private val monitoredApps = mutableMapOf<String, Long>()
    private val appUsage = mutableMapOf<String, Long>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // قراءة حدود الوقت من MainActivity
        intent?.extras?.keySet()?.forEach { key ->
            val limit = intent.getLongExtra(key, 0L)
            if (limit > 0) {
                monitoredApps[key] = limit
            }
        }
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startMonitoring()
    }

    private fun startMonitoring() {
        handler.post(object : Runnable {
            override fun run() {
                val foregroundApp = getForegroundApp()

                // إزالة الـ Overlay إذا انتقل المستخدم لتطبيق آخر
                if (overlayView != null && foregroundApp != currentPackage) {
                    removeOverlay()
                }

                foregroundApp?.let { pkg ->
                    // 🔥 STRICT SAFETY: Never block our own app
                    if (pkg == packageName) return@let

                    if (monitoredApps.containsKey(pkg)) {
                        val limit = monitoredApps[pkg]!!
                        val used = (appUsage[pkg] ?: 0L) + 1000L
                        appUsage[pkg] = used

                        // إذا تجاوز الوقت المسموح، أظهر Overlay
                        if (used >= limit && overlayView == null) {
                            showOverlay(pkg)
                        }
                    }
                }

                handler.postDelayed(this, 1000)
            }
        })
    }

    private fun getForegroundApp(): String? {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 * 60 // آخر ساعة
        val stats: List<UsageStats> =
            usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        if (stats.isNullOrEmpty()) return null
        return stats.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun showOverlay(packageName: String) {
        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.overlay_block, null)
        overlayView?.tag = packageName
        currentPackage = packageName

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        windowManager.addView(overlayView, params)
    }

    private fun removeOverlay() {
        overlayView?.let {
            windowManager.removeView(it)
            overlayView = null
            currentPackage = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        removeOverlay()
        handler.removeCallbacksAndMessages(null)
    }
}
