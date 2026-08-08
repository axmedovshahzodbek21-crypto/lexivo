package com.lexivo.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONException

class ClassWidgetConfigActivity : AppCompatActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent.extras
            ?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val classesJson = prefs.getString("lexivo_widget_classes", null)

        if (classesJson == null) {
            finishWithResult()
            return
        }

        try {
            val arr = JSONArray(classesJson)
            if (arr.length() == 0) {
                finishWithResult()
                return
            }

            val names = Array(arr.length()) { i -> arr.getJSONObject(i).getString("name") }
            val ids = Array(arr.length()) { i -> arr.getJSONObject(i).getString("id") }

            AlertDialog.Builder(this)
                .setTitle("Choose a class")
                .setItems(names) { _, which ->
                    prefs.edit().putString("widget_class_$appWidgetId", ids[which]).apply()
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    ClassWidgetProvider.updateWidget(this, appWidgetManager, appWidgetId)
                    finishWithResult()
                }
                .setOnCancelListener { finish() }
                .show()
        } catch (e: JSONException) {
            finishWithResult()
        }
    }

    private fun finishWithResult() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        ClassWidgetProvider.updateWidget(this, appWidgetManager, appWidgetId)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, result)
        finish()
    }
}
