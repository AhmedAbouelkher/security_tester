package com.ahmed.applist_detector_flutter.play_integrity

import android.content.Context
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import com.google.android.play.core.integrity.model.IntegrityErrorCode
import kotlin.math.floor


class PlayIntegrity(private val context: Context) {
    private fun isGoogleServicesAvailable(): Boolean {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val status = googleApiAvailability.isGooglePlayServicesAvailable(context)
        return status == com.google.android.gms.common.ConnectionResult.SUCCESS
    }

    private fun parseErrMsg(msg: String): Int {
        return msg.replace("\n".toRegex(), "")
            .replace(":(.*)".toRegex(), "")
            .toInt()
    }

    private fun errorCodeMsg(code: Int): String {
        return when (code) {
            IntegrityErrorCode.API_NOT_AVAILABLE -> "Integrity API is not available. The Play Store version might be old, try updating it."
            IntegrityErrorCode.APP_NOT_INSTALLED -> "The calling app is not installed. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.APP_UID_MISMATCH -> "The calling app UID (user id) does not match the one from Package Manager. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.CANNOT_BIND_TO_SERVICE -> "Binding to the service in the Play Store has failed. This can be due to having an old Play Store version installed on the device."
            IntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE -> "Unknown internal Google server error."
            IntegrityErrorCode.INTERNAL_ERROR -> "Unknown internal error."
            IntegrityErrorCode.NETWORK_ERROR -> "No available network is found. Please check your connection."
            IntegrityErrorCode.NO_ERROR -> "No error has occurred. If you ever get this, congrats, I have no idea what it means."
            IntegrityErrorCode.NONCE_IS_NOT_BASE64 -> "Nonce is not encoded as a base64 web-safe no-wrap string. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.NONCE_TOO_LONG -> "Nonce length is too long. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.NONCE_TOO_SHORT -> "Nonce length is too short. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.PLAY_SERVICES_NOT_FOUND -> "Play Services is not available or version is too old. Try updating Google Play Services."
            IntegrityErrorCode.PLAY_STORE_ACCOUNT_NOT_FOUND -> "No Play Store account is found on device. Try logging into Play Store."
            IntegrityErrorCode.PLAY_STORE_NOT_FOUND -> "No Play Store app is found on device or not official version is installed. This app can't work without Play Store."
            IntegrityErrorCode.TOO_MANY_REQUESTS -> "The calling app is making too many requests to the API and hence is throttled. This shouldn't happen. If it does please open an issue on Github."
            IntegrityErrorCode.CLOUD_PROJECT_NUMBER_IS_INVALID -> "Use the cloud project number which can be found in Project info in your Google Cloud Console for the cloud project where Play Integrity API is enabled."
            IntegrityErrorCode.CLIENT_TRANSIENT_ERROR -> "Transient error has occurred on the client device."
            else -> "Unknown Error Code"
        }
    }

    private fun parseError(e: Exception): PlayIntegrityException {
        val msg = e.message ?: return PlayIntegrityException("Unknown error", -55)

        val errorCode = parseErrMsg(msg)
        val errMsg = errorCodeMsg(errorCode)
        return PlayIntegrityException(errMsg, errorCode)
    }

    fun execute(nonce: String, callback: (String?, PlayIntegrityException?) -> Unit) {
        val isGoogleServicesAvailable = isGoogleServicesAvailable()
        if (!isGoogleServicesAvailable) {
            callback(null, PlayIntegrityException("Google Play Services is not available", -66))
            return
        }

        val manager = IntegrityManagerFactory.create(context)

        val response =
            manager.requestIntegrityToken(
                IntegrityTokenRequest.builder()
                    .setNonce(nonce)
                    .build()
            )

        response.addOnSuccessListener { resp ->
            val token = resp.token()
            callback(token, null)
        }

        response.addOnFailureListener { exception ->
            callback(null, parseError(exception))
        }
    }
}