package com.ahmed.applist_detector_flutter.library

import android.content.Context

typealias Detail = MutableCollection<Pair<String, IDetector.Result>>

fun Detail.toHashMap(): HashMap<String, String> {
    val hashMap = HashMap<String, String>()
    this.forEach {
        hashMap[it.first] = it.second.toString()
    }
    return hashMap
}

abstract class IDetector(protected val context: Context) {
    enum class Result {
        NOT_FOUND,
        METHOD_UNAVAILABLE,
        SUSPICIOUS,
        FOUND
    }

    abstract val name: String

    abstract fun run(packages: Collection<String>?, detail: Detail?): Result
}

