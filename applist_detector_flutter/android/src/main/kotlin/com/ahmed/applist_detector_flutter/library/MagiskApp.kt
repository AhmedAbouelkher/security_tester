package com.ahmed.applist_detector_flutter.library

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import java.io.File
import java.io.IOException
import java.io.InputStream

class MagiskApp(context: Context, private val stubPath: String) : IDetector(context) {

    override val name = "Magisk App"

    private val flags = PackageManager.GET_ACTIVITIES or PackageManager.GET_SERVICES or
            PackageManager.GET_PROVIDERS or PackageManager.GET_RECEIVERS or
            PackageManager.MATCH_DIRECT_BOOT_AWARE or PackageManager.MATCH_DIRECT_BOOT_UNAWARE or
            PackageManager.GET_PERMISSIONS

    private val stubInfo by lazy {
        val archive = context.cacheDir.resolve(stubPath)
        context.assets.open(stubPath).use { input ->
            archive.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        context.packageManager.getPackageArchiveInfo(archive.absolutePath, flags)!!
    }

    @SuppressLint("QueryPermissionsNeeded")
    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        if (packages != null) throw IllegalArgumentException("packages should be null")

        if(stubPath.isBlank() || stubPath.isEmpty()) {
            throw IllegalArgumentException("SubPath is empty or blank")
        }

        var result = Result.NOT_FOUND
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN)

        for (pkg in pm.queryIntentActivities(intent, PackageManager.MATCH_ALL)) {
            runCatching {
                val pInfo = pm.getPackageInfo(pkg.activityInfo.packageName, flags)
                val aInfo = pInfo.applicationInfo
                val apkFile = File(aInfo.sourceDir)
                val apkSize = apkFile.length() / 1024
                if (apkSize !in 20..40 && apkSize !in 9 * 1024..20 * 1024) return@runCatching
                if (aInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0) return@runCatching
                if (pInfo.activities.size != stubInfo.activities.size) return@runCatching
                if (pInfo.services.size != stubInfo.services.size) return@runCatching
                if (pInfo.receivers.size != stubInfo.receivers.size) return@runCatching
                if (pInfo.providers.size != stubInfo.providers.size) return@runCatching
                val pPermissionSet = pInfo.requestedPermissions.toSet()
                val stubPermissionSet = stubInfo.requestedPermissions.toMutableSet()
                stubPermissionSet.remove("com.android.launcher.permission.INSTALL_SHORTCUT")
                if (!pPermissionSet.containsAll(stubPermissionSet)) return@runCatching
                detail?.add(aInfo.packageName to Result.FOUND)
                result = Result.FOUND
            }
        }
        return result
    }
}
