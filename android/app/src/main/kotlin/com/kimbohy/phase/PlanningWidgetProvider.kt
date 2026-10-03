package com.kimbohy.phase

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.Duration
import java.time.LocalDateTime

class PlanningWidgetProvider : HomeWidgetProvider() {

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
                bind(context, views, state, now)
                manager.updateAppWidget(id, views)
            }

            // Programme la prochaine mise à jour, même si l'app est fermée.
            WidgetScheduler.scheduleNext(context, state, now)
        }

        private fun bind(context: Context, views: RemoteViews, state: WidgetState, now: LocalDateTime) {
            views.setTextViewText(R.id.title, WidgetLabels.title(state))
            views.setTextViewText(R.id.next, WidgetLabels.nextLine(state, now))

            // Jauge de progression du bloc (ou de l'intervalle libre).
            val hasPhase = state.kind != "empty"
            views.setViewVisibility(R.id.gauge, if (hasPhase) View.VISIBLE else View.GONE)
            views.setProgressBar(R.id.gauge, 1000, (state.progress * 1000).toInt(), false)

            // Compte à rebours : le Chronometer décompte TOUT SEUL, sans mise à jour.
            // S'il y a une sous-phase pomodoro, on décompte jusqu'à sa fin.
            val countdownEnd = state.sub?.endsAt ?: state.end
            if (countdownEnd != null) {
                val remainingMs = Duration.between(now, countdownEnd).toMillis().coerceAtLeast(0)
                views.setChronometerCountDown(R.id.remaining, true)
                views.setChronometer(
                    R.id.remaining,
                    SystemClock.elapsedRealtime() + remainingMs,
                    null,
                    true,
                )
                views.setViewVisibility(R.id.remaining, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.remaining, View.GONE)
            }

            // Ligne pomodoro (Focus 2/4, Pause · 3 min).
            val subText = WidgetLabels.subLine(state.sub, now)
            if (subText != null) {
                views.setTextViewText(R.id.sub, subText)
                views.setViewVisibility(R.id.sub, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.sub, View.GONE)
            }

            // Un tap ouvre l'app.
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
        }

        /** Redessine tous les widgets posés (utilisable depuis un receiver, sans l'app). */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PlanningWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            render(context, manager, ids, prefs)
        }
    }
}