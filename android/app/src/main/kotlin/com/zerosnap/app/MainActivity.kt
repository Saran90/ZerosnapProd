package com.zerosnap.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.zerosnap.app/cache"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearCache" -> {
                        try {
                            clearAppCache()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("CACHE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun clearAppCache() {
        // Clear cache directory
        val cacheDir = cacheDir
        deleteDir(cacheDir)

        // Clear external cache directory if available
        val externalCacheDir = externalCacheDir
        if (externalCacheDir != null) {
            deleteDir(externalCacheDir)
        }

        // Clear app's code cache
        try {
            val codeCacheDir = codeCacheDir
            deleteDir(codeCacheDir)
        } catch (e: Exception) {
            // Code cache might not be available on all devices
        }
    }

    private fun deleteDir(dir: File?): Boolean {
        if (dir != null && dir.isDirectory) {
            val children = dir.listFiles()
            if (children != null) {
                for (child in children) {
                    deleteDir(child)
                }
            }
        }
        return dir?.delete() ?: false
    }
}
