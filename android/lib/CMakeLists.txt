cmake_minimum_required(VERSION 3.22)
project(mupdf_mobile VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MUPDF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../mupdf" CACHE PATH "MuPDF submodule root")

# ─────────────────────────────────────────────────────────────────────────────
# Detect whether the MuPDF submodule headers are present.
# When found, also look for pre-built static libraries produced by ndk-build.
# ─────────────────────────────────────────────────────────────────────────────
if(EXISTS "${MUPDF_ROOT}/include/mupdf/fitz.h")
    message(STATUS "MuPDF submodule found at ${MUPDF_ROOT}")
    add_definitions(-DMUPDF_AVAILABLE)
    include_directories("${MUPDF_ROOT}/include")

    # ndk-build output layout: <project>/obj/local/<ABI>/libXXX.a
    set(MUPDF_LIB_DIR "${CMAKE_SOURCE_DIR}/../../build/mupdf_android/obj/local/${ANDROID_ABI}")

    if(EXISTS "${MUPDF_LIB_DIR}/libmupdf_core.a")
        message(STATUS "Using pre-built MuPDF from ${MUPDF_LIB_DIR}")
        add_library(mupdf_core STATIC IMPORTED)
        set_target_properties(mupdf_core PROPERTIES
            IMPORTED_LOCATION "${MUPDF_LIB_DIR}/libmupdf_core.a")

        if(EXISTS "${MUPDF_LIB_DIR}/libmupdf_third.a")
            add_library(mupdf_third STATIC IMPORTED)
            set_target_properties(mupdf_third PROPERTIES
                IMPORTED_LOCATION "${MUPDF_LIB_DIR}/libmupdf_third.a")
            set(MUPDF_LINK_LIBS mupdf_core mupdf_third)
        else()
            set(MUPDF_LINK_LIBS mupdf_core)
        endif()
    else()
        message(STATUS "Pre-built MuPDF not found at ${MUPDF_LIB_DIR}.")
        message(STATUS "Run './gradlew buildMuPDF' or see README for build instructions.")
        message(STATUS "Falling back to stub-only build (PDF operations will throw at runtime).")
        remove_definitions(-DMUPDF_AVAILABLE)
    endif()
else()
    message(WARNING "MuPDF submodule not initialised. Run: git submodule update --init")
    message(WARNING "PDF operations will throw MuPDFEngineException at runtime.")
endif()

# ─────────────────────────────────────────────────────────────────────────────
# JNI shared library
# ─────────────────────────────────────────────────────────────────────────────
add_library(mupdf_mobile SHARED src/main/cpp/mupdf_jni.cpp)

find_library(log-lib     log)
find_library(android-lib android)
find_library(jnigraphics jnigraphics)

target_link_libraries(mupdf_mobile
    ${MUPDF_LINK_LIBS}
    ${log-lib}
    ${android-lib}
    ${jnigraphics}
)

target_compile_options(mupdf_mobile PRIVATE -Wall -Wextra -Wno-unused-parameter)
