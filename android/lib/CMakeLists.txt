cmake_minimum_required(VERSION 3.22)
project(mupdf_mobile VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ─────────────────────────────────────────────────────────────────────────────
# MuPDF submodule path — override with -DMUPDF_ROOT=/path/to/mupdf if needed.
# Defaults to <repo-root>/mupdf (i.e. two levels up from android/lib).
# ─────────────────────────────────────────────────────────────────────────────
set(MUPDF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../mupdf" CACHE PATH "Path to MuPDF submodule root")

# ─────────────────────────────────────────────────────────────────────────────
# MuPDF include directory
# ─────────────────────────────────────────────────────────────────────────────
# Uncomment once the submodule is initialised:
# include_directories("${MUPDF_ROOT}/include")

# ─────────────────────────────────────────────────────────────────────────────
# Pre-built MuPDF static library
# ─────────────────────────────────────────────────────────────────────────────
# MuPDF ships per-ABI .a files when built with the Android Makefile:
#   make HAVE_GLUT=no HAVE_X11=no build=release
# Set MUPDF_LIBS to the path of the pre-built archive for the current ABI.
# Uncomment and adjust the path when the submodule is present:
#
# set(MUPDF_LIB_DIR "${MUPDF_ROOT}/build/release/${ANDROID_ABI}")
# add_library(mupdf STATIC IMPORTED)
# set_target_properties(mupdf PROPERTIES
#     IMPORTED_LOCATION "${MUPDF_LIB_DIR}/libmupdf.a"
# )

# ─────────────────────────────────────────────────────────────────────────────
# JNI shared library
# ─────────────────────────────────────────────────────────────────────────────
add_library(
    mupdf_mobile
    SHARED
    src/main/cpp/mupdf_jni.cpp
)

# Android system libraries
find_library(log-lib     log)
find_library(android-lib android)
find_library(jnigraphics jnigraphics)

target_link_libraries(
    mupdf_mobile
    # mupdf           # Uncomment once submodule is built
    ${log-lib}
    ${android-lib}
    ${jnigraphics}
)

# Compiler warnings
target_compile_options(mupdf_mobile PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
)
