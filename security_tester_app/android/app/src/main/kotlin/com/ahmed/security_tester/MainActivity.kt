package com.ahmed.security_tester

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.NetworkInterface


class MainActivity : FlutterActivity() {
    private val channel = "misc_tools"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "check_vpn" -> {
                    val metadata = hashMapOf<String, Boolean>()
                    var isVPNConnected = false

                    val l = NetworkInterface.getNetworkInterfaces()
                    if (l != null) {
                        for (intf in l) {
                            if (!intf.isUp || intf.interfaceAddresses.isEmpty()) continue
                            if (intf.name == "tun0" || intf.name == "ppp0") {
                                isVPNConnected = true
                                metadata["interface_name"] = true
                            }
                        }
                    }

                    val conMgr =
                        context.getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager

                    val caps = conMgr.getNetworkCapabilities(conMgr.activeNetwork)
                    if (caps != null) {
                        if (caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                            isVPNConnected = true
                            metadata["transport_vpn"] = true
                        }
                    }

                    // I really hate Java ecosystems and their lack of consistency
                    // For more
                    // - https://developer.android.com/reference/android/net/ConnectivityManager#getAllNetworks()
                    // - https://developer.android.com/reference/android/net/ConnectivityManager#getNetworkInfo(int)

                    @Suppress("DEPRECATION")
                    if (conMgr.getNetworkInfo(17)?.isConnectedOrConnecting == true
                        || conMgr.getNetworkInfo(17)?.isConnectedOrConnecting == null
                    ) {
                        isVPNConnected = true
                        metadata["network_info"] = true
                    }

                    val data = hashMapOf<String, Any>()
                    data["is_vpn_connected"] = isVPNConnected
                    if(isVPNConnected) {
                        data["metadata"] = metadata
                    }
                    result.success(data)
                }

                "check_display_settings" -> {
                    val data = mutableListOf<HashMap<String, Any>>()

                    try {
                        val displayManager =
                            context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                        val displays = displayManager.displays
                        for (display in displays) {
                            val displayInfo = hashMapOf<String, Any>()
                            displayInfo["display_id"] = display.displayId
                            displayInfo["name"] = display.name
                            displayInfo["flags"] = display.flags
                            displayInfo["rotation"] = display.rotation
                            data.add(displayInfo)
                        }
                        result.success(data)
                    } catch (e: Exception) {
                        result.error("FAILED_TO_GET_DISPLAYS", e.message, e)
                    }
                }

                "running_on_external_storage" -> {
                    val isOnExternalStorage = isOnExternalStorage(context)
                    result.success(isOnExternalStorage)
                }

                "telephone_operator_name" -> {
                    try {
                        val tm =
                            context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                        val networkOperatorName = tm.networkOperatorName
                        result.success(networkOperatorName)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }

                "cpu_info" -> {
                    val cpuInfo = getCPUInfo()
                    result.success(cpuInfo)
                }

                else -> {

                    result.notImplemented()
                }
            }
        }
    }

    @SuppressLint("SdCardPath")
    fun isOnExternalStorage(context: Context): Boolean {
        // check for API level 8 and higher
        val pm = context.packageManager
        try {
            val pi = pm.getPackageInfo(context.packageName, 0)
            val ai = pi.applicationInfo
            return ai.flags and ApplicationInfo.FLAG_EXTERNAL_STORAGE == ApplicationInfo.FLAG_EXTERNAL_STORAGE
        } catch (e: PackageManager.NameNotFoundException) {
            // ignore
        }
        // check for API level 7 - check files dir
        try {
            val filesDir = context.filesDir.absolutePath
            if (filesDir.startsWith("/data/")) {
                return false
            } else if (filesDir.contains("/mnt/") || filesDir.contains("/sdcard/")) {
                return true
            }
        } catch (e: Throwable) {
            // ignore
        }
        return false
    }

    private fun getCPUInfo(): HashMap<String, String> {
        val info = hashMapOf<String, String>()
        val f = File("/proc/cpuinfo");
        if (!f.exists() || !f.canRead()) {
            return info
        }
        val skipKeys = setOf("flags")

        val lines = f.readLines()
        for (line in lines) {
            val l = line.trim()
            if (l.isEmpty() || l.isBlank()) continue

            val data = l.split(":")
            if (data.size <= 1) continue

            val key = data[0].trim().replace(" ", "_").lowercase()
            if (key.isEmpty() || key.isBlank()) continue
            if (skipKeys.contains(key)) continue

            val value = data[1].trim().lowercase()
            if (value.isEmpty() || value.isBlank()) continue

            // check if key is already present, if yes, compare
            // the values, if different, add a suffix to the key
            if (info.containsKey(key)) {
                val oldValue = info[key]
                if (oldValue != value) {
                    info[key + "_1"] = value
                }
            } else {
                info[key] = value
            }

        }
        return info
    }

}
