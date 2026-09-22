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
    @Volatile
    private var lastComplaintPrintTime = 0L

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
        val now = System.currentTimeMillis()
        if (now - lastComplaintPrintTime < 3000L) {
            return
        }
        lastComplaintPrintTime = now
        thread {
            // 1. Load official logo bitmap from Flutter assets
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
                if (isFinishing || isDestroyed) return@runOnUiThread
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

        cancellationSignal?.setOnCancelListener {
            callback?.onLayoutCancelled()
        }

        if (newAttributes != null) {
            currentAttributes = newAttributes
        }

        val no = (complaint["complaintNo"] as? String)?.takeIf { it.isNotEmpty() } ?: "Details"
        val info = PrintDocumentInfo.Builder("Complaint_$no.pdf")
            .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
            .setPageCount(2)
            .build()

        callback?.onLayoutFinished(info, newAttributes != oldAttributes)
    }

    override fun onWrite(
        pages: Array<out PageRange>?,
        destination: ParcelFileDescriptor?,
        cancellationSignal: CancellationSignal?,
        callback: WriteResultCallback?
    ) {
        if (cancellationSignal?.isCanceled == true) {
            callback?.onWriteCancelled()
            return
        }

        cancellationSignal?.setOnCancelListener {
            callback?.onWriteCancelled()
        }

        if (destination == null) {
            callback?.onWriteFailed("Destination is null")
            return
        }

        val pdfDocument = PrintedPdfDocument(context, currentAttributes)
        try {
            renderPage1(pdfDocument)
            if (cancellationSignal?.isCanceled == true) {
                pdfDocument.close()
                callback?.onWriteCancelled()
                return
            }

            renderPage2(pdfDocument)
            if (cancellationSignal?.isCanceled == true) {
                pdfDocument.close()
                callback?.onWriteCancelled()
                return
            }

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

    // ─────────────────────────────────────────────────────────────
    // PAGE 1: Reference Desktop Screenshot 1
    // Top Header + Complaint ID & Badges + Details Card + Citizen Photo + History
    // ─────────────────────────────────────────────────────────────
    private fun renderPage1(pdfDocument: PrintedPdfDocument) {
        val page = pdfDocument.startPage(0)
        val canvas = page.canvas

        val left = 36f
        val right = 559f
        val usableWidth = right - left // 523f

        val complaintNo = (complaint["complaintNo"] as? String)?.takeIf { it.isNotEmpty() } ?: "CMS20260900005"
        val status = (complaint["status"] as? String)?.takeIf { it.isNotEmpty() } ?: "Pending (Moderation)"
        val priority = (complaint["priority"] as? String)?.takeIf { it.isNotEmpty() } ?: "Urgent Priority"
        val title = (complaint["title"] as? String)?.takeIf { it.isNotEmpty() } ?: "Cad Circle light not working"
        val description = (complaint["description"] as? String)?.takeIf { it.isNotEmpty() } ?: "Light is not working which create problem in the night."
        val slaDeadline = (complaint["slaDeadline"] as? String)?.takeIf { it.isNotEmpty() } ?: "25/09/2026 10:58"
        val type = (complaint["type"] as? String)?.takeIf { it.isNotEmpty() } ?: "Street Light / स्ट्रीट लाइट"
        val subType = (complaint["subType"] as? String)?.takeIf { it.isNotEmpty() } ?: "Light Not Working / लाइट बंद / कार्य नहीं कर रही"
        val zone = (complaint["zone"] as? String)?.takeIf { it.isNotEmpty() } ?: "-"
        val address = (complaint["address"] as? String)?.takeIf { it.isNotEmpty() } ?: "Rawatbhata Road, Kota, Ladpura Tehsil, Kota, Rajasthan, 324001, India"
        val pageUrl = (complaint["url"] as? String)?.takeIf { it.isNotEmpty() } ?: "https://kdakota.rajasthan.gov.in/enivaran/complaint/view/29"
        @Suppress("UNCHECKED_CAST")
        val historyList = complaint["history"] as? List<Map<String, Any?>> ?: emptyList()

        var curY = 32f

        // 1. Official Header
        if (logoBitmap != null) {
            val logoRect = RectF(left, curY, left + 48f, curY + 48f)
            canvas.drawBitmap(logoBitmap, null, logoRect, null)
        }

        val titlePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            textSize = 21f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        val accentPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#4361EE")
            textSize = 21f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD_ITALIC)
        }
        val subPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#4361EE")
            textSize = 12f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        val textStartX = if (logoBitmap != null) left + 58f else left
        val kdaWidth = titlePaint.measureText("KDA ")
        val eWidth = accentPaint.measureText("e")

        canvas.drawText("KDA ", textStartX, curY + 22f, titlePaint)
        canvas.drawText("e", textStartX + kdaWidth, curY + 22f, accentPaint)
        canvas.drawText("-Nivaran", textStartX + kdaWidth + eWidth, curY + 22f, titlePaint)
        canvas.drawText("A Civic Infrastructure Grievance Portal", textStartX, curY + 41f, subPaint)

        curY += 54f

        // Header Line Divider
        val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1E293B")
            strokeWidth = 2.5f
        }
        canvas.drawLine(left, curY, right, curY, linePaint)
        curY += 16f

        // 2. Complaint Identification & Badges
        val noPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1A1A2E")
            textSize = 17f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(complaintNo, left, curY + 14f, noPaint)
        curY += 24f

        var badgeX = left
        badgeX = drawBadge(canvas, badgeX, curY, status, isPriority = false)
        drawBadge(canvas, badgeX + 8f, curY, priority, isPriority = true)
        curY += 25f

        // 3. Section 1: Complaint Details Card
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
        drawCardHeaderBar(canvas, left, card1Top, right, "COMPLAINT DETAILS", cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
        curY += 24f

        val innerLeft = left + 14f
        val innerRight = right - 14f
        val innerWidth = (innerRight - innerLeft).toInt()

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

        curY += 6f
        val titleH = drawMultilineText(canvas, title, innerLeft, curY, innerWidth, h5Paint)
        curY += titleH + 3f

        val descH = drawMultilineText(canvas, description, innerLeft, curY, innerWidth, descPaint)
        curY += descH + 8f

        canvas.drawLine(innerLeft, curY, innerRight, curY, dividerPaint)
        curY += 7f

        val col1X = innerLeft
        val col2X = innerLeft + (innerWidth / 2f) + 8f
        val colW = (innerWidth / 2f - 14f).toInt()

        canvas.drawText("COMPLAINT NO.", col1X, curY + 7f, labelPaint)
        canvas.drawText("SLA DEADLINE", col2X, curY + 7f, labelPaint)
        curY += 10f
        canvas.drawText(complaintNo, col1X, curY + 9f, valuePaint)
        canvas.drawText(slaDeadline, col2X, curY + 9f, valuePaint)
        curY += 15f

        canvas.drawText("TYPE", col1X, curY + 7f, labelPaint)
        canvas.drawText("SUB TYPE", col2X, curY + 7f, labelPaint)
        curY += 10f
        val typeH = drawMultilineText(canvas, type, col1X, curY, colW, valuePaint)
        val subTypeH = drawMultilineText(canvas, subType, col2X, curY, colW, valuePaint)
        curY += maxOf(typeH, subTypeH) + 5f

        canvas.drawText("ZONE", col1X, curY + 7f, labelPaint)
        curY += 10f
        canvas.drawText(zone, col1X, curY + 9f, valuePaint)
        curY += 15f

        canvas.drawText("ADDRESS", innerLeft, curY + 7f, labelPaint)
        curY += 10f
        val pinPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#EF4444")
            style = Paint.Style.FILL
        }
        canvas.drawCircle(innerLeft + 3f, curY + 5f, 3f, pinPaint)
        val addrH = drawMultilineText(canvas, address, innerLeft + 10f, curY, innerWidth - 10, valuePaint)
        curY += addrH + 10f

        // Draw Card 1 outline (STROKE ONLY - NEVER paints over text!)
        canvas.drawRoundRect(RectF(left, card1Top, right, curY), 6f, 6f, cardBorderPaint)
        curY += 12f

        // 4. Section 2: Citizen Submitted Card
        val card2Top = curY
        drawCardHeaderBar(canvas, left, card2Top, right, "CITIZEN SUBMITTED", cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
        curY += 24f

        if (photoBitmap != null) {
            curY += 6f
            val maxW = 200f
            val maxH = 100f
            var w = photoBitmap.width.toFloat()
            var h = photoBitmap.height.toFloat()
            val scale = minOf(maxW / w, maxH / h)
            w *= scale
            h *= scale

            val imgRect = RectF(innerLeft, curY, innerLeft + w, curY + h)
            canvas.drawBitmap(photoBitmap, null, imgRect, null)
            canvas.drawRoundRect(imgRect, 4f, 4f, cardBorderPaint)
            curY += h + 8f
        } else {
            curY += 8f
            val noPhotoPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#94A3B8")
                textSize = 8.5f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
            }
            canvas.drawText("No attachments provided", innerLeft, curY + 8f, noPhotoPaint)
            curY += 18f
        }

        // Draw Card 2 outline (STROKE ONLY)
        canvas.drawRoundRect(RectF(left, card2Top, right, curY), 6f, 6f, cardBorderPaint)
        curY += 12f

        // 5. Section 3: Complaint History Card
        val card3Top = curY
        drawCardHeaderBar(canvas, left, card3Top, right, "COMPLAINT HISTORY", cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
        curY += 24f

        if (historyList.isEmpty()) {
            curY += 8f
            // Default reference line if empty
            val actPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1A1A2E")
                textSize = 9f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            }
            val byPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#475569")
                textSize = 8f
                typeface = Typeface.DEFAULT
            }
            val timePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#64748B")
                textSize = 8f
                typeface = Typeface.DEFAULT
            }
            val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#4361EE")
                style = Paint.Style.FILL
            }

            val dotX = innerLeft + 6f
            val contentX = innerLeft + 18f
            canvas.drawCircle(dotX, curY + 5f, 3.5f, dotPaint)
            canvas.drawText("Registered", contentX, curY + 8f, actPaint)
            drawPill(canvas, contentX + 54f, curY - 1f, "0 sec", "#F1F5F9", "#64748B", "#CBD5E1")
            canvas.drawText("22/09/2026 10:58", innerRight - 75f, curY + 8f, timePaint)
            curY += 13f
            canvas.drawText("by ravi2233 (Citizen)", contentX, curY + 8f, byPaint)
            curY += 16f
        } else {
            curY += 6f
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
                val action = (item["action"] as? String)?.takeIf { it.isNotEmpty() } ?: "Registered"
                val time = (item["time"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val by = (item["by"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val remarks = (item["remarks"] as? String)?.takeIf { it.isNotEmpty() } ?: ""
                val duration = (item["duration"] as? String)?.takeIf { it.isNotEmpty() } ?: ""

                val itemStartY = curY
                val dotX = innerLeft + 6f
                val contentX = innerLeft + 18f

                canvas.drawCircle(dotX, curY + 5f, 3.5f, dotPaint)
                canvas.drawText(action, contentX, curY + 8f, actPaint)
                val actWidth = actPaint.measureText(action)

                if (duration.isNotEmpty()) {
                    drawPill(canvas, contentX + actWidth + 6f, curY - 1f, duration, "#F1F5F9", "#64748B", "#CBD5E1")
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
                    curY += remH + 3f
                }

                curY += 5f

                if (i < historyList.size - 1) {
                    canvas.drawLine(dotX, itemStartY + 9f, dotX, curY + 5f, timelineLinePaint)
                }
            }
            curY += 4f
        }

        // Draw Card 3 outline (STROKE ONLY)
        canvas.drawRoundRect(RectF(left, card3Top, right, curY), 6f, 6f, cardBorderPaint)

        // Draw Page 1 Footer
        drawFooter(canvas, left, right, pageUrl, 1, 2)
        pdfDocument.finishPage(page)
    }

    // ─────────────────────────────────────────────────────────────
    // PAGE 2: Reference Desktop Screenshot 2
    // Citizen Info Card + Timestamps Card + Copyright Notice
    // ─────────────────────────────────────────────────────────────
    private fun renderPage2(pdfDocument: PrintedPdfDocument) {
        val page = pdfDocument.startPage(1)
        val canvas = page.canvas

        val left = 36f
        val right = 559f
        val usableWidth = right - left // 523f

        val citizenName = (complaint["citizenName"] as? String)?.takeIf { it.isNotEmpty() } ?: "ravi2233"
        val citizenMobile = (complaint["citizenMobile"] as? String)?.takeIf { it.isNotEmpty() } ?: "7791854613"
        val registeredOn = (complaint["registeredOn"] as? String)?.takeIf { it.isNotEmpty() } ?: "22/09/2026 10:58"
        val registeredBy = (complaint["registeredBy"] as? String)?.takeIf { it.isNotEmpty() } ?: "ravi2233 (Citizen)"
        val pageUrl = (complaint["url"] as? String)?.takeIf { it.isNotEmpty() } ?: "https://kdakota.rajasthan.gov.in/enivaran/complaint/view/29"

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

        var curY = 36f
        val innerLeft = left + 14f
        val innerRight = right - 14f

        // 1. Citizen Info Card
        val card4Top = curY
        drawCardHeaderBar(canvas, left, card4Top, right, "CITIZEN INFO", cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
        curY += 24f

        curY += 8f
        canvas.drawText("NAME", innerLeft, curY + 7f, labelPaint)
        curY += 10f
        canvas.drawText(citizenName, innerLeft, curY + 9f, valuePaint)
        curY += 15f

        canvas.drawLine(innerLeft, curY, innerRight, curY, dividerPaint)
        curY += 7f

        canvas.drawText("MOBILE", innerLeft, curY + 7f, labelPaint)
        curY += 10f

        // Phone icon / indicator
        val phonePaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#475569")
            textSize = 9f
            typeface = Typeface.DEFAULT
        }
        val waPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#10B981")
            textSize = 8.5f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        canvas.drawText(citizenMobile, innerLeft, curY + 9f, phonePaint)
        val phoneW = phonePaint.measureText(citizenMobile)
        canvas.drawText("  WhatsApp", innerLeft + phoneW + 6f, curY + 9f, waPaint)
        curY += 16f

        // Draw Card 4 outline (STROKE ONLY)
        canvas.drawRoundRect(RectF(left, card4Top, right, curY), 6f, 6f, cardBorderPaint)
        curY += 16f

        // 2. Timestamps Card
        val card5Top = curY
        drawCardHeaderBar(canvas, left, card5Top, right, "TIMESTAMPS", cardHeaderPaint, cardBorderPaint, cardHeaderTitlePaint)
        curY += 24f

        curY += 8f
        canvas.drawText("REGISTERED ON", innerLeft, curY + 7f, labelPaint)
        curY += 10f
        canvas.drawText(registeredOn, innerLeft, curY + 9f, valuePaint)
        curY += 15f

        canvas.drawLine(innerLeft, curY, innerRight, curY, dividerPaint)
        curY += 7f

        canvas.drawText("REGISTERED BY", innerLeft, curY + 7f, labelPaint)
        curY += 10f
        canvas.drawText(registeredBy, innerLeft, curY + 9f, valuePaint)
        curY += 16f

        // Draw Card 5 outline (STROKE ONLY)
        canvas.drawRoundRect(RectF(left, card5Top, right, curY), 6f, 6f, cardBorderPaint)
        curY += 40f

        // 3. Center Copyright text (as in Screenshot 2)
        val copyPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#475569")
            textSize = 8.5f
            typeface = Typeface.DEFAULT
        }
        val copyText = "© 2026 KDA e-Nivaran Kota Development Authority. All Rights Reserved.  |  Version 1.0.0"
        val copyW = copyPaint.measureText(copyText)
        val copyX = left + ((usableWidth - copyW) / 2f)
        canvas.drawText(copyText, copyX, curY, copyPaint)

        // Draw Page 2 Footer
        drawFooter(canvas, left, right, pageUrl, 2, 2)
        pdfDocument.finishPage(page)
    }

    private fun drawCardHeaderBar(
        canvas: Canvas,
        left: Float,
        top: Float,
        right: Float,
        title: String,
        headerPaint: Paint,
        borderPaint: Paint,
        titlePaint: TextPaint
    ) {
        val r = 6f
        val headerH = 24f

        // Draw header background strip with rounded top corners
        val path = Path()
        val radii = floatArrayOf(r, r, r, r, 0f, 0f, 0f, 0f)
        path.addRoundRect(RectF(left, top, right, top + headerH), radii, Path.Direction.CW)
        canvas.drawPath(path, headerPaint)

        // Header bottom divider line
        canvas.drawLine(left, top + headerH, right, top + headerH, borderPaint)

        // Header title text
        canvas.drawText(title, left + 14f, top + 16f, titlePaint)
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
