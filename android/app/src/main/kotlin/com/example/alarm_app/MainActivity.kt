package com.example.alarm_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.ContextCompat.getSystemService
import android.app.AlarmManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends FlutterActivity to integrate with Flutter engine.
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm_app/settings"

    // Configures the Flutter engine and sets up the method channel for communication.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSettingsForExactAlarm" -> {
                    openSettingsForExactAlarm()
                    result.success(true)
                }
                "checkExactAlarmPermission" -> {
                    val hasPermission = checkExactAlarmPermission()
                    result.success(hasPermission)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Opens the settings page where users can enable the exact alarm permission.
    private fun openSettingsForExactAlarm() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
            startActivity(intent)
        }
    }

    // Checks if the app has the permission to schedule exact alarms.
    private fun checkExactAlarmPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true // Prior to Android S, no such permission is required
        }
    }
}
