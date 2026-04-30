package com.example.mupdfmobile.demo

import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.artifex.mupdf.mobile.MuPDFDocument
import com.artifex.mupdf.mobile.MuPDFRenderer
import kotlinx.coroutines.*

/**
 * RecyclerView adapter that renders page thumbnails asynchronously.
 */
class ThumbnailAdapter(
    private val document: MuPDFDocument,
    private val scope: CoroutineScope,
    private val onPageClick: (Int) -> Unit
) : RecyclerView.Adapter<ThumbnailAdapter.ViewHolder>() {

    inner class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val imageView: ImageView = itemView.findViewById(android.R.id.icon)
        val pageLabel: TextView  = itemView.findViewById(android.R.id.text1)
        var renderJob: Job? = null
    }

    override fun getItemCount(): Int = document.pageCount

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val frameLayout = FrameLayout(parent.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(4, 4, 4, 4)
        }
        val imageView = ImageView(parent.context).apply {
            id = android.R.id.icon
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                300
            )
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(Color.WHITE)
        }
        val textView = TextView(parent.context).apply {
            id = android.R.id.text1
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).also { it.topMargin = 304 }
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            textSize = 10f
        }
        frameLayout.addView(imageView)
        frameLayout.addView(textView)
        return ViewHolder(frameLayout)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.renderJob?.cancel()
        holder.imageView.setImageBitmap(null)
        holder.pageLabel.text = "${position + 1}"

        holder.renderJob = scope.launch {
            val bitmap = withContext(Dispatchers.IO) {
                runCatching {
                    val page = document.loadPage(position)
                    val result = MuPDFRenderer.render(page, 0.3f)
                    page.close()
                    result
                }.getOrNull()
            }
            holder.imageView.setImageBitmap(bitmap?.bitmap)
        }

        holder.itemView.setOnClickListener { onPageClick(position) }
    }

    override fun onViewRecycled(holder: ViewHolder) {
        super.onViewRecycled(holder)
        holder.renderJob?.cancel()
        holder.imageView.setImageBitmap(null)
    }
}
