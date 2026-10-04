package com.kimbohy.phase

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Reçoit : l'alarme programmée par WidgetScheduler, mais aussi les événements
 * système (redémarrage, changement d'heure ou de fuseau, mise à jour de l'app).
 * Dans tous les cas : on redessine le widget (ce qui reprogramme la suite).
 */
class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetRenderer.updateAll(context)
    }
}