#include <algorithm>
#include <jni.h>
#include <linux_syscall_support.h>
#include <sys/stat.h>

volatile bool syscallFailed;

enum Result {
    NOT_FOUND, METHOD_UNAVAILABLE, SUSPICIOUS, FOUND
} result;

void SignalHandler(int) {
    syscallFailed = true;
}

void UpdateResult(Result out) {
    result = std::max(result, out);
}

void SyscallDetect(int call) {
    UpdateResult(syscallFailed ? METHOD_UNAVAILABLE : (call == 0 || errno == EPERM ? FOUND : NOT_FOUND));
    syscallFailed = false;
}

void FileDetection(const char* path, jboolean useSyscall) {
    syscallFailed = false;
    result = NOT_FOUND;
    if (useSyscall) {
        signal(SIGSYS, SignalHandler);
        SyscallDetect(syscall(SYS_faccessat, AT_FDCWD, path, 0));
    } else {
        struct stat buf {};
        UpdateResult(access(path, F_OK) == 0 ? FOUND : NOT_FOUND);
        UpdateResult(stat(path, &buf) == 0 ? FOUND : NOT_FOUND);
        UpdateResult(fstat(open(path, O_PATH), &buf) == 0 ? FOUND : NOT_FOUND);
    }
}

extern "C" JNIEXPORT jint JNICALL
Java_com_ahmed_applist_1detector_1flutter_library_FileDetection_nativeDetect(JNIEnv* env, jclass, jstring path, jboolean useSyscall) {
    const char* cpath = env->GetStringUTFChars(path, nullptr);
    FileDetection(cpath, useSyscall);
    env->ReleaseStringUTFChars(path, cpath);
    return result;
}
