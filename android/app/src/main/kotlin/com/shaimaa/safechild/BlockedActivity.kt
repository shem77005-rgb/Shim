
package com.shaimaa.safechild

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.MotionEvent
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity

class BlockedActivity : AppCompatActivity() {

    companion object {
        const val ACTION_CLOSE_BLOCK = "com.shaimaa.safechild.ACTION_CLOSE_BLOCK"
        const val EXTRA_BLOCKED_PKG = "blocked_pkg"
    }

    private val closeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            // اغلق شاشة الحظر فورًا
            finishAndRemoveTaskSafe()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // شاشة حظر كاملة
        setContentView(R.layout.activity_blocked)

        // منع تصوير الشاشة (اختياري لكنه مفيد)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        // خليك فوق دائمًا وخلّها ملء الشاشة
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
    }

    override fun onStart() {
        super.onStart()
        // استمع لإشارة الإغلاق من الخدمة
        registerReceiver(closeReceiver, IntentFilter(ACTION_CLOSE_BLOCK))
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(closeReceiver)
        } catch (_: Exception) {}
    }

    // ✅ منع الرجوع نهائياً
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // لا شيء
    }

    // ✅ منع اللمس نهائياً
    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        return true
    }

    // ✅ منع أي محاولة للخروج/الـ Home من داخلها
    override fun onUserLeaveHint() {
        // لا شيء
    }

    private fun finishAndRemoveTaskSafe() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                finishAndRemoveTask()
            } else {
                finish()
            }
        } catch (_: Exception) {
            finish()
        }
    }
}
