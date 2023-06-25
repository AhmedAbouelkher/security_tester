package com.ahmed.applist_detector_flutter.library

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Process
import android.util.Log
import java.io.BufferedReader
import java.io.FileReader


// Borrowed from: https://github.com/GantMan/jail-monkey
// Borrowed from: https://github.com/weikaizhi/AntiDebug
// Borrowed from: https://d3adend.org/blog/posts/android-anti-hooking-techniques-in-java/
class XPosedFramework(context: Context) : IDetector(context) {
    override val name = "XPosed Framework"

    private val dangerousPackages = setOf(
        "de.robv.android.xposed.installer",
        "com.saurik.substrate",
        "de.robv.android.xposed"
    )

    private fun stackChecking(): Result {
        try {
            throw Exception()
        } catch (e: Exception) {
            var zygoteInitCallCount = 0
            for (stackTraceElement in e.stackTrace) {
                if (stackTraceElement.className == "com.android.internal.os.ZygoteInit") {
                    zygoteInitCallCount++
                    if (zygoteInitCallCount == 2) {
                        return Result.FOUND
                    }
                }
                if (stackTraceElement.className == "com.saurik.substrate.MS$2"
                    && stackTraceElement.methodName == "invoked"
                ) {
                    return Result.FOUND
                }

                if (stackTraceElement.className == "de.robv.android.xposed.XposedBridge"
                    && stackTraceElement.methodName == "main"
                ) {
                    return Result.FOUND
                }

                if (stackTraceElement.className == "de.robv.android.xposed.XposedBridge"
                    && stackTraceElement.methodName == "handleHookedMethod"
                ) {
                    return Result.FOUND
                }
            }
        }
        return Result.NOT_FOUND
    }

    private fun jarChecks(): Result {
        val libraries = mutableSetOf<String>()
        try {
            val reader = BufferedReader(FileReader("/proc/${Process.myPid()}/maps"))
            while(true) {
                val line = reader.readLine() ?: break
                if (line.endsWith(".jar")) {
                    val begin = line.indexOf(' ') + 1
                    val end = line.lastIndexOf(' ')
                    libraries.add(line.substring(begin, end))
                }
            }
            reader.close()
        } catch (e: Exception) {
            Log.e("XPosedFramework.jarChecks()", "Checking jar failed", e)
            return Result.SUSPICIOUS
        }

        for (library in libraries) {
            if (library.contains("com.saurik.substrate")) {
                return Result.FOUND
            }
            if (library.contains("XposedBridge.jar")) {
                return Result.FOUND
            }
        }

        return Result.NOT_FOUND
    }

    @SuppressLint("QueryPermissionsNeeded")
    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        var result = Result.NOT_FOUND
        val add: (Pair<String, Result>) -> Unit = {
            result = result.coerceAtLeast(it.second)
            detail?.add(it)
        }
        val packageManager = context.packageManager
        val applicationList = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        for (applicationInfo in applicationList) {
            if (dangerousPackages.contains(applicationInfo.packageName)) {
                add(packageManager.getApplicationLabel(applicationInfo) as String to Result.FOUND)
            }
        }

        add("Stack Check" to stackChecking())
        add("Jar Check" to jarChecks())

        return result
    }

}