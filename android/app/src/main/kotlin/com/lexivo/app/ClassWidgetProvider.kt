package com.lexivo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
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
            edit.remove("widget_class_name_$id")
            edit.remove("widget_class_teacher_$id")
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
                views.setTextViewText(R.id.widget_pending, "to load your classes")
                views.setTextViewText(R.id.widget_due, "")
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
                        views.setTextViewText(R.id.widget_pending, "Open Lexivo to get started")
                        views.setTextViewText(R.id.widget_due, "")
                    } else {
                        tapClassId = obj.getString("id")
                        tapClassName = obj.getString("name")
                        tapIsTeacher = obj.optBoolean("isTeacher", false)

                        val pendingHW = obj.getInt("pendingHW")
                        val nextDue = if (obj.isNull("nextDue")) null else obj.getString("nextDue")
                        val overdue = obj.optBoolean("overdue", false)

                        views.setTextViewText(R.id.widget_class_name, tapClassName)

                        if (pendingHW == 0) {
                            views.setTextViewText(R.id.widget_pending, "No pending homework")
                            views.setTextViewText(R.id.widget_due, "")
                        } else {
                            val hwText = if (pendingHW == 1) "1 homework pending" else "$pendingHW homework pending"
                            views.setTextViewText(R.id.widget_pending, hwText)
                            if (nextDue != null) {
                                val dueText = if (overdue) "Overdue since $nextDue" else "Due $nextDue"
                                views.setTextViewText(R.id.widget_due, dueText)
                                val dueColor = if (overdue) Color.parseColor("#E53E3E") else Color.parseColor("#6B7280")
                                views.setInt(R.id.widget_due, "setTextColor", dueColor)
                            } else {
                                views.setTextViewText(R.id.widget_due, "")
                            }
                        }
                    }
                } catch (e: JSONException) {
                    views.setTextViewText(R.id.widget_class_name, "Error loading data")
                    views.setTextViewText(R.id.widget_pending, "Open Lexivo to refresh")
                    views.setTextViewText(R.id.widget_due, "")
                }
            }

            // Tap: deep link into the class if we have one, otherwise just open app
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

            if (tapIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, widgetId, tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
