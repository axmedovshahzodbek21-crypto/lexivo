package com.lexivo.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONException

class StatsWidgetProvider : AppWidgetProvider() {

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
        for (id in appWidgetIds) edit.remove("widget_stats_$id")
        edit.apply()
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val source = prefs.getString("widget_stats_$widgetId", "personal") ?: "personal"

            val views = RemoteViews(context.packageName, R.layout.widget_stats)

            // className is used for both the label and the tap deep-link
            var className = ""

            if (source == "personal") {
                val streak = prefs.getInt("lexivo_widget_streak", 0)
                val xp = prefs.getInt("lexivo_widget_xp", 0)
                views.setTextViewText(R.id.widget_source_label, "PERSONAL")
                views.setTextViewText(R.id.widget_streak_value, streak.toString())
                views.setTextViewText(R.id.widget_xp_value, formatXP(xp))
            } else {
                var streak = 0
                var xp = 0

                // Name from lexivo_widget_classes (always populated on every refresh)
                val classesJson = prefs.getString("lexivo_widget_classes", null)
                if (classesJson != null) {
                    try {
                        val arr = JSONArray(classesJson)
                        for (i in 0 until arr.length()) {
                            val obj = arr.getJSONObject(i)
                            if (obj.getString("id") == source) {
                                className = obj.getString("name")
                                break
                            }
                        }
                    } catch (_: JSONException) {}
                }

                // XP + streak from lexivo_class_stats (populated after first sync)
                val classStatsJson = prefs.getString("lexivo_class_stats", null)
                if (classStatsJson != null) {
                    try {
                        val arr = JSONArray(classStatsJson)
                        for (i in 0 until arr.length()) {
                            val obj = arr.getJSONObject(i)
                            if (obj.getString("id") == source) {
                                streak = obj.getInt("streak")
                                xp = obj.getInt("xp")
                                break
                            }
                        }
                    } catch (_: JSONException) {}
                }

                views.setTextViewText(R.id.widget_source_label, className.uppercase().ifEmpty { "CLASS" })
                views.setTextViewText(R.id.widget_streak_value, streak.toString())
                views.setTextViewText(R.id.widget_xp_value, formatXP(xp))
            }

            // Tap: open class deep-link or main app
            val tapIntent: Intent? = if (source == "personal") {
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            } else {
                val uri = Uri.parse(
                    "lexivo://class/$source?name=${Uri.encode(className)}&isTeacher=false"
                )
                Intent(Intent.ACTION_VIEW, uri).apply {
                    setPackage(context.packageName)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            }

            if (tapIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, widgetId + 200_000, tapIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.stats_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // Raw stored value is ×10 integer; display = raw ÷ 10
        private fun formatXP(raw: Int): String {
            val v = raw / 10.0
            return when {
                v >= 10_000 -> "${(v / 1000).toInt()}K"
                v >= 1_000  -> "%.1fK".format(v / 1000)
                v == v.toInt().toDouble() -> v.toInt().toString()
                else -> "%.1f".format(v)
            }
        }
    }
}
