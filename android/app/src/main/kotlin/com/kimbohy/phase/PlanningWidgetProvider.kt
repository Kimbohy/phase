package com.kimbohy.phase

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDateTime

class PlanningWidgetProvider : HomeWidgetProvider() {

    // Appelé par Android (et par HomeWidget.updateWidget côté Dart).
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        render(context, appWidgetManager, appWidgetIds, widgetData)
    }

    companion object {
        private const val KEY_PLANNING = "planning_json"

        fun render(
            context: Context,
            manager: AppWidgetManager,
            ids: IntArray,
            prefs: SharedPreferences,
        ) {
            val now = LocalDateTime.now()
            val state = WidgetEngine.compute(prefs.getString(KEY_PLANNING, null), now)

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.widget_planning)
                views.setTextViewText(R.id.title, WidgetLabels.title(state))
                views.setTextViewText(R.id.next, WidgetLabels.nextLine(state, now))

                // Un tap sur le widget ouvre l'app.
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pending = PendingIntent.getActivity(
                    context, 0, intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)

                manager.updateAppWidget(id, views)
            }
        }

        /** Redessine tous les widgets posés (utilisable depuis un receiver, sans l'app). */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PlanningWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            // Fichier utilisé par le package home_widget.
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            render(context, manager, ids, prefs)
        }
    }
}