package `in`.gov.rajasthan.kdakota.enivaran.department

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "in.gov.rajasthan.kdakota.enivaran/print"
    private var activePrintWebView: WebView? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "print") {
                val title = call.argument<String>("title") ?: "KDA-Complaint-Print"
                val url = call.argument<String>("url") ?: "https://kdakota.rajasthan.gov.in/enivaran/"

                runOnUiThread {
                    startPrintJob(title, url)
                    result.success(true)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun findWebView(root: View?): WebView? {
        if (root == null) return null
        if (root is WebView) return root
        if (root is ViewGroup) {
            for (i in 0 until root.childCount) {
                val child = findWebView(root.getChildAt(i))
                if (child != null) return child
            }
        }
        return null
    }

    private fun startPrintJob(rawTitle: String, url: String) {
        val jobName = rawTitle.replace(Regex("[^a-zA-Z0-9_-]"), "_").take(50).ifEmpty { "KDA-Complaint" }
        val printManager = getSystemService(Context.PRINT_SERVICE) as? PrintManager ?: return

        val printAttributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
            .build()

        // 1. Primary: Print directly from the live on-screen WebView (instant & 100% rendered)
        val onScreenWebView = findWebView(window.decorView)
        if (onScreenWebView != null) {
            val printAdapter = onScreenWebView.createPrintDocumentAdapter(jobName)
            printManager.print(jobName, printAdapter, printAttributes)
            return
        }

        // 2. Fallback: dedicated off-screen webview
        val printWebView = WebView(this)
        activePrintWebView = printWebView

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
