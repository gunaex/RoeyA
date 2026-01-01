package com.example.roeyp

import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val gpsChannelName = "com.example/gps"
    private val shortcutChannelName = "com.example/shortcut"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, gpsChannelName).setMethodCallHandler { call, result ->
            if (call.method == "getMediaStoreGps") {
                val uriString = call.argument<String>("uri")
                if (uriString == null) {
                    result.error("NO_URI", "No URI provided", null)
                    return@setMethodCallHandler
                }
                val uri = Uri.parse(uriString)
                val gps = getGpsFromMediaStore(uri)
                result.success(gps)
            } else {
                result.notImplemented()
            }
        }

        // Handle shortcut actions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shortcutChannelName).setMethodCallHandler { call, result ->
            if (call.method == "getInitialAction") {
                val action = getInitialAction()
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null) {
            val action = getActionFromIntent(intent)
            if (action != null) {
                // Store action to be retrieved by Flutter
                // This will be handled via method channel
            }
        }
    }

    private fun getInitialAction(): String? {
        return getActionFromIntent(intent)
    }

    private fun getActionFromIntent(intent: Intent?): String? {
        if (intent == null) return null
        
        val data = intent.data
        if (data != null && "roeya" == data.scheme) {
            val host = data.host
            val query = data.query
            
            return when (host) {
                "scan-slip" -> "quickScan"
                "manual-entry" -> {
                    if (query?.contains("type=expense") == true) {
                        "quickAddExpense"
                    } else {
                        "quickAdd"
                    }
                }
                else -> null
            }
        }
        return null
    }

    private fun getGpsFromMediaStore(uri: Uri): Map<String, Double>? {
        val projection = arrayOf(
            MediaStore.Images.Media.LATITUDE,
            MediaStore.Images.Media.LONGITUDE
        )
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val latIndex = cursor.getColumnIndex(MediaStore.Images.Media.LATITUDE)
                val lonIndex = cursor.getColumnIndex(MediaStore.Images.Media.LONGITUDE)
                if (latIndex != -1 && lonIndex != -1) {
                    val lat = cursor.getDouble(latIndex)
                    val lon = cursor.getDouble(lonIndex)
                    if (lat != 0.0 || lon != 0.0) {
                        return mapOf("lat" to lat, "lon" to lon)
                    }
                }
            }
        }
        return null
    }
}
