//
//
//package com.shaimaa.safechild
//
//import android.app.*
//import android.app.usage.UsageEvents
//import android.app.usage.UsageStatsManager
//import android.content.Context
//import android.content.Intent
//import android.content.SharedPreferences
//import android.content.pm.ServiceInfo
//import android.graphics.PixelFormat
//import android.os.*
//import android.provider.Settings
//import android.util.Log
//import android.view.*
//import android.app.AppOpsManager
//
//class AppBlockerService : Service() {
//
//    companion object {
//        private const val TAG_POLICY = "POLICY_NATIVE"
//        private const val TAG_MONITOR = "MONITOR"
//
//        private const val PREFS_NAME = "safechild_blocker_prefs"
//        private const val KEY_LIMIT_PREFIX = "limit_"
//
//        private const val CHANNEL_ID = "safechild_blocker_channel"
//        private const val NOTIF_ID = 1101
//
//        // ✅ لا نفك الحظر بسبب تذبذب systemui/emulator
//        private const val OVERLAY_STICKY_MS = 6000L
//
//        // ✅ لازم نشوف "تطبيق آخر" ثابت N مرات قبل ما نشيل overlay
//        private const val OTHER_PKG_STABLE_COUNT = 6
//    }
//
//    private lateinit var windowManager: WindowManager
//    private lateinit var prefs: SharedPreferences
//
//    private var overlayView: View? = null
//    private var currentBlockedPackage: String? = null
//
//    private val handler = Handler(Looper.getMainLooper())
//    private var isMonitoring = true
//
//    private var lastSeenBlockedAt: Long = 0L
//
//    // ✅ تثبيت خروج: لازم نفس التطبيق الآخر يتكرر
//    private var lastOtherPkg: String? = null
//    private var otherPkgCount: Int = 0
//    private var otherPkgFirstSeenAt: Long = 0L
//
//    override fun onBind(intent: Intent?): IBinder? = null
//
//    override fun onCreate() {
//        super.onCreate()
//        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
//        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
//        startAsForegroundHard()
//        startMonitoringLoop()
//    }
//
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        startAsForegroundHard()
//        intent ?: return START_STICKY
//
//        when (intent.getStringExtra("action")) {
//            "set_limit" -> {
//                val pkg = intent.getStringExtra("package")
//                val limit = intent.getLongExtra("limit_ms", 0L)
//                if (!pkg.isNullOrEmpty() && limit > 0) saveLimit(pkg, limit)
//            }
//
//            "clear_limit" -> {
//                val pkg = intent.getStringExtra("package")
//                if (!pkg.isNullOrEmpty()) {
//                    clearLimit(pkg)
//                    if (currentBlockedPackage == pkg) removeOverlay()
//                }
//            }
//
//            "clear_all" -> {
//                clearAllLimits()
//                removeOverlay()
//            }
//
//            "start" -> isMonitoring = true
//
//            "stop" -> {
//                isMonitoring = false
//                removeOverlay()
//                stopForeground(true)
//                stopSelf()
//            }
//        }
//
//        return START_STICKY
//    }
//
//    // ---------------- Foreground ----------------
//    private fun startAsForegroundHard() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val channel = NotificationChannel(
//                CHANNEL_ID,
//                "SafeChild App Blocker",
//                NotificationManager.IMPORTANCE_LOW
//            )
//            getSystemService(NotificationManager::class.java)
//                .createNotificationChannel(channel)
//        }
//
//        val intent = Intent(this, MainActivity::class.java)
//        val pending = PendingIntent.getActivity(
//            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
//        )
//
//        val notification = Notification.Builder(this, CHANNEL_ID)
//            .setContentTitle("SafeChild")
//            .setContentText("مراقبة استخدام التطبيقات")
//            .setSmallIcon(R.mipmap.ic_launcher)
//            .setContentIntent(pending)
//            .setOngoing(true)
//            .build()
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//            startForeground(
//                NOTIF_ID,
//                notification,
//                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
//            )
//        } else {
//            startForeground(NOTIF_ID, notification)
//        }
//    }
//
//    // ---------------- Monitoring ----------------
//    private fun startMonitoringLoop() {
//        handler.post(object : Runnable {
//            override fun run() {
//                try {
//                    if (!isMonitoring) {
//                        handler.postDelayed(this, 800)
//                        return
//                    }
//
//                    if (!hasUsageAccessPermission() || !canDrawOverlays()) {
//                        removeOverlay()
//                        handler.postDelayed(this, 1500)
//                        return
//                    }
//
//                    val fg = getForegroundAppStrong()
//                    val now = System.currentTimeMillis()
//
//                    val blockedPkg = currentBlockedPackage
//
//                    // ✅ إذا overlay شغال: لا تشيله إلا بخروج "مؤكد"
//                    if (overlayView != null && !blockedPkg.isNullOrEmpty()) {
//
//                        if (fg == blockedPkg) {
//                            // مازال داخل التطبيق المحظور -> صفّر خروج
//                            lastSeenBlockedAt = now
//                            resetOtherPkgStability()
//                        } else if (isIgnoredForeground(fg)) {
//                            // تذبذب طبيعي -> لا تسوي شيء
//                        } else {
//                            // شفنا تطبيق آخر (مرات متتالية) -> سجل وقرر
//                            trackOtherPkg(fg, now)
//
//                            val timeSinceBlocked = now - lastSeenBlockedAt
//                            val otherStableEnough = (otherPkgCount >= OTHER_PKG_STABLE_COUNT)
//                            val otherTimeEnough = (now - otherPkgFirstSeenAt >= OVERLAY_STICKY_MS)
//
//                            // ✅ لا نشيل overlay إلا إذا:
//                            // 1) شفنا تطبيق آخر ثابت N مرات
//                            // 2) ومر وقت كافي بدون رجوع للتطبيق المحظور
//                            if (otherStableEnough && otherTimeEnough && timeSinceBlocked >= OVERLAY_STICKY_MS) {
//                                removeOverlay()
//                            }
//                        }
//
//                        handler.postDelayed(this, 500)
//                        return
//                    }
//
//                    // ✅ ما في overlay: طبق القوانين بشكل طبيعي
//                    if (!isIgnoredForeground(fg) && fg != null) {
//                        val limit = getLimit(fg)
//                        if (limit != null && limit > 0) {
//                            val used = getTodayUsageMs(fg)
//                            if (used >= limit) {
//                                currentBlockedPackage = fg
//                                lastSeenBlockedAt = now
//                                resetOtherPkgStability()
//                                showOverlay(fg)
//                            }
//                        }
//                    }
//
//                } catch (e: Exception) {
//                    Log.e(TAG_MONITOR, "monitor error", e)
//                }
//
//                handler.postDelayed(this, 800)
//            }
//        })
//    }
//
//    // ✅ track خروج "مؤكد"
//    private fun trackOtherPkg(fg: String?, now: Long) {
//        if (fg.isNullOrBlank()) return
//
//        if (lastOtherPkg == null || lastOtherPkg != fg) {
//            lastOtherPkg = fg
//            otherPkgCount = 1
//            otherPkgFirstSeenAt = now
//        } else {
//            otherPkgCount += 1
//        }
//    }
//
//    private fun resetOtherPkgStability() {
//        lastOtherPkg = null
//        otherPkgCount = 0
//        otherPkgFirstSeenAt = 0L
//    }
//
//    // ---------------- Foreground detection (Strong) ----------------
//
//    /**
//     * ✅ أقوى من MOVE_TO_FOREGROUND:
//     * نعتمد ACTIVITY_RESUMED (Android 10+ أدق)
//     */
//    private fun getForegroundAppStrong(): String? {
//        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
//        val end = System.currentTimeMillis()
//        val start = end - 20_000 // نافذة أكبر لتقليل null
//
//        val events = usm.queryEvents(start, end)
//        val event = UsageEvents.Event()
//
//        var lastResumed: String? = null
//        var lastMovedFg: String? = null
//
//        while (events.hasNextEvent()) {
//            events.getNextEvent(event)
//
//            when (event.eventType) {
//                // Android Q+ الأفضل
//                UsageEvents.Event.ACTIVITY_RESUMED -> {
//                    lastResumed = event.packageName
//                }
//
//                // fallback
//                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
//                    lastMovedFg = event.packageName
//                }
//            }
//        }
//
//        return lastResumed ?: lastMovedFg
//    }
//
//    private fun isIgnoredForeground(pkg: String?): Boolean {
//        if (pkg.isNullOrBlank()) return true
//        if (pkg == packageName) return true
//        if (pkg == "com.android.systemui") return true
//
//        // ✅ على كثير أجهزة/Emulator يصير foreground يتذبذب لهذه الحزم
//        if (pkg.startsWith("com.android.launcher")) return true
//        if (pkg.startsWith("com.google.android.permissioncontroller")) return true
//        if (pkg.startsWith("com.android.permissioncontroller")) return true
//        if (pkg.startsWith("com.google.android.inputmethod")) return true
//        if (pkg.startsWith("com.android.inputmethod")) return true
//
//        return false
//    }
//
//    // ---------------- Usage time ----------------
//    private fun getTodayUsageMs(pkg: String): Long {
//        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
//        val cal = java.util.Calendar.getInstance().apply {
//            set(java.util.Calendar.HOUR_OF_DAY, 0)
//            set(java.util.Calendar.MINUTE, 0)
//            set(java.util.Calendar.SECOND, 0)
//            set(java.util.Calendar.MILLISECOND, 0)
//        }
//
//        val stats = usm.queryUsageStats(
//            UsageStatsManager.INTERVAL_DAILY,
//            cal.timeInMillis,
//            System.currentTimeMillis()
//        )
//
//        return stats.firstOrNull { it.packageName == pkg }
//            ?.let {
//                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
//                    it.totalTimeVisible
//                else it.totalTimeInForeground
//            } ?: 0L
//    }
//
//    // ---------------- Permissions ----------------
//    private fun canDrawOverlays(): Boolean =
//        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
//
//    private fun hasUsageAccessPermission(): Boolean {
//        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
//        val mode = appOps.checkOpNoThrow(
//            AppOpsManager.OPSTR_GET_USAGE_STATS,
//            Process.myUid(),
//            packageName
//        )
//        return mode == AppOpsManager.MODE_ALLOWED
//    }
//
//    // ---------------- Overlay ----------------
//    private fun showOverlay(pkg: String) {
//        if (!canDrawOverlays()) return
//        if (overlayView != null) return
//
//        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
//        overlayView = inflater.inflate(R.layout.overlay_block, null).apply {
//            isClickable = true
//            isFocusable = true
//            isFocusableInTouchMode = true
//
//            // ✅ امسك كل اللمس/السحب/السكرول
//            setOnTouchListener { _, _ -> true }
//            setOnGenericMotionListener { _, _ -> true }
//        }
//
//        val type =
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
//                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
//            else WindowManager.LayoutParams.TYPE_PHONE
//
//        // ✅ Overlay “قافل” (لا NOT_FOCUSABLE ولا NOT_TOUCH_MODAL)
//        val flags =
//            WindowManager.LayoutParams.FLAG_FULLSCREEN or
//                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
//                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
//
//        val params = WindowManager.LayoutParams(
//            WindowManager.LayoutParams.MATCH_PARENT,
//            WindowManager.LayoutParams.MATCH_PARENT,
//            type,
//            flags,
//            PixelFormat.TRANSLUCENT
//        ).apply {
//            gravity = Gravity.TOP or Gravity.START
//        }
//
//        try {
//            windowManager.addView(overlayView, params)
//        } catch (e: Exception) {
//            Log.e(TAG_MONITOR, "showOverlay addView failed", e)
//            overlayView = null
//            currentBlockedPackage = null
//        }
//    }
//
//    private fun removeOverlay() {
//        overlayView?.let {
//            try {
//                windowManager.removeViewImmediate(it)
//            } catch (_: Exception) {}
//        }
//        overlayView = null
//        currentBlockedPackage = null
//        lastSeenBlockedAt = 0L
//        resetOtherPkgStability()
//    }
//
//    // ---------------- Limits ----------------
//    private fun saveLimit(pkg: String, ms: Long) {
//        prefs.edit().putLong(KEY_LIMIT_PREFIX + pkg, ms).apply()
//    }
//
//    private fun getLimit(pkg: String): Long? =
//        if (prefs.contains(KEY_LIMIT_PREFIX + pkg))
//            prefs.getLong(KEY_LIMIT_PREFIX + pkg, 0L)
//        else null
//
//    private fun clearLimit(pkg: String) {
//        prefs.edit().remove(KEY_LIMIT_PREFIX + pkg).apply()
//    }
//
//    private fun clearAllLimits() {
//        prefs.edit().clear().apply()
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        removeOverlay()
//        handler.removeCallbacksAndMessages(null)
//    }
//


