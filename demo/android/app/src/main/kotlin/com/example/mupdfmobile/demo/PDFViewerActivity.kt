package com.example.mupdfmobile.demo

import android.graphics.Bitmap
import android.os.Bundle
import android.widget.*
import android.view.Gravity
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.artifex.mupdf.mobile.MuPDFDocument
import com.artifex.mupdf.mobile.MuPDFRenderer
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.*

/**
 * A minimal PDF viewer Activity that renders pages using [MuPDFDocument].
 *
 * Receives a `content://` URI or file path via [EXTRA_PDF_URI] and renders
 * pages one at a time with Previous / Next navigation.
 */
class PDFViewerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PDF_URI = "extra_pdf_uri"
    }

    private var document: MuPDFDocument? = null
    private var currentPage = 0

    private lateinit var imageView: ImageView
    private lateinit var pageLabel: TextView
    private lateinit var prevBtn: Button
    private lateinit var nextBtn: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        setContentView(root)

        imageView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(android.graphics.Color.LTGRAY)
        }

        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            setPadding(8, 8, 8, 8)
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
        }

        prevBtn = Button(this).apply { text = "◀ Prev"; setOnClickListener { navigate(-1) } }
        nextBtn = Button(this).apply { text = "Next ▶"; setOnClickListener { navigate(+1) } }
        pageLabel = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f)
            gravity = Gravity.CENTER
        }

        toolbar.addView(prevBtn)
        toolbar.addView(pageLabel)
        toolbar.addView(nextBtn)

        root.addView(imageView)
        root.addView(toolbar)

        val uriString = intent.getStringExtra(EXTRA_PDF_URI) ?: run {
            showError("No PDF URI provided")
            return
        }

        openDocument(uriString)
    }

    override fun onDestroy() {
        document?.close()
        super.onDestroy()
    }

    private fun openDocument(uriString: String) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val path = resolveToPath(uriString)
                val doc = MuPDFDocument.open(path)
                withContext(Dispatchers.Main) {
                    document = doc
                    title = doc.title ?: "PDF Viewer"
                    renderPage(0)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { showError(e.message ?: "Failed to open PDF") }
            }
        }
    }

    private fun renderPage(index: Int) {
        val doc = document ?: return
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val page   = doc.loadPage(index)
                val scale  = resources.displayMetrics.density
                val bitmap = MuPDFRenderer.render(page, scale)
                withContext(Dispatchers.Main) {
                    imageView.setImageBitmap(bitmap.bitmap)
                    currentPage = index
                    pageLabel.text = "${index + 1} / ${doc.pageCount}"
                    prevBtn.isEnabled = index > 0
                    nextBtn.isEnabled = index < doc.pageCount - 1
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) { showError(e.message ?: "Render error") }
            }
        }
    }

    private fun navigate(delta: Int) {
        val doc = document ?: return
        val next = currentPage + delta
        if (next in 0 until doc.pageCount) renderPage(next)
    }

    /** Copies a content:// URI to a temporary file and returns its path. */
    private fun resolveToPath(uriString: String): String {
        if (!uriString.startsWith("content://")) return uriString
        val uri = android.net.Uri.parse(uriString)
        val tmp = File(cacheDir, "mupdf_demo_tmp.pdf")
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(tmp).use { output -> input.copyTo(output) }
        }
        return tmp.absolutePath
    }

    private fun showError(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }
}
