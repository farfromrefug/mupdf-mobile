# ``MuPDFMobile``

A cross-platform PDF library wrapping MuPDF for iOS and macOS.

## Overview

**MuPDF Mobile** exposes the battle-tested [MuPDF](https://mupdf.com/) C engine through an idiomatic Swift API. It mirrors the Android (Kotlin) API surface so you can share mental models and documentation across both platforms.

### Core classes

- ``MuPDFDocument`` — open, save, merge, and edit PDF documents
- ``MuPDFPage`` — render, search, and annotate individual pages
- ``MuPDFAnnotation`` — create and modify PDF annotations
- ``MuPDFEditor`` — insert images, apply redactions
- ``MuPDFRenderer`` — tiled and scaled rendering utilities
- ``MuPDFBitmap`` — platform bitmap wrapper (`UIImage` / `NSImage`)

### Value types

- ``MuPDFRect`` — rectangle in PDF user-space coordinates
- ``MuPDFColor`` — RGBA colour with normalised components
- ``MuPDFOutlineItem`` — a node in the document's table of contents

## Topics

### Getting Started

- <doc:GettingStarted>

### Document Management

- ``MuPDFDocument``

### Page Rendering and Annotation

- ``MuPDFPage``
- ``MuPDFAnnotation``
- ``MuPDFAnnotationType``
- ``MuPDFRenderer``

### Editing

- ``MuPDFEditor``

### Value Types

- ``MuPDFRect``
- ``MuPDFColor``
- ``MuPDFOutlineItem``
- ``MuPDFBitmap``

### Errors

- ``MuPDFError``
