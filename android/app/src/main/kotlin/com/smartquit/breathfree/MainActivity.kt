package com.smartquit.breathfree

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartquit.breathfree/widget"
    private var pendingInterventionLaunch = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if launched from widget
        if (intent?.getBooleanExtra("launch_intervention", false) == true) {
            pendingInterventionLaunch = true
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Handle widget launch when app is already running
        if (intent.getBooleanExtra("launch_intervention", false)) {
            flutterEngine?.dartExecutor?.let {
                MethodChannel(it.binaryMessenger, CHANNEL).invokeMethod("launchIntervention", null)
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // If there's a pending intervention launch, trigger it now
        if (pendingInterventionLaunch) {
            pendingInterventionLaunch = false
            flutterEngine?.dartExecutor?.let {
                MethodChannel(it.binaryMessenger, CHANNEL).invokeMethod("launchIntervention", null)
            }
        }
    }
}