package com.shaimaa.safechild

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.os.*
import android.provider.Settings
import android.util.Log
import android.app.AppOpsManager

class AppBlockerService : Service() {

    companion object {
        private const val TAG_MONITOR = "MONITOR"
        private const val TAG_POLICY = "POLICY_NATIVE"

        private const val PREFS_NAME = "safechild_blocker_prefs"
        private const val KEY_LIMIT_PREFIX = "limit_"

        private const val CHANNEL_ID = "safechild_blocker_channel"
        private const val NOTIF_ID = 1101

        // سرعة المراقبة
        private const val TICK_MS = 450L

        // تأكيد خروج من التطبيق المحظور (عشان SystemUI/Launcher)
        private const val EXIT_CONFIRM_TICKS = 2
    }

    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var isMonitoring = true

    private var blockedPkg: String? = null
    private var exitTicks = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        startAsForegroundHard()
        startMonitoringLoop()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForegroundHard()

        intent ?: return START_STICKY

        when (intent.getStringExtra("action")) {
            "set_limit" -> {
                val pkg = intent.getStringExtra("package")
                val limit = intent.getLongExtra("limit_ms", 0L)
                if (!pkg.isNullOrEmpty() && limit > 0) {
                    saveLimit(pkg, limit)
                    Log.d(TAG_POLICY, "set_limit pkg=$pkg ms=$limit")
                }
            }

            "clear_limit" -> {
                val pkg = intent.getStringExtra("package")
                if (!pkg.isNullOrEmpty()) {
                    clearLimit(pkg)
                    Log.d(TAG_POLICY, "clear_limit pkg=$pkg")
                    if (blockedPkg == pkg) {
                        blockedPkg = null
                        sendUnblockSignal()
                    }
                }
            }

            "clear_all" -> {
                clearAllLimits()
                Log.d(TAG_POLICY, "clear_all")
                blockedPkg = null
                sendUnblockSignal()
            }

            "start" -> {
                isMonitoring = true
                Log.d(TAG_POLICY, "start monitoring")
            }

            "stop" -> {
                isMonitoring = false
                Log.d(TAG_POLICY, "stop monitoring")
                blockedPkg = null
                sendUnblockSignal()
                stopForeground(true)
                stopSelf()
            }
        }

