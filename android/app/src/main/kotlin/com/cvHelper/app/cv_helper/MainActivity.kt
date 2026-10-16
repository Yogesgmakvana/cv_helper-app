package com.cvHelper.app.cv_helper

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.content.ContentValues
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "cv_helper/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "savePdf" -> {
                            val fileName = call.argument<String>("fileName")
                            val bytes = call.argument<ByteArray>("bytes")
                            if (fileName.isNullOrBlank() || bytes == null) {
                                result.error("INVALID_PDF", "PDF name and contents are required", null)
                                return@setMethodCallHandler
                            }
                            result.success(savePdf(fileName, bytes))
                        }
                        "openSavedPdf" -> {
                            val savedLocation = call.argument<String>("location")
                            if (savedLocation.isNullOrBlank()) {
                                result.error("INVALID_LOCATION", "No saved PDF location was provided", null)
                                return@setMethodCallHandler
                            }
                            val parsed = Uri.parse(savedLocation)
                            val uri = if (parsed.scheme == "file") {
                                FileProvider.getUriForFile(
                                    this,
                                    "$packageName.fileProvider.com.crazecoder.openfile",
                                    File(parsed.path!!),
                                )
                            } else if (parsed.scheme == null) {
                                FileProvider.getUriForFile(
                                    this,
                                    "$packageName.fileProvider.com.crazecoder.openfile",
                                    File(savedLocation),
                                )
                            } else parsed
                            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/pdf")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(viewIntent)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("DOWNLOAD_ACTION_FAILED", error.message, null)
                }
            }
    }

    private fun savePdf(fileName: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/CV Helper")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create the PDF in Downloads")
            try {
                contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                    ?: throw IllegalStateException("Could not write the PDF to Downloads")
                val published = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
                contentResolver.update(uri, published, null, null)
                return uri.toString()
            } catch (error: Exception) {
                contentResolver.delete(uri, null, null)
                throw error
            }
        }

        val downloads = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw IllegalStateException("Device Downloads storage is unavailable")
        val output = File(downloads, fileName)
        output.writeBytes(bytes)
        return Uri.fromFile(output).toString()
    }
}
