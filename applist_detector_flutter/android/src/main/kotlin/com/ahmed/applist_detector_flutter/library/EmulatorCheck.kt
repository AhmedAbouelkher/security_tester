package com.ahmed.applist_detector_flutter.library

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import java.io.File

class EmulatorCheck(context: Context) : IDetector(context) {
    override val name = "Emulator Check"

    private fun buildChecks(): Boolean {
        return ((Build.BRAND.startsWith("generic")
                && Build.DEVICE.startsWith("generic"))
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.FINGERPRINT.startsWith("google/sdk_gphone_")
                || Build.FINGERPRINT.startsWith(":user/release-keys")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.HARDWARE.contains("vbox86")
                || Build.MODEL.contains("google_sdk ")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.MANUFACTURER.contains("bluestacks", ignoreCase = true)
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))
                || Build.PRODUCT.startsWith("google_sdk")
                || Build.PRODUCT.contains("sdk_x86")
                || Build.PRODUCT.contains("vbox86p")
                || Build.BOARD.lowercase().contains("nox")
                || Build.BOOTLOADER.contains("nox", ignoreCase = true)
                || Build.HARDWARE.contains("nox", ignoreCase = true)
                || Build.PRODUCT.contains("nox", ignoreCase = true)
                || Build.SERIAL.contains("nox", ignoreCase = true)
                || Build.HOST == "ubuntu" // To Avoid False Positives on Oppo Realme Devices
                || Build.BOARD.contains("windows")
                || Build.HARDWARE.contains("windows")
    }

    private fun checkWiredWifi(): Boolean {
        /*
        We can check wired wifi to detect emulator

        Resources:
            - https://stackoverflow.com/questions/68512057/getter-for-connectioninfo-wifiinfo-is-deprecated-deprecated-in-java-api-31
            - https://stackoverflow.com/questions/71549864/is-the-android-wifi-api-really-so-broken-on-android-10
            - https://stackoverflow.com/questions/71281724/getting-wifi-ssid-from-connectivitymanager-networkcapabilities-synchronously
            - https://github.com/fluttercommunity/plus_plugins/tree/main/packages/connectivity_plus/connectivity_plus
            - https://stackoverflow.com/questions/51141970/check-internet-connectivity-android-in-kotlin
         */
        TODO("Implement Check Wifi SSID (wiredssid)")
    }

    private val genyFiles = setOf("/dev/socket/genyd", "/dev/socket/baseband_genyd")
    private val pipes = setOf("/dev/socket/qemud", "/dev/qemu_pipe")
    private val x86Files = setOf(
        "ueventd.android_x86.rc",
        "x86.prop",
        "ueventd.ttVM_x86.rc",
        "init.ttVM_x86.rc",
        "fstab.ttVM_x86",
        "fstab.vbox86",
        "init.vbox86.rc",
        "ueventd.vbox86.rc"
    )
    private val andyFiles = setOf("fstab.andy", "ueventd.andy.rc")
    private val noxFiles = setOf("fstab.nox", "init.nox.rc", "ueventd.nox.rc")

    private fun filesExist(targets: Set<String>): Boolean {
        for (file in targets) {
            if (File(file).exists()) {
                return true
            }
        }
        return false
    }

    // Copied from: https://github.com/mofneko/EmulatorDetector
    private fun checkSusFiles(): Boolean {
        return filesExist(genyFiles)
                || filesExist(pipes)
                || filesExist(x86Files)
                || filesExist(andyFiles)
                || filesExist(noxFiles)
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

    private fun checkDesktopCPUs(v: String): Boolean {
        return v.contains("intel", true)
                || v.contains("amd", true)
                || v.contains("ryzen", true)
    }

    private fun checkCPUInfo(): Boolean {
        val cpuInfo = getCPUInfo()
        if (cpuInfo.isEmpty()) {
            return false
        }

        val vendorID = cpuInfo["vendor_id"] ?: ""
        if (checkDesktopCPUs(vendorID)) return true

        if (cpuInfo.contains("model_name")) {
            val modelName = cpuInfo["model_name"] ?: ""
            if (checkDesktopCPUs(modelName)) return true
        } else {
            val processor = cpuInfo["processor"] ?: ""
            if (checkDesktopCPUs(processor)) return true
        }

        return false
    }

    private fun checkNetworkOperatorName(): Boolean {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val networkOperatorName = tm.networkOperatorName
        return networkOperatorName == "Android"
    }

    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        if (packages != null) throw IllegalArgumentException("packages should be null")

        var result = Result.NOT_FOUND
        val add: (Pair<String, Result>) -> Unit = {
            result = result.coerceAtLeast(it.second)
            detail?.add(it)
        }

        add("basic_checks" to if (buildChecks()) Result.FOUND else Result.NOT_FOUND)

        add("sus_files" to if (checkSusFiles()) Result.FOUND else Result.NOT_FOUND)

        add("cpu" to if (checkCPUInfo()) Result.SUSPICIOUS else Result.NOT_FOUND)

        add("network_operator_name" to if (checkNetworkOperatorName()) Result.SUSPICIOUS else Result.NOT_FOUND)

        return result
    }
}