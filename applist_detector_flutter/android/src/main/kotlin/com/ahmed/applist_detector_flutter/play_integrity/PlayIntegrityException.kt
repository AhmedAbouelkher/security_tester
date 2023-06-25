package com.ahmed.applist_detector_flutter.play_integrity

class PlayIntegrityException(message: String) : Exception(message) {
    var errorCode: Int = 0

    constructor(message: String, errorCode: Int) : this(message) {
        this.errorCode = errorCode
    }

    override fun toString(): String {
        return "PlayIntegrityException(message='$message', errorCode=$errorCode)"
    }
}
