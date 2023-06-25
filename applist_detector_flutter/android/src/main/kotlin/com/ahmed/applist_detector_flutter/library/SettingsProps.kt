package com.ahmed.applist_detector_flutter.library

import android.content.Context
import android.os.Debug
import android.provider.Settings
import android.util.Log
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader


private val TAG = SettingsProps::class.java.simpleName

class SettingsProps(context: Context) : IDetector(context) {
    override val name = "Settings Props"

    private fun checkDevOptionsEnabled(): Boolean {
        return Settings.Secure.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
            0
        ) == 1
    }

    private fun getValueFromProp(propName: String): String {
        val line: String
        var input: BufferedReader? = null
        try {
            val p = Runtime.getRuntime().exec("getprop $propName")
            input = BufferedReader(InputStreamReader(p.inputStream), 1024)
            line = input.readLine()
            input.close()
        } catch (ex: IOException) {
            Log.e(TAG, "Unable to read prop $propName", ex)
            return "-"
        } finally {
            if (input != null) {
                try {
                    input.close()
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
        }
        return line
    }

    private fun checkADBEnabled(): Boolean {
        return Settings.Secure.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) > 0
                || getValueFromProp("sys.usb.ffs.ready").contains("1")
                || getValueFromProp("sys.usb.state").contains("adb")
                || getValueFromProp("sys.usb.config").contains("adb")
                || getValueFromProp("persist.sys.usb.reboot.funnc").contains("adb")
                || getValueFromProp("init.svc.adbd").contains("running")
                || getValueFromProp("init.svc.adbd").contains("restarting")
                || getValueFromProp("ro.debuggable").contains("1")
                || getValueFromProp("ro.secure").contains("0")
                || Debug.isDebuggerConnected()
                || Debug.waitingForDebugger()
    }

    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        if (packages != null) throw IllegalArgumentException("packages should be null")
        var result = Result.NOT_FOUND
        val add: (Pair<String, Result>) -> Unit = {
            result = result.coerceAtLeast(it.second)
            detail?.add(it)
        }

        add("Dev Options Enabled" to if (checkDevOptionsEnabled()) Result.SUSPICIOUS else Result.NOT_FOUND)
        add("ADB Enabled" to if (checkADBEnabled()) Result.SUSPICIOUS else Result.NOT_FOUND)

        return result
    }
}