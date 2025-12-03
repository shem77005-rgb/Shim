
package com.example.safechild_system

import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

class AppMonitorService : Service() {

  companion object {
    private val limits = ConcurrentHashMap<String, Long>() // package -> millis per day
    private const val TAG = "AppMonitorService"

    fun setLimitForPackage(pkg: String, millis: Long) {
      if (pkg.isBlank()) return
      if (millis <= 0) limits.remove(pkg) else limits[pkg] = millis
      Log.i(TAG, "setLimitForPackage: $pkg -> $millis")
    }

    fun clearLimitForPackage(pkg: String) {
      if (pkg.isBlank()) return
      limits.remove(pkg)
      Log.i(TAG, "clearLimitForPackage: $pkg")
    }
  }

  private lateinit var usageManager: UsageStatsManager
  private val handler = Handler(Looper.getMainLooper())
  private val intervalMs: Long = 5_000 // كل 5 ثواني

  private val checker = object : Runnable {
    override fun run() {
      try {
        checkUsageAndBlockIfNeeded()
      } catch (t: Throwable) {
        Log.e(TAG, "checker error", t)
      } finally {
        handler.postDelayed(this, intervalMs)
      }
    }
  }

  override fun onCreate() {
    super.onCreate()
    usageManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    handler.post(checker)
    Log.i(TAG, "MonitorService started")
  }

  override fun onDestroy() {
    handler.removeCallbacks(checker)
    super.onDestroy()
    Log.i(TAG, "MonitorService stopped")
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun checkUsageAndBlockIfNeeded() {
    val now = System.currentTimeMillis()
    val cal = java.util.Calendar.getInstance()
    cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
    cal.set(java.util.Calendar.MINUTE, 0)
    cal.set(java.util.Calendar.SECOND, 0)
    cal.set(java.util.Calendar.MILLISECOND, 0)
    val startOfDay = cal.timeInMillis

    val aggregated = usageManager.queryAndAggregateUsageStats(startOfDay, now)
    for ((pkg, limit) in limits) {
      val usage = aggregated[pkg]?.totalTimeInForeground ?: 0L
      if (limit > 0 && usage >= limit) {
        Log.i(TAG, "limit exceeded for $pkg usage=$usage limit=$limit -> launching BlockActivity")
        val i = Intent(this, BlockActivity::class.java)
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        i.putExtra("package", pkg)
        i.putExtra("usedMillis", usage)
        i.putExtra("limitMillis", limit)
        startActivity(i)
      }
    }
  }
}
