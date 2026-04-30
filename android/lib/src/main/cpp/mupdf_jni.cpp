/**
 * mupdf_jni.cpp — JNI bridge between the Android Kotlin API and MuPDF C engine.
 *
 * Each JNI function corresponds to an `external` (native) function declared in
 * the Kotlin source under com.artifex.mupdf.mobile.
 *
 * Building with full MuPDF support requires the submodule to be initialised:
 *   git submodule update --init --recursive
 *
 * When MUPDF_AVAILABLE is NOT defined (stub build), every function throws
 * MuPDFEngineException so callers receive a clear error at runtime.
 */

#include <jni.h>
#include <android/bitmap.h>
#include <android/log.h>
#include <cinttypes>
#include <cstring>
#include <cstdlib>
#include <string>
#include <vector>

#ifdef MUPDF_AVAILABLE
#include "mupdf/fitz.h"
#include "mupdf/pdf.h"
#endif

#define LOG_TAG "MuPDFMobile"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

static void throwJavaException(JNIEnv *env, const char *className, const char *msg) {
    jclass cls = env->FindClass(className);
    if (cls != nullptr) {
        env->ThrowNew(cls, msg);
        env->DeleteLocalRef(cls);
    }
}

static void throwMuPDFException(JNIEnv *env, const char *msg) {
    throwJavaException(env, "com/artifex/mupdf/mobile/MuPDFEngineException", msg);
}

static std::string jstringToString(JNIEnv *env, jstring jstr) {
    if (jstr == nullptr) return {};
    const char *chars = env->GetStringUTFChars(jstr, nullptr);
    std::string result(chars);
    env->ReleaseStringUTFChars(jstr, chars);
    return result;
}

// ---------------------------------------------------------------------------
// Handle structs and cast macros (MuPDF build only)
// ---------------------------------------------------------------------------

#ifdef MUPDF_AVAILABLE

struct DocHandle {
    fz_context  *ctx;
    fz_document *doc;
};

struct PageHandle {
    fz_context *ctx;
    fz_page    *page;
};

struct AnnotHandle {
    fz_context *ctx;
    pdf_page   *pdfPage;  // kept alive while annot is live
    pdf_annot  *annot;
};

#define DOC(h)  (reinterpret_cast<DocHandle *>(static_cast<uintptr_t>(h)))
#define PAGE(h) (reinterpret_cast<PageHandle *>(static_cast<uintptr_t>(h)))
#define ANNOT(h) (reinterpret_cast<AnnotHandle *>(static_cast<uintptr_t>(h)))

// Recursively walk fz_outline tree, appending "depth\ttitle\tpageIndex" entries.
static void walkOutline(fz_context *ctx, fz_outline *node, int depth,
                        std::vector<std::string> &out) {
    (void)ctx;
    while (node) {
        int pageIdx = node->page.page;
        char buf[4096];
        snprintf(buf, sizeof(buf), "%d\t%s\t%d",
                 depth,
                 node->title ? node->title : "",
                 pageIdx);
        out.push_back(buf);
        if (node->down) {
            walkOutline(ctx, node->down, depth + 1, out);
        }
        node = node->next;
    }
}

