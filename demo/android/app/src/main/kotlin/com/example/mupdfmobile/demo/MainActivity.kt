package com.example.mupdfmobile.demo

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.AppCompatButton
import android.widget.LinearLayout
import android.widget.TextView
import android.view.Gravity
import android.graphics.Color

/**
 * Entry-point Activity for the MuPDF Mobile demo application.
 *
 * Presents a simple UI with a button to pick a PDF file from storage,
 * then launches [PDFViewerActivity] to display it.
 */
class MainActivity : AppCompatActivity() {

    private val pickPdf = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { openViewer(it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Build layout programmatically to keep the demo self-contained.
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity     = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(Color.WHITE)
        }
        setContentView(root)

        val title = TextView(this).apply {
            text     = "MuPDF Mobile Demo"
            textSize = 24f
            setTextColor(Color.parseColor("#1A1A2E"))
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(this).apply {
            text     = "Cross-platform PDF rendering powered by MuPDF"
            textSize = 14f
            setTextColor(Color.parseColor("#6B6B8D"))
            gravity   = Gravity.CENTER
            setPadding(0, 12, 0, 40)
        }

        val openBtn = AppCompatButton(this).apply {
            text = "Open PDF from Storage"
            setOnClickListener { pickPdf.launch("application/pdf") }
        }

        root.addView(title)
        root.addView(subtitle)
        root.addView(openBtn)
    }

    private fun openViewer(uri: Uri) {
        val intent = Intent(this, PDFViewerActivity::class.java).apply {
            putExtra(PDFViewerActivity.EXTRA_PDF_URI, uri.toString())
        }
        startActivity(intent)
    }
}
