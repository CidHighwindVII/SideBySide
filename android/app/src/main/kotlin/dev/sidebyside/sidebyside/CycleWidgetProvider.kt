package dev.sidebyside.sidebyside

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

// v0.4.0 (#7): reads the labels Flutter writes via home_widget and renders
// them as RemoteViews. The dot is decoration; phase + day are always text
// (never color-only, §7).
class CycleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        ids: IntArray
    ) {
        // mirrors home_widget's SharedPreferences name (plugin contract)
        val prefs =
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.cycle_widget)
            views.setTextViewText(R.id.widget_phase, prefs.getString("phaseLabel", "SideBySide"))
            views.setTextViewText(R.id.widget_day, prefs.getString("dayLabel", ""))
            views.setInt(R.id.widget_dot, "setBackgroundColor", prefs.getInt("dotColor", Color.GRAY))
            val open = PendingIntent.getActivity(
                context, 0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            manager.updateAppWidget(id, views)
        }
    }
}
