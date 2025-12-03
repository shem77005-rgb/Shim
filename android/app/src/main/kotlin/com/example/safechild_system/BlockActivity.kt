package com.example.safechild_system

import android.content.Context
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import androidx.appcompat.app.AppCompatActivity
import android.widget.*

class BlockActivity : AppCompatActivity() {
 
  private val PARENT_PIN = "1234"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // عرض الشاشة فوق القفل وتشغيل الشاشة
    window.addFlags(
      WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
      WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
      WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
    )

    val pkg = intent?.getStringExtra("package") ?: "التطبيق"
    val used = intent?.getLongExtra("usedMillis", 0L) ?: 0L
    val limit = intent?.getLongExtra("limitMillis", 0L) ?: 0L

    val usedMin = used / 60000
    val limitMin = limit / 60000

    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setPadding(32, 120, 32, 32)
    }

    val tv = TextView(this).apply {
      text = "انتهت المدة المسموحة\n$pkg"
      textSize = 22f
      gravity = Gravity.CENTER
    }

    val sub = TextView(this).apply {
      text = "المدة المستعملة: ${usedMin}د\nالحد: ${limitMin}د"
      textSize = 14f
      gravity = Gravity.CENTER
    }

    val pinLabel = TextView(this).apply {
      text = "أدخل رمز الوالد للإلغاء"
      setPadding(0, 20, 0, 8)
    }

    val pinInput = EditText(this).apply {
      hint = "PIN"
      inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_VARIATION_PASSWORD
      gravity = Gravity.CENTER
    }

    val btn = Button(this).apply {
      text = "تحقق"
      setOnClickListener {
        val v = pinInput.text?.toString() ?: ""
        if (v == PARENT_PIN) {
          finish()
        } else {
          Toast.makeText(this@BlockActivity, "رمز خاطئ", Toast.LENGTH_SHORT).show()
        }
      }
    }

    val spacer = Space(this).apply { minimumHeight = 24 }

    root.addView(tv, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
    root.addView(sub, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
    root.addView(spacer)
    root.addView(pinLabel)
    root.addView(pinInput, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
    root.addView(btn, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

    setContentView(root)
  }

  override fun onBackPressed() {
   
  }
}
