package com.example.roeyp

import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val gpsChannelName = "com.example/gps"

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
