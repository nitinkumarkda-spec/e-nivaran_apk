package `in`.gov.rajasthan.kdakota.enivaran.department

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import android.print.pdf.PrintedPdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.Base64
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val CHANNEL = "in.gov.rajasthan.kdakota.enivaran/print"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "printComplaint" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                    startComplaintPrintJob(data)
                    result.success(true)
                }
                "print" -> {
                    val title = call.argument<String>("title") ?: "KDA-Complaint-Print"
                    val url = call.argument<String>("url") ?: "https://kdakota.rajasthan.gov.in/enivaran/"
                    startGenericPrintJob(title, url)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startComplaintPrintJob(complaintData: Map<String, Any?>) {
        thread {
            // 1. Load logo bitmap from Flutter assets
            var logoBitmap: Bitmap? = null
            try {
                assets.open("flutter_assets/assets/images/logo2.png").use { stream ->
                    logoBitmap = BitmapFactory.decodeStream(stream)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // 2. Decode or download citizen photo
            var photoBitmap: Bitmap? = null
            val base64Str = complaintData["citizenPhotoBase64"] as? String
            if (!base64Str.isNullOrEmpty()) {
                try {
                    val cleanBase64 = if (base64Str.contains(",")) base64Str.substringAfter(",") else base64Str
                    val decodedBytes = Base64.decode(cleanBase64, Base64.DEFAULT)
                    photoBitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            if (photoBitmap == null) {
                val photoUrl = complaintData["citizenPhotoUrl"] as? String
                if (!photoUrl.isNullOrEmpty() && (photoUrl.startsWith("http://") || photoUrl.startsWith("https://"))) {
                    try {
                        val conn = URL(photoUrl).openConnection() as HttpURLConnection
                        conn.connectTimeout = 4000
                        conn.readTimeout = 4000
                        conn.doInput = true
                        conn.connect()
                        if (conn.responseCode == 200) {
                            conn.inputStream.use { stream ->
                                photoBitmap = BitmapFactory.decodeStream(stream)
                            }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }

            runOnUiThread {
                val printManager = getSystemService(Context.PRINT_SERVICE) as? PrintManager ?: return@runOnUiThread
                val complaintNo = (complaintData["complaintNo"] as? String)?.takeIf { it.isNotEmpty() } ?: "Document"
                val jobName = "KDA_$complaintNo".replace(Regex("[^a-zA-Z0-9_-]"), "_")

                val printAttributes = PrintAttributes.Builder()
                    .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                    .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                    .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                    .build()

                val adapter = ComplaintPrintDocumentAdapter(this, complaintData, logoBitmap, photoBitmap)
                printManager.print(jobName, adapter, printAttributes)
            }
        }
    }

    private fun startGenericPrintJob(rawTitle: String, url: String) {
        val jobName = rawTitle.replace(Regex("[^a-zA-Z0-9_-]"), "_").take(50).ifEmpty { "KDA-Document" }
        val printManager = getSystemService(Context.PRINT_SERVICE) as? PrintManager ?: return

        val printAttributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
            .build()

        val printWebView = WebView(this)
        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        cookieManager.setAcceptThirdPartyCookies(printWebView, true)
        printWebView.settings.javaScriptEnabled = true
        printWebView.settings.domStorageEnabled = true
        printWebView.settings.loadWithOverviewMode = true
        printWebView.settings.useWideViewPort = true

        printWebView.webViewClient = object : WebViewClient() {
            private var hasPrinted = false
            override fun onPageFinished(view: WebView, loadedUrl: String) {
                if (!hasPrinted) {
                    hasPrinted = true
                    view.postDelayed({
                        val printAdapter = view.createPrintDocumentAdapter(jobName)
                        printManager.print(jobName, printAdapter, printAttributes)
                    }, 400)
                }
            }
        }
        printWebView.loadUrl(url)
    }
}

class ComplaintPrintDocumentAdapter(
    private val context: Context,
    private val complaint: Map<String, Any?>,
    private val logoBitmap: Bitmap?,
    private val photoBitmap: Bitmap?
) : PrintDocumentAdapter() {
    private var currentAttributes: PrintAttributes = PrintAttributes.Builder()
        .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
        .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
        .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
        .build()

    override fun onLayout(
        oldAttributes: PrintAttributes?,
        newAttributes: PrintAttributes?,
        cancellationSignal: CancellationSignal?,
        callback: LayoutResultCallback?,
        extras: Bundle?
    ) {
        if (cancellationSignal?.isCanceled == true) {
            callback?.onLayoutCancelled()
            return
        }

        if (newAttributes != null) {
            currentAttributes = newAttributes
        }

        val no = (complaint["complaintNo"] as? String)?.takeIf { it.isNotEmpty() } ?: "Details"
        val info = PrintDocumentInfo.Builder("Complaint_$no.pdf")
            .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
            .setPageCount(PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
            .build()

        callback?.onLayoutFinished(info, newAttributes != oldAttributes)
    }

    override fun onWrite(
        pages: Array<out PageRange>?,
        destination: ParcelFileDescriptor?,
        cancellationSignal: CancellationSignal?,
        callback: WriteResultCallback?
    ) {
        if (destination == null) {
            callback?.onWriteFailed("Destination is null")
            return
        }

        val pdfDocument = PrintedPdfDocument(context, currentAttributes)
        try {
            renderDocument(pdfDocument)

            FileOutputStream(destination.fileDescriptor).use { out ->
                pdfDocument.writeTo(out)
                out.flush()
            }

            callback?.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
        } catch (e: Exception) {
            callback?.onWriteFailed(e.message ?: "Failed to generate print document")
        } finally {
            pdfDocument.close()
        }
    }

    private fun renderDocument(pdfDocument: PrintedPdfDocument) {
        var pageNum = 1
        var page = pdfDocument.startPage(pageNum - 1)
        var canvas = page.canvas

        val left = 36f
        val right = 559f
        val usableWidth = right - left // 523f
        val maxY = 780f

        val complaintNo = (complaint["complaintNo"] as? String)?.takeIf { it.isNotEmpty() } ?: "CMS20260900005"
        val status = (complaint["status"] as? String)?.takeIf { it.isNotEmpty() } ?: "Pending (Moderation)"
        val priority = (complaint["priority"] as? String)?.takeIf { it.isNotEmpty() } ?: "Urgent Priority"
        val title = (complaint["title"] as? String)?.takeIf { it.isNotEmpty() } ?: "Complaint Details"
        val description = (complaint["description"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val slaDeadline = (complaint["slaDeadline"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val type = (complaint["type"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val subType = (complaint["subType"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val zone = (complaint["zone"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val address = (complaint["address"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val pageUrl = (complaint["url"] as? String)?.takeIf { it.isNotEmpty() } ?: "https://kdakota.rajasthan.gov.in/enivaran/"
        @Suppress("UNCHECKED_CAST")
        val historyList = complaint["history"] as? List<Map<String, Any?>> ?: emptyList()

        // ── 1. Top Header ──
        var curY = 32f

        // Draw KDA Logo
        if (logoBitmap != null) {
            val logoRect = RectF(left, curY, left + 48f, curY + 48f)
            canvas.drawBitmap(logoBitmap, null, logoRect, null)
        }

        // Draw Title text
        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            textSize = 20f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val accentPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#4361EE")
            textSize = 20f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD_ITALIC)
        }
        val subPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#4361EE")
            textSize = 11.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        val textStartX = if (logoBitmap != null) left + 58f else left
        val kdaWidth = titlePaint.measureText("KDA ")
        val eWidth = accentPaint.measureText("e")

        canvas.drawText("KDA ", textStartX, curY + 22f, titlePaint)
        canvas.drawText("e", textStartX + kdaWidth, curY + 22f, accentPaint)
        canvas.drawText("-Nivaran", textStartX + kdaWidth + eWidth, curY + 22f, titlePaint)
        canvas.drawText("A Civic Infrastructure Grievance Portal", textStartX, curY + 40f, subPaint)

        curY += 54f

        // Header Line Divider
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1E293B")
            strokeWidth = 2.5f
        }
        canvas.drawLine(left, curY, right, curY, linePaint)
        curY += 16f

        // ── 2. Complaint Identification & Badges ──
        val noPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            textSize = 17f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(complaintNo, left, curY + 14f, noPaint)
        curY += 24f

        // Badges: Status and Priority
        var badgeX = left
        badgeX = drawBadge(canvas, badgeX, curY, status, isPriority = false)
        drawBadge(canvas, badgeX + 8f, curY, priority, isPriority = true)
        curY += 24f

        // ── 3. Section 1: Complaint Details Card ──
        val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val cardBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#CBD5E1")
            style = Paint.Style.STROKE
            strokeWidth = 1f
        }
        val cardHeaderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#EEF1FB")
            style = Paint.Style.FILL
        }
        val cardHeaderTitlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            textSize = 9.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            letterSpacing = 0.04f
        }

        val card1Top = curY
        curY += 22f // for card header

        // Card 1 Body
        val h5Paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#0F172A")
            textSize = 12f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val descPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#475569")
            textSize = 9f
            typeface = Typeface.DEFAULT
        }
        val labelPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#64748B")
            textSize = 7.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            letterSpacing = 0.04f
        }
        val valuePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#0F172A")
            textSize = 9f
            typeface = Typeface.DEFAULT
        }
        val dividerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#E2E8F0")
            strokeWidth = 0.8f
        }

        val innerLeft = left + 14f
        val innerRight = right - 14f
        val innerWidth = (innerRight - innerLeft).toInt()

        curY += 8f
        val titleH = drawMultilineText(canvas, title, innerLeft, curY, innerWidth, h5Paint)
        curY += titleH + 4f

        val descH = drawMultilineText(canvas, description, innerLeft, curY, innerWidth, descPaint)
        curY += descH + 10f

        canvas.drawLine(innerLeft, curY, innerRight, curY, dividerPaint)
        curY += 8f

        // Grid (2 columns)
        val col1X = innerLeft
        val col2X = innerLeft + (innerWidth / 2f) + 10f
        val colW = (innerWidth / 2f - 16f).toInt()

        canvas.drawText("COMPLAINT NO.", col1X, curY + 7f, labelPaint)
        canvas.drawText("SLA DEADLINE", col2X, curY + 7f, labelPaint)
        curY += 11f
        canvas.drawText(complaintNo, col1X, curY + 9f, valuePaint)
        canvas.drawText(slaDeadline, col2X, curY + 9f, valuePaint)
        curY += 16f

        canvas.drawText("TYPE", col1X, curY + 7f, labelPaint)
        canvas.drawText("SUB TYPE", col2X, curY + 7f, labelPaint)
        curY += 11f
        val typeH = drawMultilineText(canvas, type, col1X, curY, colW, valuePaint)
        val subTypeH = drawMultilineText(canvas, subType, col2X, curY, colW, valuePaint)
        curY += maxOf(typeH, subTypeH) + 6f

        canvas.drawText("ZONE", col1X, curY + 7f, labelPaint)
        curY += 11f
        canvas.drawText(zone, col1X, curY + 9f, valuePaint)
        curY += 16f

        canvas.drawText("ADDRESS", innerLeft, curY + 7f, labelPaint)
        curY += 11f
        val pinPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#EF4444")
            style = Paint.Style.FILL
        }
        canvas.drawCircle(innerLeft + 3f, curY + 5f, 3f, pinPaint)
        val addrH = drawMultilineText(canvas, address, innerLeft + 10f, curY, innerWidth - 10, valuePaint)
        curY += addrH + 12f

        val card1Bottom = curY
        drawCardContainer(canvas, left, card1Top, right, card1Bottom, "COMPLAINT DETAILS", cardPaint, cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)

        curY += 14f

        // ── 4. Section 2: Citizen Submitted Card ──
        val card2Top = curY
        curY += 22f

        if (photoBitmap != null) {
            curY += 8f
            val maxW = 200f
            val maxH = 110f
            var w = photoBitmap.width.toFloat()
            var h = photoBitmap.height.toFloat()
            val scale = minOf(maxW / w, maxH / h)
            w *= scale
            h *= scale

            val imgRect = RectF(innerLeft, curY, innerLeft + w, curY + h)
            canvas.drawBitmap(photoBitmap, null, imgRect, null)
            canvas.drawRoundRect(imgRect, 4f, 4f, cardBorderPaint)
            curY += h + 10f
        } else {
            curY += 10f
            val noPhotoPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#94A3B8")
                textSize = 8.5f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
            }
            canvas.drawText("No attachments provided", innerLeft, curY + 8f, noPhotoPaint)
            curY += 22f
        }

        val card2Bottom = curY
        drawCardContainer(canvas, left, card2Top, right, card2Bottom, "CITIZEN SUBMITTED", cardPaint, cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)

        curY += 14f

        // ── 5. Section 3: Complaint History Card ──
        var isPage2 = false
        if (curY + 80f > maxY) {
            drawFooter(canvas, left, right, pageUrl, 1, 2)
            pdfDocument.finishPage(page)

            pageNum = 2
            isPage2 = true
            page = pdfDocument.startPage(pageNum - 1)
            canvas = page.canvas

            val runHeaderPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#64748B")
                textSize = 9f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }
            canvas.drawText("KDA e-Nivaran — Complaint $complaintNo (Continued)", left, 40f, runHeaderPaint)
            canvas.drawLine(left, 46f, right, 46f, dividerPaint)
            curY = 56f
        }

        val card3Top = curY
        curY += 22f

        if (historyList.isEmpty()) {
            curY += 10f
            val noHistPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#94A3B8")
                textSize = 8.5f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
            }
            canvas.drawText("No history yet", innerLeft, curY + 8f, noHistPaint)
            curY += 22f
        } else {
            curY += 8f
            val actPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1A1A2E")
                textSize = 9f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }
            val byPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#334155")
                textSize = 8f
                typeface = Typeface.DEFAULT
            }
            val timePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#64748B")
                textSize = 8f
                typeface = Typeface.DEFAULT
            }
            val remPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#475569")
                textSize = 7.5f
                typeface = Typeface.DEFAULT
            }
            val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#4361EE")
                style = Paint.Style.FILL
            }
            val timelineLinePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#CBD5E1")
                strokeWidth = 1f
            }

            for (i in historyList.indices) {
                val item = historyList[i]
                val action = (item["action"] as? String)?.takeIf { it.isNotEmpty() } ?: "Updated"
                val time = (item["time"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val by = (item["by"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val remarks = (item["remarks"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val duration = (item["duration"] as? String)?.takeIf { it.isNotEmpty() } ?: ""

                if (!isPage2 && curY + 40f > maxY) {
                    drawCardContainer(canvas, left, card3Top, right, curY + 6f, "COMPLAINT HISTORY", cardPaint, cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
                    drawFooter(canvas, left, right, pageUrl, 1, 2)
                    pdfDocument.finishPage(page)

                    pageNum = 2
                    isPage2 = true
                    page = pdfDocument.startPage(pageNum - 1)
                    canvas = page.canvas

                    val runHeaderPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = Color.parseColor("#64748B")
                        textSize = 9f
                        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    }
                    canvas.drawText("KDA e-Nivaran — Complaint $complaintNo (History Continued)", left, 40f, runHeaderPaint)
                    canvas.drawLine(left, 46f, right, 46f, dividerPaint)
                    curY = 56f
                }

                val itemStartY = curY
                val dotX = innerLeft + 6f
                val contentX = innerLeft + 18f

                canvas.drawCircle(dotX, curY + 5f, 3.5f, dotPaint)

                canvas.drawText(action, contentX, curY + 8f, actPaint)
                val actWidth = actPaint.measureText(action)

                var durOffset = contentX + actWidth + 6f
                if (duration.isNotEmpty()) {
                    durOffset = drawPill(canvas, durOffset, curY - 1f, duration, "#F1F5F9", "#64748B", "#CBD5E1") + 6f
                }

                if (time.isNotEmpty()) {
                    val timeW = timePaint.measureText(time)
                    canvas.drawText(time, innerRight - timeW, curY + 8f, timePaint)
                }
                curY += 13f

                if (by.isNotEmpty()) {
                    canvas.drawText(by, contentX, curY + 8f, byPaint)
                    curY += 12f
                }

                if (remarks.isNotEmpty()) {
                    val remH = drawMultilineText(canvas, remarks, contentX, curY, (innerRight - contentX).toInt(), remPaint)
                    curY += remH + 4f
                }

                curY += 6f

                if (i < historyList.size - 1) {
                    canvas.drawLine(dotX, itemStartY + 9f, dotX, curY + 5f, timelineLinePaint)
                }
            }
            curY += 4f
        }

        val card3Bottom = curY
        drawCardContainer(canvas, left, if (isPage2 && card3Top > 100f) 56f else card3Top, right, card3Bottom, "COMPLAINT HISTORY", cardPaint, cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)

        val totalPages = if (isPage2) 2 else 1
        drawFooter(canvas, left, right, pageUrl, pageNum, totalPages)

        pdfDocument.finishPage(page)
    }

    private fun drawCardContainer(
        canvas: Canvas,
        left: Float,
        top: Float,
        right: Float,
        bottom: Float,
        title: String,
        cardPaint: Paint,
        headerPaint: Paint,
        borderPaint: Paint,
        titlePaint: TextPaint
    ) {
        val r = 6f
        val headerH = 22f

        // Draw card background
        canvas.drawRoundRect(RectF(left, top, right, bottom), r, r, cardPaint)

        // Draw card header background with top rounded corners
        val path = Path()
        val radii = floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f)
        path.addRoundRect(RectF(left, top, right, top + headerH), radii, Path.Direction.CW)
        canvas.drawPath(path, headerPaint)

        // Header bottom divider line
        canvas.drawLine(left, top + headerH, right, top + headerH, borderPaint)

        // Outer card border
        canvas.drawRoundRect(RectF(left, top, right, bottom), r, r, borderPaint)

        // Header title
        canvas.drawText(title, left + 14f, top + 15f, titlePaint)
    }

    private fun drawBadge(
        canvas: Canvas,
        x: Float,
        y: Float,
        text: String,
        isPriority: Boolean
    ): Float {
        val lower = text.lowercase()
        val bgColor: Int
        val textColor: Int
        val borderColor: Int

        if (isPriority) {
            when {
                lower.contains("urgent") -> {
                    bgColor = Color.parseColor("#FEE2E2")
                    textColor = Color.parseColor("#B91C1C")
                    borderColor = Color.parseColor("#EF4444")
                }
                lower.contains("high") -> {
                    bgColor = Color.parseColor("#FFEDD5")
                    textColor = Color.parseColor("#C2410C")
                    borderColor = Color.parseColor("#F97316")
                }
                else -> {
                    bgColor = Color.parseColor("#F1F5F9")
                    textColor = Color.parseColor("#334155")
                    borderColor = Color.parseColor("#94A3B8")
                }
            }
        } else {
            when {
                lower.contains("pending") -> {
                    bgColor = Color.parseColor("#FEF3C7")
                    textColor = Color.parseColor("#B45309")
                    borderColor = Color.parseColor("#F59E0B")
                }
                lower.contains("completed") || lower.contains("resolved") || lower.contains("approved") -> {
                    bgColor = Color.parseColor("#D1FAE5")
                    textColor = Color.parseColor("#065F46")
                    borderColor = Color.parseColor("#10B981")
                }
                lower.contains("reject") -> {
                    bgColor = Color.parseColor("#FEE2E2")
                    textColor = Color.parseColor("#991B1B")
                    borderColor = Color.parseColor("#EF4444")
                }
                else -> {
                    bgColor = Color.parseColor("#F1F5F9")
                    textColor = Color.parseColor("#334155")
                    borderColor = Color.parseColor("#94A3B8")
                }
            }
        }

        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = textColor
            textSize = 8.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val textWidth = textPaint.measureText(text)
        val padX = 8f
        val badgeW = textWidth + (padX * 2f)
        val badgeH = 16f

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = bgColor
            style = Paint.Style.FILL
        }
        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = borderColor
            style = Paint.Style.STROKE
            strokeWidth = 1f
        }

        val rect = RectF(x, y, x + badgeW, y + badgeH)
        canvas.drawRoundRect(rect, 3.5f, 3.5f, bgPaint)
        canvas.drawRoundRect(rect, 3.5f, 3.5f, borderPaint)
        canvas.drawText(text, x + padX, y + 11.5f, textPaint)

        return x + badgeW
    }

    private fun drawPill(
        canvas: Canvas,
        x: Float,
        y: Float,
        text: String,
        bgHex: String,
        textHex: String,
        borderHex: String
    ): Float {
        val textPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(textHex)
            textSize = 7.5f
            typeface = Typeface.DEFAULT
        }
        val textW = textPaint.measureText(text)
        val padX = 5f
        val pillW = textW + (padX * 2f)
        val pillH = 13f

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(bgHex)
            style = Paint.Style.FILL
        }
        val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(borderHex)
            style = Paint.Style.STROKE
            strokeWidth = 0.8f
        }

        val rect = RectF(x, y, x + pillW, y + pillH)
        canvas.drawRoundRect(rect, 3f, 3f, bgPaint)
        canvas.drawRoundRect(rect, 3f, 3f, borderPaint)
        canvas.drawText(text, x + padX, y + 9.5f, textPaint)

        return x + pillW
    }

    private fun drawFooter(
        canvas: Canvas,
        left: Float,
        right: Float,
        url: String,
        pageNum: Int,
        total: Int
    ) {
        val footerY = 812f
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#CBD5E1")
            strokeWidth = 0.6f
        }
        canvas.drawLine(left, footerY, right, footerY, linePaint)

        val footerTextPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#64748B")
            textSize = 7f
            typeface = Typeface.DEFAULT
        }

        val displayUrl = if (url.length > 70) url.take(67) + "..." else url
        canvas.drawText(displayUrl, left, footerY + 12f, footerTextPaint)

        val pageStr = "$pageNum/$total"
        val pageW = footerTextPaint.measureText(pageStr)
        canvas.drawText(pageStr, right - pageW, footerY + 12f, footerTextPaint)
    }

    private fun drawMultilineText(
        canvas: Canvas,
        text: String,
        x: Float,
        y: Float,
        width: Int,
        paint: TextPaint
    ): Float {
        if (text.isEmpty() || width <= 0) return 0f
        val layout = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setLineSpacing(0f, 1.15f)
                .setIncludePad(false)
                .build()
        } else {
            @Suppress("DEPRECATION")
            StaticLayout(text, paint, width, Layout.Alignment.ALIGN_NORMAL, 1.15f, 0f, false)
        }
        canvas.save()
        canvas.translate(x, y)
        layout.draw(canvas)
        canvas.restore()
        return layout.height.toFloat()
    }
}
