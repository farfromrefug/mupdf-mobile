package com.example.mupdfmobile.demo

import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.artifex.mupdf.mobile.MuPDFDocument
import kotlinx.coroutines.*

/**
 * Demonstrates **tiled PDF rendering**: instead of rendering the whole page
 * into a single (potentially huge) bitmap, only the visible tiles are rendered
 * at the current zoom level.
 *
 * This means:
 * - Smooth zooming without blur — tiles are re-rendered at the new zoom level
 * - Low memory usage — only on-screen tiles are kept in memory
 * - Fast initial load — only visible tiles are rendered first
 *
 * ## Gestures
 * | Gesture | Action |
 * |---------|--------|
 * | Pinch   | Zoom in / out |
 * | Drag    | Pan |
 * | Double-tap | Cycle zoom levels (1× → 2× → 4× → 1×) |
 *
 * **Entry point**: launch via [EXTRA_PDF_PATH] intent extra.
 */
class TiledViewerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PDF_PATH = "extra_pdf_path"
    }

    private var document: MuPDFDocument? = null
    private var currentPage = 0

    private lateinit var tiledView: TiledPDFView
    private lateinit var pageLabel: TextView
    private lateinit var prevBtn: Button
    private lateinit var nextBtn: Button
    private lateinit var zoomLabel: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── Layout ──────────────────────────────────────────────────────────
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        // Tiled view (fills the screen)
        tiledView = TiledPDFView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            setBackgroundColor(android.graphics.Color.DKGRAY)
        }

        // Navigation bar at the bottom
        val navBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.CENTER_VERTICAL
            setPadding(8, 8, 8, 8)
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
            setBackgroundColor(android.graphics.Color.parseColor("#1A1A2E"))
        }

        prevBtn = Button(this).apply {
            text = "◀"
            setOnClickListener { navigate(-1) }
        }
        nextBtn = Button(this).apply {
            text = "▶"
            setOnClickListener { navigate(+1) }
        }
        pageLabel = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f)
            gravity = Gravity.CENTER
            setTextColor(android.graphics.Color.WHITE)
        }
        zoomLabel = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT)
            setPadding(8, 0, 8, 0)
            setTextColor(android.graphics.Color.LTGRAY)
            text = "100%"
        }

        navBar.addView(prevBtn)
        navBar.addView(pageLabel)
        navBar.addView(zoomLabel)
        navBar.addView(nextBtn)

        root.addView(tiledView)
        root.addView(navBar)
        setContentView(root)

        // ── Load document ───────────────────────────────────────────────────
        val path = intent.getStringExtra(EXTRA_PDF_PATH) ?: run {
            Toast.makeText(this, "No PDF path provided", Toast.LENGTH_LONG).show()
            finish(); return
        }

        lifecycleScope.launch(Dispatchers.IO) {
            val doc = runCatching { MuPDFDocument.open(path) }.getOrElse {
                withContext(Dispatchers.Main) {
                    Toast.makeText(
                        this@TiledViewerActivity,
                        "Cannot open: ${it.message}",
                        Toast.LENGTH_LONG
                    ).show()
                    finish()
                }
                return@launch
            }
            withContext(Dispatchers.Main) {
                document = doc
                title = doc.title?.let { "Tiled Viewer – $it" } ?: "Tiled Viewer"
                loadPage(0)
            }
        }
    }

    override fun onDestroy() {
        document?.close()
        super.onDestroy()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Page navigation
    // ─────────────────────────────────────────────────────────────────────────

    private fun loadPage(index: Int) {
        val doc = document ?: return
        lifecycleScope.launch(Dispatchers.IO) {
            val page = runCatching { doc.loadPage(index) }.getOrNull()
            withContext(Dispatchers.Main) {
                tiledView.setPage(page)
                currentPage = index
                pageLabel.text = "${index + 1} / ${doc.pageCount}"
                prevBtn.isEnabled = index > 0
                nextBtn.isEnabled = index < doc.pageCount - 1
            }
        }
    }

    private fun navigate(delta: Int) {
        val doc = document ?: return
        val next = currentPage + delta
        if (next in 0 until doc.pageCount) loadPage(next)
    }
}
