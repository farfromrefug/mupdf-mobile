---
layout: home

hero:
  name: MuPDF Mobile
  text: PDF rendering for every mobile platform
  tagline: >
    A cross-platform library wrapping the battle-tested MuPDF engine with a
    beautiful, idiomatic API for iOS (Swift) and Android (Kotlin).
  image:
    light: /logo.svg
    dark: /logo.svg
    alt: MuPDF Mobile logo
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/farfromrefug/mupdf-mobile

features:
  - icon: 📄
    title: High-fidelity Rendering
    details: >
      Pixel-perfect page rendering at any scale using the industry-leading
      MuPDF C engine — trusted by millions of users in open-source and
      commercial PDF applications worldwide.

  - icon: 🧩
    title: Tiled Rendering
    details: >
      Render only the tiles currently visible. Ideal for large documents
      in UICollectionView (iOS) or RecyclerView (Android) with smooth
      60 fps scrolling.

  - icon: ✏️
    title: Rich Annotations
    details: >
      Add, edit, and remove 13 annotation types — highlights, underlines,
      strikeouts, ink drawings, stamps, text notes, and redaction marks.

  - icon: 🔍
    title: Full-text Search
    details: >
      Fast text search with bounding-rectangle results for precise
      hit-highlighting overlaid on the rendered page.

  - icon: ✂️
    title: Document Editing
    details: >
      Merge multiple PDFs, split documents, insert/delete pages,
      insert raster images, and apply permanent redactions.

  - icon: 🏎
    title: Native Performance
    details: >
      Zero JavaScript bridge. Swift on iOS and Kotlin/JNI on Android means
      you get hardware-accelerated, memory-efficient rendering everywhere.

  - icon: 📦
    title: Easy Installation
    details: >
      One line via Swift Package Manager or Jitpack/Gradle. No CocoaPods,
      no manual framework linking, no binary blobs to manage.

  - icon: 🔗
    title: ObjC Compatible
    details: >
      Full `@objcMembers` surface area. Every class and method is accessible
      from legacy Objective-C codebases with zero bridging code.
---
