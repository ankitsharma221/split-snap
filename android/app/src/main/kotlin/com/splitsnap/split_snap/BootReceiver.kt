package com.splitsnap.split_snap

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Restart background service after device reboot
            val serviceIntent = Intent(context, MainActivity::class.java)
            serviceIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }
}
