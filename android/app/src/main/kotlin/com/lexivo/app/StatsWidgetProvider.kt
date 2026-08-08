package com.lexivo.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

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

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val streak = prefs.getInt("lexivo_widget_streak", 0)
            val xp = prefs.getInt("lexivo_widget_xp", 0)

            val views = RemoteViews(context.packageName, R.layout.widget_stats)

            views.setTextViewText(R.id.widget_streak_value, streak.toString())
            views.setTextViewText(R.id.widget_xp_value, formatXP(xp))

            // Tap opens the app
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP }

            if (launchIntent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, widgetId + 200_000, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.stats_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }

        private fun formatXP(xp: Int): String = when {
            xp >= 10_000 -> "${xp / 1000}K"
            xp >= 1_000  -> "${xp / 1000}.${(xp % 1000) / 100}K"
            else         -> xp.toString()
        }
    }
}
