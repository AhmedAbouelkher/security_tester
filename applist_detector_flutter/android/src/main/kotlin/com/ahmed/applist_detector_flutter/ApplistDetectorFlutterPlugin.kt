package com.ahmed.applist_detector_flutter

import android.content.Context
import android.util.Log
import com.ahmed.applist_detector_flutter.library.*
import com.ahmed.applist_detector_flutter.play_integrity.PlayIntegrity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// tag
private const val TAG = "ApplistDetectorFlutterPlugin"

/** ApplistDetectorFlutterPlugin */
class ApplistDetectorFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.ahmed/applist_detector_flutter"
        )
        channel.setMethodCallHandler(this)

        try {
            System.loadLibrary("applist_detector")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load applist_detector library", e)
            val data = hashMapOf(
                "error" to (e.message ?: "Unknown error")
            )
            channel.invokeMethod("native_library_load_failed_callback", data)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "abnormal_environment" -> {
                checkAbnormalEnv(result)
                return
            }

            "file_detection" -> {
                checkFileDetection(call, result)
                return
            }


            "xposed_framework" -> {
                checkXposedFramework(call, result)
                return
            }

            "xposed_modules" -> {
                checkXposedModules(call, result)
                return
            }

            "magisk_app" -> {
                checkMagiskApp(result)
                return
            }

            "pm_command" -> {
                checkPMCommand(call, result)
                return
            }

            "pm_conventional_apis" -> {
                checkConventionalAPIS(call, result)
                return
            }

            "pm_sundry_apis" -> {
                checkSundryAPIS(call, result)
                return
            }

            "pm_query_intent_activities" -> {
                checkPMQueryIntentActivities(call, result)
                return
            }

            "settings_props" -> {
                checkSettingsProps(call, result)
                return
            }

            "emulator_check" -> {
                checkEmulator(call, result)
                return
            }

            "integrity_api_check" -> {
                integrityApiCheck(call, result)
                return
            }

            "root_beer_check" -> {
                rootBeerCheck(call, result)
                return
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkAbnormalEnv(result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val dtc = AbnormalEnvironment(context)
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("ABNORMAL_ENV_CHECK_FAILED", e.message, null)
        }
    }

    private fun checkFileDetection(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()

        val useSysCall = call.argument<Boolean>("use_syscall") ?: false
        val packages = call.argument<List<String>>("packages") ?: emptyList()
        if (packages.isEmpty()) {
            result.error("MAGISK_DETECTION_FAILED", "No packages to check", null)
            return
        }

        try {
            val dtc = FileDetection(context, useSysCall)
            val r = dtc.run(packages, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("FILE_DETECTION_FAILED", e.message, null)
        }
    }
    private fun checkXposedFramework(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val dtc = XPosedFramework(context)
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("XPOSED_DETECTION_FAILED", e.message, null)
        }
    }


    private fun checkXposedModules(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        val lspatch = call.argument<Boolean>("lspatch") ?: false
        try {
            val dtc = XposedModules(context, lspatch)
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("XPOSED_MODULES_DETECTION_FAILED", e.message, null)
        }
    }

    private fun checkMagiskApp(result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val dtc = MagiskApp(context, "stub-release.apk")
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("MAGISK_DETECTION_FAILED", e.message, null)
        }
    }

    private fun checkPMCommand(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()

        val packages = call.argument<List<String>>("packages") ?: emptyList()
        if (packages.isEmpty()) {
            result.error("CHECK_PM_COMMAND_FAILED", "No packages to check", null)
            return
        }

        try {
            val dtc = PMCommand(context)
            val r = dtc.run(packages, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_PM_COMMAND_FAILED", e.message, null)
        }
    }

    private fun checkConventionalAPIS(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()

        val packages = call.argument<List<String>>("packages") ?: emptyList()
        if (packages.isEmpty()) {
            result.error("CHECK_PM_CONVENTIONAL_APIS_FAILED", "No packages to check", null)
            return
        }

        try {
            val dtc = PMConventionalAPIs(context)
            val r = dtc.run(packages, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_PM_CONVENTIONAL_APIS_FAILED", "No packages to check", null)
        }
    }

    private fun checkSundryAPIS(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()

        val packages = call.argument<List<String>>("packages") ?: emptyList()
        if (packages.isEmpty()) {
            result.error("CHECK_PM_SUNDRY_APIS_FAILED", "No packages to check", null)
            return
        }

        try {
            val dtc = PMSundryAPIs(context)
            val r = dtc.run(packages, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_PM_SUNDRY_APIS_FAILED", "No packages to check", null)
        }
    }

    private fun checkPMQueryIntentActivities(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()

        val packages = call.argument<List<String>>("packages") ?: emptyList()
        if (packages.isEmpty()) {
            result.error("CHECK_PM_QUERY_INTENT_ACTIVITIES", "No packages to check", null)
            return
        }

        try {
            val dtc = PMQueryIntentActivities(context)
            val r = dtc.run(packages, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_PM_QUERY_INTENT_ACTIVITIES", "No packages to check", null)
        }
    }

    private fun checkSettingsProps(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val dtc = SettingsProps(context)
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_SETTINGS_PROPS_FAILED", e.message, null)
        }
    }

    private fun checkEmulator(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val dtc = EmulatorCheck(context)
            val r = dtc.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("CHECK_EMULATOR_FAILED", e.message, null)
        }
    }

    private fun integrityApiCheck(call: MethodCall, result: Result) {
        val integrity = PlayIntegrity(context)

        val nonce = call.argument<String>("nonce_string") ?: ""

        try {
            integrity.execute(nonce) { token, e ->
                if (e != null) {
                    val data = hashMapOf("error_code" to e.errorCode)
                    result.error("INTEGRITY_API_EXCEPTION", e.message, data)
                    return@execute
                }
                val data = hashMapOf("token" to token)
                result.success(data)
            }
        } catch (e: Exception) {
            result.error("INTEGRITY_API_FAILED", e.message, null)
        }
    }

    private fun rootBeerCheck(call: MethodCall, result: Result) {
        val detail = mutableListOf<Pair<String, IDetector.Result>>()
        try {
            val rootBeer = RootBeerD(context)
            val r = rootBeer.run(null, detail)

            val data = HashMap<String, Any>()
            data["type"] = r.toString()
            data["details"] = detail.toHashMap()
            result.success(data)
        } catch (e: Exception) {
            result.error("ROOT_BEER_CHECKS_FAILED", e.message, null)
        }
    }
}
