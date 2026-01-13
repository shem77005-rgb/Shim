package com.example.safechild_system

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.LinearLayout
import android.view.Gravity
import android.graphics.Color
import android.view.ViewGroup

class BlockActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        val pkg = intent.getStringExtra("package") ?: ""

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.setBackgroundColor(Color.parseColor("#FFFFFF"))
        root.gravity = Gravity.CENTER
        val lp = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        root.layoutParams = lp

        val tv = TextView(this)
        tv.text = "انتهى وقت التطبيق\n$pkg"
        tv.textSize = 20f
        tv.setTextColor(Color.parseColor("#1F2A34"))
        tv.gravity = Gravity.CENTER
        tv.setPadding(30, 30, 30, 30)

        val btn = Button(this)
        btn.text = "إلغاء للوالد"
        btn.setOnClickListener {
            finish()
        }

        val btnLp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        btnLp.topMargin = 24

        root.addView(tv)
        root.addView(btn, btnLp)
        setContentView(root)
    }

    override fun onBackPressed() {
        // منع زر العودة هنا
    }
}
