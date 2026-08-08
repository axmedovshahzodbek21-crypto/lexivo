package com.lexivo.app

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class ClassWidgetConfigActivity : AppCompatActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Default result: cancelled (user pressed back without picking)
        setResult(RESULT_CANCELED)

        setContentView(R.layout.activity_widget_config)

        // Extract the widget ID from the intent that launched this activity
        appWidgetId = intent.extras
            ?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        loadClasses()
    }

    private fun loadClasses() {
        val prefs     = HomeWidgetPlugin.getData(this)
        val json      = prefs.getString("lexivo_widget_classes", null)
        val container = findViewById<LinearLayout>(R.id.class_list_container)
        val empty     = findViewById<View>(R.id.empty_state)

        if (json.isNullOrEmpty()) {
            container.visibility = View.GONE
            empty.visibility     = View.VISIBLE
            return
        }

        val array = JSONArray(json)
        if (array.length() == 0) {
            container.visibility = View.GONE
            empty.visibility     = View.VISIBLE
            return
        }

        container.visibility = View.VISIBLE
        empty.visibility     = View.GONE

        for (i in 0 until array.length()) {
            val cls = array.getJSONObject(i)
            addClassCard(container, cls)
        }
    }

    private fun addClassCard(container: LinearLayout, cls: JSONObject) {
        val view = LayoutInflater.from(this)
            .inflate(R.layout.item_class_picker, container, false)

        val id        = cls.getString("id")
        val name      = cls.getString("name")
        val pendingHW = cls.getInt("pendingHW")
        val overdue   = cls.optBoolean("overdue", false)

        view.findViewById<TextView>(R.id.item_class_name).text = name
        view.findViewById<TextView>(R.id.item_class_status).text = when {
            pendingHW == 0 -> "✅ All done"
            overdue        -> "⚠️ $pendingHW overdue"
            pendingHW == 1 -> "📖 1 pending"
            else           -> "📖 $pendingHW pending"
        }

        view.setOnClickListener { onClassSelected(id) }
        container.addView(view)
    }

    private fun onClassSelected(classId: String) {
        // Save this widget's chosen class
        getSharedPreferences("lexivo_widget_cfg", MODE_PRIVATE)
            .edit()
            .putString("class_id_$appWidgetId", classId)
            .apply()

        // Trigger an immediate widget redraw with the new data
        val manager = AppWidgetManager.getInstance(this)
        ClassWidgetProvider.updateWidget(this, manager, appWidgetId)

        // Return OK so the launcher places the widget
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, result)
        finish()
    }
}