#endif // MUPDF_AVAILABLE

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeOpen
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeOpen(
        JNIEnv *env, jclass /*clazz*/, jstring jpath) {
#ifdef MUPDF_AVAILABLE
    std::string path = jstringToString(env, jpath);
    LOGI("nativeOpen: %s", path.c_str());

    fz_context *ctx = fz_new_context(nullptr, nullptr, FZ_STORE_DEFAULT);
    if (!ctx) {
        throwMuPDFException(env, "Failed to create fz_context");
        return -1L;
    }
    fz_register_document_handlers(ctx);

    fz_document *doc = nullptr;
    fz_try(ctx) {
        doc = fz_open_document(ctx, path.c_str());
    }
    fz_catch(ctx) {
        throwMuPDFException(env, fz_caught_message(ctx));
        fz_drop_context(ctx);
        return -1L;
    }

    auto *dh = new DocHandle{ctx, doc};
    return static_cast<jlong>(reinterpret_cast<uintptr_t>(dh));
#else
    (void)jpath;
    throwMuPDFException(env, "MuPDF not available: run 'git submodule update --init'");
    return -1L;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeOpenFromBytes
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeOpenFromBytes(
        JNIEnv *env, jclass /*clazz*/, jbyteArray jdata) {
#ifdef MUPDF_AVAILABLE
    jsize len   = env->GetArrayLength(jdata);
    jbyte *bytes = env->GetByteArrayElements(jdata, nullptr);

    fz_context *ctx = fz_new_context(nullptr, nullptr, FZ_STORE_DEFAULT);
    if (!ctx) {
        env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
        throwMuPDFException(env, "Failed to create fz_context");
        return -1L;
    }
    fz_register_document_handlers(ctx);

    fz_document *doc = nullptr;
    fz_try(ctx) {
        fz_buffer *buf = fz_new_buffer_from_copied_data(
            ctx, reinterpret_cast<const unsigned char *>(bytes),
            static_cast<size_t>(len));
        fz_stream *stream = fz_open_buffer(ctx, buf);
        fz_drop_buffer(ctx, buf);
        doc = fz_open_document_with_stream(ctx, "application/pdf", stream);
        fz_drop_stream(ctx, stream);
    }
    fz_catch(ctx) {
        env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
        throwMuPDFException(env, fz_caught_message(ctx));
        fz_drop_context(ctx);
        return -1L;
    }

    env->ReleaseByteArrayElements(jdata, bytes, JNI_ABORT);
    auto *dh = new DocHandle{ctx, doc};
    return static_cast<jlong>(reinterpret_cast<uintptr_t>(dh));
#else
    (void)jdata;
    throwMuPDFException(env, "MuPDF not available: run 'git submodule update --init'");
    return -1L;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeGetPageCount
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jint JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageCount(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1L) return 0;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    int count = 0;
    fz_try(dh->ctx) {
        count = fz_count_pages(dh->ctx, dh->doc);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
        return 0;
    }
    return count;
#else
    (void)env;
    return 0;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeLoadPage
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeLoadPage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1L) return -1L;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    fz_page *page = nullptr;
    fz_try(dh->ctx) {
        page = fz_load_page(dh->ctx, dh->doc, index);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
        return -1L;
    }
    auto *ph = new PageHandle{dh->ctx, page};
    return static_cast<jlong>(reinterpret_cast<uintptr_t>(ph));
#else
    (void)env; (void)index;
    return -1L;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeGetPageWidth / nativeGetPageHeight
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jfloat JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageWidth(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1L) return 595.0f;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    float w = 595.0f;
    fz_try(dh->ctx) {
        fz_page *page = fz_load_page(dh->ctx, dh->doc, index);
        fz_rect bounds = fz_bound_page(dh->ctx, page);
        w = bounds.x1 - bounds.x0;
        fz_drop_page(dh->ctx, page);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
    }
    return w;
#else
    (void)env; (void)index;
    return 595.0f;
#endif
}

extern "C" JNIEXPORT jfloat JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetPageHeight(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1L) return 842.0f;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    float h = 842.0f;
    fz_try(dh->ctx) {
        fz_page *page = fz_load_page(dh->ctx, dh->doc, index);
        fz_rect bounds = fz_bound_page(dh->ctx, page);
        h = bounds.y1 - bounds.y0;
        fz_drop_page(dh->ctx, page);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
    }
    return h;
