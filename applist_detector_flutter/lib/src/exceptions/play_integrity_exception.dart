enum IntegrityErrorCode {
  // Internal Error codes

  apiNotAvailable,
  appNotInstalled,
  appUidMismatch,
  cannotBindToService,
  googleServerUnavailable,
  internalError,
  networkError,
  noError,
  nonceIsNotBase64,
  nonceTooLong,
  nonceTooShort,
  playServicesNotFound,
  playStoreAccountNotFound,
  playStoreNotFound,
  tooManyRequests,
  playStoreVersionOutdated,
  playServicesVersionOutdated,
  cloudProjectNumberIsInvalid,
  clientTransientError,

  // Custom error codes
  unknownException,
  playServicesNotAvailable,
}

class PlayIntegrityException implements Exception {
  final String message;
  final int errorCode;

  PlayIntegrityException(this.message, this.errorCode);

  IntegrityErrorCode get error => _parseErrorCode(errorCode);

  static IntegrityErrorCode _parseErrorCode(int code) {
    final data = {
      0: IntegrityErrorCode.noError,
      -1: IntegrityErrorCode.apiNotAvailable,
      -2: IntegrityErrorCode.playStoreNotFound,
      -3: IntegrityErrorCode.networkError,
      -4: IntegrityErrorCode.playStoreAccountNotFound,
      -5: IntegrityErrorCode.appNotInstalled,
      -6: IntegrityErrorCode.playServicesNotFound,
      -7: IntegrityErrorCode.appUidMismatch,
      -8: IntegrityErrorCode.tooManyRequests,
      -9: IntegrityErrorCode.cannotBindToService,
      -10: IntegrityErrorCode.nonceTooShort,
      -11: IntegrityErrorCode.nonceTooLong,
      -12: IntegrityErrorCode.googleServerUnavailable,
      -13: IntegrityErrorCode.nonceIsNotBase64,
      -100: IntegrityErrorCode.internalError,
      -14: IntegrityErrorCode.playStoreVersionOutdated,
      -15: IntegrityErrorCode.playServicesVersionOutdated,
      -16: IntegrityErrorCode.cloudProjectNumberIsInvalid,
      -17: IntegrityErrorCode.clientTransientError,
      -55: IntegrityErrorCode.unknownException,
      -66: IntegrityErrorCode.playServicesNotAvailable,
    };
    return data[code] ?? IntegrityErrorCode.internalError;
  }

  @override
  String toString() {
    return 'PlayIntegrityException{$message, code: $errorCode, error: ${_parseErrorCode(errorCode)}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayIntegrityException &&
        other.message == message &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode => message.hashCode ^ errorCode.hashCode;
}
