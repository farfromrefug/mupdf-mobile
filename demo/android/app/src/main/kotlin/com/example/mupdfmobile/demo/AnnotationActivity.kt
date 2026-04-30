package com.example.mupdfmobile.demo

import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.artifex.mupdf.mobile.*
import kotlinx.coroutines.*

/**
 * Demonstrates annotation add / list / remove on a page.
 */
class AnnotationActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_PDF_PATH = "extra_pdf_path"
    }

    private var document: MuPDFDocument? = null
    private var currentPage: MuPDFPage? = null
    private val annotations = mutableListOf<MuPDFAnnotation>()

    private lateinit var pageImageView: ImageView
    private lateinit var listView: ListView
    private lateinit var listAdapter: ArrayAdapter<String>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Annotations Demo"

        val path = intent.getStringExtra(EXTRA_PDF_PATH) ?: run { finish(); return }
        val doc = runCatching { MuPDFDocument.open(path) }.getOrElse { finish(); return }
        document = doc

        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        setContentView(root)

        pageImageView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(android.graphics.Color.LTGRAY)
        }

        listAdapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, mutableListOf<String>())
        listView = ListView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            adapter = listAdapter
        }
        listView.setOnItemLongClickListener { _, _, position, _ ->
            removeAnnotation(position); true
        }

        val toolbar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(8, 8, 8, 8)
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
        }
        for ((label, type) in listOf(
            "Highlight" to MuPDFAnnotationType.Highlight,
            "Underline" to MuPDFAnnotationType.Underline,
            "Ink"       to MuPDFAnnotationType.Ink,
        )) {
            val btn = Button(this).apply {
                text = label
                setOnClickListener { addAnnotation(type) }
            }
            toolbar.addView(btn)
        }

        root.addView(pageImageView)
        root.addView(listView)
        root.addView(toolbar)

        loadPage(0)
    }

    override fun onDestroy() {
        document?.close()
        super.onDestroy()
    }

    private fun loadPage(index: Int) {
        val doc = document ?: return
        lifecycleScope.launch(Dispatchers.IO) {
            val page   = runCatching { doc.loadPage(index) }.getOrNull() ?: return@launch
            val bitmap = runCatching { page.render(1.5f) }.getOrNull()
            val annots = runCatching { page.annotations() }.getOrElse { emptyList() }
            withContext(Dispatchers.Main) {
                currentPage = page
                pageImageView.setImageBitmap(bitmap?.bitmap)
                annotations.clear()
                annotations.addAll(annots)
                refreshList()
            }
        }
    }

    private fun addAnnotation(type: MuPDFAnnotationType) {
        val page = currentPage ?: return
        val rect = MuPDFRect(72f, 100f, 200f, 20f)
        runCatching {
            val annot = page.addAnnotation(type, rect)
            annot.color = MuPDFColor(1f, 1f, 0f, 0.5f)
            annot.update()
            annotations.add(annot)
            refreshList()
        }.onFailure {
            Toast.makeText(this, "Failed: ${it.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun removeAnnotation(position: Int) {
        val page = currentPage ?: return
        val annot = annotations.getOrNull(position) ?: return
        AlertDialog.Builder(this)
            .setTitle("Remove annotation?")
            .setPositiveButton("Remove") { _, _ ->
                runCatching { page.removeAnnotation(annot) }
                annotations.removeAt(position)
                refreshList()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun refreshList() {
        listAdapter.clear()
        listAdapter.addAll(annotations.mapIndexed { i, a ->
            "${i + 1}. ${a.type.displayName}  [${a.rect.x.toInt()},${a.rect.y.toInt()}]"
        })
    }
}
