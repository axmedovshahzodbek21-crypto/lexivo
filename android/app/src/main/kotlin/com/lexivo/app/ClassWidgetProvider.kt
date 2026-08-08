package com.lexivo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONException

class ClassWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val edit = prefs.edit()
        for (id in appWidgetIds) {
            edit.remove("widget_class_$id")
        }
        edit.apply()
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val classesJson = prefs.getString("lexivo_widget_classes", null)
            val selectedId = prefs.getString("widget_class_$widgetId", null)

            val views = RemoteViews(context.packageName, R.layout.widget_class)

            var tapClassId: String? = null
            var tapClassName: String? = null
            var tapIsTeacher = false

            if (classesJson == null) {
                views.setTextViewText(R.id.widget_class_name, "Open Lexivo")
                views.setViewVisibility(R.id.widget_badge, View.GONE)
                views.setTextViewText(R.id.widget_pending, "to load your classes")
            } else {
                try {
                    val arr = JSONArray(classesJson)

                    var obj = if (arr.length() > 0) arr.getJSONObject(0) else null
                    if (selectedId != null) {
                        for (i in 0 until arr.length()) {
                            val c = arr.getJSONObject(i)
                            if (c.getString("id") == selectedId) { obj = c; break }
                        }
                    }

                    if (obj == null) {
                        views.setTextViewText(R.id.widget_class_name, "No classes")
                        views.setViewVisibility(R.id.widget_badge, View.GONE)
                        views.setTextViewText(R.id.widget_pending, "Open Lexivo to get started")
                    } else {
                        tapClassId = obj.getString("id")
                        tapClassName = obj.getString("name")
                        tapIsTeacher = obj.optBoolean("isTeacher", false)
                        val pendingHW = obj.getInt("pendingHW")

                        views.setTextViewText(R.id.widget_class_name, tapClassName)

                        if (pendingHW == 0) {
                            views.setViewVisibility(R.id.widget_badge, View.GONE)
                            views.setTextViewText(R.id.widget_pending, "No homework")
                        } else {
                            views.setViewVisibility(R.id.widget_badge, View.VISIBLE)
                            views.setTextViewText(R.id.widget_badge, "$pendingHW")
                            views.setTextViewText(R.id.widget_pending, "homework pending")
                        }
                    }
                } catch (e: JSONException) {
                    views.setTextViewText(R.id.widget_class_name, "Error loading")
                    views.setViewVisibility(R.id.widget_badge, View.GONE)
                    views.setTextViewText(R.id.widget_pending, "Open Lexivo to refresh")
                }
            }

            // Tap: deep link into the class if we have one, otherwise open app
            val tapIntent = if (tapClassId != null) {
                val encodedName = Uri.encode(tapClassName ?: "")
                val uri = Uri.parse("lexivo://class/$tapClassId?name=$encodedName&isTeacher=$tapIsTeacher")
                Intent(Intent.ACTION_VIEW, uri).apply {
                    setPackage(context.packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            } else {
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            }

            // Main body tap: open the class (or app if no class selected)
            if (tapIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, widgetId, tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            // "LEXIVO" label tap: re-open class picker to switch class
            val configIntent = Intent(context, ClassWidgetConfigActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val configPendingIntent = PendingIntent.getActivity(
                context, widgetId + 100_000, configIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_app_label, configPendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
