/**
 * mupdf_jni.cpp — JNI bridge between the Android Kotlin API and MuPDF C engine.
 *
 * Each JNI function corresponds to an `external` (native) function declared in
 * the Kotlin source under com.artifex.mupdf.mobile.
 *
 * Building requires the MuPDF submodule to be initialised:
 *   git submodule update --init --recursive
 *
 * The CMakeLists.txt in the same directory handles finding and linking MuPDF.
 */

#include <jni.h>
#include <android/bitmap.h>
#include <android/log.h>
#include <cinttypes>
#include <cstring>
#include <cstdlib>
#include <string>

// MuPDF headers — available once the submodule is initialised.
// #include "mupdf/fitz.h"
// #include "mupdf/pdf.h"

#define LOG_TAG "MuPDFMobile"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ---------------------------------------------------------------------------
// Utility: throw a Java exception from C++
// ---------------------------------------------------------------------------

static void throwJavaException(JNIEnv *env, const char *className, const char *msg) {
    jclass cls = env->FindClass(className);
    if (cls != nullptr) {
        env->ThrowNew(cls, msg);
    }
}

static void throwMuPDFException(JNIEnv *env, const char *msg) {
    throwJavaException(env,
        "com/artifex/mupdf/mobile/MuPDFEngineException", msg);
}

// ---------------------------------------------------------------------------
// Utility: convert Java String to std::string
// ---------------------------------------------------------------------------

static std::string jstringToString(JNIEnv *env, jstring jstr) {
    if (jstr == nullptr) return {};
    const char *chars = env->GetStringUTFChars(jstr, nullptr);
    std::string result(chars);
    env->ReleaseStringUTFChars(jstr, chars);
    return result;
}

// ---------------------------------------------------------------------------
// MuPDFDocument — native methods
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeOpen(
        JNIEnv *env, jclass /*clazz*/, jstring jpath) {
    std::string path = jstringToString(env, jpath);
    LOGI("nativeOpen: %s", path.c_str());

    // TODO: (requires mupdf submodule)
    // fz_context *ctx = fz_new_context(nullptr, nullptr, FZ_STORE_DEFAULT);
    // if (!ctx) {
    //     throwMuPDFException(env, "Failed to create fz_context");
    //     return -1;
    // }
    // fz_register_document_handlers(ctx);
    // fz_document *doc = nullptr;
    // fz_try(ctx) {
    //     doc = fz_open_document(ctx, path.c_str());
    // }
    // fz_catch(ctx) {
    //     throwMuPDFException(env, fz_caught_message(ctx));
    //     fz_drop_context(ctx);
    //     return -1;
    // }
    // // Store ctx inside the doc handle struct (or use a wrapper struct).
    // return reinterpret_cast<jlong>(doc);

    return -1L; // placeholder
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeOpenFromBytes(
        JNIEnv *env, jclass /*clazz*/, jbyteArray jdata) {
    jsize len = env->GetArrayLength(jdata);
    jbyte *bytes = env->GetByteArrayElements(jdata, nullptr);

    // TODO: (requires mupdf submodule)
    // fz_context *ctx = fz_new_context(nullptr, nullptr, FZ_STORE_DEFAULT);
    // fz_register_document_handlers(ctx);
    // fz_buffer *buf = fz_new_buffer_from_copied_data(ctx,
    //     reinterpret_cast<const unsigned char *>(bytes), static_cast<size_t>(len));
    // fz_stream *stream = fz_open_buffer(ctx, buf);
    // fz_document *doc = nullptr;
    // fz_try(ctx) {
    //     doc = fz_open_document_with_stream(ctx, "application/pdf", stream);
    // }
    // fz_catch(ctx) {
    //     throwMuPDFException(env, fz_caught_message(ctx));
    //     env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
    //     return -1;
    // }
    // env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
    // return reinterpret_cast<jlong>(doc);

    (void)len;
    env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
    return -1L; // placeholder
}

extern "C" JNIEXPORT jint JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageCount(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1) return 0;
    // TODO: auto *doc = reinterpret_cast<fz_document *>(docHandle);
    // return fz_count_pages(ctx, doc);
    return 0;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeLoadPage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1) return -1;
    // TODO:
    // fz_document *doc = reinterpret_cast<fz_document *>(docHandle);
    // fz_page *page = nullptr;
    // fz_try(ctx) {
    //     page = fz_load_page(ctx, doc, index);
    // }
    // fz_catch(ctx) {
    //     throwMuPDFException(env, fz_caught_message(ctx));
    //     return -1;
    // }
    // return reinterpret_cast<jlong>(page);
    (void)env; (void)index;
    return -1L;
}

extern "C" JNIEXPORT jfloat JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageWidth(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1) return 595.0f; // A4 placeholder
    // TODO: load page and call fz_bound_page → width
    (void)index;
    return 595.0f;
}

