package com.lexivo.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

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

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
        ) {
            val prefs       = HomeWidgetPlugin.getData(context)
            val classesJson = prefs.getString("lexivo_widget_classes", null)

            val widgetPrefs = context.getSharedPreferences("lexivo_widget_cfg", Context.MODE_PRIVATE)
            val pinnedId    = widgetPrefs.getString("class_id_$widgetId", null)

            val views = RemoteViews(context.packageName, R.layout.widget_class)

            var resolvedName = ""

            if (classesJson == null || pinnedId == null) {
                views.setTextViewText(R.id.widget_class_name, "Tap to set up")
                views.setTextViewText(R.id.widget_pending, "No class selected")
                views.setTextViewText(R.id.widget_due, "")
            } else {
                val array = JSONArray(classesJson)
                var found = false
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    if (obj.getString("id") == pinnedId) {
                        resolvedName  = obj.getString("name")
                        val pendingHW = obj.getInt("pendingHW")
                        val nextDue   = if (obj.isNull("nextDue")) null else obj.getString("nextDue")
                        val overdue   = obj.optBoolean("overdue", false)

                        views.setTextViewText(R.id.widget_class_name, resolvedName)
                        views.setTextViewText(R.id.widget_pending, when {
                            pendingHW == 0 -> "✅ All done"
                            pendingHW == 1 -> "📖 1 pending"
                            else           -> "📖 $pendingHW pending"
                        })
                        views.setTextViewText(R.id.widget_due, when {
                            nextDue == null -> ""
                            overdue        -> "⚠️ Overdue"
                            else           -> "📅 $nextDue"
                        })
                        found = true
                        break
                    }
                }
                if (!found) {
                    views.setTextViewText(R.id.widget_class_name, "Class not found")
                    views.setTextViewText(R.id.widget_pending, "")
                    views.setTextViewText(R.id.widget_due, "")
                }
            }

            // Tap → deep link into the app carrying classId + className
            val encodedName = Uri.encode(resolvedName)
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                data  = Uri.parse("lexivo://class/$pinnedId?name=$encodedName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = android.app.PendingIntent.getActivity(
                context, widgetId, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_class_name, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
