package com.thetork.studentos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "studentos/google")
            .setMethodCallHandler { call, result ->
                if (call.method != "defaultWebClientId") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val id = resources.getIdentifier("default_web_client_id", "string", packageName)
                result.success(if (id == 0) "" else getString(id))
            }
    }
}
