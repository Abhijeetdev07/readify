package com.example.readify

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.readify/intent"
    private var methodChannel: MethodChannel? = null
    private var pendingPdfMap: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialPdf" -> {
                    val pdfData = pendingPdfMap ?: processIntent(intent)
                    pendingPdfMap = null
                    result.success(pdfData)
                }
                else -> result.notImplemented()
            }
        }

        // Check if there was an initial intent
        pendingPdfMap = processIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val pdfData = processIntent(intent)
        if (pdfData != null) {
            methodChannel?.invokeMethod("onPdfOpened", pdfData) ?: run {
                pendingPdfMap = pdfData
            }
        }
    }

    private fun processIntent(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        val action = intent.action
        val uri: Uri? = intent.data ?: intent.getParcelableExtra(Intent.EXTRA_STREAM)

        if (Intent.ACTION_VIEW == action || Intent.ACTION_SEND == action) {
            if (uri != null) {
                return copyUriToLocalCache(uri)
            }
        }
        return null
    }

    private fun copyUriToLocalCache(uri: Uri): Map<String, String>? {
        return try {
            var fileName = "document.pdf"

            if (uri.scheme == "content") {
                val cursor = contentResolver.query(uri, null, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (nameIndex != -1) {
                            val name = it.getString(nameIndex)
                            if (!name.isNullOrBlank()) {
                                fileName = name
                            }
                        }
                    }
                }
            } else if (uri.scheme == "file") {
                val path = uri.path
                if (path != null) {
                    val file = File(path)
                    if (file.exists()) {
                        return mapOf("path" to file.absolutePath, "name" to file.name)
                    }
                }
            }

            if (!fileName.endsWith(".pdf", ignoreCase = true)) {
                fileName = "$fileName.pdf"
            }

            val cacheDir = File(cacheDir, "opened_pdfs")
            if (!cacheDir.exists()) {
                cacheDir.mkdirs()
            }

            val targetFile = File(cacheDir, fileName)
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream != null) {
                inputStream.use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                    }
                }
                mapOf("path" to targetFile.absolutePath, "name" to fileName)
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
