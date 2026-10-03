package com.kimbohy.phase

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/** Textes affichés par le widget (équivalent de labels.dart). */
object WidgetLabels {
    private val DAY_NAMES = arrayOf("Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim")
    private val HOUR = DateTimeFormatter.ofPattern("HH:mm")

    fun title(state: WidgetState): String = when (state.kind) {
        "block" -> state.title ?: ""
        "free" -> "Libre"
        else -> "Aucun planning"
    }

    fun nextLine(state: WidgetState, now: LocalDateTime): String {
        if (state.kind == "empty") return "Ouvre l'app pour importer ton planning"
        val start = state.nextStart ?: return ""
        val name = state.nextTitle ?: return ""

        val days = ChronoUnit.DAYS.between(now.toLocalDate(), start.toLocalDate())
        val time = start.format(HOUR)
        val whenText = when (days) {
            0L -> time
            1L -> "demain $time"
            else -> "${DAY_NAMES[start.dayOfWeek.value - 1]} $time"
        }
        return "Ensuite : $name · $whenText"
    }

    fun subLine(sub: WSub?, now: LocalDateTime): String? {
        if (sub == null) return null
        if (sub.isFocus) return "Focus ${sub.index}/${sub.total}"
        val seconds = Duration_between(now, sub.endsAt)
        return "Pause · ${(seconds + 59) / 60} min"
    }

    private fun Duration_between(from: LocalDateTime, to: LocalDateTime): Long =
        ChronoUnit.SECONDS.between(from, to).coerceAtLeast(0)
}