extern "C" JNIEXPORT jfloat JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageHeight(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1) return 842.0f; // A4 placeholder
    (void)index;
    return 842.0f;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeSave(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jstring jpath) {
    if (docHandle == -1) return JNI_FALSE;
    std::string path = jstringToString(env, jpath);
    // TODO:
    // pdf_document *pdoc = pdf_document_from_fz_document(ctx,
    //     reinterpret_cast<fz_document *>(docHandle));
    // fz_try(ctx) {
    //     pdf_save_document(ctx, pdoc, path.c_str(), nullptr);
    // }
    // fz_catch(ctx) {
    //     return JNI_FALSE;
    // }
    (void)path;
    return JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeMerge(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong dstHandle, jlong srcHandle) {
    if (dstHandle == -1 || srcHandle == -1) return;
    // TODO: pdf_merge_document(ctx, dst, src)
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeInsertBlankPage(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle,
        jint index, jfloat width, jfloat height) {
    if (docHandle == -1) return;
    // TODO: pdf_insert_page, pdf_add_page with mediabox
    (void)index; (void)width; (void)height;
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeDeletePage(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1) return;
    // TODO: pdf_delete_page(ctx, pdfDoc, index)
    (void)index;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetMetadata(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jstring jkey) {
    if (docHandle == -1) return nullptr;
    std::string key = jstringToString(env, jkey);
    // TODO:
    // char buf[256] = {};
    // int n = fz_lookup_metadata(ctx, doc, key.c_str(), buf, sizeof(buf));
    // if (n > 0) return env->NewStringUTF(buf);
    (void)key;
    return nullptr;
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeClose(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1) return;
    LOGI("nativeClose doc handle=%" PRId64, static_cast<int64_t>(docHandle));
    // TODO: fz_drop_document(ctx, doc); fz_drop_context(ctx);
}

// ---------------------------------------------------------------------------
// MuPDFPage — native methods
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeRender(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle,
        jobject bitmap, jfloat scale, jint x, jint y, jint width, jint height) {
    if (pageHandle == -1) return;

    AndroidBitmapInfo info;
    if (AndroidBitmap_getInfo(env, bitmap, &info) < 0) {
        LOGE("AndroidBitmap_getInfo failed");
        return;
    }

    void *pixels = nullptr;
    if (AndroidBitmap_lockPixels(env, bitmap, &pixels) < 0) {
        LOGE("AndroidBitmap_lockPixels failed");
        return;
    }

    // TODO: (requires mupdf submodule)
    // fz_page *page = reinterpret_cast<fz_page *>(pageHandle);
    // fz_matrix matrix = fz_scale(scale, scale);
    // fz_irect clip = fz_make_irect(x, y, x + width, y + height);
    // fz_pixmap *pix = fz_new_pixmap_with_bbox_and_data(ctx,
    //     fz_device_rgb(ctx), clip, nullptr, 1,
    //     static_cast<unsigned char *>(pixels));
    // fz_clear_pixmap_with_value(ctx, pix, 0xFF);
    // fz_device *dev = fz_new_draw_device(ctx, matrix, pix);
    // fz_run_page(ctx, page, dev, fz_identity, nullptr);
    // fz_close_device(ctx, dev);
    // fz_drop_device(ctx, dev);
    // fz_drop_pixmap(ctx, pix);

    // Placeholder: fill with white
    memset(pixels, 0xFF, static_cast<size_t>(info.stride) * static_cast<size_t>(info.height));
    (void)scale; (void)x; (void)y; (void)width; (void)height;

    AndroidBitmap_unlockPixels(env, bitmap);
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeGetAnnotations(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle) {
    (void)pageHandle;
    // TODO: iterate pdf_first_annot / pdf_next_annot
    return env->NewLongArray(0);
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeAddAnnotation(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong pageHandle,
        jint type, jfloat x0, jfloat y0, jfloat x1, jfloat y1) {
    if (pageHandle == -1) return -1;
    // TODO: pdf_create_annot, pdf_set_annot_rect
    (void)type; (void)x0; (void)y0; (void)x1; (void)y1;
    return -1L;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeRemoveAnnotation(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong pageHandle, jlong annotHandle) {
    if (pageHandle == -1 || annotHandle == -1) return JNI_FALSE;
    // TODO: pdf_delete_annot
    return JNI_FALSE;
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeSearch(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle, jstring jtext) {
    (void)pageHandle; (void)jtext;
    // TODO: fz_search_page, return flat array [x0,y0,x1,y1, ...]
    return env->NewFloatArray(0);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeGetTextContent(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle) {
    (void)pageHandle;
    // TODO: fz_new_stext_page, extract text
    return env->NewStringUTF("");
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeClosePage(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong pageHandle) {
    if (pageHandle == -1) return;
    LOGI("nativeClosePage handle=%" PRId64, static_cast<int64_t>(pageHandle));
    // TODO: fz_drop_page(ctx, page)
}

// ---------------------------------------------------------------------------
// MuPDFAnnotation — native methods
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeUpdateAnnotation(
        JNIEnv *env, jclass /*clazz*/, jlong nativeHandle,
        jfloat x0, jfloat y0, jfloat x1, jfloat y1,
        jfloat r, jfloat g, jfloat b, jfloat a,
        jfloat opacity, jstring jcontents) {
    if (nativeHandle == -1) return;
    std::string contents = jstringToString(env, jcontents);
    (void)x0; (void)y0; (void)x1; (void)y1;
    (void)r; (void)g; (void)b; (void)a; (void)opacity; (void)contents;
    // TODO: pdf_set_annot_rect, pdf_set_annot_color, pdf_set_annot_opacity,
    //       pdf_set_annot_contents, pdf_update_annot
}

// ---------------------------------------------------------------------------
// MuPDFEditor — native methods
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFEditor_nativeInsertImage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jlong pageHandle,
        jbyteArray jimageBytes, jfloat x0, jfloat y0, jfloat x1, jfloat y1) {
    if (docHandle == -1 || pageHandle == -1) return JNI_FALSE;
    jsize len = env->GetArrayLength(jimageBytes);
    jbyte *bytes = env->GetByteArrayElements(jimageBytes, nullptr);
    // TODO: fz_new_image_from_buffer, pdf_add_image_to_page
    (void)len; (void)x0; (void)y0; (void)x1; (void)y1;
    env->ReleaseByteArrayElements(jimageBytes, bytes, JNI_ABORT);
    return JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFEditor_nativeApplyRedactions(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1) return JNI_FALSE;
    // TODO: pdf_redact_page for every page
    return JNI_FALSE;
}
