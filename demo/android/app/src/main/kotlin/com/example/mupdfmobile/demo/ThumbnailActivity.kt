package com.example.mupdfmobile.demo

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.artifex.mupdf.mobile.MuPDFDocument

/**
 * Full-screen RecyclerView grid of page thumbnails.
 *
 * Selecting a thumbnail finishes this activity and returns the chosen page index
 * to the caller via [RESULT_PAGE_INDEX].
 */
class ThumbnailActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PDF_PATH    = "extra_pdf_path"
        const val RESULT_PAGE_INDEX = "result_page_index"
    }

    private var document: MuPDFDocument? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Page Thumbnails"

        val path = intent.getStringExtra(EXTRA_PDF_PATH) ?: run {
            Toast.makeText(this, "No path provided", Toast.LENGTH_SHORT).show()
            finish(); return
        }

        val doc = runCatching { MuPDFDocument.open(path) }.getOrElse {
            Toast.makeText(this, "Cannot open: ${it.message}", Toast.LENGTH_LONG).show()
            finish(); return
        }
        document = doc

        val rv = RecyclerView(this)
        rv.layoutManager = GridLayoutManager(this, 3)
        rv.adapter = ThumbnailAdapter(doc, lifecycleScope) { index ->
            val result = Intent().putExtra(RESULT_PAGE_INDEX, index)
            setResult(Activity.RESULT_OK, result)
            finish()
        }
        setContentView(rv)
    }

    override fun onDestroy() {
        document?.close()
        super.onDestroy()
    }
}
