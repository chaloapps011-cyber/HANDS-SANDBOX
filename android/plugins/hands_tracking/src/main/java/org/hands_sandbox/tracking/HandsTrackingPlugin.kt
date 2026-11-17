package org.hands_sandbox.tracking

import org.godotengine.godot.GodotPlugin
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.UsedByGodot
import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/** CameraX and MediaPipe integration. Camera permission is requested by the Godot startup screen. */
class HandsTrackingPlugin(godot: Godot) : GodotPlugin(godot) {
    private val cameraExecutor = Executors.newSingleThreadExecutor()
    private val latestFrame = AtomicReference<Map<String, Any>>(emptyMap())
    @Volatile private var cameraProvider: ProcessCameraProvider? = null
    @Volatile private var handLandmarker: HandLandmarker? = null
    @Volatile private var cameraRunning = false
    @Volatile private var permissionRequested = false

    override fun getPluginName() = "HandsTracking"

    @UsedByGodot
    fun hasCameraPermission(): Boolean = ContextCompat.checkSelfPermission(
        activity, Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED

    @UsedByGodot
    fun requestCameraPermission() {
        if (!permissionRequested && !hasCameraPermission()) {
            permissionRequested = true
            activity.runOnUiThread {
                activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
            }
        }
    }

    @UsedByGodot
    fun isCameraRunning(): Boolean = cameraRunning

    @UsedByGodot
    fun startTracking(): Boolean {
        if (!hasCameraPermission()) return false
        if (cameraRunning) return true
        cameraExecutor.execute {
            try {
                val options = HandLandmarker.HandLandmarkerOptions.builder()
                    .setBaseOptions(BaseOptions.builder().setModelAssetPath(MODEL_ASSET).build())
                    .setNumHands(MAX_HANDS)
                    .setMinHandDetectionConfidence(MIN_CONFIDENCE)
                    .setMinHandPresenceConfidence(MIN_CONFIDENCE)
                    .setMinTrackingConfidence(MIN_CONFIDENCE)
                    .setRunningMode(RunningMode.LIVE_STREAM)
                    .setResultListener(this::onLandmarks)
                    .setErrorListener { error -> latestFrame.set(mapOf("error" to (error.message ?: "MediaPipe error"), "timestamp_ms" to SystemClock.uptimeMillis(), "camera_active" to cameraRunning, "hands" to emptyList<Map<String, Any>>())) }
                    .build()
                handLandmarker = HandLandmarker.createFromOptions(activity, options)
                val providerFuture = ProcessCameraProvider.getInstance(activity)
                providerFuture.addListener({
                    try {
                        val provider = providerFuture.get()
                        val analysis = ImageAnalysis.Builder()
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                            .build()
                        analysis.setAnalyzer(cameraExecutor, ::analyzeFrame)
                        provider.unbindAll()
                        provider.bindToLifecycle(activity, CameraSelector.DEFAULT_FRONT_CAMERA, analysis)
                        cameraProvider = provider
                        cameraRunning = true
                    } catch (error: Exception) {
                        publishError(error)
                    }
                }, ContextCompat.getMainExecutor(activity))
            } catch (error: Exception) {
                publishError(error)
            }
        }
        return true
    }

    private fun analyzeFrame(proxy: ImageProxy) {
        try {
            val source = proxy.toBitmap()
            val matrix = Matrix().apply {
                postRotate(proxy.imageInfo.rotationDegrees.toFloat())
                postScale(-1f, 1f)
            }
            val upright = Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
            if (upright !== source) source.recycle()
            val image = BitmapImageBuilder(upright).build()
            handLandmarker?.detectAsync(image, SystemClock.uptimeMillis())
        } catch (error: Exception) {
            publishError(error)
        } finally {
            proxy.close()
        }
    }

    private fun onLandmarks(result: HandLandmarkerResult, input: com.google.mediapipe.framework.image.MPImage) {
        val sides = result.handedness()
        val hands = result.landmarks().mapIndexed { handIndex, points ->
            val category = sides.getOrNull(handIndex).orEmpty().firstOrNull()
            val landmarks = points.map { point -> mapOf("x" to point.x().toDouble(), "y" to point.y().toDouble(), "z" to point.z().toDouble()) }
            mapOf("side" to (category?.categoryName() ?: "Unknown"), "confidence" to (category?.score()?.toDouble() ?: 0.0), "landmarks" to landmarks)
        }
        latestFrame.set(mapOf("timestamp_ms" to result.timestampMs(), "camera_active" to cameraRunning, "hands" to hands))
    }

    @UsedByGodot
    fun getLatestFrame(): Map<String, Any> {
        val frame = latestFrame.get()
        val timestamp = frame["timestamp_ms"] as? Long ?: -1L
        if (!cameraRunning || timestamp < 0L || SystemClock.uptimeMillis() - timestamp > TRACKING_TIMEOUT_MS) {
            return mapOf("timestamp_ms" to timestamp, "camera_active" to cameraRunning, "hands" to emptyList<Map<String, Any>>())
        }
        return frame
    }

    @UsedByGodot
    fun stopTracking() {
        cameraRunning = false
        cameraExecutor.execute {
            cameraProvider?.unbindAll()
            cameraProvider = null
            handLandmarker?.close()
            handLandmarker = null
            latestFrame.set(emptyMap())
        }
    }

    private fun publishError(error: Exception) {
        latestFrame.set(mapOf("timestamp_ms" to SystemClock.uptimeMillis(), "camera_active" to false, "hands" to emptyList<Map<String, Any>>(), "error" to (error.message ?: error.javaClass.simpleName)))
        cameraRunning = false
    }

    override fun onMainDestroy() {
        stopTracking()
        cameraExecutor.shutdown()
    }

    companion object {
        private const val CAMERA_PERMISSION_REQUEST = 7403
        private const val MODEL_ASSET = "hand_landmarker.task"
        private const val MAX_HANDS = 2
        private const val MIN_CONFIDENCE = 0.5f
        private const val TRACKING_TIMEOUT_MS = 750L
    }
}
