/* MIT. Código JNI ejecutado dentro del invitado Android. */
#include <jni.h>
static int count;
JNIEXPORT jstring JNICALL Java_cl_miao_nativeprobe_MainActivity_nativeAbi(JNIEnv* env,jclass cls){
 (void)cls;
#if defined(__aarch64__)
 return (*env)->NewStringUTF(env,"arm64-v8a");
#elif defined(__arm__)
 return (*env)->NewStringUTF(env,"armeabi-v7a");
#else
 return (*env)->NewStringUTF(env,"arquitectura inesperada");
#endif
}
JNIEXPORT jint JNICALL Java_cl_miao_nativeprobe_MainActivity_increment(JNIEnv* env,jclass cls){(void)env;(void)cls;return ++count;}
