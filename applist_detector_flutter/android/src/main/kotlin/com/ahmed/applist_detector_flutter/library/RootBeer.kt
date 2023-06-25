package com.ahmed.applist_detector_flutter.library

import android.content.Context
import com.scottyab.rootbeer.RootBeer

class RootBeerD(context: Context) : IDetector(context) {
    override val name = "Root Beer"

    override fun run(packages: Collection<String>?, detail: Detail?): Result {
        var result = Result.NOT_FOUND
        val add: (Pair<String, Result>) -> Unit = {
            result = result.coerceAtLeast(it.second)
            detail?.add(it)
        }
        val rootBeer = RootBeer(context)
        add("detect_root_management_apps" to if (rootBeer.detectRootManagementApps()) Result.FOUND else Result.NOT_FOUND)
        add("detect_potentially_dangerous_apps" to if (rootBeer.detectPotentiallyDangerousApps()) Result.FOUND else Result.NOT_FOUND)
        add("check_for_dangerous_props" to if (rootBeer.checkForDangerousProps()) Result.FOUND else Result.NOT_FOUND)
        add("check_for_rw_paths" to if (rootBeer.checkForRWPaths()) Result.FOUND else Result.NOT_FOUND)
        add("detect_test_keys" to if (rootBeer.detectTestKeys()) Result.FOUND else Result.NOT_FOUND)
        add("check_su_exists" to if (rootBeer.checkSuExists()) Result.FOUND else Result.NOT_FOUND)
        add("check_for_root_native" to if (rootBeer.checkForRootNative()) Result.FOUND else Result.NOT_FOUND)
        add("check_for_magisk_binary" to if (rootBeer.checkForMagiskBinary()) Result.FOUND else Result.NOT_FOUND)
        return result
    }
}