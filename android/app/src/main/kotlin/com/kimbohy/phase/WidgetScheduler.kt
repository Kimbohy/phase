package com.kimbohy.phase

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.Duration
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * Programme la PROCHAINE mise à jour du widget : soit la prochaine frontière
 * (début/fin de bloc, changement de focus/pause), soit un « tick » de 5 minutes
 * pour faire avancer la jauge, selon ce qui arrive en premier.
 */
object WidgetScheduler {
    private const val REQUEST_CODE = 4242
    private val TICK: Duration = Duration.ofMinutes(5)

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetUpdateReceiver::class.java)
        return PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun scheduleNext(context: Context, state: WidgetState, now: LocalDateTime) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = pendingIntent(context)

        val boundary = state.nextBoundary
        if (state.kind == "empty" || boundary == null) {
            alarmManager.cancel(pending) // rien à afficher : pas d'alarme
            return
        }

        var trigger = boundary.plusSeconds(1) // juste APRÈS la frontière
        val tick = now.plus(TICK)
        if (tick.isBefore(trigger)) trigger = tick

        val millis = trigger.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()

        try {
            val canBeExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
            if (canBeExact) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pending)
            } else {
                // Permission « alarmes exactes » absente : le widget reste utilisable, un peu moins précis.
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pending)
            }
        } catch (e: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, millis, pending)
        }
    }
}