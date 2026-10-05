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
import org.json.JSONArray
import java.time.Duration
import java.time.LocalDateTime

/**
 * Dessine TOUS les widgets Phase posés (grand et compact), avec un seul calcul.
 * Appelé par les providers, par le receiver d'alarme et par les événements système.
 */
object WidgetRenderer {
    private const val KEY_PLANNING = "planning_json"
    private const val KEY_ALARMS = "alarm_block_ids"

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

        // Le bloc suivant a-t-il une alarme active ?
        val alarmIds = readAlarmIds(prefs)
        val nextHasAlarm = state.nextBlockId != null && state.nextBlockId in alarmIds

        for (id in bigIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_planning)
            bind(context, views, state, now, nextHasAlarm, compact = false)
            manager.updateAppWidget(id, views)
        }
        for (id in smallIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_planning_small)
            bind(context, views, state, now, nextHasAlarm, compact = true)
            manager.updateAppWidget(id, views)
        }

        // Programme la prochaine mise à jour, même si l'app est fermée.
        WidgetScheduler.scheduleNext(context, state, now)
    }

    /** Liste des identifiants de blocs dont l'alarme est active (envoyée par l'app Flutter). */
    private fun readAlarmIds(prefs: SharedPreferences): Set<String> {
        val raw = prefs.getString(KEY_ALARMS, null) ?: return emptySet()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { array.getString(it) }.toSet()
        } catch (e: Exception) {
            emptySet() // JSON illisible : on n'affiche simplement pas l'icône
        }
    }

    private fun bind(
        context: Context,
        views: RemoteViews,
        state: WidgetState,
        now: LocalDateTime,
        nextHasAlarm: Boolean,
        compact: Boolean,
    ) {
        views.setTextViewText(R.id.title, WidgetLabels.title(state))
        views.setTextViewText(R.id.next, WidgetLabels.nextLine(state, now))

        // Petite icône d'alarme avant « Ensuite : … » si le bloc suivant a une alarme active.
        views.setViewVisibility(R.id.next_alarm, if (nextHasAlarm) View.VISIBLE else View.GONE)

        // Ligne pomodoro (« Focus 2/4 », « Pause · 3 min »).
        // Dans le widget compact, elle est sur la même rangée que « Ensuite » : on ajoute un séparateur.
        val subText = WidgetLabels.subLine(state.sub, now)
        if (subText != null) {
            views.setTextViewText(R.id.sub, if (compact) "$subText ·" else subText)
            views.setViewVisibility(R.id.sub, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.sub, View.GONE)
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