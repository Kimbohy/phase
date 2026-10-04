package com.kimbohy.phase

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.time.Duration
import java.time.LocalDateTime

/**
 * Dessine TOUS les widgets Phase posés (grand et compact), avec un seul calcul.
 * Appelé par les providers, par le receiver d'alarme et par les événements système.
 */
object WidgetRenderer {
    private const val KEY_PLANNING = "planning_json"

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val bigIds = manager.getAppWidgetIds(
            ComponentName(context, PlanningWidgetProvider::class.java),
        )
        val smallIds = manager.getAppWidgetIds(
            ComponentName(context, PlanningWidgetSmallProvider::class.java),
        )

        // Plus aucun widget posé : inutile de garder une alarme.
        if (bigIds.isEmpty() && smallIds.isEmpty()) {
            WidgetScheduler.cancel(context)
            return
        }

        // Fichier utilisé par le package home_widget.
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val now = LocalDateTime.now()
        val state = WidgetEngine.compute(prefs.getString(KEY_PLANNING, null), now)

        for (id in bigIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_planning)
            bind(context, views, state, now, compact = false)
            manager.updateAppWidget(id, views)
        }
        for (id in smallIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_planning_small)
            bind(context, views, state, now, compact = true)
            manager.updateAppWidget(id, views)
        }

        // Programme la prochaine mise à jour, même si l'app est fermée.
        WidgetScheduler.scheduleNext(context, state, now)
    }

    private fun bind(
        context: Context,
        views: RemoteViews,
        state: WidgetState,
        now: LocalDateTime,
        compact: Boolean,
    ) {
        views.setTextViewText(R.id.title, WidgetLabels.title(state))

        val nextLine = WidgetLabels.nextLine(state, now)
        val subText = WidgetLabels.subLine(state.sub, now)

        if (compact) {
            // Une seule ligne discrète : « Focus 2/4 · Ensuite : Ménage · 10:00 ».
            val line = listOfNotNull(subText, nextLine.takeIf { it.isNotEmpty() })
                .joinToString(" · ")
            views.setTextViewText(R.id.next, line)
        } else {
            views.setTextViewText(R.id.next, nextLine)
            if (subText != null) {
                views.setTextViewText(R.id.sub, subText)
                views.setViewVisibility(R.id.sub, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.sub, View.GONE)
            }
        }

        // Jauge de progression du bloc (ou de l'intervalle libre).
        val hasPhase = state.kind != "empty"
        views.setViewVisibility(R.id.gauge, if (hasPhase) View.VISIBLE else View.GONE)
        views.setProgressBar(R.id.gauge, 1000, (state.progress * 1000).toInt(), false)

        // Compte à rebours : le Chronometer décompte tout seul, sans mise à jour.
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
}