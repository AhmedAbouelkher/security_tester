package com.ahmed.applist_detector_flutter.library

import android.content.Context
import java.io.BufferedReader
import java.io.FileInputStream
import java.io.InputStreamReader

class AbnormalEnvironment(context: Context) : IDetector(context) {
    override val name = "Abnormal Environment"

    private fun checkProcSelfMaps(): Boolean {
        var susMapsString = false
        try {
            val ret = StringBuilder()
            val smapsFile = FileInputStream("/proc/self/smaps")
            val mapsFile = FileInputStream("/proc/self/maps")
            val files = listOf(smapsFile, mapsFile)
            for (f in files) {
                lateinit var reader: InputStreamReader
                lateinit var bufReader: BufferedReader
                try {
                    reader = InputStreamReader(f, Charsets.UTF_8)
                    bufReader = BufferedReader(reader)

                    while (true) {
                        val line = bufReader.readLine() ?: break
                        val l = line.split("/", "_", "-").toString()
                        if (l.contains(".magisk", ignoreCase = true)
                            || (l.contains("riru", ignoreCase = true)
                                    || (l.contains("zygisk", ignoreCase = true)))
                        ) {
                            ret.append(l).append('\n')
                        }
                    }
                } catch (e: Exception) {
                    // do nothing
                } finally {
                    bufReader.close()
                    reader.close()
                }

                susMapsString = ret.isNotEmpty()
            }
            smapsFile.close()
            mapsFile.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return susMapsString
    }

    private external fun detectXposed(): Boolean

    private fun detectDual(): Result {
        val filedir = context.filesDir.path
        return if (filedir.startsWith("/data/user") && !filedir.startsWith("/data/user/0"))
            Result.SUSPICIOUS
        else Result.NOT_FOUND
    }

    private fun detectFile(path: String): Result {
        var res = FileDetection.detect(path, true)
        if (res == Result.METHOD_UNAVAILABLE) res = FileDetection.detect(path, false)
        if (res == Result.FOUND) res = Result.SUSPICIOUS
        return res
    }

    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        if (packages != null) throw IllegalArgumentException("packages should be null")

        val susSelfMaps = checkProcSelfMaps()

        var result = Result.NOT_FOUND
        val add: (Pair<String, Result>) -> Unit = {
            result = result.coerceAtLeast(it.second)
            detail?.add(it)
        }
        add("Xposed hooks" to if (detectXposed()) Result.FOUND else Result.NOT_FOUND)
        add("Dual / Work profile" to detectDual())
        add(Pair("HMA (old version)", detectFile("/data/misc/hide_my_applist")))
        add("XPrivacyLua" to detectFile("/data/system/xlua"))
        add(
            "TWRP" to if (detectFile("/storage/emulated/0/TWRP") != Result.NOT_FOUND
                || detectFile("/storage/emulated/TWRP") != Result.NOT_FOUND
            )
                Result.SUSPICIOUS else Result.NOT_FOUND
        )
        add(Pair("Xposed Edge", detectFile("/data/system/xedge")))
        add(Pair("Riru Clipboard", detectFile("/data/misc/clipboard")))
        add(Pair("隐秘空间", detectFile("/data/system/cn.geektang.privacyspace")))
        add(
            Pair(
                "Magisk/Riru/Zygisk Maps Scan",
                if (susSelfMaps) Result.FOUND else Result.NOT_FOUND
            )
        )
        var sufilenum = 0
        var busyboxnum = 0
        var magisknum = 0
        val places = arrayOf(
            "/sbin/",
            "/system/bin/",
            "/system/xbin/",
            "/proc/self/root/bin/",
            "/data/local/xbin/",
            "/data/local/bin/",
            "/system/sd/xbin/",
            "/system/bin/failsafe/",
            "/data/local/",
            "/cache"
        )
        for (where in places) {
            val sufile = where + "su"
            val busyboxfile = where + "busybox"
            val magiskfile = where + "magisk"
            if (detectFile(sufile) != Result.NOT_FOUND) {
                sufilenum += 1
            }
            if (detectFile(busyboxfile) != Result.NOT_FOUND) {
                busyboxnum += 1
            }
            if (detectFile(magiskfile) != Result.NOT_FOUND) {
                magisknum += 1
            }
        }
        add(Pair("Su File", if (sufilenum != 0) Result.FOUND else Result.NOT_FOUND))
        add(
            Pair(
                "Busybox File",
                if (busyboxnum != 0) Result.FOUND else Result.NOT_FOUND
            )
        )
        add(
            Pair(
                "Magisk File",
                if (magisknum != 0) Result.FOUND else Result.NOT_FOUND
            )
        )
        return result
    }


}
