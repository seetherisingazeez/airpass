package com.example.airpass

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.os.Handler
import android.os.Looper

/** AirpassPlugin */
class AirpassPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "airpass")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "copyFileAndDeleteOriginal") {
            val sourceUri = call.argument<String>("sourceUri")
            val destinationFilepath = call.argument<String>("destinationFilepath")

            if (sourceUri == null || destinationFilepath == null) {
                result.error("INVALID_ARGS", "sourceUri and destinationFilepath are required", null)
                return
            }

            // Run in a background thread to prevent ANRs
            Thread {
                try {
                    val uri = android.net.Uri.parse(sourceUri)
                    val contentResolver = context.contentResolver
                    val inputStream = contentResolver.openInputStream(uri)
                    
                    if (inputStream == null) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("FILE_ERROR", "Could not open input stream", null)
                        }
                        return@Thread
                    }
                    
                    val file = java.io.File(destinationFilepath)
                    file.parentFile?.mkdirs()
                    val outputStream = java.io.FileOutputStream(file)
                    
                    inputStream.copyTo(outputStream)
                    inputStream.close()
                    outputStream.close()
                    
                    contentResolver.delete(uri, null, null)
                    
                    Handler(Looper.getMainLooper()).post {
                        result.success(true)
                    }
                } catch (e: Exception) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("COPY_ERROR", e.message, null)
                    }
                }
            }.start()
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
