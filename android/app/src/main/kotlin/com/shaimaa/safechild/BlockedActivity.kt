package com.shaimaa.safechild

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.LinearLayout
import android.view.Gravity
import android.graphics.Color
import android.view.ViewGroup

class BlockedActivity : Activity() {
    
    companion object {
        const val ACTION_UNBLOCK = "com.shaimaa.safechild.UNBLOCK"
        private const val TAG = "BlockedActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set window flags to show over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        
        val pkg = intent.getStringExtra("package") ?: ""
        val appName = intent.getStringExtra("appName") ?: ""
        
        // Create layout
        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setBackgroundColor(Color.parseColor("#FFFFFF"))
        root.gravity = Gravity.CENTER
        val lp = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        root.layoutParams = lp
        
        // Title text
        val titleTv = TextView(this)
        titleTv.text = "التطبيق محظور مؤقتاً"
        titleTv.textSize = 24f
        titleTv.setTextColor(Color.parseColor("#FF0000"))
        titleTv.gravity = Gravity.CENTER
        titleTv.setPadding(30, 30, 30, 10)
        
        // App info text
        val appTv = TextView(this)
        appTv.text = "تم حظر التطبيق:\n$appName\n($pkg)"
        appTv.textSize = 18f
        appTv.setTextColor(Color.parseColor("#1F2A34"))
        appTv.gravity = Gravity.CENTER
        appTv.setPadding(30, 10, 30, 30)
        
        // Unblock button
        val unblockBtn = Button(this)
        unblockBtn.text = "إلغاء الحظر"
        unblockBtn.setOnClickListener {
            try {
                // Send unblock broadcast
                val unblockIntent = Intent(ACTION_UNBLOCK)
                unblockIntent.putExtra("package", pkg)
                sendBroadcast(unblockIntent)
                finish()
            } catch (e: Exception) {
                Log.e(TAG, "Error sending unblock broadcast", e)
            }
        }
        
        val btnLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, 
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        btnLp.topMargin = 24
        
        // Add views to root
        root.addView(titleTv)
        root.addView(appTv)
        root.addView(unblockBtn, btnLp)
        
        setContentView(root)
    }
    
    override fun onBackPressed() {
        // Prevent back button from closing the activity
        // This keeps the block enforced
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "BlockedActivity destroyed")
    }
}