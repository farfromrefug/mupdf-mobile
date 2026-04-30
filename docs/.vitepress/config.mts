import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'MuPDF Mobile',
  description: 'Cross-platform MuPDF wrapper for iOS and Android',
  base: '/mupdf-mobile/',
  outDir: '../docs-dist',

  themeConfig: {
    logo: { light: '/logo.svg', dark: '/logo.svg', alt: 'MuPDF Mobile' },

    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'API Reference', link: '/api/document' },
      {
        text: 'GitHub',
        link: 'https://github.com/farfromrefug/mupdf-mobile',
      },
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting Started', link: '/guide/' },
          { text: 'Rendering Pages', link: '/guide/rendering' },
          { text: 'Annotations', link: '/guide/annotations' },
          { text: 'Document Editing', link: '/guide/editing' },
        ],
      },
      {
        text: 'API Reference',
        items: [
          { text: 'MuPDFDocument', link: '/api/document' },
          { text: 'MuPDFPage', link: '/api/page' },
          { text: 'MuPDFAnnotation', link: '/api/annotation' },
          { text: 'MuPDFEditor', link: '/api/editor' },
          { text: 'MuPDFRenderer', link: '/api/renderer' },
          { text: 'Types', link: '/api/types' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/farfromrefug/mupdf-mobile' },
    ],

    footer: {
      message:
        'Wrapper code released under the MIT License. MuPDF engine under AGPL-3.0.',
      copyright:
        'Copyright © 2024 Martin Guillon · Built on MuPDF by Artifex Software',
    },

    editLink: {
      pattern:
        'https://github.com/farfromrefug/mupdf-mobile/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },
  },
})
