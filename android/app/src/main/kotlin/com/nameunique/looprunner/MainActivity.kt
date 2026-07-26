package com.nameunique.looprunner

import android.content.Intent
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        window.decorView.post(::hideNavigationBar)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.post(::hideNavigationBar)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESULT_SHARER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != SHARE_TEXT_METHOD) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    val text = call.argument<String>("text")
                    if (text.isNullOrBlank()) {
                        result.error(
                            "invalid_arguments",
                            "A non-empty text value is required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    val subject = call.argument<String>("subject")
                    val chooserTitle = call.argument<String>("chooserTitle")
                    val shareIntent =
                        Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            if (!subject.isNullOrBlank()) {
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                            }
                        }

                    startActivity(Intent.createChooser(shareIntent, chooserTitle))
                    result.success(null)
                } catch (exception: Exception) {
                    result.error("share_failed", exception.message, null)
                }
            }
    }

    private fun hideNavigationBar() {
        WindowCompat.getInsetsController(window, window.decorView).apply {
            systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            hide(WindowInsetsCompat.Type.navigationBars())
        }
    }

    private companion object {
        const val RESULT_SHARER_CHANNEL = "com.nameunique.looprunner/result_sharer"
        const val SHARE_TEXT_METHOD = "shareText"
    }
}
