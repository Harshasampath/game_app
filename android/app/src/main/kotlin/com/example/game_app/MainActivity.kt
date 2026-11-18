package com.amazing_game.game_app

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val cameraManager: CameraManager
        get() = getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private var activeTorchId: String? = null
    private var foreground = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "game_app/voyager_torch")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isAvailable" -> result.success(findTorch() != null)
                        "setKeepAwake" -> {
                            if (call.argument<Boolean>("enabled") == true && foreground) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            }
                            result.success(null)
                        }
                        "setTorch" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            if (enabled && !foreground) {
                                result.error("INACTIVE", "Return to the app to send a signal.", null)
                            } else {
                                val id = if (enabled) activeTorchId ?: findTorch() else activeTorchId
                                if (id == null && enabled) {
                                    result.error("NO_TORCH", "This device has no flashlight.", null)
                                } else {
                                    if (id != null) cameraManager.setTorchMode(id, enabled)
                                    activeTorchId = if (enabled) id else null
                                    result.success(null)
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("TORCH_UNAVAILABLE", "Flashlight unavailable. Close other camera apps and try again.", null)
                }
            }
    }

    private fun findTorch(): String? = cameraManager.cameraIdList.firstOrNull {
        cameraManager.getCameraCharacteristics(it)
            .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
    }

    override fun onResume() {
        super.onResume()
        foreground = true
    }

    override fun onPause() {
        foreground = false
        try {
            activeTorchId?.let { cameraManager.setTorchMode(it, false) }
        } catch (_: Exception) {
            // The camera may already have been reclaimed by the system.
        }
        activeTorchId = null
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onPause()
    }
}
