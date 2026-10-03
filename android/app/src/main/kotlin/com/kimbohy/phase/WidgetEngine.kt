package com.kimbohy.phase

import org.json.JSONObject
import java.time.Duration
import java.time.LocalDateTime

data class WBlock(
    val id: String,
    val days: Set<Int>,
    val startMin: Int,
    val endMin: Int,
    val name: String,
    val focusMin: Int?,
    val breakMin: Int?,
) {
    val durationMin: Int
        get() = if (endMin <= startMin) 1440 - startMin + endMin else endMin - startMin
}

data class Occ(val block: WBlock, val start: LocalDateTime, val end: LocalDateTime)

data class WSub(val isFocus: Boolean, val index: Int, val total: Int, val endsAt: LocalDateTime) {
    val testLabel: String get() = "${if (isFocus) "focus" else "pause"} $index/$total"
}

data class WidgetState(
    val kind: String, // "block" | "free" | "empty"
    val title: String? = null,
    val progress: Double = 0.0,
    val end: LocalDateTime? = null,
    val sub: WSub? = null,
    val nextTitle: String? = null,
    val nextStart: LocalDateTime? = null,
    val nextBoundary: LocalDateTime? = null,
)

object WidgetEngine {

    fun compute(json: String?, now: LocalDateTime): WidgetState {
        val blocks = parseBlocks(json)
        if (blocks.isEmpty()) return WidgetState(kind = "empty")

        val occurrences = occurrences(blocks, now)
        val current = occurrences.firstOrNull { !it.start.isAfter(now) && it.end.isAfter(now) }
        val next = occurrences.firstOrNull { it.start.isAfter(now) }

        if (current != null) {
            val total = Duration.between(current.start, current.end).toMillis().toDouble()
            val elapsed = Duration.between(current.start, now).toMillis().toDouble()
            val sub = subPhase(current, now)
            return WidgetState(
                kind = "block",
                title = current.block.name,
                progress = (elapsed / total).coerceIn(0.0, 1.0),
                end = current.end,
                sub = sub,
                nextTitle = next?.block?.name,
                nextStart = next?.start,
                nextBoundary = sub?.endsAt ?: current.end,
            )
        }

        if (next == null) return WidgetState(kind = "empty")

        val previousEnd = occurrences.filter { !it.end.isAfter(now) }.maxOfOrNull { it.end }
        var progress = 0.0
        if (previousEnd != null) {
            val total = Duration.between(previousEnd, next.start).toMillis().toDouble()
            val elapsed = Duration.between(previousEnd, now).toMillis().toDouble()
            if (total > 0) progress = (elapsed / total).coerceIn(0.0, 1.0)
        }
        return WidgetState(
            kind = "free",
            progress = progress,
            end = next.start,
            nextTitle = next.block.name,
            nextStart = next.start,
            nextBoundary = next.start,
        )
    }

    private fun parseBlocks(json: String?): List<WBlock> {
        if (json.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONObject(json).getJSONArray("blocks")
            (0 until array.length()).map { i ->
                val o = array.getJSONObject(i)
                val d = o.getJSONArray("d")
                val p = o.optJSONArray("p")
                WBlock(
                    id = o.getString("id"),
                    days = (0 until d.length()).map { d.getInt(it) }.toSet(),
                    startMin = o.getInt("s"),
                    endMin = o.getInt("e"),
                    name = o.getString("n"),
                    focusMin = p?.getInt(0),
                    breakMin = p?.getInt(1),
                )
            }
        } catch (e: Exception) {
            emptyList() // JSON illisible : on affiche « Aucun planning »
        }
    }

    private fun occurrences(blocks: List<WBlock>, now: LocalDateTime): List<Occ> {
        val today = now.toLocalDate()
        val result = mutableListOf<Occ>()
        for (offset in -1L..7L) {
            val date = today.plusDays(offset)
            for (block in blocks) {
                if (date.dayOfWeek.value !in block.days) continue // 1 = lundi ... 7 = dimanche
                val start = date.atStartOfDay().plusMinutes(block.startMin.toLong())
                val end = start.plusMinutes(block.durationMin.toLong())
                result.add(Occ(block, start, end))
            }
        }
        return result.sortedBy { it.start }
    }

    private fun subPhase(o: Occ, now: LocalDateTime): WSub? {
        val focusMin = o.block.focusMin ?: return null
        val breakMin = o.block.breakMin ?: return null

        val totalSec = Duration.between(o.start, o.end).seconds
        val focusSec = focusMin * 60L
        val cycleSec = (focusMin + breakMin) * 60L
        if (focusSec >= totalSec) return null

        val elapsedSec = Duration.between(o.start, now).seconds
        val totalFocus = ((totalSec + cycleSec - 1) / cycleSec).toInt()

        var cycleStart = 0L
        var index = 1
        while (true) {
            if (totalSec - cycleStart <= cycleSec) {
                return WSub(true, index, totalFocus, o.end)
            }
            val focusEnd = cycleStart + focusSec
            val cycleEnd = cycleStart + cycleSec
            if (elapsedSec < focusEnd) return WSub(true, index, totalFocus, o.start.plusSeconds(focusEnd))
            if (elapsedSec < cycleEnd) return WSub(false, index, totalFocus, o.start.plusSeconds(cycleEnd))
            cycleStart = cycleEnd
            index++
        }
    }
}