#else
    (void)env; (void)index;
    return 842.0f;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeSave
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeSave(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jstring jpath) {
    if (docHandle == -1L) return JNI_FALSE;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    std::string path = jstringToString(env, jpath);
    fz_try(dh->ctx) {
        pdf_document *pdoc = pdf_document_from_fz_document(dh->ctx, dh->doc);
        if (!pdoc) fz_throw(dh->ctx, FZ_ERROR_GENERIC, "Not a PDF document");
        pdf_save_document(dh->ctx, pdoc, path.c_str(), nullptr);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
        return JNI_FALSE;
    }
    return JNI_TRUE;
#else
    (void)env; (void)jpath;
    return JNI_FALSE;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeMerge
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeMerge(
        JNIEnv *env, jclass /*clazz*/, jlong dstHandle, jlong srcHandle) {
    if (dstHandle == -1L || srcHandle == -1L) return;
#ifdef MUPDF_AVAILABLE
    auto *dst = DOC(dstHandle);
    auto *src = DOC(srcHandle);
    fz_try(dst->ctx) {
        pdf_document *pdst = pdf_document_from_fz_document(dst->ctx, dst->doc);
        pdf_document *psrc = pdf_document_from_fz_document(src->ctx, src->doc);
        if (!pdst || !psrc) fz_throw(dst->ctx, FZ_ERROR_GENERIC, "Not PDF documents");
        int n = pdf_count_pages(src->ctx, psrc);
        pdf_graft_map *map = pdf_new_graft_map(dst->ctx, pdst);
        for (int i = 0; i < n; i++) {
            pdf_graft_mapped_page(dst->ctx, map, -1, psrc, i);
        }
        pdf_drop_graft_map(dst->ctx, map);
    }
    fz_catch(dst->ctx) {
        throwMuPDFException(env, fz_caught_message(dst->ctx));
    }
#else
    (void)env;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeInsertBlankPage
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeInsertBlankPage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle,
        jint index, jfloat width, jfloat height) {
    if (docHandle == -1L) return;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    fz_try(dh->ctx) {
        pdf_document *pdoc = pdf_document_from_fz_document(dh->ctx, dh->doc);
        if (!pdoc) fz_throw(dh->ctx, FZ_ERROR_GENERIC, "Not a PDF document");
        fz_rect mediabox = fz_make_rect(0, 0, width, height);
        pdf_obj *page_obj = pdf_add_page(dh->ctx, pdoc, mediabox, 0, nullptr, nullptr);
        pdf_insert_page(dh->ctx, pdoc, index, page_obj);
        pdf_drop_obj(dh->ctx, page_obj);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
    }
#else
    (void)env; (void)index; (void)width; (void)height;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeDeletePage
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeDeletePage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jint index) {
    if (docHandle == -1L) return;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    fz_try(dh->ctx) {
        pdf_document *pdoc = pdf_document_from_fz_document(dh->ctx, dh->doc);
        if (!pdoc) fz_throw(dh->ctx, FZ_ERROR_GENERIC, "Not a PDF document");
        pdf_delete_page(dh->ctx, pdoc, index);
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
    }
#else
    (void)env; (void)index;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeGetMetadata
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jstring JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetMetadata(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jstring jkey) {
    if (docHandle == -1L) return nullptr;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    std::string key = jstringToString(env, jkey);
    char buf[512] = {};
    int n = fz_lookup_metadata(dh->ctx, dh->doc, key.c_str(), buf, static_cast<int>(sizeof(buf)));
    if (n > 0) return env->NewStringUTF(buf);
    return nullptr;
#else
    (void)jkey;
    return nullptr;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeGetOutline
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeGetOutline(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle) {
#ifdef MUPDF_AVAILABLE
    if (docHandle == -1L) {
        jclass strCls = env->FindClass("java/lang/String");
        return env->NewObjectArray(0, strCls, nullptr);
    }
    auto *dh = DOC(docHandle);
    std::vector<std::string> entries;
    fz_try(dh->ctx) {
        fz_outline *outline = fz_load_outline(dh->ctx, dh->doc);
        if (outline) {
            walkOutline(dh->ctx, outline, 0, entries);
            fz_drop_outline(dh->ctx, outline);
        }
    }
    fz_catch(dh->ctx) {
        LOGE("nativeGetOutline error: %s", fz_caught_message(dh->ctx));
    }
    jclass strCls = env->FindClass("java/lang/String");
    jobjectArray arr = env->NewObjectArray(static_cast<jsize>(entries.size()), strCls, nullptr);
    for (jsize i = 0; i < static_cast<jsize>(entries.size()); i++) {
        jstring s = env->NewStringUTF(entries[i].c_str());
        env->SetObjectArrayElement(arr, i, s);
        env->DeleteLocalRef(s);
    }
    env->DeleteLocalRef(strCls);
    return arr;
#else
    jclass strCls = env->FindClass("java/lang/String");
    return env->NewObjectArray(0, strCls, nullptr);
#endif
}

// ---------------------------------------------------------------------------
// MuPDFDocument — nativeClose
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFDocument_nativeClose(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1L) return;
    LOGI("nativeClose doc handle=%" PRId64, static_cast<int64_t>(docHandle));
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    fz_drop_document(dh->ctx, dh->doc);
    fz_drop_context(dh->ctx);
    delete dh;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeRender
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeRender(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle,
        jobject bitmap, jfloat scale, jint x, jint y, jint width, jint height) {
    if (pageHandle == -1L) return;

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

#ifdef MUPDF_AVAILABLE
    auto *ph = PAGE(pageHandle);
    fz_context *ctx = ph->ctx;
    fz_try(ctx) {
        fz_matrix matrix = fz_scale(scale, scale);
        fz_irect bbox = fz_make_irect(x, y, x + width, y + height);
        // Use BGRx (fz_device_bgr + alpha=1) to match Android ARGB_8888 byte layout.
        fz_pixmap *pix = fz_new_pixmap_with_bbox_and_data(
            ctx, fz_device_bgr(ctx), bbox, nullptr, 1,
            static_cast<unsigned char *>(pixels));
        fz_clear_pixmap_with_value(ctx, pix, 0xFF);
        fz_device *dev = fz_new_draw_device(ctx, matrix, pix);
        fz_run_page(ctx, ph->page, dev, fz_identity, nullptr);
        fz_close_device(ctx, dev);
        fz_drop_device(ctx, dev);
        fz_drop_pixmap(ctx, pix);
    }
    fz_catch(ctx) {
        LOGE("nativeRender error: %s", fz_caught_message(ctx));
        // Fill white on error so bitmap is not left in garbage state.
        memset(pixels, 0xFF,
               static_cast<size_t>(info.stride) * static_cast<size_t>(info.height));
    }
#else
    memset(pixels, 0xFF,
           static_cast<size_t>(info.stride) * static_cast<size_t>(info.height));
    (void)scale; (void)x; (void)y; (void)width; (void)height;
#endif

    AndroidBitmap_unlockPixels(env, bitmap);
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeGetAnnotations
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlongArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeGetAnnotations(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle) {
#ifdef MUPDF_AVAILABLE
    if (pageHandle == -1L) return env->NewLongArray(0);
    auto *ph = PAGE(pageHandle);
    std::vector<jlong> handles;
    fz_try(ph->ctx) {
        pdf_page *pdfPage = pdf_page_from_fz_page(ph->ctx, ph->page);
        if (pdfPage) {
            for (pdf_annot *annot = pdf_first_annot(ph->ctx, pdfPage);
                 annot != nullptr;
                 annot = pdf_next_annot(ph->ctx, annot)) {
                // Keep the pdfPage alive: take a reference so we can hold it per-annot.
                pdf_keep_page(ph->ctx, pdfPage);
                auto *ah = new AnnotHandle{ph->ctx, pdfPage, annot};
                handles.push_back(static_cast<jlong>(reinterpret_cast<uintptr_t>(ah)));
            }
        }
    }
    fz_catch(ph->ctx) {
        throwMuPDFException(env, fz_caught_message(ph->ctx));
        return env->NewLongArray(0);
    }
    jlongArray arr = env->NewLongArray(static_cast<jsize>(handles.size()));
    if (!handles.empty()) {
        env->SetLongArrayRegion(arr, 0, static_cast<jsize>(handles.size()), handles.data());
    }
    return arr;
#else
    return env->NewLongArray(0);
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeAddAnnotation
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jlong JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeAddAnnotation(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle,
        jint type, jfloat x0, jfloat y0, jfloat x1, jfloat y1) {
    if (pageHandle == -1L) return -1L;
#ifdef MUPDF_AVAILABLE
    auto *ph = PAGE(pageHandle);
    jlong result = -1L;
    fz_try(ph->ctx) {
        pdf_page *pdfPage = pdf_page_from_fz_page(ph->ctx, ph->page);
        if (!pdfPage) fz_throw(ph->ctx, FZ_ERROR_GENERIC, "Not a PDF page");
        pdf_annot *annot = pdf_create_annot(ph->ctx, pdfPage,
                                            static_cast<enum pdf_annot_type>(type));
        fz_rect rect = fz_make_rect(x0, y0, x1, y1);
        pdf_set_annot_rect(ph->ctx, annot, rect);
        pdf_update_annot(ph->ctx, annot);
        pdf_keep_page(ph->ctx, pdfPage);
        auto *ah = new AnnotHandle{ph->ctx, pdfPage, annot};
        result = static_cast<jlong>(reinterpret_cast<uintptr_t>(ah));
    }
    fz_catch(ph->ctx) {
        throwMuPDFException(env, fz_caught_message(ph->ctx));
    }
    return result;
#else
    (void)env; (void)type; (void)x0; (void)y0; (void)x1; (void)y1;
    return -1L;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeRemoveAnnotation
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeRemoveAnnotation(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle, jlong annotHandle) {
    if (pageHandle == -1L || annotHandle == -1L) return JNI_FALSE;
#ifdef MUPDF_AVAILABLE
    auto *ph  = PAGE(pageHandle);
    auto *ah  = ANNOT(annotHandle);
    fz_try(ph->ctx) {
        pdf_delete_annot(ph->ctx, ah->pdfPage, ah->annot);
    }
    fz_catch(ph->ctx) {
        throwMuPDFException(env, fz_caught_message(ph->ctx));
        return JNI_FALSE;
    }
    pdf_drop_page(ah->ctx, ah->pdfPage);
    delete ah;
    return JNI_TRUE;
#else
    (void)env;
    return JNI_FALSE;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeSearch
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeSearch(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle, jstring jtext) {
    if (pageHandle == -1L || jtext == nullptr) return env->NewFloatArray(0);
#ifdef MUPDF_AVAILABLE
    auto *ph = PAGE(pageHandle);
    std::string text = jstringToString(env, jtext);
    if (text.empty()) return env->NewFloatArray(0);

    static constexpr int MAX_QUADS = 256;
    fz_quad quads[MAX_QUADS];
    int nhits = 0;
    fz_try(ph->ctx) {
        nhits = fz_search_page(ph->ctx, ph->page, text.c_str(), nullptr,
                               quads, MAX_QUADS);
    }
    fz_catch(ph->ctx) {
        LOGE("nativeSearch error: %s", fz_caught_message(ph->ctx));
        return env->NewFloatArray(0);
    }

    // Return [x0,y0,x1,y1] bounding box for each hit quad.
    jfloatArray arr = env->NewFloatArray(nhits * 4);
    std::vector<jfloat> data;
    data.reserve(static_cast<size_t>(nhits) * 4);
    for (int i = 0; i < nhits; i++) {
        fz_rect r = fz_rect_from_quad(quads[i]);
        data.push_back(r.x0);
        data.push_back(r.y0);
        data.push_back(r.x1);
        data.push_back(r.y1);
    }
    if (!data.empty()) {
        env->SetFloatArrayRegion(arr, 0, static_cast<jsize>(data.size()), data.data());
    }
    return arr;
#else
    (void)jtext;
    return env->NewFloatArray(0);
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeGetTextContent
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jstring JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeGetTextContent(
        JNIEnv *env, jclass /*clazz*/, jlong pageHandle) {
    if (pageHandle == -1L) return env->NewStringUTF("");
#ifdef MUPDF_AVAILABLE
    auto *ph = PAGE(pageHandle);
    jstring result = env->NewStringUTF("");
    fz_try(ph->ctx) {
        fz_stext_options opts = {};
        fz_stext_page *stext = fz_new_stext_page_from_page(ph->ctx, ph->page, &opts);
        fz_buffer *buf = fz_new_buffer_from_stext_page(ph->ctx, stext);
        fz_drop_stext_page(ph->ctx, stext);
        const char *str = reinterpret_cast<const char *>(fz_string_from_buffer(ph->ctx, buf));
        result = env->NewStringUTF(str ? str : "");
        fz_drop_buffer(ph->ctx, buf);
    }
    fz_catch(ph->ctx) {
        LOGE("nativeGetTextContent error: %s", fz_caught_message(ph->ctx));
    }
    return result;
#else
    return env->NewStringUTF("");
#endif
}

// ---------------------------------------------------------------------------
// MuPDFPage — nativeClosePage
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFPage_nativeClosePage(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong pageHandle) {
    if (pageHandle == -1L) return;
    LOGI("nativeClosePage handle=%" PRId64, static_cast<int64_t>(pageHandle));
#ifdef MUPDF_AVAILABLE
    auto *ph = PAGE(pageHandle);
    fz_drop_page(ph->ctx, ph->page);
    delete ph;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFAnnotation — nativeUpdateAnnotation
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeUpdateAnnotation(
        JNIEnv *env, jclass /*clazz*/, jlong annotHandle,
        jfloat x0, jfloat y0, jfloat x1, jfloat y1,
        jfloat r, jfloat g, jfloat b, jfloat /*a*/,
        jfloat opacity, jstring jcontents) {
    if (annotHandle == -1L) return;
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    std::string contents = jstringToString(env, jcontents);
    fz_try(ah->ctx) {
        fz_rect rect = fz_make_rect(x0, y0, x1, y1);
        pdf_set_annot_rect(ah->ctx, ah->annot, rect);
        float color[3] = {r, g, b};
        pdf_set_annot_color(ah->ctx, ah->annot, 3, color);
        pdf_set_annot_opacity(ah->ctx, ah->annot, opacity);
        pdf_set_annot_contents(ah->ctx, ah->annot, contents.c_str());
        pdf_update_annot(ah->ctx, ah->annot);
    }
    fz_catch(ah->ctx) {
        throwMuPDFException(env, fz_caught_message(ah->ctx));
    }
#else
    (void)env; (void)x0; (void)y0; (void)x1; (void)y1;
    (void)r; (void)g; (void)b; (void)opacity; (void)jcontents;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFAnnotation — property getters
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jint JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeGetAnnotationType(
        JNIEnv *env, jclass /*clazz*/, jlong annotHandle) {
    if (annotHandle == -1L) return -1;
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    int type = -1;
    fz_try(ah->ctx) {
        type = static_cast<int>(pdf_annot_type(ah->ctx, ah->annot));
    }
    fz_catch(ah->ctx) {
        throwMuPDFException(env, fz_caught_message(ah->ctx));
    }
    return type;
#else
    (void)env;
    return -1;
#endif
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeGetAnnotationRect(
        JNIEnv *env, jclass /*clazz*/, jlong annotHandle) {
    jfloatArray arr = env->NewFloatArray(4);
    if (annotHandle == -1L) return arr;
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    fz_try(ah->ctx) {
        fz_rect rect = pdf_annot_rect(ah->ctx, ah->annot);
        jfloat vals[4] = {rect.x0, rect.y0, rect.x1, rect.y1};
        env->SetFloatArrayRegion(arr, 0, 4, vals);
    }
    fz_catch(ah->ctx) {
        throwMuPDFException(env, fz_caught_message(ah->ctx));
    }
#endif
    return arr;
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeGetAnnotationColor(
        JNIEnv *env, jclass /*clazz*/, jlong annotHandle) {
    jfloatArray arr = env->NewFloatArray(4);
    if (annotHandle == -1L) return arr;
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    fz_try(ah->ctx) {
        int n = 0;
        float color[4] = {0.0f, 0.0f, 0.0f, 0.0f};
        pdf_annot_color(ah->ctx, ah->annot, &n, color);
        float opacity = pdf_annot_opacity(ah->ctx, ah->annot);
        jfloat vals[4] = {
            (n > 0) ? color[0] : 0.0f,
            (n > 1) ? color[1] : 0.0f,
            (n > 2) ? color[2] : 0.0f,
            opacity
        };
        env->SetFloatArrayRegion(arr, 0, 4, vals);
    }
    fz_catch(ah->ctx) {
        throwMuPDFException(env, fz_caught_message(ah->ctx));
    }
#endif
    return arr;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeGetAnnotationContents(
        JNIEnv *env, jclass /*clazz*/, jlong annotHandle) {
    if (annotHandle == -1L) return env->NewStringUTF("");
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    jstring result = env->NewStringUTF("");
    fz_try(ah->ctx) {
        const char *contents = pdf_annot_contents(ah->ctx, ah->annot);
        result = env->NewStringUTF(contents ? contents : "");
    }
    fz_catch(ah->ctx) {
        throwMuPDFException(env, fz_caught_message(ah->ctx));
    }
    return result;
#else
    return env->NewStringUTF("");
#endif
}

extern "C" JNIEXPORT void JNICALL
Java_com_artifex_mupdf_mobile_MuPDFAnnotation_nativeDropAnnotation(
        JNIEnv * /*env*/, jclass /*clazz*/, jlong annotHandle) {
    if (annotHandle == -1L) return;
#ifdef MUPDF_AVAILABLE
    auto *ah = ANNOT(annotHandle);
    pdf_drop_page(ah->ctx, ah->pdfPage);
    delete ah;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFEditor — nativeInsertImage
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFEditor_nativeInsertImage(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle, jlong pageHandle,
        jbyteArray jimageBytes, jfloat x0, jfloat y0, jfloat x1, jfloat y1) {
    if (docHandle == -1L || pageHandle == -1L) return JNI_FALSE;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    auto *ph = PAGE(pageHandle);
    jsize len   = env->GetArrayLength(jimageBytes);
    jbyte *bytes = env->GetByteArrayElements(jimageBytes, nullptr);
    jboolean ok = JNI_FALSE;
    fz_try(dh->ctx) {
        pdf_document *pdoc   = pdf_document_from_fz_document(dh->ctx, dh->doc);
        pdf_page     *pdfPage = pdf_page_from_fz_page(ph->ctx, ph->page);
        if (!pdoc || !pdfPage) fz_throw(dh->ctx, FZ_ERROR_GENERIC, "Not PDF objects");

        // Build fz_image from the raw bytes.
        fz_buffer *imgbuf = fz_new_buffer_from_copied_data(
            dh->ctx,
            reinterpret_cast<const unsigned char *>(bytes),
            static_cast<size_t>(len));
        fz_image *img = fz_new_image_from_buffer(dh->ctx, imgbuf);
        fz_drop_buffer(dh->ctx, imgbuf);

        // Add image as XObject to document resources and get a reference name.
        pdf_obj *imgres = pdf_add_image(dh->ctx, pdoc, img);
        fz_drop_image(dh->ctx, img);

        // Ensure page Resources / XObject dict exists.
        pdf_obj *resources = pdf_dict_get_inheritable(dh->ctx, pdfPage->obj,
                                                       PDF_NAME(Resources));
        if (!resources || pdf_is_null(dh->ctx, resources)) {
            resources = pdf_new_dict(dh->ctx, pdoc, 1);
            pdf_dict_put(dh->ctx, pdfPage->obj, PDF_NAME(Resources), resources);
            pdf_drop_obj(dh->ctx, resources);
            resources = pdf_dict_get(dh->ctx, pdfPage->obj, PDF_NAME(Resources));
        }
        pdf_obj *xobjs = pdf_dict_get(dh->ctx, resources, PDF_NAME(XObject));
        if (!xobjs || pdf_is_null(dh->ctx, xobjs)) {
            xobjs = pdf_new_dict(dh->ctx, pdoc, 1);
            pdf_dict_put(dh->ctx, resources, PDF_NAME(XObject), xobjs);
            pdf_drop_obj(dh->ctx, xobjs);
            xobjs = pdf_dict_get(dh->ctx, resources, PDF_NAME(XObject));
        }
        pdf_dict_puts(dh->ctx, xobjs, "Im1", imgres);
        pdf_drop_obj(dh->ctx, imgres);

        // Build content stream: scale + translate matrix then draw.
        float imgW = x1 - x0;
        float imgH = y1 - y0;
        char content[512];
        snprintf(content, sizeof(content),
                 "q\n%.4f 0 0 %.4f %.4f %.4f cm\n/Im1 Do\nQ\n",
                 imgW, imgH, x0, y0);

        // Append a new content stream entry to the page.
        fz_buffer *cbuf = fz_new_buffer_from_copied_data(
            dh->ctx,
            reinterpret_cast<const unsigned char *>(content),
            strlen(content));
        pdf_obj *cstm = pdf_add_stream(dh->ctx, pdoc, cbuf, nullptr, 0);
        fz_drop_buffer(dh->ctx, cbuf);

        // Add to page Contents (as array or single ref).
        pdf_obj *contents_obj = pdf_dict_get(dh->ctx, pdfPage->obj, PDF_NAME(Contents));
        if (!contents_obj || pdf_is_null(dh->ctx, contents_obj)) {
            pdf_dict_put(dh->ctx, pdfPage->obj, PDF_NAME(Contents), cstm);
        } else if (pdf_is_array(dh->ctx, contents_obj)) {
            pdf_array_push(dh->ctx, contents_obj, cstm);
        } else {
            pdf_obj *arr2 = pdf_new_array(dh->ctx, pdoc, 2);
            pdf_array_push(dh->ctx, arr2, contents_obj);
            pdf_array_push(dh->ctx, arr2, cstm);
            pdf_dict_put(dh->ctx, pdfPage->obj, PDF_NAME(Contents), arr2);
            pdf_drop_obj(dh->ctx, arr2);
        }
        pdf_drop_obj(dh->ctx, cstm);
        ok = JNI_TRUE;
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
    }
    env->ReleaseByteArrayElements(jimageBytes, bytes, JNI_ABORT);
    return ok;
#else
    jsize len = env->GetArrayLength(jimageBytes);
    jbyte *bytes = env->GetByteArrayElements(jimageBytes, nullptr);
    (void)len; (void)x0; (void)y0; (void)x1; (void)y1;
    env->ReleaseByteArrayElements(jimageBytes, bytes, JNI_ABORT);
    return JNI_FALSE;
#endif
}

// ---------------------------------------------------------------------------
// MuPDFEditor — nativeApplyRedactions
// ---------------------------------------------------------------------------

extern "C" JNIEXPORT jboolean JNICALL
Java_com_artifex_mupdf_mobile_MuPDFEditor_nativeApplyRedactions(
        JNIEnv *env, jclass /*clazz*/, jlong docHandle) {
    if (docHandle == -1L) return JNI_FALSE;
#ifdef MUPDF_AVAILABLE
    auto *dh = DOC(docHandle);
    fz_try(dh->ctx) {
        pdf_document *pdoc = pdf_document_from_fz_document(dh->ctx, dh->doc);
        if (!pdoc) fz_throw(dh->ctx, FZ_ERROR_GENERIC, "Not a PDF document");
        int n = pdf_count_pages(dh->ctx, pdoc);
        for (int i = 0; i < n; i++) {
            pdf_page *pdfPage = pdf_load_page(dh->ctx, pdoc, i);
            pdf_redact_page(dh->ctx, pdoc, pdfPage, nullptr);
            fz_drop_page(dh->ctx, &pdfPage->super);
        }
    }
    fz_catch(dh->ctx) {
        throwMuPDFException(env, fz_caught_message(dh->ctx));
        return JNI_FALSE;
    }
    return JNI_TRUE;
#else
    (void)env;
    return JNI_FALSE;
#endif
}
