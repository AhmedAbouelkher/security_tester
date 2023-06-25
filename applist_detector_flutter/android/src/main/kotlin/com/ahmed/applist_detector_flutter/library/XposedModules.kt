package com.ahmed.applist_detector_flutter.library

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class XposedModules(context: Context, private val lspatch: Boolean = false) : IDetector(context) {
    override val name = "Xposed Modules"

    @SuppressLint("QueryPermissionsNeeded")
    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        if (packages != null) throw IllegalArgumentException("packages should be null")

        var result = Result.NOT_FOUND
        val pm = context.packageManager
        val set = if (detail == null) null else mutableSetOf<Pair<String, Result>>()
        val intent = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        var meta = "";
        var meta2 = ""
        if (lspatch) {
            meta = "lspatch"
            meta2 = "jshook"
        } else {
            meta = "xposedminversion"
            meta2 = "xposeddescription"
        }
        for (pkg in intent) {
            if (pkg.metaData?.get(meta) != null || pkg.metaData?.get(meta2) != null) {
                val label = pm.getApplicationLabel(pkg) as String
                result = Result.FOUND
                set?.add(label to Result.FOUND)
            }
        }
        if (set.isNullOrEmpty()) {
            val intent =
                pm.queryIntentActivities(Intent(Intent.ACTION_MAIN), PackageManager.GET_META_DATA)
            for (pkg in intent) {
                val ainfo = pkg.activityInfo.applicationInfo
                if (lspatch) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        if (ainfo.appComponentFactory?.contains("lsposed") == true
                        ) {
                            val label = pm.getApplicationLabel(ainfo) as String
                            result = Result.FOUND
                            set?.add("$label(Api28)" to Result.FOUND)
                        }
                    }
                }
                if (ainfo.metaData?.get(meta) != null || ainfo.metaData?.get(meta2) != null) {
                    val label = pm.getApplicationLabel(ainfo) as String
                    result = Result.FOUND
                    set?.add(label to Result.FOUND)
                }
            }
        }
        detail?.addAll(set!!)
        return result
    }
}
