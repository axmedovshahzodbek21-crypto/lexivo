package com.lexivo.app

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray

class StatsWidgetConfigActivity : AppCompatActivity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        widgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) { finish(); return }

        val prefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        val classesJson = prefs.getString("lexivo_widget_classes", null)

        // Options: Personal first, then each class
        val options = mutableListOf(Pair("personal", "⚡  Personal"))
        if (classesJson != null) {
            try {
                val arr = JSONArray(classesJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    options.add(Pair(obj.getString("id"), "🎓  ${obj.getString("name")}"))
                }
            } catch (_: Exception) {}
        }

        val dp = resources.displayMetrics.density

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#0F0E1A"))
            setPadding((24 * dp).toInt(), (32 * dp).toInt(), (24 * dp).toInt(), (24 * dp).toInt())
        }

        val title = TextView(this).apply {
            text = "Stats Widget"
            textSize = 20f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            setPadding(0, 0, 0, (4 * dp).toInt())
        }
        root.addView(title)

        val sub = TextView(this).apply {
            text = "Choose what to display"
            textSize = 13f
            setTextColor(Color.parseColor("#6B63CC"))
            setPadding(0, 0, 0, (24 * dp).toInt())
        }
        root.addView(sub)

        for ((sourceId, label) in options) {
            val row = TextView(this).apply {
                text = label
                textSize = 16f
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#1A1545"))
                setPadding((16 * dp).toInt(), (14 * dp).toInt(), (16 * dp).toInt(), (14 * dp).toInt())
                gravity = Gravity.CENTER_VERTICAL
                setOnClickListener { pickSource(sourceId) }
            }
            root.addView(row)

            val spacer = LinearLayout(this)
            spacer.minimumHeight = (10 * dp).toInt()
            root.addView(spacer)
        }

        val scroll = ScrollView(this)
        scroll.addView(root)
        setContentView(scroll)
    }

    private fun pickSource(sourceId: String) {
        getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
            .edit().putString("widget_stats_$widgetId", sourceId).apply()

        StatsWidgetProvider.updateWidget(this, AppWidgetManager.getInstance(this), widgetId)

        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }
}