        return START_STICKY
    }

    // ---------------- Foreground ----------------
    private fun startAsForegroundHard() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SafeChild App Blocker",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        val pending = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("SafeChild")
            .setContentText("مراقبة استخدام التطبيقات")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    // ---------------- Monitoring ----------------
    private fun startMonitoringLoop() {
        handler.post(object : Runnable {
            override fun run() {
                try {
                    if (!isMonitoring) {
                        handler.postDelayed(this, TICK_MS)
                        return
                    }

                    if (!hasUsageAccessPermission()) {
                        // بدون Usage Access ما نقدر نراقب
                        blockedPkg = null
                        sendUnblockSignal()
                        handler.postDelayed(this, 1500)
                        return
                    }

                    val fg = getForegroundAppByEvents()

                    // ✅ إذا فيه تطبيق محظور حالياً
                    if (!blockedPkg.isNullOrEmpty()) {
                        val bp = blockedPkg!!

                        if (fg == bp) {
                            // الطفل رجع للتطبيق المحظور -> طيّره فوراً واظهر واجهة الحظر
                            exitTicks = 0
                            kickOutAndShowBlock(bp)
                        } else {
                            // خرج من التطبيق المحظور -> بعد تأكيد بسيط، اقفل واجهة الحظر وافرّغ الحالة
                            exitTicks++
                            if (exitTicks >= EXIT_CONFIRM_TICKS) {
                                blockedPkg = null
                                exitTicks = 0
                                sendUnblockSignal()
                            }
                        }

                        handler.postDelayed(this, TICK_MS)
                        return
                    }

                    // ✅ ما فيه حظر مفعل الآن -> شيّك هل التطبيق الحالي تعدّى حدّه
                    if (fg != null && fg != packageName && fg != "com.android.systemui") {
                        val limit = getLimit(fg)
                        if (limit != null && limit > 0) {
                            val used = getTodayUsageMs(fg)
                            if (used >= limit) {
                                blockedPkg = fg
                                exitTicks = 0
                                kickOutAndShowBlock(fg)
                            }
                        }
                    }

                } catch (e: Exception) {
                    Log.e(TAG_MONITOR, "monitor error", e)
                }

                handler.postDelayed(this, TICK_MS)
            }
        })
    }

    // ---------------- Actions ----------------
    private fun kickOutAndShowBlock(pkg: String) {
        val i = Intent(this, BlockedActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("package", pkg)
        }
        try {
            startActivity(i)
        } catch (e: Exception) {
            Log.e(TAG_MONITOR, "startActivity BlockedActivity failed", e)
        }

        goHome()
    }

    private fun goHome() {
        val home = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        try {
            startActivity(home)
        } catch (e: Exception) {
            Log.e(TAG_MONITOR, "goHome failed", e)
        }
    }

    private fun sendUnblockSignal() {
        // إغلاق واجهة الحظر لو كانت مفتوحة
        val b = Intent(BlockedActivity.ACTION_UNBLOCK)
        sendBroadcast(b)
    }

    // ---------------- Usage ----------------
    private fun getForegroundAppByEvents(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 15_000

        val events = usm.queryEvents(start, end)
        val event = UsageEvents.Event()
        var lastPkg: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastPkg = event.packageName
            }
        }
        return lastPkg
    }

    private fun getTodayUsageMs(pkg: String): Long {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val cal = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            cal.timeInMillis,
            System.currentTimeMillis()
        )

        return stats.firstOrNull { it.packageName == pkg }
            ?.let {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) it.totalTimeVisible
                else it.totalTimeInForeground
            } ?: 0L
    }

    // ---------------- Permissions ----------------
    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    // ---------------- Limits ----------------
    private fun saveLimit(pkg: String, ms: Long) {
        prefs.edit().putLong(KEY_LIMIT_PREFIX + pkg, ms).apply()
    }

    private fun getLimit(pkg: String): Long? =
        if (prefs.contains(KEY_LIMIT_PREFIX + pkg))
            prefs.getLong(KEY_LIMIT_PREFIX + pkg, 0L)
        else null

    private fun clearLimit(pkg: String) {
        prefs.edit().remove(KEY_LIMIT_PREFIX + pkg).apply()
    }

    private fun clearAllLimits() {
        prefs.edit().clear().apply()
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
    }
}


